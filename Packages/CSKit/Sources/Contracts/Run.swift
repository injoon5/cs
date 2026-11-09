import Foundation

// Results of running Python. JSON shapes match what `Resources/python/app_support.py` emits.

public enum OutputStream: String, Codable, Sendable, Hashable {
    case stdout, stderr
}

public struct OutputChunk: Codable, Sendable, Hashable {
    public var stream: OutputStream
    public var text: String

    public init(stream: OutputStream, text: String) {
        self.stream = stream
        self.text = text
    }
}

public struct PythonError: Codable, Sendable, Hashable, Error {
    /// Exception class name, e.g. `IndexError`.
    public var type: String
    public var message: String
    /// Formatted traceback with support frames removed.
    public var traceback: String
    /// Line in the user's code, 1-based, when known.
    public var line: Int?

    public init(type: String, message: String, traceback: String, line: Int? = nil) {
        self.type = type
        self.message = message
        self.traceback = traceback
        self.line = line
    }
}

public enum RunOutcome: Codable, Sendable, Hashable {
    case finished
    case failed(PythonError)
    /// Stopped by the user.
    case stopped
    case timedOut
}

public struct RunResult: Codable, Sendable, Hashable {
    public var outcome: RunOutcome
    /// Seconds.
    public var duration: Double

    public init(outcome: RunOutcome, duration: Double) {
        self.outcome = outcome
        self.duration = duration
    }
}

/// One test, from `app_support.run_tests`.
public struct TestResult: Codable, Sendable, Hashable, Identifiable {
    /// The test line as written (`first_true([]) == 0`) or `assert` line for python tests.
    public var name: String
    public var passed: Bool
    /// Source of the call, e.g. `first_true([])`.
    public var input: String?
    /// `repr` of the expected value.
    public var expected: String?
    /// `repr` of what the call returned.
    public var got: String?
    public var error: PythonError?
    /// Seconds.
    public var duration: Double

    public var id: String { name }

    public init(name: String, passed: Bool, input: String? = nil, expected: String? = nil, got: String? = nil, error: PythonError? = nil, duration: Double = 0) {
        self.name = name
        self.passed = passed
        self.input = input
        self.expected = expected
        self.got = got
        self.error = error
        self.duration = duration
    }
}

public struct TestReport: Codable, Sendable, Hashable {
    public var results: [TestResult]
    /// Set when the user code itself failed to load (syntax error, error at top level).
    public var loadError: PythonError?

    public var passed: Bool { loadError == nil && !results.isEmpty && results.allSatisfy(\.passed) }

    public init(results: [TestResult], loadError: PythonError? = nil) {
        self.results = results
        self.loadError = loadError
    }
}

/// What the UI asks the Python runtime to do. Implemented by `Runtime.PythonRuntime`.
public protocol PythonRunning: Sendable {
    /// Runs code in fresh globals, streaming output. `input()` calls `readLine`.
    func run(
        _ code: String,
        output: @escaping @Sendable (OutputChunk) -> Void,
        readLine: @escaping @Sendable (_ prompt: String) async -> String?
    ) async -> RunResult

    /// Runs `exercise`'s tests against `code`. Each test has `timeout` seconds.
    func runTests(_ code: String, exercise: Exercise, timeout: Double) async -> TestReport

    /// Runs code under the tracer (PLAN.md, Step-through execution).
    func trace(_ code: String) async -> Trace

    /// Runs code and returns the `viz` frames it produced.
    func visualize(_ code: String) async -> VizRun

    /// Interrupts the current run with `KeyboardInterrupt`.
    func stop() async
}
