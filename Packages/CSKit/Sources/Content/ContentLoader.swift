import Foundation
import Contracts

/// Loads the `content/` folder (PLAN.md, "Authoring syntax"):
///
///     content/<track>/track.md              optional: id, title, order
///     content/<track>/<NN-unit>/unit.md     id, title, requires
///     content/<track>/<NN-unit>/NN-*.md     lessons, in filename order
///     content/<track>/<NN-unit>/exercises/*.md
///     content/<track>/<NN-unit>/cards.md    optional
///     content/_recorded/<hash>.json         from tools/; see `RecordedHash`
///
/// Folders starting with `_` or `.` are skipped.
public enum ContentLoader {
    public struct Result: Sendable {
        public var tracks: [Track]
        public var errors: [ContentError]
    }

    /// Loads everything or throws the first error.
    public static func load(root: URL) throws -> [Track] {
        let result = loadAll(root: root)
        if let first = result.errors.first { throw first }
        return result.tracks
    }

    /// Loads what it can and reports every problem found (for `tools/` and the validator).
    /// When `errors` isn't empty, `tracks` may be incomplete.
    public static func loadAll(root: URL) -> Result {
        var loader = Loader(root: root)
        loader.run()
        return Result(tracks: loader.tracks, errors: loader.errors)
    }
}

private struct Loader {
    let root: URL
    var tracks: [Track] = []
    var errors: [ContentError] = []

    private var unitPaths: [(unit: CourseUnit, path: String, requiresLine: Int)] = []
    private var seenUnitIDs: [String: String] = [:]
    private var seenExerciseIDs: [String: String] = [:]
    private let fileManager = FileManager.default

    init(root: URL) {
        self.root = root
    }

    // MARK: Walk

    mutating func run() {
        guard isDirectory(root) else {
            errors.append(ContentError(path: "", message: "content folder not found at \(root.path)"))
            return
        }
        var ordered: [(track: Track, order: Int?, folder: String)] = []
        for folder in subfolders(of: root) {
            if let entry = loadTrack(folder: folder) { ordered.append(entry) }
        }
        ordered.sort { lhs, rhs in
            switch (lhs.order, rhs.order) {
            case let (a?, b?) where a != b: return a < b
            case (_?, nil): return true
            case (nil, _?): return false
            default: return lhs.folder < rhs.folder
            }
        }
        tracks = ordered.map(\.track)

        let allUnitIDs = Set(unitPaths.map(\.unit.id))
        for item in unitPaths {
            for required in item.unit.requires where !allUnitIDs.contains(required) {
                errors.append(ContentError(path: item.path, line: item.requiresLine, message: "requires unknown unit `\(required)`"))
            }
        }
    }

    private mutating func loadTrack(folder: String) -> (track: Track, order: Int?, folder: String)? {
        let dir = root.appendingPathComponent(folder)
        var id = folder
        var title = Self.titleCase(folder)
        var order: Int?

        let trackFile = "\(folder)/track.md"
        if let source = read(trackFile) {
            do {
                let lines = SourceLines.split(source)
                guard let (frontmatter, _) = try Frontmatter.extract(from: lines, path: trackFile) else {
                    throw ContentError(path: trackFile, line: 1, message: "track.md needs frontmatter")
                }
                id = frontmatter.string("id") ?? id
                title = frontmatter.string("title") ?? title
                order = try frontmatter.int("order")
            } catch {
                record(error, path: trackFile)
            }
        }

        var units: [CourseUnit] = []
        for unitFolder in subfolders(of: dir) {
            if let unit = loadUnit(folder: "\(folder)/\(unitFolder)") { units.append(unit) }
        }
        return (Track(id: id, title: title, units: units), order, folder)
    }

