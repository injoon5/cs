import Foundation
import Testing
@testable import Review

// Reference vectors were generated with py-fsrs 6.3.2 (pip `fsrs==6.3.2`), default parameters,
// start 2024-01-01T00:00:00Z, each review made exactly when the card was due.

private let t0 = Date(timeIntervalSince1970: 1_704_067_200)  // 2024-01-01T00:00:00Z

private func noFuzz() -> Scheduler {
    Scheduler(parameters: FSRSParameters(enableFuzz: false))
}

private struct Constant: RandomNumberGenerator {
    var value: UInt64
    mutating func next() -> UInt64 { value }
}

private struct Expected {
    var rating: Rating
    var state: ReviewState
    var step: Int?
    var stability: Double
    var difficulty: Double
    var intervalSeconds: Double
}

@Suite struct SchedulerTests {
    @Test func referenceSequenceMatchesPyFSRS() {
        let vectors: [Expected] = [
            .init(rating: .good, state: .learning, step: 1, stability: 2.3065, difficulty: 2.118103970459016, intervalSeconds: 600),
            .init(rating: .good, state: .review, step: nil, stability: 2.3065, difficulty: 2.111214235785395, intervalSeconds: 172_800),
            .init(rating: .good, state: .review, step: nil, stability: 10.971048263078135, difficulty: 2.1043313908464483, intervalSeconds: 950_400),
            .init(rating: .good, state: .review, step: nil, stability: 46.316858440073425, difficulty: 2.0974554287524403, intervalSeconds: 3_974_400),
            .init(rating: .again, state: .relearning, step: 0, stability: 2.9338452901880046, difficulty: 7.387715706030851, intervalSeconds: 600),
            .init(rating: .good, state: .review, step: nil, stability: 2.9338452901880046, difficulty: 7.375556359621658, intervalSeconds: 259_200),
            .init(rating: .good, state: .review, step: nil, stability: 7.799102228394648, difficulty: 7.363409172558875, intervalSeconds: 691_200),
            .init(rating: .easy, state: .review, step: nil, stability: 28.49617137775706, difficulty: 6.467611752457447, intervalSeconds: 2_419_200),
            .init(rating: .hard, state: .review, step: nil, stability: 52.14693048778561, difficulty: 7.6402644412857565, intervalSeconds: 4_492_800),
            .init(rating: .good, state: .review, step: nil, stability: 100.89598491706877, difficulty: 7.627852546141309, intervalSeconds: 8_726_400),
            .init(rating: .good, state: .review, step: nil, stability: 185.94192985544345, difficulty: 7.615453062892006, intervalSeconds: 16_070_400),
        ]
        let scheduler = noFuzz()
        var card = SchedulingCard(due: t0)
        var now = t0
        for (i, v) in vectors.enumerated() {
            let result = scheduler.review(card, rating: v.rating, now: now)
            card = result.card
            #expect(card.state == v.state, "state \(i)")
            #expect(card.step == v.step, "step \(i)")
            #expect(abs((card.stability ?? 0) - v.stability) < 1e-9, "stability \(i)")
            #expect(abs((card.difficulty ?? 0) - v.difficulty) < 1e-9, "difficulty \(i)")
            #expect(card.due.timeIntervalSince(now) == v.intervalSeconds, "interval \(i)")
            #expect(card.lastReview == now)
            #expect(result.log.rating == v.rating)
            now = card.due
        }
        #expect(card.reps == vectors.count)
        #expect(card.lapses == 1)
        // py-fsrs: get_card_retrievability(card, due + 5 days) = 0.898145541510724
        let r = scheduler.retrievability(card, now: now.addingTimeInterval(5 * 86_400))
        #expect(abs(r - 0.898145541510724) < 1e-12)
    }

    @Test func newCardRetrievabilityIsZero() {
        #expect(noFuzz().retrievability(SchedulingCard(due: t0), now: t0) == 0)
    }

