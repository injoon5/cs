import Foundation

public enum UnitMasteryLevel: Int, Sendable, Codable, Hashable, CaseIterable, Comparable {
    case new
    case learning
    case practiced
    case mastered

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Inputs for a unit's progress level. Plain numbers so Store can fill them from SwiftData.
public struct UnitProgress: Sendable, Codable, Hashable {
    public var lessonsStarted: Int
    public var coreExercisesTotal: Int
    public var coreExercisesPassed: Int
    /// Scheduling state of every review card that belongs to the unit.
    public var cards: [SchedulingCard]

    public init(lessonsStarted: Int, coreExercisesTotal: Int, coreExercisesPassed: Int, cards: [SchedulingCard]) {
        self.lessonsStarted = lessonsStarted
        self.coreExercisesTotal = coreExercisesTotal
        self.coreExercisesPassed = coreExercisesPassed
        self.cards = cards
    }
}

public enum UnitMastery {
    /// A card counts as stable once its stability is at least this many days.
    public static let stableDays = 21.0

    /// New -> Learning -> Practiced -> Mastered.
    ///
    /// - Learning: any lesson started or any core exercise passed.
    /// - Practiced: the unit has core exercises and all of them passed.
    /// - Mastered: practiced, the unit has at least one card, and every card is in the
    ///   `review` state (not new, learning or relearning) with stability >= `stableDays`.
    ///   A lapse (Again) drops a card to relearning, so the unit falls back to Practiced.
    public static func level(for progress: UnitProgress) -> UnitMasteryLevel {
        let started = progress.lessonsStarted > 0 || progress.coreExercisesPassed > 0
        guard started else { return .new }

        let practiced = progress.coreExercisesTotal > 0
            && progress.coreExercisesPassed >= progress.coreExercisesTotal
        guard practiced else { return .learning }

        let stable = !progress.cards.isEmpty && progress.cards.allSatisfy {
            $0.state == .review && ($0.stability ?? 0) >= stableDays
        }
        return stable ? .mastered : .practiced
    }
}
