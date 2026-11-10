#if canImport(UIKit)
import Contracts
import SwiftUI

// Public API used by Lessons and the app. Stubs until the Exercises agent implements them; keep the signatures.

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
        EmptyView()
    }
}

/// One exercise: prompt, editor, tests, hints. Pushed inside a `NavigationStack`.
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
        Text(exercise.title)
    }
}
#endif
