#if canImport(UIKit)
import Contracts
import SwiftUI

/// Exercises sectioned by unit, warm-up first, with each one's state.
struct PracticeList: View {
    let library: ContentLibrary
    let runner: any PythonRunning
    let progress: any ProgressRecording
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Practice")
                .navigationDestination(for: String.self) { id in
                    if let exercise = library.exercise(id: id) {
                        ExerciseView(exercise: exercise, runner: runner, progress: progress)
                    }
                }
        }
        #if DEBUG
        .task {
            if let id = ExercisesLaunchOptions.prepare(progress: progress, library: library) {
                path = [id]
            }
        }
        #endif
    }

    private var units: [CourseUnit] {
        library.tracks.flatMap(\.units).filter { !$0.exercises.isEmpty }
    }

    @ViewBuilder
    private var content: some View {
        if units.isEmpty {
            ContentUnavailableView("No exercises", systemImage: "checklist")
        } else {
            List {
                ForEach(units) { unit in
                    UnitSection(unit: unit, progress: progress)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

private struct UnitSection: View {
    let unit: CourseUnit
    let progress: any ProgressRecording

    private var exercises: [Exercise] {
        // Stable sort keeps authored order within a level.
        unit.exercises.enumerated()
            .sorted { ($0.element.level.sortOrder, $0.offset) < ($1.element.level.sortOrder, $1.offset) }
            .map(\.element)
    }

    var body: some View {
        let passed = unit.exercises.count { progress.exerciseProgress($0.id).state == .passed }
        Section {
            ForEach(exercises) { exercise in
                NavigationLink(value: exercise.id) {
                    ExerciseRow(exercise: exercise, state: progress.exerciseProgress(exercise.id).state)
                }
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text(unit.title)
                Spacer()
                Text("\(passed) of \(unit.exercises.count)")
                    .monospacedDigit()
                    .accessibilityLabel("\(passed) of \(unit.exercises.count) passed")
            }
        }
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise
    let state: ExerciseState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.title)
                Text(exercise.level.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            stateSymbol
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var stateSymbol: some View {
        switch state {
        case .notStarted:
            EmptyView()
        case .attempted:
            Image(systemName: "circle.dashed")
                .foregroundStyle(.tertiary)
                .accessibilityLabel("Attempted")
        case .passed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Passed")
        }
    }
}
#endif
