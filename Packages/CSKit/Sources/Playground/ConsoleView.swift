#if canImport(UIKit)
import Contracts
import SwiftUI

/// Streamed program output: stdout in the primary color, stderr in red, with an inline
/// field for `input()` and a status line when the run ends.
struct ConsoleView: View {
    @Bindable var session: RunSession
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            output
        }
        .background(Color(.secondarySystemBackground))
    }

    private var header: some View {
        HStack {
            Text("Output")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Button("Clear") { session.clear() }
                .font(.subheadline)
                .disabled(session.lines.isEmpty || session.isRunning)
                .frame(minHeight: 44)
        }
        .padding(.horizontal)
    }

    private var output: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(session.lines) { line in
                    Text(verbatim: line.text.isEmpty ? " " : line.text)
                        .foregroundStyle(line.stream == .stderr ? Color.red : Color.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let prompt = session.inputPrompt {
                    inputRow(prompt: prompt)
                }
                statusLine
                    .font(.footnote)
                    .padding(.top, session.lines.isEmpty ? 0 : 8)
            }
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .padding()
        }
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .scrollDismissesKeyboard(.interactively)
    }

    private func inputRow(prompt: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: prompt)
            TextField("Input", text: $session.inputText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.return)
                .focused($inputFocused)
                .onSubmit { session.submitInput() }
                .onAppear { inputFocused = true }
        }
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private var statusLine: some View {
        switch session.status {
        case .idle:
            if session.lines.isEmpty {
                Text("No output")
                    .foregroundStyle(.tertiary)
            }
        case .running:
            EmptyView()
        case .finished(let duration):
            Text("Finished in \(duration, format: .number.precision(.fractionLength(2))) s")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        case .failed(let error):
            Text(verbatim: error.line.map { "\(error.type) on line \($0)" } ?? error.type)
                .foregroundStyle(.secondary)
        case .stopped:
            Text("Stopped")
                .foregroundStyle(.secondary)
        case .timedOut:
            Text("Timed out")
                .foregroundStyle(.secondary)
        }
    }
}
#endif
