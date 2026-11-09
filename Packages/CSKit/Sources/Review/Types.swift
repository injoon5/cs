import Foundation

/// How well the learner recalled a card. Raw values match upstream FSRS (1...4).
public enum Rating: Int, Sendable, Codable, Hashable, CaseIterable, Comparable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    public static func < (lhs: Rating, rhs: Rating) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Where a card is in its life. `new` means never reviewed; upstream FSRS treats
/// this as `learning` at step 0 with no memory state, and so does `Scheduler`.
public enum ReviewState: String, Sendable, Codable, Hashable, CaseIterable {
    case new
    case learning
    case review
    case relearning
}

/// The two FSRS memory variables.
public struct MemoryState: Sendable, Codable, Hashable {
    /// Days for retrievability to fall from 100% to 90%.
    public var stability: Double
    /// 1 (easy) ... 10 (hard).
    public var difficulty: Double

    public init(stability: Double, difficulty: Double) {
        self.stability = stability
        self.difficulty = difficulty
    }
}

/// Scheduling state of one card (or any reviewable item). Persisted by the Store area.
public struct SchedulingCard: Sendable, Codable, Hashable {
    /// Nil until the first review.
    public var memory: MemoryState?
    public var due: Date
    public var lastReview: Date?
    public var reps: Int
    /// Times a review-state card was rated Again.
    public var lapses: Int
    public var state: ReviewState
    /// Index into the learning or relearning steps. Nil in `new` and `review`.
    public var step: Int?

    public var stability: Double? { memory?.stability }
    public var difficulty: Double? { memory?.difficulty }

    /// A card that has never been reviewed.
    public init(due: Date) {
        self.memory = nil
        self.due = due
        self.lastReview = nil
        self.reps = 0
        self.lapses = 0
        self.state = .new
        self.step = nil
    }

    public init(
        memory: MemoryState?, due: Date, lastReview: Date?, reps: Int, lapses: Int,
        state: ReviewState, step: Int?
    ) {
        self.memory = memory
        self.due = due
        self.lastReview = lastReview
        self.reps = reps
        self.lapses = lapses
        self.state = state
        self.step = step
    }
}

/// One recorded review, for history and later parameter optimization.
public struct ReviewLog: Sendable, Codable, Hashable {
    public var rating: Rating
    public var reviewedAt: Date
    /// State before this review.
    public var stateBefore: ReviewState
    /// Seconds between the previous review and this one. Nil for the first.
    public var elapsed: TimeInterval?

    public init(rating: Rating, reviewedAt: Date, stateBefore: ReviewState, elapsed: TimeInterval?) {
        self.rating = rating
        self.reviewedAt = reviewedAt
        self.stateBefore = stateBefore
        self.elapsed = elapsed
    }
}
