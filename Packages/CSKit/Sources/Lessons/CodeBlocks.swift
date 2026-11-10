#if canImport(UIKit)
import Contracts
import Editor
import SwiftUI
import Visuals

/// A runnable cell: read-only code and Run. Output appears below once something prints.
struct CodeCellView: View {
    let source: String
    let runner: any PythonRunning

    @State private var run = CellRun()

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            CodeBox {
                CodeEditor(code: source)
                if !run.frames.isEmpty {
                    Divider()
                    VizPlayerView(frames: run.frames)
                        .padding(12)
                }
                if !run.output.isEmpty {
                    Divider()
                    OutputText(chunks: run.output)
                }
            }
            runButton
        }
        #if DEBUG
        .task {
            if LessonsLaunchOptions.runsCells { await run.run(source, runner: runner) }
        }
        #endif
    }

    private var runButton: some View {
        Button {
            if run.isRunning {
                Task { await runner.stop() }
            } else {
                Task { await run.run(source, runner: runner) }
            }
        } label: {
            Label {
                Text(run.isRunning ? "Stop" : "Run")
            } icon: {
                Image(systemName: run.isRunning ? "stop.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(minWidth: 64)
        }
        .buttonStyle(.bordered)
        .frame(minHeight: 44)
    }
}

/// A `python trace` block: the bundled trace, or a live one when nothing was recorded.
struct TraceBlockView: View {
    let code: CodeBlock
    let stop: Int?
    let library: ContentLibrary
    let runner: any PythonRunning

    @State private var trace: Trace?

    init(code: CodeBlock, stop: Int?, library: ContentLibrary, runner: any PythonRunning) {
        self.code = code
        self.stop = stop
        self.library = library
        self.runner = runner
        _trace = State(initialValue: library.recordedTrace(for: code))
    }

    var body: some View {
        if let trace {
            InlineTraceView(code: code.source, trace: trace, stop: stop)
        } else {
            CodeBox {
                CodeEditor(code: code.source)
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(.secondarySystemBackground))
            }
            .task {
                trace = await runner.trace(code.source)
            }
        }
    }
}

/// "What does this print?" The answer is typed, then compared with the recorded output.
struct PredictView: View {
    let code: CodeBlock
    let id: BlockID
    @Bindable var model: ReaderModel

    @FocusState private var focused: Bool

    var body: some View {
        let result = model.predictResults[id]
        VStack(alignment: .leading, spacing: 12) {
            CodeBox {
                CodeEditor(code: code.source)
            }
            TextField("Output", text: answer, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .lineLimit(1...12)
                .focused($focused)
                .disabled(!model.acceptsAnswers(id.step))
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .frame(minHeight: 44)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
                .foregroundStyle(result.map { $0.isCorrect ? Color.primary : Color.secondary } ?? Color.primary)
            if let result {
                ResultLabel(isCorrect: result.isCorrect)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Output")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    CodeBox {
                        OutputText(chunks: [OutputChunk(stream: .stdout, text: result.expected)])
                    }
                }
            }
        }
    }

    private var answer: Binding<String> {
        Binding(
            get: { model.predictAnswers[id] ?? "" },
            set: { model.predictAnswers[id] = $0 }
        )
    }
}
#endif
