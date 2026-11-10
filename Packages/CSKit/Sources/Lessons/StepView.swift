#if canImport(UIKit)
import Contracts
import Editor
import SwiftUI
import Textual
import Visuals

/// The blocks of one step, top to bottom.
struct StepView: View {
    let stepIndex: Int
    let model: ReaderModel
    let library: ContentLibrary
    let runner: any PythonRunning

    var body: some View {
        let step = model.lesson.steps[stepIndex]
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(step.blocks.enumerated()), id: \.offset) { index, block in
                blockView(block, id: BlockID(step: stepIndex, block: index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: Block, id: BlockID) -> some View {
        switch block {
        case .markdown(let text):
            StructuredText(markdown: text)
                .font(.body)
                .textual.textSelection(.enabled)
        case .code(let code):
            codeView(code, id: id)
        case .choice(let question):
            ChoiceView(question: question, id: id, model: model)
        case .diagram(let diagram):
            DiagramView(diagram: diagram)
                .frame(maxWidth: .infinity)
        case .exercise(let exerciseID):
            ExerciseLinkRow(exerciseID: exerciseID, library: library, progress: model.progress)
        }
    }

    @ViewBuilder
    private func codeView(_ code: CodeBlock, id: BlockID) -> some View {
        switch code.role {
        case .cell:
            if code.language == .python {
                CodeCellView(source: code.source, runner: runner)
            } else {
                CodeBox { CodeEditor(code: code.source) }
            }
        case .trace(let stop):
            TraceBlockView(code: code, stop: stop, library: library, runner: runner)
        case .predict:
            PredictView(code: code, id: id, model: model)
        case .arrange:
            ArrangeView(code: code, id: id, model: model)
        case .starter, .solution, .tests, .setup, .check:
            // Used by checks and exercises, not shown.
            EmptyView()
        }
    }
}

/// Code with a hairline border. Content goes edge to edge inside.
struct CodeBox<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .clipShape(.rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.separator), lineWidth: 1 / 3)
        }
    }
}

/// Program output in SF Mono, below code inside a `CodeBox`.
struct OutputText: View {
    let chunks: [OutputChunk]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(chunks.enumerated()), id: \.offset) { _, chunk in
                Text(verbatim: Self.trimmed(chunk.text))
                    .foregroundStyle(chunk.stream == .stderr ? Color.red : Color.primary)
            }
        }
        .font(.system(.subheadline, design: .monospaced))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
    }

    static func trimmed(_ text: String) -> String {
        var text = Substring(text)
        while text.last == "\n" { text.removeLast() }
        return String(text)
    }
}

/// Correct / not quite, after Check.
struct ResultLabel: View {
    let isCorrect: Bool

    var body: some View {
        Label {
            Text(isCorrect ? "Correct" : "Not quite")
        } icon: {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isCorrect ? .green : .red)
                .symbolEffect(.bounce, options: .nonRepeating, value: isCorrect)
        }
        .font(.headline)
    }
}
#endif
