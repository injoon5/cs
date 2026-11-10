import Contracts
import Observation

/// Runs an exercise's tests and keeps the latest report.
@Observable
@MainActor
final class ExerciseSession {
    /// A finished run. `id` changes every run so identical reports still trigger feedback.
    struct Completed: Equatable {
        let id: Int
        let report: TestReport
    }

    /// Seconds each test may take.
    static let timeout = 2.0

    private(set) var isRunning = false
    private(set) var last: Completed?

    private let runner: any PythonRunning
    private var nextID = 0

    init(runner: any PythonRunning) {
        self.runner = runner
    }

    @discardableResult
    func run(_ code: String, exercise: Exercise) async -> Completed? {
        guard !isRunning else { return nil }
        isRunning = true
        let report = await runner.runTests(code, exercise: exercise, timeout: Self.timeout)
        isRunning = false
        nextID += 1
        let completed = Completed(id: nextID, report: report)
        last = completed
        return completed
    }

    func stop() async {
        await runner.stop()
    }

    func clear() {
        last = nil
    }
}
