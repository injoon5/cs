#if canImport(UIKit)
import Contracts
import Editor
import SwiftUI
import Textual

/// Hints one at a time (nudge, approach, near-solution), then the solution after a confirmation.
struct HintsSheet: View {
    let exercise: Exercise
    let progress: any ProgressRecording
    @State private var confirmingSolution = false
    @State private var detent: PresentationDetent
    @Environment(\.dismiss) private var dismiss

    init(exercise: Exercise, progress: any ProgressRecording) {
        self.exercise = exercise
        self.progress = progress
        _detent = State(initialValue: progress.exerciseProgress(exercise.id).solutionViewed ? .large : .medium)
    }

    private var state: ExerciseProgress { progress.exerciseProgress(exercise.id) }
    private var revealed: Int { min(state.hintsRevealed, exercise.hints.count) }
    private var showsSolution: Bool { state.solutionViewed }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(exercise.hints.prefix(revealed).indices, id: \.self) { index in
                        Section("Hint \(index + 1)") {
                            StructuredText(markdown: exercise.hints[index])
                                .textual.textSelection(.enabled)
                        }
                        .id(index)
                    }
                    if showsSolution {
                        Section("Solution") {
                            CodeEditor(code: exercise.solution)
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        }
                        .id("solution")
                    } else {
                        Section { nextButton }
                    }
                }
                .listStyle(.insetGrouped)
                .onChange(of: revealed) {
                    withAnimation { proxy.scrollTo(revealed - 1, anchor: .top) }
                }
                .onChange(of: showsSolution) {
                    withAnimation { proxy.scrollTo("solution", anchor: .top) }
                }
                .onAppear {
                    if showsSolution { proxy.scrollTo("solution", anchor: .top) }
                }
            }
            .navigationTitle("Hints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .confirmationDialog("Show the solution?", isPresented: $confirmingSolution, titleVisibility: .visible) {
            Button("Show solution", action: showSolution)
        } message: {
            Text("This exercise will come back in review.")
        }
    }

    @ViewBuilder
    private var nextButton: some View {
        if revealed < exercise.hints.count {
            Button(revealed == 0 ? "Show hint" : "Show next hint") {
                withAnimation {
                    progress.recordHintsRevealed(revealed + 1, exerciseID: exercise.id)
                }
            }
        } else {
            Button("Show solution") { confirmingSolution = true }
        }
    }

    private func showSolution() {
        withAnimation {
            progress.recordSolutionViewed(exerciseID: exercise.id)
            detent = .large
        }
    }
}
#endif