    @Test func defaultsMatchUpstream() {
        let p = FSRSParameters.default
        #expect(p.weights.count == 21)
        #expect(p.desiredRetention == 0.9)
        #expect(p.learningSteps == [60, 600])
        #expect(p.relearningSteps == [600])
        #expect(p.maximumInterval == 36500)
        #expect(p.enableFuzz)
    }

    @Test func previewMatchesActualReviewsAndIsFuzzFree() {
        let scheduler = Scheduler()  // fuzz on
        let first = noFuzz().review(SchedulingCard(due: t0), rating: .good, now: t0).card
        let second = noFuzz().review(first, rating: .good, now: first.due).card
        let preview = scheduler.nextIntervals(second, now: second.due)
        for rating in Rating.allCases {
            let exact = noFuzz().review(second, rating: rating, now: second.due).card
            #expect(preview[rating] == exact.due.timeIntervalSince(second.due))
        }
        #expect(preview[.again] == 600)
        #expect(preview.count == 4)
    }

    @Test func intervalLabels() {
        #expect(Scheduler.label(for: 600) == "10m")
        #expect(Scheduler.label(for: 3 * 86_400) == "3d")
        #expect(Scheduler.label(for: 2 * 3600) == "2h")
        #expect(Scheduler.label(for: 60 * 86_400) == "2mo")
        #expect(Scheduler.label(for: 30) == "<1m")
    }

    @Test func fuzzMatchesPyFSRSForFixedRandomValues() {
        // random() patched to 0.0, 0.5, 0.999 in py-fsrs; intervals in days for ratings good x5, easy.
        let cases: [(UInt64, [Double])] = [
            (0, [2, 9, 37, 131, 632]),
            (1 << 63, [2, 12, 50, 174, 836]),
            (UInt64.max, [2, 14, 59, 207, 1005]),
        ]
        for (bits, days) in cases {
            var generator = Constant(value: bits)
            let scheduler = Scheduler()
            var card = SchedulingCard(due: t0)
            var now = t0
            var got: [Double] = []
            let ratings: [Rating] = [.good, .good, .good, .good, .good, .easy]
            for (i, rating) in ratings.enumerated() {
                card = scheduler.review(card, rating: rating, now: now, using: &generator).card
                if i >= 1 { got.append(card.due.timeIntervalSince(now) / 86_400) }
                now = card.due
            }
            #expect(got == days, "bits \(bits)")
        }
    }

    @Test func fuzzIsDeterministicWithSeedAndBounded() {
        func run(seed: UInt64) -> [Date] {
            var generator = SeededGenerator(seed: seed)
            var card = SchedulingCard(due: t0)
            var now = t0
            var dues: [Date] = []
            for _ in 0..<8 {
                card = Scheduler().review(card, rating: .good, now: now, using: &generator).card
                dues.append(card.due)
                now = card.due
            }
            return dues
        }
        #expect(run(seed: 42) == run(seed: 42))
        #expect(run(seed: 42) != run(seed: 7))
    }

    @Test func fuzzNeverExceedsMaximumInterval() {
        var parameters = FSRSParameters()
        parameters.maximumInterval = 10
        let scheduler = Scheduler(parameters: parameters)
        var generator = Constant(value: UInt64.max)
        var card = SchedulingCard(due: t0)
        var now = t0
        for _ in 0..<8 {
            card = scheduler.review(card, rating: .easy, now: now, using: &generator).card
            #expect(card.due.timeIntervalSince(now) <= 10 * 86_400)
            now = card.due
        }
    }

    @Test func noFuzzForLearningSteps() {
        var generator = Constant(value: UInt64.max)
        let card = Scheduler().review(SchedulingCard(due: t0), rating: .again, now: t0, using: &generator).card
        #expect(card.due.timeIntervalSince(t0) == 60)
        #expect(card.state == .learning)
    }

