#if canImport(UIKit)
import Contracts
import Editor
import Exercises
import SwiftUI
import Textual

/// Task-list options. One answer uses circles, several use squares, like a form.
struct ChoiceView: View {
    let question: ChoiceQuestion
    let id: BlockID
    @Bindable var model: ReaderModel

    var body: some View {
        let result = model.choiceResults[id]
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 0) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    if index > 0 {
                        Divider().padding(.leading, 52)
                    }
                    row(index: index, option: option, checked: result != nil)
                }
            }
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
            if let result {
                ResultLabel(isCorrect: result)
            }
        }
    }

    private var selection: Set<Int> {
        model.choiceSelections[id, default: []]
    }

    private func row(index: Int, option: ChoiceQuestion.Option, checked: Bool) -> some View {
        let isSelected = selection.contains(index)
        return Button {
            toggle(index)
        } label: {
            HStack(spacing: 12) {
                symbol(isSelected: isSelected, isCorrect: option.isCorrect, checked: checked)
                    .font(.title3)
                    .frame(width: 28)
                InlineText(markdown: option.text)
                    .foregroundStyle(checked && !option.isCorrect && !isSelected ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!model.acceptsAnswers(id.step))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(checked ? (option.isCorrect ? "Correct answer" : "") : "")
    }

    @ViewBuilder
    private func symbol(isSelected: Bool, isCorrect: Bool, checked: Bool) -> some View {
        let shape = question.allowsMultiple ? "square" : "circle"
        if checked && isCorrect {
            Image(systemName: "checkmark.\(shape).fill")
                .foregroundStyle(.green)
        } else if checked && isSelected {
            Image(systemName: "xmark.\(shape).fill")
                .foregroundStyle(.red)
        } else if isSelected {
            Image(systemName: question.allowsMultiple ? "checkmark.square.fill" : "largecircle.fill.circle")
                .foregroundStyle(.tint)
        } else {
            Image(systemName: shape)
                .foregroundStyle(.tertiary)
        }
    }

    private func toggle(_ index: Int) {
        var selection = self.selection
        if question.allowsMultiple {
            if selection.contains(index) { selection.remove(index) } else { selection.insert(index) }
        } else {
            selection = [index]
        }
        model.choiceSelections[id] = selection
    }
}

/// Shuffled lines to put in order. Indentation is part of each line.
struct ArrangeView: View {
    let code: CodeBlock
    let id: BlockID
    @Bindable var model: ReaderModel

    @State private var listHeight: CGFloat = 0

    private var lines: [String] { ArrangeShuffle.lines(of: code.source) }

    var body: some View {
        let result = model.arrangeResults[id]
        let editable = model.acceptsAnswers(id.step)
        VStack(alignment: .leading, spacing: 12) {
            List {
                ForEach(order, id: \.self) { lineIndex in
                    Text(verbatim: lines[lineIndex])
                        .font(.system(.subheadline, design: .monospaced))
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 8))
                        .listRowBackground(Color(.secondarySystemBackground))
                }
                .onMove { source, destination in
                    var order = self.order
                    order.move(fromOffsets: source, toOffset: destination)
                    model.arrangeOrders[id] = order
                }
                .moveDisabled(!editable)
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(editable ? .active : .inactive))
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .onScrollGeometryChange(for: CGFloat.self, of: \.contentSize.height) { _, height in
                listHeight = height
            }
            .frame(height: max(listHeight, CGFloat(lines.count) * 44))
            .clipShape(.rect(cornerRadius: 12))

            if let result {
                ResultLabel(isCorrect: result.isCorrect)
                if let report = result.report, !result.isCorrect {
                    TestResultsView(report: report)
                }
                if !result.isCorrect {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Solution")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        CodeBox { CodeEditor(code: code.source) }
                    }
                }
            }
        }
    }

    private var order: [Int] {
        model.arrangeOrders[id] ?? Array(lines.indices)
    }
}

/// Each test with a pass or fail mark, and what came back for the failures.
struct TestResultsView: View {
    let report: TestReport

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = report.loadError {
                Text(verbatim: "\(error.type): \(error.message)")
                    .foregroundStyle(.red)
            }
            ForEach(report.results) { test in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: test.passed ? "checkmark" : "xmark")
                        .foregroundStyle(test.passed ? .green : .red)
                        .accessibilityLabel(test.passed ? "Passed" : "Failed")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: test.name)
                        if !test.passed {
                            if let error = test.error {
                                Text(verbatim: "\(error.type): \(error.message)")
                                    .foregroundStyle(.secondary)
                            } else if let got = test.got {
                                Text(verbatim: "got \(got)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .font(.system(.footnote, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A row that opens an exercise.
struct ExerciseLinkRow: View {
    let exerciseID: String
    let library: ContentLibrary
    let progress: any ProgressRecording

    var body: some View {
        if let exercise = library.exercise(id: exerciseID) {
            NavigationLink(value: LearnRoute.exercise(exerciseID)) {
                HStack {
                    ExerciseRowLabel(exercise: exercise, state: progress.exerciseProgress(exerciseID).state)
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}
#endif
