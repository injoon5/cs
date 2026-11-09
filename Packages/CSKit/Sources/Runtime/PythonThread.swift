import Foundation

/// One long-lived thread that owns the interpreter. Jobs run in submission order.
/// Python code can block for a long time, so it stays off the cooperative pool.
final class PythonThread: @unchecked Sendable {
    // `jobs` is guarded by `condition`.
    private let condition = NSCondition()
    private var jobs: [@Sendable () -> Void] = []

    init(name: String = "Python") {
        let thread = Thread { [self] in loop() }
        thread.name = name
        thread.qualityOfService = .userInitiated
        // Deep recursion in learner code needs more than the 512 KB default.
        thread.stackSize = 16 << 20
        thread.start()
    }

    /// Runs `body` on the Python thread and returns its result.
    func perform<T: Sendable>(_ body: @escaping @Sendable () -> T) async -> T {
        await withCheckedContinuation { continuation in
            submit { continuation.resume(returning: body()) }
        }
    }

    private func submit(_ job: @escaping @Sendable () -> Void) {
        condition.lock()
        jobs.append(job)
        condition.signal()
        condition.unlock()
    }

    private func loop() {
        while true {
            condition.lock()
            while jobs.isEmpty {
                condition.wait()
            }
            let job = jobs.removeFirst()
            condition.unlock()
            job()
        }
    }
}
