import Foundation
import Contracts

/// Parses one lesson file (PLAN.md, "Authoring syntax").
///
/// - Steps are separated by a `---` line with a blank line (or the file edge) on each side.
///   A `---` directly under text is a heading underline and does not split. Fences are respected.
/// - Inside a step, fenced blocks become `.code` / `.diagram`; fences for other languages stay
///   in the prose. Consecutive `- [ ]` / `- [x]` lines become one `.choice`. A line holding only a
///   link to `exercises/*.md` becomes `.exercise`. Everything else is `.markdown`, merged.
public enum LessonParser {
    /// - Parameters:
    ///   - resolveExercise: maps a link target such as `exercises/first-true.md` to the exercise id,
    ///     or nil if there's no such exercise.
    ///   - recorded: finds what `tools/` recorded for a block hash.
    public static func parse(
        _ source: String,
        path: String,
        resolveExercise: @escaping (_ link: String) -> String? = { _ in nil },
        recorded: @escaping RecordedLookup = { _ in nil }
    ) throws -> Lesson {
        let lines = SourceLines.split(source)
        guard let (frontmatter, bodyStart) = try Frontmatter.extract(from: lines, path: path) else {
            throw ContentError(path: path, line: 1, message: "lesson needs frontmatter with `id` and `title`")
        }
        let id = try frontmatter.requiredString("id")
        let title = try frontmatter.requiredString("title")

        let pieces = try MarkdownScanner.pieces(Array(lines[bodyStart...]), path: path)
        var steps: [Step] = []
        for group in splitSteps(pieces) {
            var parser = StepParser(path: path, resolveExercise: resolveExercise, recorded: recorded)
            if let step = try parser.parse(group) { steps.append(step) }
        }
        guard !steps.isEmpty else {
            throw ContentError(path: path, line: lines.last?.number, message: "lesson has no steps")
        }
        return Lesson(id: id, title: title, steps: steps)
    }

    // MARK: Step splitting

    private static func splitSteps(_ pieces: [Piece]) -> [[Piece]] {
        func blank(_ index: Int) -> Bool {
            guard pieces.indices.contains(index) else { return true }
            if case .text(let line) = pieces[index] { return line.isBlank }
            return false
        }
        var groups: [[Piece]] = []
        var current: [Piece] = []
        for (index, piece) in pieces.enumerated() {
            if case .text(let line) = piece,
               line.text.trimmingCharacters(in: .whitespaces) == "---",
               blank(index - 1), blank(index + 1) {
                groups.append(current)
                current = []
            } else {
                current.append(piece)
            }
        }
        groups.append(current)
        return groups
    }

    // MARK: Step contents

    private struct ProseLine {
        var line: Line
        /// Inside a fence that stays prose: never a choice or link.
        var literal: Bool
    }

    private struct StepParser {
        let path: String
        let resolveExercise: (String) -> String?
        let recorded: RecordedLookup
        var blocks: [Block] = []
        var prose: [ProseLine] = []

        init(path: String, resolveExercise: @escaping (String) -> String?, recorded: @escaping RecordedLookup) {
            self.path = path
            self.resolveExercise = resolveExercise
            self.recorded = recorded
        }

        mutating func parse(_ pieces: [Piece]) throws -> Step? {
            for piece in pieces {
                switch piece {
                case .text(let line):
                    prose.append(ProseLine(line: line, literal: false))
                case .fence(let fence):
                    try add(fence)
                }
            }
            try flushProse()
            guard !blocks.isEmpty else { return nil }
            return Step(kind: Self.kind(of: blocks), blocks: blocks)
        }

