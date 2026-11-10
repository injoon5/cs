import Contracts
import Foundation
import Observation
import Synchronization

/// One line of console output. The last line stays open until a newline arrives.
struct ConsoleLine: Identifiable, Hashable, Sendable {
    let id: Int
    var stream: Contracts.OutputStream
    var text: String
}

/// Runs code through a `PythonRunning`, collecting streamed output into console lines.
@Observable
@MainActor
final class RunSession {
    enum Status: Equatable {
        case idle
        case running
        case finished(duration: Double)
        case failed(PythonError)
        case stopped
        case timedOut
    }

    /// Keeps the console responsive when a program prints without end.
    static let maxLines = 5_000

    private(set) var lines: [ConsoleLine] = []
    private(set) var status: Status = .idle
    /// Prompt of a pending `input()` call. Empty string when `input()` has no prompt.
    private(set) var inputPrompt: String?
    var inputText = ""

    var isRunning: Bool { status == .running }

    /// 1-based line of the error from the last run.
    var errorLine: Int? {
        if case .failed(let error) = status { error.line } else { nil }
    }

    private let runner: any PythonRunning
    private var nextLineID = 0
    private var lineIsOpen = false
    private var inputContinuation: CheckedContinuation<String?, Never>?

    init(runner: any PythonRunning) {
        self.runner = runner
    }

    func run(_ code: String) async {
        guard !isRunning else { return }
        clear()
        status = .running

        let buffer = OutputBuffer()
        let flusher = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                self?.append(buffer.drain())
            }
        }
        let result = await runner.run(
            code,
            output: { chunk in buffer.append(chunk) },
            readLine: { [weak self] prompt in
                await self?.requestInput(prompt: prompt, flushing: buffer)
            }
        )
        flusher.cancel()
        append(buffer.drain())
        finishInput(nil)

        switch result.outcome {
        case .finished:
            status = .finished(duration: result.duration)
        case .failed(let error):
            append([OutputChunk(stream: .stderr, text: Self.message(for: error))])
            status = .failed(error)
        case .stopped:
            status = .stopped
        case .timedOut:
            status = .timedOut
        }
    }

    func stop() async {
        finishInput(nil)
        await runner.stop()
    }

    func clear() {
        lines = []
        lineIsOpen = false
        if !isRunning { status = .idle }
    }

    func submitInput() {
        let text = inputText
        append([OutputChunk(stream: .stdout, text: (inputPrompt ?? "") + text + "\n")])
        finishInput(text)
    }

    // MARK: Private

    private func requestInput(prompt: String, flushing buffer: OutputBuffer) async -> String? {
        // Show everything printed before the prompt first.
        append(buffer.drain())
        finishInput(nil)
        inputPrompt = prompt
        return await withCheckedContinuation { inputContinuation = $0 }
    }

    private func finishInput(_ line: String?) {
        inputPrompt = nil
        inputText = ""
        inputContinuation?.resume(returning: line)
        inputContinuation = nil
    }

    private func append(_ chunks: [OutputChunk]) {
        guard !chunks.isEmpty else { return }
        var lines = self.lines
        for chunk in chunks {
            let pieces = chunk.text.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, piece) in pieces.enumerated() {
                let isLast = index == pieces.count - 1
                if isLast && piece.isEmpty {
                    // Text ended with a newline: the previous line is closed.
                    lineIsOpen = false
                    break
                }
                if lineIsOpen, let last = lines.indices.last, lines[last].stream == chunk.stream {
                    lines[last].text += piece
                } else {
                    lines.append(ConsoleLine(id: nextLineID, stream: chunk.stream, text: String(piece)))
                    nextLineID += 1
                }
                lineIsOpen = isLast
            }
        }
        if lines.count > Self.maxLines {
            lines.removeFirst(lines.count - Self.maxLines)
        }
        self.lines = lines
    }

    private static func message(for error: PythonError) -> String {
        let text = error.traceback.isEmpty ? "\(error.type): \(error.message)" : error.traceback
        return text.hasSuffix("\n") ? text : text + "\n"
    }
}

/// Collects output on the interpreter thread; the main actor drains it a few times a second.
final class OutputBuffer: Sendable {
    private let chunks = Mutex<[OutputChunk]>([])

    func append(_ chunk: OutputChunk) {
        chunks.withLock { $0.append(chunk) }
    }

    func drain() -> [OutputChunk] {
        chunks.withLock { chunks in
            defer { chunks = [] }
            return chunks
        }
    }
}
