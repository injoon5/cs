import Contracts
import Foundation
import Observation
import Synchronization

/// Runs one lesson cell and collects what it prints. Cells that call `viz` also keep
/// the frames they produced.
@MainActor
@Observable
final class CellRun {
    enum Status: Equatable {
        case idle, running, finished, failed, stopped
    }

    private(set) var output: [OutputChunk] = []
    private(set) var frames: [VizFrame] = []
    private(set) var status: Status = .idle

    var isRunning: Bool { status == .running }
    var hasOutput: Bool { !output.isEmpty || !frames.isEmpty }

    /// Keeps a runaway loop from growing the lesson without end.
    private static let maxCharacters = 20_000

    func run(_ code: String, runner: any PythonRunning) async {
        guard !isRunning else { return }
        output = []
        frames = []
        status = .running

        if Self.usesViz(code) {
            let run = await runner.visualize(code)
            frames = run.frames
            if !run.output.isEmpty { append([OutputChunk(stream: .stdout, text: run.output)]) }
            finish(run.result)
            return
        }

        let buffer = OutputBuffer()
        let flusher = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                self?.append(buffer.drain())
            }
        }
        let result = await runner.run(code, output: { buffer.append($0) }, readLine: { _ in nil })
        flusher.cancel()
        append(buffer.drain())
        finish(result)
    }

    private func finish(_ result: RunResult) {
        switch result.outcome {
        case .finished:
            status = .finished
        case .failed(let error):
            let text = error.traceback.isEmpty ? "\(error.type): \(error.message)" : error.traceback
            append([OutputChunk(stream: .stderr, text: text)])
            status = .failed
        case .stopped, .timedOut:
            status = .stopped
        }
    }

    private func append(_ chunks: [OutputChunk]) {
        guard !chunks.isEmpty else { return }
        var output = self.output
        for chunk in chunks {
            if let last = output.indices.last, output[last].stream == chunk.stream {
                output[last].text += chunk.text
            } else {
                output.append(chunk)
            }
        }
        if let last = output.indices.last, output[last].text.count > Self.maxCharacters {
            output[last].text = String(output[last].text.suffix(Self.maxCharacters))
        }
        self.output = output
    }

    static func usesViz(_ code: String) -> Bool {
        code.split(separator: "\n").contains { line in
            let line = line.trimmingCharacters(in: .whitespaces)
            return line == "import viz" || line.hasPrefix("import viz ") || line.hasPrefix("from viz ")
        }
    }
}

/// Collects output on the interpreter thread; the main actor drains it.
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
