import Contracts
import Foundation
import Observation

/// A block's position in a lesson.
struct BlockID: Hashable, Sendable {
    let step: Int
    let block: Int
}

struct PredictResult: Equatable {
    var expected: String
    var isCorrect: Bool
}

struct ArrangeResult: Equatable {
    var report: TestReport?
    var isCorrect: Bool
}

/// The result of one Check, for haptics.
struct CheckEvent: Equatable {
    let id: Int
    let isCorrect: Bool
}

/// State of one open lesson: which steps are showing, answers and results.
@MainActor
@Observable
final class ReaderModel {
    let lesson: Lesson
    let unitID: String

    /// Steps on screen, counting from the first. At least 1.
    private(set) var revealed: Int
    /// Steps whose questions have been checked.
    private(set) var checkedSteps: Set<Int> = []
    private(set) var isFinished = false
    private(set) var isChecking = false
    private(set) var lastCheck: CheckEvent?

    var predictAnswers: [BlockID: String] = [:]
    private(set) var predictResults: [BlockID: PredictResult] = [:]
    var choiceSelections: [BlockID: Set<Int>] = [:]
    private(set) var choiceResults: [BlockID: Bool] = [:]
    var arrangeOrders: [BlockID: [Int]] = [:]
    private(set) var arrangeResults: [BlockID: ArrangeResult] = [:]

    private let library: ContentLibrary
    private let runner: any PythonRunning
    let progress: any ProgressRecording

    init(lesson: Lesson, unitID: String, library: ContentLibrary, runner: any PythonRunning, progress: any ProgressRecording) {
        self.lesson = lesson
        self.unitID = unitID
        self.library = library
        self.runner = runner
        self.progress = progress

        let saved = progress.lessonProgress(lesson.id)
        let count = max(lesson.steps.count, 1)
        switch saved.state {
        case .completed:
            revealed = count
            checkedSteps = Set(0..<count)
        case .inProgress:
            revealed = min(saved.furthestStep + 1, count)
            checkedSteps = Set(0..<(revealed - 1))
        case .notStarted:
            revealed = 1
        }

        for (stepIndex, step) in lesson.steps.enumerated() {
            for (blockIndex, block) in step.blocks.enumerated() {
                if case .code(let code) = block, code.role == .arrange {
                    let count = ArrangeShuffle.lines(of: code.source).count
                    let id = BlockID(step: stepIndex, block: blockIndex)
                    arrangeOrders[id] = ArrangeShuffle.order(count: count, seed: "\(lesson.id)/\(stepIndex)")
                }
            }
        }
    }

    var stepCount: Int { lesson.steps.count }
    var currentStep: Int { revealed - 1 }
    var isAtLastStep: Bool { revealed >= stepCount }
    var fractionComplete: Double {
        stepCount == 0 ? 1 : Double(revealed) / Double(stepCount)
    }

    /// Records the steps already on screen. Call when the reader appears.
    func recordOpened() {
        guard stepCount > 0 else { return }
        progress.recordStep(lessonID: lesson.id, stepIndex: currentStep, stepCount: stepCount)
    }

    // MARK: Steps

    static func isQuestion(_ block: Block) -> Bool {
        switch block {
        case .choice: true
        case .code(let code): code.role == .predict || code.role == .arrange
        default: false
        }
    }

    func hasQuestion(_ step: Int) -> Bool {
        lesson.steps.indices.contains(step) && lesson.steps[step].blocks.contains(where: Self.isQuestion)
    }

    /// The current step has a question that hasn't been checked.
    var needsCheck: Bool {
        hasQuestion(currentStep) && !checkedSteps.contains(currentStep)
    }

    func isChecked(_ step: Int) -> Bool {
        checkedSteps.contains(step)
    }

    /// Questions take answers only on the current step until checked.
    func acceptsAnswers(_ step: Int) -> Bool {
        step == currentStep && !checkedSteps.contains(step) && !isChecking
    }