    @Test func emptyRelearningStepsKeepReviewState() {
        let scheduler = Scheduler(parameters: FSRSParameters(relearningSteps: [], enableFuzz: false))
        var card = SchedulingCard(due: t0)
        card = scheduler.review(card, rating: .easy, now: t0).card
        let lapse = scheduler.review(card, rating: .again, now: card.due)
        #expect(lapse.card.state == .review)
        #expect(lapse.card.lapses == 1)
        #expect(lapse.card.due > card.due)
    }

    @Test func codableRoundTrip() throws {
        let scheduler = noFuzz()
        let result = scheduler.review(SchedulingCard(due: t0), rating: .good, now: t0)
        let encoder = JSONEncoder()
        let card = try JSONDecoder().decode(SchedulingCard.self, from: encoder.encode(result.card))
        let log = try JSONDecoder().decode(ReviewLog.self, from: encoder.encode(result.log))
        let params = try JSONDecoder().decode(FSRSParameters.self, from: encoder.encode(FSRSParameters.default))
        let item = ReviewItem(id: "a", kind: .resolve, scheduling: result.card)
        let decodedItem = try JSONDecoder().decode(ReviewItem.self, from: encoder.encode(item))
        #expect(card == result.card)
        #expect(log == result.log)
        #expect(params == .default)
        #expect(decodedItem == item)
        let progress = UnitProgress(lessonsStarted: 1, coreExercisesTotal: 2, coreExercisesPassed: 1, cards: [result.card])
        #expect(try JSONDecoder().decode(UnitProgress.self, from: encoder.encode(progress)) == progress)
        #expect(Set([result.card, card]).count == 1)
    }
}

// MARK: Queue

private var calendar: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return c
}

private func item(_ id: String, _ kind: ReviewItemKind, dueHours: Double?, state: ReviewState = .review) -> ReviewItem {
    var card = SchedulingCard(due: t0.addingTimeInterval((dueHours ?? 0) * 3600))
    card.state = state
    if state != .new { card.memory = MemoryState(stability: 5, difficulty: 5) }
    return ReviewItem(id: id, kind: kind, scheduling: card)
}

@Suite struct ReviewQueueTests {
    // now = 12:00 on 2024-01-01 UTC; end of day = 24:00
    private let now = t0.addingTimeInterval(12 * 3600)

    @Test func dueTodayOrderedByDueDate() {
        let items = [
            item("c", .card, dueHours: 10),
            item("a", .card, dueHours: -30),  // overdue
            item("future", .card, dueHours: 24),  // tomorrow 00:00
            item("b", .card, dueHours: 3),
            item("late", .card, dueHours: 23.5),  // later today, still included
        ]
        let queue = ReviewQueue.today(items: items, now: now, calendar: calendar, newLimit: 0)
        #expect(queue.map(\.id) == ["a", "b", "c", "late"])
    }

    @Test func newItemsRespectDailyLimit() {
        let items = (0..<5).map { item("n\($0)", .card, dueHours: 0, state: .new) }
        let queue = ReviewQueue.today(items: items, now: now, calendar: calendar, newLimit: 3)
        #expect(queue.map(\.id) == ["n0", "n1", "n2"])
        let reduced = ReviewQueue.today(items: items, now: now, calendar: calendar, newLimit: 3, newIntroducedToday: 2)
        #expect(reduced.map(\.id) == ["n0"])
        let none = ReviewQueue.today(items: items, now: now, calendar: calendar, newLimit: 3, newIntroducedToday: 9)
        #expect(none.isEmpty)
    }

    @Test func newItemsFollowDueItems() {
        let items = [item("n", .card, dueHours: -100, state: .new), item("d", .card, dueHours: 1)]
        let queue = ReviewQueue.today(items: items, now: now, calendar: calendar, newLimit: 5)
        #expect(queue.map(\.id) == ["d", "n"])
    }

