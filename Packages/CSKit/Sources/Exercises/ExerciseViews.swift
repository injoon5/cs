#if canImport(UIKit)
import Contracts
import SwiftUI

// Public API used by Lessons and the app. Keep the signatures.

/// The Practice tab: exercises by unit and level.
public struct PracticeView: View {
    let library: ContentLibrary
    let runner: any PythonRunning
    let progress: any ProgressRecording

    public init(library: ContentLibrary, runner: any PythonRunning, progress: any ProgressRecording) {
        self.library = library
        self.runner = runner
        self.progress = progress
    }

    public var body: some View {
        PracticeList(library: library, runner: runner, progress: progress)
    }
}

/// One exercise: prompt, editor, tests, hints. Pushed inside a `NavigationStack`; it doesn't create one.
public struct ExerciseView: View {
    let exercise: Exercise
    let runner: any PythonRunning
    let progress: any ProgressRecording

    public init(exercise: Exercise, runner: any PythonRunning, progress: any ProgressRecording) {
        self.exercise = exercise
        self.runner = runner
        self.progress = progress
    }

    public var body: some View {
        ExerciseScreen(exercise: exercise, runner: runner, progress: progress)
            .id(exercise.id)
    }
}
#endif
