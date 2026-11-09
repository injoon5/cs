import CPythonBridge
import Contracts
import Dispatch
import Foundation
import Synchronization

/// Output and input for one call into Python. The C callbacks route to `RunIO.current`.
final class RunIO: Sendable {
    /// The run in progress, if it streams output. Set and cleared on the Python thread.
    static let current = Mutex<RunIO?>(nil)

    private let output: OutputBatcher?
    private let readLine: (@Sendable (String) async -> String?)?
    private let state = Mutex(State())

    private struct State {
        var stopRequested = false
        var waiter: LineWaiter?
    }

    init(
        output: (@Sendable (OutputChunk) -> Void)?,
        readLine: (@Sendable (String) async -> String?)?
    ) {
        self.output = output.map(OutputBatcher.init)
        self.readLine = readLine
    }

    var stopRequested: Bool { state.withLock { $0.stopRequested } }

    /// Marks the run stopped and ends any pending `input()` with EOF.
    func requestStop() {
        let waiter = state.withLock { state in
            state.stopRequested = true
            return state.waiter
        }
        waiter?.finish(nil)
    }

    /// Delivers everything written so far. Blocks until delivered.
    func flush() {
        output?.flushNow()
    }

    fileprivate func write(stream: Int32, text: String) {
        output?.append(OutputChunk(stream: stream == 2 ? .stderr : .stdout, text: text))
    }

    /// Runs on the Python thread with the GIL released; blocks until the UI answers.
    fileprivate func readLine(prompt: String) -> String? {
        guard let readLine else { return nil }
        flush()
        let waiter = LineWaiter()
        let stopped = state.withLock { state in
            state.waiter = waiter
            return state.stopRequested
        }
        if stopped { return nil }
        Task {
            let line = await readLine(prompt)
            waiter.finish(line)
        }
        let line = waiter.wait()
        state.withLock { $0.waiter = nil }
        return line
    }

    /// Callbacks handed to the C bridge.
    static func installCallbacks() {
        csb_set_callbacks(writeCallback, readlineCallback)
    }
}

private let writeCallback: csb_write_callback = { stream, text, length in
    guard let io = RunIO.current.withLock({ $0 }) else { return }
    let buffer = UnsafeRawBufferPointer(start: text, count: length)
    io.write(stream: stream, text: String(decoding: buffer, as: UTF8.self))
}

private let readlineCallback: csb_readline_callback = { prompt in
    guard let io = RunIO.current.withLock({ $0 }) else { return nil }
    guard let line = io.readLine(prompt: String(cString: prompt)) else { return nil }
    return strdup(line)
}

/// One `input()` call waiting for the UI. The first answer wins.
private final class LineWaiter: Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private let answer = Mutex<(done: Bool, line: String?)>((false, nil))

    func finish(_ line: String?) {
        let first = answer.withLock { answer in
            guard !answer.done else { return false }
            answer = (true, line)
            return true
        }
        if first { semaphore.signal() }
    }

    func wait() -> String? {
        semaphore.wait()
        return answer.withLock { $0.line }
    }
}

/// Coalesces writes and delivers them at most every 16 ms, in order, on a serial queue.
private final class OutputBatcher: Sendable {
    private let sink: @Sendable (OutputChunk) -> Void
    private let queue = DispatchQueue(label: "PythonRuntime.output", qos: .userInitiated)
    private let state = Mutex<(pending: [OutputChunk], scheduled: Bool)>(([], false))

    init(sink: @escaping @Sendable (OutputChunk) -> Void) {
        self.sink = sink
    }

    func append(_ chunk: OutputChunk) {
        let schedule = state.withLock { state in
            if let last = state.pending.indices.last, state.pending[last].stream == chunk.stream {
                state.pending[last].text += chunk.text
            } else {
                state.pending.append(chunk)
            }
            guard !state.scheduled else { return false }
            state.scheduled = true
            return true
        }
        if schedule {
            queue.asyncAfter(deadline: .now() + .milliseconds(16)) { [self] in deliver() }
        }
    }

    func flushNow() {
        queue.sync { deliver() }
    }

    private func deliver() {
        let chunks = state.withLock { state in
            let chunks = state.pending
            state = ([], false)
            return chunks
        }
        for chunk in chunks {
            sink(chunk)
        }
    }
}