    @Test func interleavesKindsWithoutThreeInARow() {
        var items: [ReviewItem] = []
        for i in 0..<6 { items.append(item("c\(i)", .card, dueHours: Double(i))) }
        for i in 0..<3 { items.append(item("r\(i)", .resolve, dueHours: Double(10 + i))) }
        for i in 0..<2 { items.append(item("i\(i)", .interleaved, dueHours: Double(15 + i))) }
        let queue = ReviewQueue.today(items: items, now: now, calendar: calendar, newLimit: 0)
        #expect(queue.count == 11)
        #expect(Set(queue.map(\.id)).count == 11)
        for i in 2..<queue.count {
            #expect(!(queue[i].kind == queue[i - 1].kind && queue[i].kind == queue[i - 2].kind), "run at \(i)")
        }
        // Earliest due still comes first.
        #expect(queue.first?.id == "c0")
    }

    @Test func singleKindIsLeftAlone() {
        let items = (0..<5).map { item("c\($0)", .card, dueHours: Double($0)) }
        let queue = ReviewQueue.today(items: items, now: now, calendar: calendar, newLimit: 0)
        #expect(queue.map(\.id) == ["c0", "c1", "c2", "c3", "c4"])
    }

    @Test func calendarTimeZoneDecidesEndOfDay() {
        var pacific = Calendar(identifier: .gregorian)
        pacific.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .gmt
        // 12:00 UTC is 04:00 PST; the day ends at 08:00 UTC on Jan 2.
        let items = [item("in", .card, dueHours: 30), item("out", .card, dueHours: 33)]
        let queue = ReviewQueue.today(items: items, now: now, calendar: pacific, newLimit: 0)
        #expect(queue.map(\.id) == ["in"])
    }
}

// MARK: Mastery

private func stableCard(_ stability: Double, state: ReviewState = .review) -> SchedulingCard {
    var card = SchedulingCard(due: t0)
    card.memory = MemoryState(stability: stability, difficulty: 5)
    card.state = state
    return card
}

@Suite struct UnitMasteryTests {
    @Test func transitions() {
        func level(_ started: Int, _ total: Int, _ passed: Int, _ cards: [SchedulingCard]) -> UnitMasteryLevel {
            UnitMastery.level(for: UnitProgress(lessonsStarted: started, coreExercisesTotal: total, coreExercisesPassed: passed, cards: cards))
        }
        #expect(level(0, 3, 0, []) == .new)
        #expect(level(1, 3, 0, []) == .learning)
        #expect(level(1, 3, 2, [stableCard(30)]) == .learning)
        #expect(level(1, 3, 3, []) == .practiced)
        #expect(level(1, 3, 3, [stableCard(30), stableCard(20.9)]) == .practiced)
        #expect(level(1, 3, 3, [stableCard(30), stableCard(21)]) == .mastered)
        #expect(level(1, 3, 3, [SchedulingCard(due: t0)]) == .practiced)
    }

    @Test func lapseDropsMasteryToPracticed() {
        let progress = UnitProgress(lessonsStarted: 1, coreExercisesTotal: 1, coreExercisesPassed: 1,
                                    cards: [stableCard(60), stableCard(60, state: .relearning)])
        #expect(UnitMastery.level(for: progress) == .practiced)
    }

    @Test func passedExerciseImpliesStarted() {
        let progress = UnitProgress(lessonsStarted: 0, coreExercisesTotal: 3, coreExercisesPassed: 1, cards: [])
        #expect(UnitMastery.level(for: progress) == .learning)
    }

    @Test func noCoreExercisesCannotBePracticed() {
        let progress = UnitProgress(lessonsStarted: 2, coreExercisesTotal: 0, coreExercisesPassed: 0, cards: [stableCard(90)])
        #expect(UnitMastery.level(for: progress) == .learning)
    }

    @Test func levelsAreOrdered() {
        #expect(UnitMasteryLevel.new < .learning && .learning < .practiced && .practiced < .mastered)
    }
}