    /// Every question on the current step has an answer.
    var canCheck: Bool {
        guard needsCheck, !isChecking else { return false }
        for (index, block) in lesson.steps[currentStep].blocks.enumerated() {
            let id = BlockID(step: currentStep, block: index)
            switch block {
            case .choice:
                if choiceSelections[id, default: []].isEmpty { return false }
            case .code(let code) where code.role == .predict:
                if (predictAnswers[id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
            default:
                break
            }
        }
        return true
    }

    func reveal() {
        guard !needsCheck, revealed < stepCount else { return }
        revealed += 1
        progress.recordStep(lessonID: lesson.id, stepIndex: currentStep, stepCount: stepCount)
    }

    func finish() {
        guard !needsCheck, isAtLastStep else { return }
        isFinished = true
    }

    /// Shows every step again from the first.
    func startOver() {
        revealed = 1
        isFinished = false
        checkedSteps = []
        predictAnswers = [:]
        predictResults = [:]
        choiceSelections = [:]
        choiceResults = [:]
        arrangeResults = [:]
    }

    #if DEBUG
    /// Skips the current step's question, for screenshots.
    func debugMarkChecked() {
        checkedSteps.insert(currentStep)
    }
    #endif

    // MARK: Checking

    func check() async {
        guard canCheck else { return }
        let stepIndex = currentStep
        let step = lesson.steps[stepIndex]
        isChecking = true
        defer { isChecking = false }

        var allCorrect = true
        for (index, block) in step.blocks.enumerated() {
            let id = BlockID(step: stepIndex, block: index)
            switch block {
            case .choice(let question):
                let correct = Set(question.options.indices.filter { question.options[$0].isCorrect })
                let isCorrect = choiceSelections[id, default: []] == correct
                choiceResults[id] = isCorrect
                allCorrect = allCorrect && isCorrect
            case .code(let code) where code.role == .predict:
                let expected: String = if let recorded = code.recordedOutput {
                    recorded
                } else {
                    await output(of: code.source)
                }
                let isCorrect = OutputMatch.matches(predictAnswers[id] ?? "", expected)
                predictResults[id] = PredictResult(expected: expected, isCorrect: isCorrect)
                allCorrect = allCorrect && isCorrect
            case .code(let code) where code.role == .arrange:
                let result = await checkArrange(code, id: id, step: step)
                arrangeResults[id] = result
                allCorrect = allCorrect && result.isCorrect
            default:
                break
            }
        }
        checkedSteps.insert(stepIndex)
        lastCheck = CheckEvent(id: (lastCheck?.id ?? 0) + 1, isCorrect: allCorrect)
    }

    func arrangedCode(_ code: CodeBlock, id: BlockID) -> String {
        let lines = ArrangeShuffle.lines(of: code.source)
        let order = arrangeOrders[id] ?? Array(lines.indices)
        return order.map { lines[$0] }.joined(separator: "\n") + "\n"
    }

    private func checkArrange(_ code: CodeBlock, id: BlockID, step: Step) async -> ArrangeResult {
        let arranged = arrangedCode(code, id: id)
        guard let exercise = ArrangeTests.exercise(for: step, lessonID: lesson.id, stepIndex: id.step, library: library) else {
            // No tests to run: the order itself is the answer.
            let isCorrect = arrangeOrders[id] == Array(ArrangeShuffle.lines(of: code.source).indices)
            return ArrangeResult(report: nil, isCorrect: isCorrect)
        }
        let report = await runner.runTests(arranged, exercise: exercise, timeout: 2)
        return ArrangeResult(report: report, isCorrect: report.passed)
    }

    /// Runs a predict block when no output was recorded for it.
    private func output(of source: String) async -> String {
        let buffer = OutputBuffer()
        let result = await runner.run(source, output: { buffer.append($0) }, readLine: { _ in nil })
        var text = buffer.drain().filter { $0.stream == .stdout }.map(\.text).joined()
        if case .failed(let error) = result.outcome {
            text += "\(error.type): \(error.message)\n"
        }
        return text
    }
}
