#if canImport(SwiftData)
import Foundation
import SwiftData
import Contracts
import Review

// CloudKit-compatible: every property has a default or is optional, no unique attributes,
// no relationships. Enums are stored as raw strings so new cases never break old rows.
// Rows can be duplicated by sync, so every reader takes the newest `updatedAt` per key.

@Model
final class LessonRecord {
    var lessonID: String = ""
    var stateRaw: String = LessonState.notStarted.rawValue
    var furthestStep: Int = 0
    var updatedAt: Date = Date(timeIntervalSince1970: 0)

    init(lessonID: String) {
        self.lessonID = lessonID
    }

    var progress: LessonProgress {
        get { LessonProgress(state: LessonState(rawValue: stateRaw) ?? .notStarted, furthestStep: furthestStep) }
        set {
            stateRaw = newValue.state.rawValue
            furthestStep = newValue.furthestStep
        }
    }
}

@Model
final class ExerciseRecord {
    var exerciseID: String = ""
    var stateRaw: String = ExerciseState.notStarted.rawValue
    var hintsRevealed: Int = 0
    var solutionViewed: Bool = false
    var savedCode: String?
    /// When the latest test run finished, and whether it passed.
    var lastAttemptAt: Date?
    var lastAttemptPassed: Bool?
    /// First time the exercise passed. Review waits a day after it before re-solving.
    var passedAt: Date?
    var updatedAt: Date = Date(timeIntervalSince1970: 0)

    init(exerciseID: String) {
        self.exerciseID = exerciseID
    }

    var progress: ExerciseProgress {
        get {
            ExerciseProgress(
                state: ExerciseState(rawValue: stateRaw) ?? .notStarted,
                hintsRevealed: hintsRevealed, solutionViewed: solutionViewed, savedCode: savedCode)
        }
        set {
            stateRaw = newValue.state.rawValue
            hintsRevealed = newValue.hintsRevealed
            solutionViewed = newValue.solutionViewed
            savedCode = newValue.savedCode
        }
    }
}

@Model
final class ReviewRecord {
    /// Review item id (see `ReviewItemID`).
    var itemID: String = ""
    var kindRaw: String = ReviewItemKind.card.rawValue
    /// JSON of `SchedulingCard`. Nil is read as a new card.
    var schedulingData: Data?
    var lastRatingRaw: Int?
    var historyCount: Int = 0
    /// First review, for the daily new-item limit.
    var introducedAt: Date?
    var updatedAt: Date = Date(timeIntervalSince1970: 0)

    init(itemID: String, kind: ReviewItemKind) {
        self.itemID = itemID
        self.kindRaw = kind.rawValue
    }

    var kind: ReviewItemKind { ReviewItemKind(rawValue: kindRaw) ?? .card }
    var lastRating: Rating? { lastRatingRaw.flatMap(Rating.init(rawValue:)) }

    var scheduling: SchedulingCard? {
        get { schedulingData.flatMap { try? StoreCodec.decoder.decode(SchedulingCard.self, from: $0) } }
        set { schedulingData = newValue.flatMap { try? StoreCodec.encoder.encode($0) } }
    }
}
#endif
