#if canImport(UIKit)
import Contracts
import SwiftUI

/// One unit: its lessons in order, then its exercises.
struct UnitView: View {
    let unit: CourseUnit
    let progress: any ProgressRecording

    var body: some View {
        List {
            if !unit.lessons.isEmpty {
                Section("Lessons") {
                    ForEach(unit.lessons) { lesson in
                        NavigationLink(value: LearnRoute.lesson(unitID: unit.id, lessonID: lesson.id)) {
                            Label {
                                Text(lesson.title)
                            } icon: {
                                LessonStateIcon(state: progress.lessonProgress(lesson.id).state)
                            }
                        }
                    }
                }
            }
            if !unit.exercises.isEmpty {
                Section("Exercises") {
                    ForEach(exercisesByLevel) { exercise in
                        NavigationLink(value: LearnRoute.exercise(exercise.id)) {
                            ExerciseRowLabel(exercise: exercise, state: progress.exerciseProgress(exercise.id).state)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if unit.lessons.isEmpty && unit.exercises.isEmpty {
                ContentUnavailableView("No lessons", systemImage: "book")
            }
        }
        .navigationTitle(unit.title)
    }

    /// Warm-up, core, stretch; authored order within a level.
    private var exercisesByLevel: [Exercise] {
        let levels = ExerciseLevel.allCases
        return unit.exercises.enumerated()
            .sorted { a, b in
                let la = levels.firstIndex(of: a.element.level) ?? 0
                let lb = levels.firstIndex(of: b.element.level) ?? 0
                return (la, a.offset) < (lb, b.offset)
            }
            .map(\.element)
    }
}

/// Not started, in progress or done.
struct LessonStateIcon: View {
    let state: LessonState

    var body: some View {
        switch state {
        case .notStarted:
            Image(systemName: "circle")
                .foregroundStyle(.tertiary)
                .accessibilityLabel("Not started")
        case .inProgress:
            Image(systemName: "circle.lefthalf.filled")
                .foregroundStyle(.tint)
                .accessibilityLabel("In progress")
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Done")
        }
    }
}

/// Title, level and state of an exercise, for list rows and lesson links.
struct ExerciseRowLabel: View {
    let exercise: Exercise
    let state: ExerciseState

    var body: some View {
        Label {
            LabeledContent {
                Text(Self.levelName(exercise.level))
            } label: {
                Text(exercise.title)
            }
        } icon: {
            switch state {
            case .notStarted:
                Image(systemName: "circle")
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("Not started")
            case .attempted:
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Attempted")
            case .passed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Passed")
            }
        }
    }

    static func levelName(_ level: ExerciseLevel) -> String {
        switch level {
        case .warmup: "Warm-up"
        case .core: "Core"
        case .stretch: "Stretch"
        }
    }
}

#endif
