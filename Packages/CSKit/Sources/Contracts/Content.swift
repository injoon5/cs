import Foundation

// Content model produced by the `Content` loader from `content/` (see PLAN.md, Authoring syntax).
// Ids are stable slugs; progress is keyed by them.

public struct Track: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var title: String
    public var units: [Unit]

    public init(id: String, title: String, units: [Unit]) {
        self.id = id
        self.title = title
        self.units = units
    }
}

public struct Unit: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var title: String
    /// Unit ids this one builds on. Suggests order; nothing is locked.
    public var requires: [String]
    public var lessons: [Lesson]
    public var exercises: [Exercise]
    public var cards: [Card]

    public init(id: String, title: String, requires: [String] = [], lessons: [Lesson] = [], exercises: [Exercise] = [], cards: [Card] = []) {
        self.id = id
        self.title = title
        self.requires = requires
        self.lessons = lessons
        self.exercises = exercises
        self.cards = cards
    }
}

public struct Lesson: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var title: String
    public var steps: [Step]

    public init(id: String, title: String, steps: [Step]) {
        self.id = id
        self.title = title
        self.steps = steps
    }
}

/// The smallest thing on screen. Steps are separated by a `---` line with blank lines around it.
public struct Step: Codable, Sendable, Hashable {
    public var kind: StepKind
    public var blocks: [Block]

    public init(kind: StepKind, blocks: [Block]) {
        self.kind = kind
        self.blocks = blocks
    }
}

/// Derived from a step's blocks (PLAN.md, block table).
public enum StepKind: String, Codable, Sendable, Hashable {
    case read, predict, trace, arrange, implement, analyze
}

public enum Block: Codable, Sendable, Hashable {
    /// Prose, as Markdown source.
    case markdown(String)
    case code(CodeBlock)
    /// Task-list options (`- [x]` / `- [ ]`).
    case choice(ChoiceQuestion)
    /// A ```diagram block, parsed.
    case diagram(Diagram)
    /// A link alone on a line to `exercises/*.md`, resolved to the exercise id.
    case exercise(id: String)
}

public enum CodeLanguage: String, Codable, Sendable, Hashable {
    case python, shell
}

/// The info-string role of a fenced block.
public enum CodeRole: Codable, Sendable, Hashable {
    /// ```python / ```shell: runnable cell.
    case cell
    /// ```python trace stop=N
    case trace(stop: Int?)
    /// ```python predict: expected output is recorded by tools/ (`recordedOutput`).
    case predict
    /// ```python arrange: lines are shuffled by the app.
    case arrange
    case starter, solution
    /// ```python tests: plain asserts.
    case tests
    /// ```shell setup / ```shell check
    case setup, check
}

public struct CodeBlock: Codable, Sendable, Hashable {
    public var language: CodeLanguage
    public var role: CodeRole
    public var source: String
    /// For `predict`: the real output, recorded at build time.
    public var recordedOutput: String?
    /// For `trace`: path of the bundled trace JSON, relative to the content root.
    public var recordedTrace: String?

    public init(language: CodeLanguage, role: CodeRole, source: String, recordedOutput: String? = nil, recordedTrace: String? = nil) {
        self.language = language
        self.role = role
        self.source = source
        self.recordedOutput = recordedOutput
        self.recordedTrace = recordedTrace
    }
}

public struct ChoiceQuestion: Codable, Sendable, Hashable {
    public struct Option: Codable, Sendable, Hashable {
        public var text: String
        public var isCorrect: Bool
        public init(text: String, isCorrect: Bool) {
            self.text = text
            self.isCorrect = isCorrect
        }
    }

    public var options: [Option]
    public var allowsMultiple: Bool { options.filter(\.isCorrect).count > 1 }

    public init(options: [Option]) {
        self.options = options
    }
}

public enum ExerciseLevel: String, Codable, Sendable, Hashable, CaseIterable {
    case warmup, core, stretch
}

public struct Exercise: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var title: String
    public var level: ExerciseLevel
    public var language: CodeLanguage
    /// Problem statement, Markdown.
    public var prompt: String
    public var starter: String
    public var solution: String
    /// One `call == expected` per line, from the ```tests block.
    public var testLines: [String]
    /// Plain asserts, from a ```python tests block.
    public var pythonTests: String?
    /// Linux exercises: ```shell setup and ```shell check.
    public var setup: String?
    public var check: String?
    /// Ordered: nudge, approach, near-solution.
    public var hints: [String]

    public init(id: String, title: String, level: ExerciseLevel, language: CodeLanguage = .python, prompt: String, starter: String, solution: String, testLines: [String] = [], pythonTests: String? = nil, setup: String? = nil, check: String? = nil, hints: [String] = []) {
        self.id = id
        self.title = title
        self.level = level
        self.language = language
        self.prompt = prompt
        self.starter = starter
        self.solution = solution
        self.testLines = testLines
        self.pythonTests = pythonTests
        self.setup = setup
        self.check = check
        self.hints = hints
    }
}

/// From `cards.md`: each `##` heading is a question, the text under it the answer.
public struct Card: Codable, Sendable, Hashable, Identifiable {
    /// `<unit id>/<slug of question>`.
    public var id: String
    public var question: String
    public var answer: String

    public init(id: String, question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}
