import Contracts
import Foundation

// Foundation-only helpers for the Learn screens: lookups, the suggested next lesson,
// answer matching and the arrange shuffle.

/// Where the Learn tab can navigate.
enum LearnRoute: Hashable {
    case unit(String)
    case lesson(unitID: String, lessonID: String)
    case exercise(String)
}

/// Lookups over a `ContentLibrary` by id.
struct LibraryIndex {
    let library: ContentLibrary
    private let unitsByID: [String: CourseUnit]

    init(library: ContentLibrary) {
        self.library = library
        var units: [String: CourseUnit] = [:]
        for unit in library.tracks.flatMap(\.units) {
            units[unit.id] = unit
        }
        unitsByID = units
    }

    var isEmpty: Bool {
        library.tracks.allSatisfy { $0.units.isEmpty }
    }

    func unit(_ id: String) -> CourseUnit? {
        unitsByID[id]
    }

    func lesson(_ lessonID: String, in unitID: String) -> Lesson? {
        unitsByID[unitID]?.lessons.first { $0.id == lessonID }
    }

    /// The lesson after `lessonID` in its unit.
    func lesson(after lessonID: String, in unitID: String) -> Lesson? {
        guard let lessons = unitsByID[unitID]?.lessons,
              let index = lessons.firstIndex(where: { $0.id == lessonID }),
              index + 1 < lessons.count
        else { return nil }
        return lessons[index + 1]
    }
}

/// What to study next: the first unit already started and not finished; otherwise the
/// first untouched unit whose `requires` are all finished. Nothing is locked; this only
/// picks which row to suggest.
enum NextLessonSuggestion {
    @MainActor
    static func suggest(in tracks: [Track], progress: any ProgressRecording) -> (unit: CourseUnit, lesson: Lesson)? {
        let units = tracks.flatMap(\.units)
        func states(_ unit: CourseUnit) -> [LessonState] {
            unit.lessons.map { progress.lessonProgress($0.id).state }
        }
        func isDone(_ unit: CourseUnit) -> Bool {
            states(unit).allSatisfy { $0 == .completed }
        }
        func firstOpenLesson(_ unit: CourseUnit) -> Lesson? {
            unit.lessons.first { progress.lessonProgress($0.id).state != .completed }
        }
        let doneIDs = Set(units.filter(isDone).map(\.id))

        let started = units.first { unit in
            !isDone(unit) && states(unit).contains { $0 != .notStarted }
        }
        let ready = units.first { unit in
            !isDone(unit) && unit.requires.allSatisfy(doneIDs.contains)
        }
        guard let unit = started ?? ready ?? units.first(where: { !isDone($0) }),
              let lesson = firstOpenLesson(unit)
        else { return nil }
        return (unit, lesson)
    }
}

/// Predict answers match the real output line by line, ignoring trailing whitespace and
/// trailing blank lines.
enum OutputMatch {
    static func normalized(_ text: String) -> [String] {
        var lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                var line = Substring(line)
                while let last = line.last, last.isWhitespace { line.removeLast() }
                return String(line)
            }
        while let last = lines.last, last.isEmpty { lines.removeLast() }
        return lines
    }

    static func matches(_ answer: String, _ expected: String) -> Bool {
        normalized(answer) == normalized(expected)
    }
}

/// Lines for an arrange block, shuffled the same way every time for a given seed.
enum ArrangeShuffle {
    /// Non-blank lines of `source`, indentation kept.
    static func lines(of source: String) -> [String] {
        source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// A permutation of `0..<count`, never the identity when `count > 1`.
    static func order(count: Int, seed: String) -> [Int] {
        var generator = SplitMix64(seed: fnv1a(seed))
        var order = Array(0..<count)
        order.shuffle(using: &generator)
        if count > 1, order == Array(0..<count) {
            order.append(order.removeFirst())
        }
        return order
    }

    private static func fnv1a(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }
}

/// Builds the exercise an arrange block's code is tested against.
enum ArrangeTests {
    /// The step's ```tests block, or else an exercise linked from the same step.
    static func exercise(for step: Step, lessonID: String, stepIndex: Int, library: ContentLibrary) -> Exercise? {
        for block in step.blocks {
            if case .code(let code) = block, code.role == .tests {
                return exercise(fromTests: code.source, id: "\(lessonID)#\(stepIndex)")
            }
        }
        for block in step.blocks {
            if case .exercise(let id) = block, let exercise = library.exercise(id: id) {
                return exercise
            }
        }
        return nil
    }

    /// Lesson ```tests and ```python tests blocks both arrive as `.tests`, so tell them apart
    /// by content: one `call == expected` per line, or plain asserts.
    static func exercise(fromTests source: String, id: String) -> Exercise {
        let lines = source
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        let isAsserts = lines.contains { line in
            !line.contains("==") || line.hasPrefix("assert") || line.hasPrefix("import ")
                || line.hasPrefix("from ") || line.hasPrefix("def ") || line.hasPrefix("for ")
        }
        return Exercise(
            id: id,
            title: "",
            level: .core,
            prompt: "",
            starter: "",
            solution: "",
            testLines: isAsserts ? [] : lines,
            pythonTests: isAsserts ? source : nil
        )
    }
}
