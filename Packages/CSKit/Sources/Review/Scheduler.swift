import Foundation

/// FSRS-6 scheduler, a Swift port of open-spaced-repetition/py-fsrs 6.3.2
/// (`fsrs/scheduler.py`, `Scheduler.review_card`). Formulas, clamping, rounding
/// (banker's, as Python's `round`) and fuzz ranges follow that file.
///
/// Differences from upstream: cards have an explicit `new` state (upstream uses
/// `learning` at step 0 with no memory), and `reps`/`lapses` are counted.
public struct Scheduler: Sendable, Hashable {
    public var parameters: FSRSParameters

    private static let day: TimeInterval = 86_400
    private static let stabilityMin = 0.001
    private let decay: Double
    private let factor: Double

    public init(parameters: FSRSParameters = .default) {
        self.parameters = parameters
        decay = -parameters.w(20)
        factor = pow(0.9, 1 / decay) - 1
    }

    // MARK: Retrievability

    /// Probability of recalling the card at `now`. Zero for a card never reviewed.
    public func retrievability(_ card: SchedulingCard, now: Date) -> Double {
        guard let memory = card.memory, let last = card.lastReview else { return 0 }
        return retrievability(stability: memory.stability, elapsedDays: Self.wholeDays(from: last, to: now) ?? 0)
    }

    private func retrievability(stability: Double, elapsedDays: Int) -> Double {
        pow(1 + factor * Double(max(0, elapsedDays)) / stability, decay)
    }

    private static func wholeDays(from last: Date, to now: Date) -> Int? {
        Int((now.timeIntervalSince(last) / day).rounded(.down))
    }

    // MARK: Review

    /// Review with system randomness for fuzz.
    public func review(_ card: SchedulingCard, rating: Rating, now: Date) -> (card: SchedulingCard, log: ReviewLog) {
        var generator = SystemRandomNumberGenerator()
        return review(card, rating: rating, now: now, using: &generator)
    }

    /// Review with an injected generator for fuzz (tests pass a `SeededGenerator`).
    public func review<G: RandomNumberGenerator>(
        _ card: SchedulingCard, rating: Rating, now: Date, using generator: inout G
    ) -> (card: SchedulingCard, log: ReviewLog) {
        var next = card
        let elapsedDays: Int? = card.lastReview.flatMap { Self.wholeDays(from: $0, to: now) }
        let isShortTerm = (elapsedDays ?? Int.max) < 1

        // Memory update (all states).
        let updated: MemoryState
        if let memory = card.memory {
            let stability: Double
            if isShortTerm {
                stability = shortTermStability(memory.stability, rating)
            } else {
                let r = retrievability(stability: memory.stability, elapsedDays: elapsedDays ?? 0)
                stability = nextStability(memory, r, rating)
            }
            updated = MemoryState(stability: stability, difficulty: nextDifficulty(memory.difficulty, rating))
        } else {
            updated = MemoryState(stability: initialStability(rating), difficulty: initialDifficulty(rating).clamped(1, 10))
        }
        next.memory = updated

        // Next state and interval.
        let interval: TimeInterval
        switch card.state {
        case .new, .learning:
            let t = advance(step: card.step ?? 0, steps: parameters.learningSteps, rating: rating, stability: updated.stability, staying: .learning)
            next.state = t.state
            next.step = t.step
            interval = t.interval
        case .relearning:
            let t = advance(step: card.step ?? 0, steps: parameters.relearningSteps, rating: rating, stability: updated.stability, staying: .relearning)
            next.state = t.state
            next.step = t.step
            interval = t.interval
        case .review:
            if rating == .again {
                next.lapses += 1
                if let first = parameters.relearningSteps.first {
                    next.state = .relearning
                    next.step = 0
                    interval = first
                } else {
                    interval = Double(nextIntervalDays(updated.stability)) * Self.day
                }
            } else {
                interval = Double(nextIntervalDays(updated.stability)) * Self.day
            }
        }

        let finalInterval = (parameters.enableFuzz && next.state == .review)
            ? fuzzed(interval, using: &generator) : interval
        next.due = now.addingTimeInterval(finalInterval)
        next.lastReview = now
        next.reps += 1

        let log = ReviewLog(
            rating: rating, reviewedAt: now, stateBefore: card.state,
            elapsed: card.lastReview.map { now.timeIntervalSince($0) })
        return (next, log)
    }

    // MARK: Preview

    /// Interval (seconds) each rating would schedule, without fuzz. For button labels.
    public func nextIntervals(_ card: SchedulingCard, now: Date) -> [Rating: TimeInterval] {
        var exact = self
        exact.parameters.enableFuzz = false
        var generator = SystemRandomNumberGenerator()
        var result: [Rating: TimeInterval] = [:]
        for rating in Rating.allCases {
            let outcome = exact.review(card, rating: rating, now: now, using: &generator)
            result[rating] = outcome.card.due.timeIntervalSince(now)
        }
        return result
    }

    /// Compact label for an interval: "10m", "3d", "2mo", "1y".
    public static func label(for interval: TimeInterval) -> String {
        let minutes = interval / 60
        if minutes < 1 { return "<1m" }
        if minutes < 60 { return "\(Int(minutes.rounded()))m" }
        let hours = minutes / 60
        if hours < 24 { return "\(Int(hours.rounded()))h" }
        let days = hours / 24
        if days < 30 { return "\(Int(days.rounded()))d" }
        if days < 365 { return "\(Int((days / 30).rounded()))mo" }
        let years = days / 365
        return years < 10 ? String(format: "%.1fy", years) : "\(Int(years.rounded()))y"
    }