        private mutating func add(_ fence: Fence) throws {
            switch try CodeInfo.parse(fence.info, path: path, line: fence.open.number) {
            case .prose:
                prose.append(contentsOf: fence.raw.map { ProseLine(line: $0, literal: true) })
            case .diagram:
                try flushProse()
                do {
                    blocks.append(.diagram(try DiagramParser.parse(fence.source)))
                } catch let error as ContentError {
                    throw error.located(in: path, lineOffset: fence.open.number)
                }
            case .code(let language, let role):
                try flushProse()
                var block = CodeBlock(language: language, role: role, source: fence.source)
                switch role {
                case .predict:
                    block.recordedOutput = recorded(RecordedHash.hash(source: block.source))?.output
                case .trace:
                    let hash = RecordedHash.hash(source: block.source)
                    if recorded(hash)?.hasTrace == true {
                        block.recordedTrace = RecordedHash.relativePath(forHash: hash)
                    }
                default:
                    break
                }
                blocks.append(.code(block))
            }
        }

        private mutating func flushProse() throws {
            defer { prose = [] }
            var text: [String] = []
            var options: [(option: ChoiceQuestion.Option, line: Int)] = []

            func emitText() {
                if let markdown = Self.trimmedMarkdown(text) { blocks.append(.markdown(markdown)) }
                text = []
            }
            func emitChoice() throws {
                guard let first = options.first else { return }
                if !options.contains(where: { $0.option.isCorrect }) {
                    throw ContentError(path: path, line: first.line, message: "choice has no correct option (mark one with `- [x]`)")
                }
                blocks.append(.choice(ChoiceQuestion(options: options.map(\.option))))
                options = []
            }

            for item in prose {
                if !item.literal, let option = Self.choiceOption(item.line.text) {
                    emitText()
                    options.append((option, item.line.number))
                    continue
                }
                try emitChoice()
                if !item.literal, let target = Self.exerciseLink(item.line.text) {
                    emitText()
                    guard let id = resolveExercise(target) else {
                        throw ContentError(path: path, line: item.line.number, message: "no exercise at `\(target)`")
                    }
                    blocks.append(.exercise(id: id))
                    continue
                }
                text.append(item.line.text)
            }
            emitText()
            try emitChoice()
        }

        // MARK: Line classifiers

        static func choiceOption(_ text: String) -> ChoiceQuestion.Option? {
            let line = text.drop(while: { $0 == " " || $0 == "\t" })
            for (marker, correct) in [("- [ ] ", false), ("- [x] ", true), ("- [X] ", true)] {
                if line.hasPrefix(marker) {
                    let body = line.dropFirst(marker.count).trimmingCharacters(in: .whitespaces)
                    return body.isEmpty ? nil : ChoiceQuestion.Option(text: body, isCorrect: correct)
                }
            }
            return nil
        }

        /// `[label](exercises/name.md)` alone on a line gives `exercises/name.md`.
        static func exerciseLink(_ text: String) -> String? {
            let line = text.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("["), line.hasSuffix(")"),
                  let split = line.range(of: "](", options: .backwards) else { return nil }
            var target = String(line[split.upperBound...].dropLast())
            if target.hasPrefix("./") { target.removeFirst(2) }
            guard target.hasPrefix("exercises/"), target.hasSuffix(".md"), !target.contains(" ") else { return nil }
            return target
        }

        static func trimmedMarkdown(_ lines: [String]) -> String? {
            func blank(_ line: String) -> Bool { line.allSatisfy { $0 == " " || $0 == "\t" } }
            guard let first = lines.firstIndex(where: { !blank($0) }),
                  let last = lines.lastIndex(where: { !blank($0) }) else { return nil }
            return lines[first...last].joined(separator: "\n")
        }

        // MARK: Kind

        /// PLAN.md: trace, predict, arrange, then implement (exercise link), then analyze
        /// (choice without a trace), else read.
        static func kind(of blocks: [Block]) -> StepKind {
            var trace = false, predict = false, arrange = false, exercise = false, choice = false
            for block in blocks {
                switch block {
                case .code(let code):
                    switch code.role {
                    case .trace: trace = true
                    case .predict: predict = true
                    case .arrange: arrange = true
                    default: break
                    }
                case .exercise: exercise = true
                case .choice: choice = true
                case .markdown, .diagram: break
                }
            }
            if trace { return .trace }
            if predict { return .predict }
            if arrange { return .arrange }
            if exercise { return .implement }
            if choice { return .analyze }
            return .read
        }
    }
}
