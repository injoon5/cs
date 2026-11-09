import CPythonBridge
import Contracts
import Dispatch
import Foundation

/// The embedded CPython interpreter (PLAN.md, Python runtime design).
///
/// One interpreter lives on a dedicated thread. Calls run one at a time, in order.
/// Python-side entry points are `app_support.run/run_tests/trace/visualize`
/// (docs/contracts.md); when `app_support` isn't bundled, `run` falls back to a
/// plain `exec` and the others return a failure.
public actor PythonRuntime: PythonRunning {
    public static let shared = PythonRuntime()

    public struct Configuration: Sendable {
        /// PYTHONHOME: the bundle's `python` folder, holding `lib/python3.14`.
        public var home: URL
        /// Prepended to `sys.path`. Holds `app_support.py`, `trace.py`, `viz.py`.
        public var searchPaths: [URL]
        /// Working directory for user code.
        public var scratchDirectory: URL

        public init(home: URL, searchPaths: [URL], scratchDirectory: URL) {
            self.home = home
            self.searchPaths = searchPaths
            self.scratchDirectory = scratchDirectory
        }

        public static var bundled: Configuration {
            let resources = Bundle.main.resourceURL ?? Bundle.main.bundleURL
            let python = resources.appending(path: "python", directoryHint: .isDirectory)
            let scratch = FileManager.default.temporaryDirectory.appending(path: "run", directoryHint: .isDirectory)
            return Configuration(home: python, searchPaths: [python], scratchDirectory: scratch)
        }
    }

    /// False on platforms without an embedded interpreter (macOS and Linux builds of the package).
    public nonisolated static var isAvailable: Bool { csb_is_available() != 0 }

    private let configuration: Configuration
    private let thread = PythonThread()
    private var startup: Task<PythonError?, Never>?
    /// I/O of the call that's running, so `stop()` can end a pending `input()`.
    private var activeIO: RunIO?

    public init(configuration: Configuration = .bundled) {
        self.configuration = configuration
    }

    /// Starts the interpreter if needed. Returns the startup error, if any.
    /// Safe to call repeatedly; call early (at launch) to hide startup time.
    @discardableResult
    public func start() async -> PythonError? {
        if let startup {
            return await startup.value
        }
        let configuration = configuration
        let thread = thread
        let task = Task { await thread.perform { Self.initialize(configuration) } }
        startup = task
        return await task.value
    }

    // MARK: - PythonRunning

    public func run(
        _ code: String,
        output: @escaping @Sendable (OutputChunk) -> Void,
        readLine: @escaping @Sendable (_ prompt: String) async -> String?
    ) async -> RunResult {
        let clock = ContinuousClock()
        let start = clock.now
        let io = RunIO(output: output, readLine: readLine)

        var reply = await call("app_support", "run", [code], io: io)
        if case .missingModule = reply {
            reply = await call("_csruntime", "run", [code], io: io)
        }

        let outcome: RunOutcome
        switch reply {
        case .value(let json):
            switch decode(RunPayload.self, from: json, function: "run") {
            case .success(let payload):
                outcome = payload.error.map { Self.outcome(for: $0, io: io) } ?? .finished
            case .failure(let error):
                outcome = .failed(error)
            }
        case .missingModule(let error), .failed(let error):
            outcome = Self.outcome(for: error, io: io)
        }
        return RunResult(outcome: outcome, duration: (clock.now - start).seconds)
    }

    public func runTests(_ code: String, exercise: Exercise, timeout: Double) async -> TestReport {
        let testLines = (try? JSONEncoder().encode(exercise.testLines)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let args = [code, testLines, exercise.pythonTests ?? "", String(timeout)]
        switch await call("app_support", "run_tests", args, io: nil) {
        case .value(let json):
            switch decode(TestReport.self, from: json, function: "run_tests") {
            case .success(let report): return report
            case .failure(let error): return TestReport(results: [], loadError: error)
            }
        case .missingModule(let error), .failed(let error):
            return TestReport(results: [], loadError: error)
        }
    }

    public func trace(_ code: String) async -> Trace {
        switch await call("app_support", "trace", [code], io: nil) {
        case .value(let json):
            switch decode(Trace.self, from: json, function: "trace") {
            case .success(let trace): return trace
            case .failure(let error): return Trace(steps: [], error: error)
            }
        case .missingModule(let error), .failed(let error):
            return Trace(steps: [], error: error)
        }
    }

    public func visualize(_ code: String) async -> VizRun {
        let clock = ContinuousClock()
        let start = clock.now
        let io = RunIO(output: nil, readLine: nil)
        let reply = await call("app_support", "visualize", [code], io: io)
        let duration = { (clock.now - start).seconds }

        switch reply {
        case .value(let json):
            switch decode(VizPayload.self, from: json, function: "visualize") {
            case .success(let payload):
                let outcome = payload.error.map { Self.outcome(for: $0, io: io) } ?? .finished
                return VizRun(frames: payload.frames, output: payload.output, result: RunResult(outcome: outcome, duration: duration()))
            case .failure(let error):
                return VizRun(frames: [], output: "", result: RunResult(outcome: .failed(error), duration: duration()))
            }
        case .missingModule(let error), .failed(let error):
            return VizRun(frames: [], output: "", result: RunResult(outcome: Self.outcome(for: error, io: io), duration: duration()))
        }
    }

    public func stop() async {
        activeIO?.requestStop()
        // Taking the GIL can wait on a long C call; never block the caller or the cooperative pool.
        DispatchQueue.global(qos: .userInitiated).async {
            _ = csb_interrupt()
        }
    }

    // MARK: - Calls

    private enum Reply: Sendable {
        /// The function's JSON result.
        case value(String)
        /// The module isn't installed.
        case missingModule(PythonError)
        case failed(PythonError)
    }

    private func call(_ module: String, _ function: String, _ args: [String], io: RunIO?) async -> Reply {
        if let error = await start() {
            return .failed(error)
        }
        activeIO = io
        defer { activeIO = nil }
        return await thread.perform {
            RunIO.current.withLock { $0 = io }
            defer {
                io?.flush()
                RunIO.current.withLock { $0 = nil }
            }
            return Self.callOnThread(module, function, args)
        }
    }

    /// Runs on the Python thread.
    private static func callOnThread(_ module: String, _ function: String, _ args: [String]) -> Reply {
        var error: UnsafeMutablePointer<CChar>?
        let result = withCStrings(args) { argv in
            csb_call(module, function, argv.baseAddress, Int32(argv.count), &error)
        }
        guard let result else {
            let message = takeString(error) ?? "RuntimeError\nPython call failed."
            return .failed(errorFromBridge(message))
        }
        let text = takeString(result) ?? ""

        if text.hasPrefix("ok:") {
            return .value(String(text.dropFirst(3)))
        }
        if text.hasPrefix("err:"), let data = text.dropFirst(4).data(using: .utf8),
           let failure = try? JSONDecoder().decode(CallFailure.self, from: data) {
            return failure.missing ? .missingModule(failure.error) : .failed(failure.error)
        }
        return .failed(PythonError(type: "RuntimeError", message: "Unexpected reply from _csruntime.call.", traceback: ""))
    }

    /// Runs on the Python thread.
    private static func initialize(_ configuration: Configuration) -> PythonError? {
        RunIO.installCallbacks()
        var error: UnsafeMutablePointer<CChar>?
        let paths = configuration.searchPaths.map { $0.path(percentEncoded: false) }
        let status = withCStrings(paths) { argv in
            csb_initialize(configuration.home.path(percentEncoded: false), argv.baseAddress, Int32(argv.count), Bootstrap.source, &error)
        }
        if status != 0 {
            let message = takeString(error) ?? "Unknown error"
            return PythonError(type: "RuntimeError", message: "Python failed to start: \(message)", traceback: "")
        }
        let scratch = configuration.scratchDirectory.path(percentEncoded: false)
        if case .failed(let error) = callOnThread("_csruntime", "configure", [scratch]) {
            return error
        }
        return nil
    }

    // MARK: - Results

    private struct RunPayload: Decodable {
        var error: PythonError?
    }

    private struct VizPayload: Decodable {
        var frames: [VizFrame]
        var output: String
        var error: PythonError?
    }

    private struct CallFailure: Decodable {
        var missing: Bool
        var error: PythonError
    }

    private static func outcome(for error: PythonError, io: RunIO?) -> RunOutcome {
        if error.type == "KeyboardInterrupt" || io?.stopRequested == true {
            return .stopped
        }
        return .failed(error)
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String, function: String) -> Result<T, PythonError> {
        do {
            return .success(try JSONDecoder().decode(T.self, from: Data(json.utf8)))
        } catch {
            return .failure(PythonError(
                type: "RuntimeError",
                message: "Couldn't read the result of app_support.\(function): \(error.localizedDescription)",
                traceback: ""
            ))
        }
    }

    /// `"Type\nmessage"` from the C bridge.
    private static func errorFromBridge(_ message: String) -> PythonError {
        let parts = message.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        let type = parts.first.map(String.init) ?? "RuntimeError"
        let detail = parts.count > 1 ? String(parts[1]) : ""
        return PythonError(type: type, message: detail, traceback: "")
    }
}

// MARK: - C helpers

/// Copies a `malloc`ed C string into a Swift string and frees it.
private func takeString(_ pointer: UnsafeMutablePointer<CChar>?) -> String? {
    guard let pointer else { return nil }
    defer { free(pointer) }
    return String(cString: pointer)
}

/// Calls `body` with a C array of NUL-terminated copies of `strings`.
private func withCStrings<R>(_ strings: [String], _ body: (UnsafeBufferPointer<UnsafePointer<CChar>>) -> R) -> R {
    let copies: [UnsafeMutablePointer<CChar>] = strings.map { string in
        let utf8 = Array(string.utf8CString)
        let copy = UnsafeMutablePointer<CChar>.allocate(capacity: utf8.count)
        copy.initialize(from: utf8, count: utf8.count)
        return copy
    }
    defer {
        for copy in copies {
            copy.deallocate()
        }
    }
    let pointers = copies.map { UnsafePointer($0) }
    return pointers.withUnsafeBufferPointer(body)
}

private extension Duration {
    var seconds: Double {
        let (seconds, attoseconds) = components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
}