    // MARK: Step logic

    private struct Transition {
        var state: ReviewState
        var step: Int?
        var interval: TimeInterval
    }

    /// Learning and relearning share this logic (`relearning` graduates to `review`).
    private func advance(step: Int, steps: [TimeInterval], rating: Rating, stability: Double, staying: ReviewState) -> Transition {
        let graduate = Transition(state: .review, step: nil, interval: Double(nextIntervalDays(stability)) * Self.day)
        guard !steps.isEmpty else { return graduate }
        // Card was scheduled with more steps than the current configuration.
        if step >= steps.count && rating != .again { return graduate }
        let current = min(step, steps.count - 1)
        switch rating {
        case .again:
            return Transition(state: staying, step: 0, interval: steps[0])
        case .hard:
            let interval: TimeInterval
            if current == 0 && steps.count == 1 {
                interval = steps[0] * 1.5
            } else if current == 0 {
                interval = (steps[0] + steps[1]) / 2
            } else {
                interval = steps[current]
            }
            return Transition(state: staying, step: current, interval: interval)
        case .good:
            if current + 1 == steps.count { return graduate }
            return Transition(state: staying, step: current + 1, interval: steps[current + 1])
        case .easy:
            return graduate
        }
    }

    // MARK: Formulas (py-fsrs 6.3.2)

    private func initialStability(_ rating: Rating) -> Double {
        max(parameters.w(rating.rawValue - 1), Self.stabilityMin)
    }

    private func initialDifficulty(_ rating: Rating) -> Double {
        parameters.w(4) - exp(parameters.w(5) * Double(rating.rawValue - 1)) + 1
    }

    private func nextIntervalDays(_ stability: Double) -> Int {
        let raw = (stability / factor) * (pow(parameters.desiredRetention, 1 / decay) - 1)
        let days = Int(raw.rounded(.toNearestOrEven))
        return min(max(days, 1), parameters.maximumInterval)
    }

    private func shortTermStability(_ stability: Double, _ rating: Rating) -> Double {
        var increase = exp(parameters.w(17) * (Double(rating.rawValue) - 3 + parameters.w(18)))
            * pow(stability, -parameters.w(19))
        if rating != .again { increase = max(increase, 1) }
        return max(stability * increase, Self.stabilityMin)
    }

    private func nextDifficulty(_ difficulty: Double, _ rating: Rating) -> Double {
        let easyInitial = initialDifficulty(.easy)
        let delta = -(parameters.w(6) * Double(rating.rawValue - 3))
        let damped = difficulty + (10 - difficulty) * delta / 9
        let reverted = parameters.w(7) * easyInitial + (1 - parameters.w(7)) * damped
        return reverted.clamped(1, 10)
    }

    private func nextStability(_ m: MemoryState, _ r: Double, _ rating: Rating) -> Double {
        let value: Double
        if rating == .again {
            let longTerm = parameters.w(11)
                * pow(m.difficulty, -parameters.w(12))
                * (pow(m.stability + 1, parameters.w(13)) - 1)
                * exp((1 - r) * parameters.w(14))
            let shortTerm = m.stability / exp(parameters.w(17) * parameters.w(18))
            value = min(longTerm, shortTerm)
        } else {
            let hardPenalty = rating == .hard ? parameters.w(15) : 1
            let easyBonus = rating == .easy ? parameters.w(16) : 1
            value = m.stability * (1
                + exp(parameters.w(8))
                * (11 - m.difficulty)
                * pow(m.stability, -parameters.w(9))
                * (exp((1 - r) * parameters.w(10)) - 1)
                * hardPenalty * easyBonus)
        }
        return max(value, Self.stabilityMin)
    }

    // MARK: Fuzz

    private static let fuzzRanges: [(start: Double, end: Double, factor: Double)] = [
        (2.5, 7.0, 0.15), (7.0, 20.0, 0.1), (20.0, .infinity, 0.05),
    ]

    private func fuzzed<G: RandomNumberGenerator>(_ interval: TimeInterval, using generator: inout G) -> TimeInterval {
        let days = Int((interval / Self.day).rounded(.down))
        guard Double(days) >= 2.5 else { return interval }
        var delta = 1.0
        for range in Self.fuzzRanges {
            delta += range.factor * max(min(Double(days), range.end) - range.start, 0)
        }
        var low = Int((Double(days) - delta).rounded(.toNearestOrEven))
        var high = Int((Double(days) + delta).rounded(.toNearestOrEven))
        low = max(2, low)
        high = min(high, parameters.maximumInterval)
        low = min(low, high)
        // 53-bit uniform in [0, 1), like Python's random().
        let unit = Double(generator.next() >> 11) / 9_007_199_254_740_992
        let picked = (unit * Double(high - low + 1) + Double(low)).rounded(.toNearestOrEven)
        return Double(min(Int(picked), parameters.maximumInterval)) * Self.day
    }
}

extension Double {
    fileprivate func clamped(_ lower: Double, _ upper: Double) -> Double {
        Swift.min(Swift.max(self, lower), upper)
    }
}
