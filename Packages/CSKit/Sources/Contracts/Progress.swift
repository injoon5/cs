import Foundation
import Observation

// Progress the screens record and read. Implemented with SwiftData by `Store`;
// `InMemoryProgress` is for previews, tests and screenshots.

public enum LessonState: String, Codable, Sendable, Hashable {
    case notStarted, inProgress, completed
}

public struct LessonProgress: Codable, Sendable, Hashable {
    public var state: LessonState
    /// Furthest step reached, 0-based.
    public var furthestStep: Int

    public init(state: LessonState = .notStarted, furthestStep: Int = 0) {
        self.state = state
        self.furthestStep = furthestStep
    }
}

public enum ExerciseState: String, Codable, Sendable, Hashable {
    case notStarted, attempted, passed
}

public struct ExerciseProgress: Codable, Sendable, Hashable {
    public var state: ExerciseState
    public var hintsRevealed: Int
    /// Seeing the solution marks the exercise for re-solve in review.
    public var solutionViewed: Bool
    /// The user's latest code, saved while typing. `nil` means start from the starter.
    public var savedCode: String?

    public init(state: ExerciseState = .notStarted, hintsRevealed: Int = 0, solutionViewed: Bool = false, savedCode: String? = nil) {
        self.state = state
        self.hintsRevealed = hintsRevealed
        self.solutionViewed = solutionViewed
        self.savedCode = savedCode
    }
}

/// Reads must be observation-tracked (read `@Observable` or `@Model` state), so views
/// that call them in `body` update when progress changes.
@MainActor
public protocol ProgressRecording: AnyObject {
    func lessonProgress(_ lessonID: String) -> LessonProgress
    /// Marks `stepIndex` reached. Reaching the last step completes the lesson.
    func recordStep(lessonID: String, stepIndex: Int, stepCount: Int)

    func exerciseProgress(_ exerciseID: String) -> ExerciseProgress
    func saveCode(_ code: String, exerciseID: String)
    /// A passing report marks the exercise passed; it never goes back to attempted.
    func recordAttempt(exerciseID: String, report: TestReport)
    func recordHintsRevealed(_ count: Int, exerciseID: String)
    func recordSolutionViewed(exerciseID: String)
}

@MainActor
@Observable
public final class InMemoryProgress: ProgressRecording {
    public var lessons: [String: LessonProgress]
    public var exercises: [String: ExerciseProgress]

    public init(lessons: [String: LessonProgress] = [:], exercises: [String: ExerciseProgress] = [:]) {
        self.lessons = lessons
        self.exercises = exercises
    }

    public func lessonProgress(_ lessonID: String) -> LessonProgress {
        lessons[lessonID] ?? LessonProgress()
    }

    public func recordStep(lessonID: String, stepIndex: Int, stepCount: Int) {
        var progress = lessonProgress(lessonID)
        progress.furthestStep = max(progress.furthestStep, stepIndex)
        if stepIndex >= stepCount - 1 {
            progress.state = .completed
        } else if progress.state == .notStarted {
            progress.state = .inProgress
        }
        lessons[lessonID] = progress
    }

    public func exerciseProgress(_ exerciseID: String) -> ExerciseProgress {
        exercises[exerciseID] ?? ExerciseProgress()
    }

    public func saveCode(_ code: String, exerciseID: String) {
        exercises[exerciseID, default: ExerciseProgress()].savedCode = code
    }

    public func recordAttempt(exerciseID: String, report: TestReport) {
        var progress = exerciseProgress(exerciseID)
        if report.passed {
            progress.state = .passed
        } else if progress.state == .notStarted {
            progress.state = .attempted
        }
        exercises[exerciseID] = progress
    }

    public func recordHintsRevealed(_ count: Int, exerciseID: String) {
        var progress = exerciseProgress(exerciseID)
        progress.hintsRevealed = max(progress.hintsRevealed, count)
        exercises[exerciseID] = progress
    }

    public func recordSolutionViewed(exerciseID: String) {
        exercises[exerciseID, default: ExerciseProgress()].solutionViewed = true
    }
}
