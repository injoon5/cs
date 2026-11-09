#if DEBUG
import Contracts
import Runtime
import SwiftUI

/// Temporary screen for milestone 1: runs fixed snippets through the embedded interpreter.
struct PythonSmokeView: View {
    @State private var model = PythonSmokeModel()
    @State private var sample = Sample.sum
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Code", selection: $sample) {
                        ForEach(Sample.allCases) { sample in
                            Text(sample.title).tag(sample)
                        }
                    }
                    .disabled(model.isRunning)
                    Text(sample.code)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }

                Section("Output") {
                    if model.output.isEmpty && model.prompt == nil {
                        Text(model.isRunning ? "Running" : "No output")
                            .foregroundStyle(.secondary)
                    } else if !model.output.isEmpty {
                        Text(model.output.trimmingCharacters(in: .newlines))
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    if let prompt = model.prompt {
                        TextField(prompt.isEmpty ? "Input" : prompt, text: $model.inputLine)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($inputFocused)
                            .onSubmit { model.submitLine() }
                            .onAppear { inputFocused = true }
                    }
                }

                if let status = model.status {
                    Section {
                        LabeledContent("Result", value: status)
                        if let duration = model.duration {
                            LabeledContent("Time") {
                                Text("\(duration, format: .number.precision(.fractionLength(3))) s")
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Python")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if model.isRunning {
                            Task { await model.stop() }
                        } else {
                            Task { await model.run(sample.code) }
                        }
                    } label: {
                        Label(model.isRunning ? "Stop" : "Run", systemImage: model.isRunning ? "stop.fill" : "play.fill")
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .keyboardShortcut(model.isRunning ? "." : "r", modifiers: .command)
                }
            }
            .task { await autoRun() }
            .sensoryFeedback(trigger: model.runCount) { _, _ in
                switch model.lastOutcome {
                case .finished: .success
                case .failed: .error
                default: nil
                }
            }
        }
    }

    /// For checks without UI automation: `-PythonSmokeSample loop -PythonSmokeStopAfter 2`
    /// runs a sample at launch and calls the Stop button's action after the given seconds.
    private func autoRun() async {
        let defaults = UserDefaults.standard
        guard let name = defaults.string(forKey: "PythonSmokeSample"), let autoSample = Sample(rawValue: name) else { return }
        sample = autoSample
        let stopAfter = defaults.double(forKey: "PythonSmokeStopAfter")
        if stopAfter > 0 {
            Task {
                try? await Task.sleep(for: .seconds(stopAfter))
                await model.stop()
            }
        }
        await model.run(autoSample.code)

        // `-PythonSmokeThen error` runs a second sample once the first ends.
        if let next = defaults.string(forKey: "PythonSmokeThen").flatMap(Sample.init(rawValue:)) {
            sample = next
            await model.run(next.code)
        }
    }
}

private enum Sample: String, CaseIterable, Identifiable {
    case sum, loop, input, error

    var id: Self { self }

    var title: String {
        switch self {
        case .sum: "Sum"
        case .loop: "Infinite loop"
        case .input: "Input"
        case .error: "Error"
        }
    }

    var code: String {
        switch self {
        case .sum:
            "print(sum(range(10)))"
        case .loop:
            "print(\"looping\")\nwhile True:\n    pass"
        case .input:
            "name = input(\"Name\")\nprint(f\"Hello, {name}\")"
        case .error:
            "def f(xs):\n    return xs[3]\n\nf([1, 2])"
        }
    }
}

@Observable
@MainActor
private final class PythonSmokeModel {
    var output = ""
    var isRunning = false
    var status: String?
    var duration: Double?
    var prompt: String?
    var inputLine = ""
    private(set) var runCount = 0
    private(set) var lastOutcome: RunOutcome?
    private var lineContinuation: CheckedContinuation<String?, Never>?

    func run(_ code: String) async {
        output = ""
        status = nil
        duration = nil
        isRunning = true
        let result = await PythonRuntime.shared.run(
            code,
            output: { [weak self] chunk in
                DispatchQueue.main.async {
                    MainActor.assumeIsolated { self?.output += chunk.text }
                }
            },
            readLine: { [weak self] prompt in
                await self?.requestLine(prompt)
            }
        )
        // Output callbacks queued before the result arrive first.
        await Task.yield()
        isRunning = false
        duration = result.duration
        lastOutcome = result.outcome
        runCount += 1
        switch result.outcome {
        case .finished:
            status = "Finished"
        case .stopped:
            status = "Stopped"
        case .timedOut:
            status = "Timed out"
        case .failed(let error):
            status = error.type
            output += error.traceback.isEmpty ? "\(error.type): \(error.message)" : error.traceback
        }
    }

    func stop() async {
        finishLine(nil)
        await PythonRuntime.shared.stop()
    }

    func submitLine() {
        let line = inputLine
        output += (prompt ?? "") + line + "\n"
        finishLine(line)
    }

    private func requestLine(_ prompt: String) async -> String? {
        finishLine(nil)
        self.prompt = prompt
        return await withCheckedContinuation { lineContinuation = $0 }
    }

    private func finishLine(_ line: String?) {
        prompt = nil
        inputLine = ""
        lineContinuation?.resume(returning: line)
        lineContinuation = nil
    }
}

#Preview {
    PythonSmokeView()
}
#endif
