import Foundation

/// What a queue item asks the learner to do (PLAN.md, Review).
public enum ReviewItemKind: String, Sendable, Codable, Hashable, CaseIterable {
    /// Recall card.
    case card
    /// Re-solve an old exercise from a blank editor.
    case resolve
    /// Problem that doesn't say which technique to use.
    case interleaved
}

public struct ReviewItem: Sendable, Codable, Hashable, Identifiable {
    public var id: String
    public var kind: ReviewItemKind
    public var scheduling: SchedulingCard

    public init(id: String, kind: ReviewItemKind, scheduling: SchedulingCard) {
        self.id = id
        self.kind = kind
        self.scheduling = scheduling
    }
}

public enum ReviewQueue {
    /// Longest run of one kind allowed when another kind is available.
    public static let maxRun = 2

    /// Today's queue.
    ///
    /// - Due items: not `new` and due before the end of `now`'s day in `calendar`.
    ///   Overdue and in-day learning steps are included. Ordered by due date, ties by id.
    /// - New items: `new` state, kept in input order, at most `newLimit - newIntroducedToday`
    ///   (never negative). They follow the due items before interleaving.
    /// - Interleaving: items keep their order except that when the next item would be the
    ///   third of the same kind in a row, the earliest later item of another kind moves up.
    ///   If only one kind remains, runs are unavoidable.
    public static func today(
        items: [ReviewItem],
        now: Date,
        calendar: Calendar,
        newLimit: Int,
        newIntroducedToday: Int = 0
    ) -> [ReviewItem] {
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
            ?? now.addingTimeInterval(86_400)

        let due = items
            .filter { $0.scheduling.state != .new && $0.scheduling.due < startOfTomorrow }
            .sorted { lhs, rhs in
                lhs.scheduling.due == rhs.scheduling.due
                    ? lhs.id < rhs.id : lhs.scheduling.due < rhs.scheduling.due
            }
        let newCount = max(0, newLimit - newIntroducedToday)
        let fresh = items.filter { $0.scheduling.state == .new }.prefix(newCount)
        return interleave(due + fresh)
    }

    static func interleave(_ ordered: [ReviewItem]) -> [ReviewItem] {
        var remaining = ordered
        var result: [ReviewItem] = []
        result.reserveCapacity(ordered.count)
        while !remaining.isEmpty {
            var pick = 0
            if let last = result.last, result.count >= maxRun,
               result.suffix(maxRun).allSatisfy({ $0.kind == last.kind }),
               remaining[0].kind == last.kind,
               let other = remaining.firstIndex(where: { $0.kind != last.kind }) {
                pick = other
            }
            result.append(remaining.remove(at: pick))
        }
        return result
    }
}
