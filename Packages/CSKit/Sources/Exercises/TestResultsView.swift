#if canImport(UIKit)
import Contracts
import SwiftUI

/// The results sheet: summary, then failing tests with input, expected and got, then passing ones.
struct TestResultsView: View {
    let completed: ExerciseSession.Completed
    @State private var bounce = 0
    @Environment(\.dismiss) private var dismiss

    private var report: TestReport { completed.report }

    var body: some View {
        NavigationStack {
            List {
                summary
                let failed = report.results.filter { !$0.passed }
                let passed = report.results.filter(\.passed)
                if !failed.isEmpty {
                    Section("Failed") {
                        ForEach(failed) { FailedTestRow(result: $0) }
                    }
                }
                if !passed.isEmpty {
                    Section("Passed") {
                        ForEach(passed) { PassedTestRow(result: $0) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .task {
            // Bounce once the sheet has settled, so the effect is seen.
            try? await Task.sleep(for: .milliseconds(350))
            if report.passed { bounce += 1 }
        }
    }

    /// "3 of 5 passed", or the load error with its message under it.
    private var summary: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    ResultSymbol(passed: report.passed)
                        .font(.title)
                        .symbolEffect(.bounce, value: bounce)
                    Text(report.summary)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
                if let message = report.loadError?.message, !message.isEmpty {
                    Text(verbatim: message)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

private struct FailedTestRow: View {
    let result: TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                ResultSymbol(passed: false)
                Code(result.input ?? result.name)
            }
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 4) {
                if let expected = result.expected {
                    detail("Expected", expected)
                }
                if let got = result.got {
                    detail("Got", got)
                }
                if let error = result.error {
                    GridRow {
                        Text("Error")
                            .foregroundStyle(.secondary)
                        Text(error.summary)
                            .foregroundStyle(.red)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.leading, symbolIndent)
        }
        .textSelection(.enabled)
    }

    /// Lines details up under the code, past the symbol.
    @ScaledMetric(relativeTo: .subheadline) private var symbolIndent: CGFloat = 28

    private func detail(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Code(value)
        }
    }
}

private struct PassedTestRow: View {
    let result: TestResult

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            ResultSymbol(passed: true)
            Code(result.name)
        }
        .textSelection(.enabled)
    }
}

/// Test source or a value, in SF Mono.
private struct Code: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(verbatim: text)
            .font(.system(.subheadline, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
