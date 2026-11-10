import Contracts

// Display strings and derived values shared by the exercise screens.

extension ExerciseLevel {
    var displayName: String {
        switch self {
        case .warmup: "Warm-up"
        case .core: "Core"
        case .stretch: "Stretch"
        }
    }

    var sortOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

extension PythonError {
    var isTimeout: Bool { type == "TimeoutError" }
    var isStop: Bool { type == "KeyboardInterrupt" }

    /// One line for a result row: "Took too long", "Stopped", or "IndexError: list index out of range".
    var summary: String {
        if isTimeout { return "Took too long" }
        if isStop { return "Stopped" }
        return message.isEmpty ? type : "\(type): \(message)"
    }
}

extension TestReport {
    var passedCount: Int { results.count(where: \.passed) }

    /// The run was cut short with Stop; not counted as an attempt.
    var wasStopped: Bool {
        loadError?.isStop == true || results.contains { $0.error?.isStop == true }
    }

    /// Line to highlight in the editor: the load error's, else the first failing test's.
    var errorLine: Int? {
        if let loadError { return loadError.line }
        return results.lazy.compactMap { $0.passed ? nil : $0.error?.line }.first
    }

    var summary: String {
        if let loadError {
            if loadError.isStop { return "Stopped" }
            return loadError.line.map { "\(loadError.type) on line \($0)" } ?? loadError.type
        }
        if results.isEmpty { return "No tests" }
        return "\(passedCount) of \(results.count) passed"
    }
}