    private mutating func loadUnit(folder: String) -> CourseUnit? {
        let unitPath = "\(folder)/unit.md"
        guard let source = read(unitPath) else {
            if !fileManager.fileExists(atPath: root.appendingPathComponent(unitPath).path) {
                errors.append(ContentError(path: unitPath, message: "unit folder has no unit.md"))
            }
            return nil
        }

        var unit: CourseUnit
        var requiresLine = 1
        do {
            let lines = SourceLines.split(source)
            guard let (frontmatter, _) = try Frontmatter.extract(from: lines, path: unitPath) else {
                throw ContentError(path: unitPath, line: 1, message: "unit.md needs frontmatter with `id` and `title`")
            }
            unit = CourseUnit(
                id: try frontmatter.requiredString("id"),
                title: try frontmatter.requiredString("title"),
                requires: try frontmatter.strings("requires")
            )
            requiresLine = frontmatter.line(of: "requires")
        } catch {
            record(error, path: unitPath)
            return nil
        }
        if let other = seenUnitIDs[unit.id] {
            errors.append(ContentError(path: unitPath, line: 1, message: "unit id `\(unit.id)` is already used by \(other)"))
        }
        seenUnitIDs[unit.id] = unitPath

        // Exercises first: lessons link to them by path.
        var exerciseIDs: [String: String] = [:]
        let exerciseNames = markdownFiles(in: "\(folder)/exercises", matching: { _ in true })
        for name in exerciseNames {
            let path = "\(folder)/exercises/\(name)"
            guard let text = read(path) else { continue }
            do {
                let exercise = try ExerciseParser.parse(text, path: path)
                if let other = seenExerciseIDs[exercise.id] {
                    errors.append(ContentError(path: path, line: 1, message: "exercise id `\(exercise.id)` is already used by \(other)"))
                }
                seenExerciseIDs[exercise.id] = path
                exerciseIDs["exercises/\(name)"] = exercise.id
                unit.exercises.append(exercise)
            } catch {
                record(error, path: path)
                exerciseIDs["exercises/\(name)"] = "?" // keeps links to a broken exercise from piling on errors
            }
        }

        let recorded = recordedLookup()
        var lessonIDs: Set<String> = []
        let lessonNames = markdownFiles(in: folder, matching: { Self.isLessonName($0) })
        for name in lessonNames {
            let path = "\(folder)/\(name)"
            guard let text = read(path) else { continue }
            do {
                let lesson = try LessonParser.parse(text, path: path, resolveExercise: { exerciseIDs[$0] }, recorded: recorded)
                if !lessonIDs.insert(lesson.id).inserted {
                    errors.append(ContentError(path: path, line: 1, message: "lesson id `\(lesson.id)` is used twice in this unit"))
                }
                unit.lessons.append(lesson)
            } catch {
                record(error, path: path)
            }
        }

        let cardsPath = "\(folder)/cards.md"
        if let text = read(cardsPath) {
            do {
                unit.cards = try CardsParser.parse(text, path: cardsPath, unitID: unit.id)
            } catch {
                record(error, path: cardsPath)
            }
        }

        unitPaths.append((unit, unitPath, requiresLine))
        return unit
    }

    // MARK: Files

    private func recordedLookup() -> RecordedLookup {
        let directory = root.appendingPathComponent("_recorded")
        return { hash in
            let url = directory.appendingPathComponent("\(hash).json")
            guard let data = try? Data(contentsOf: url),
                  let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
            return RecordedEntry(output: object["output"] as? String, hasTrace: object["trace"] != nil)
        }
    }

    private mutating func read(_ relativePath: String) -> String? {
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            errors.append(ContentError(path: relativePath, message: "can't read file as UTF-8"))
            return nil
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        var flag: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &flag) && flag.boolValue
    }

    /// Sorted names of non-hidden, non-underscore subfolders.
    private func subfolders(of url: URL) -> [String] {
        let names = (try? fileManager.contentsOfDirectory(atPath: url.path)) ?? []
        return names
            .filter { !$0.hasPrefix("_") && !$0.hasPrefix(".") && isDirectory(url.appendingPathComponent($0)) }
            .sorted()
    }

    private func markdownFiles(in relativeFolder: String, matching include: (String) -> Bool) -> [String] {
        let url = root.appendingPathComponent(relativeFolder)
        let names = (try? fileManager.contentsOfDirectory(atPath: url.path)) ?? []
        return names
            .filter { $0.hasSuffix(".md") && !$0.hasPrefix(".") && !isDirectory(url.appendingPathComponent($0)) && include($0) }
            .sorted()
    }

    /// `NN-name.md`: leading digits, a hyphen, then anything.
    private static func isLessonName(_ name: String) -> Bool {
        let digits = name.prefix(while: { $0.isASCII && $0.isNumber })
        return !digits.isEmpty && name.dropFirst(digits.count).hasPrefix("-")
    }

    private mutating func record(_ error: Error, path: String) {
        if let error = error as? ContentError {
            errors.append(error.path.isEmpty ? error.located(in: path) : error)
        } else {
            errors.append(ContentError(path: path, message: "\(error)"))
        }
    }

    /// `cs-foundations` becomes `Cs Foundations`.
    private static func titleCase(_ folder: String) -> String {
        folder.split(whereSeparator: { $0 == "-" || $0 == "_" })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
