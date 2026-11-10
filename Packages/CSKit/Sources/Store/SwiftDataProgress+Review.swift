#if canImport(SwiftData)
import Foundation
import Contracts
import Review

// Review items. What enters the pool (PLAN.md, Review):
// - cards of units with at least one lesson started;
// - re-solve: an exercise whose solution was viewed, or that passed at least a day ago;
// - interleaved: a core exercise passed (without the solution) at least a day ago, from a
//   unit other than the one most recently studied. It is a separate item from the re-solve,
//   with its own schedule.
// An item that already has a review record stays in the pool while its content exists.

extension SwiftDataProgress {
    private static let resolveDelay: TimeInterval = 86_400

    /// Today's queue: due items first, then new items up to the daily limit, interleaved by kind.
    public func dueItems(
        library: ContentLibrary, now: Date, calendar: Calendar, newLimit: Int? = nil
    ) -> [ReviewItem] {
        let units = library.tracks.flatMap(\.units)
        let currentUnitID = currentUnitID(in: units)
        let agedBefore = now.addingTimeInterval(-Self.resolveDelay)

        var candidates: [(id: String, kind: ReviewItemKind)] = []
        var seen: Set<String> = []
        func add(_ id: String, _ kind: ReviewItemKind) {
            if seen.insert(id).inserted { candidates.append((id, kind)) }
        }

        for unit in units {
            let started = unit.lessons.contains { lessonProgress($0.id).state != .notStarted }
            if started {
                for card in unit.cards { add(card.id, .card) }
            }
            for exercise in unit.exercises {
                let progress = exerciseProgress(exercise.id)
                let passed = progress.state == .passed
                // A passed exercise with no timestamp (older data) counts as aged.
                let aged = passed && (exerciseRecords[exercise.id]?.passedAt.map { $0 <= agedBefore } ?? true)
                if progress.solutionViewed || aged {
                    add(ReviewItemID.resolve(exerciseID: exercise.id), .resolve)
                }
                if exercise.level == .core, aged, !progress.solutionViewed, unit.id != currentUnitID {
                    add(ReviewItemID.interleaved(exerciseID: exercise.id), .interleaved)
                }
            }
        }

        // Keep items already in review while their content still exists.
        var cardIDs: Set<String> = []
        for unit in units { for card in unit.cards { cardIDs.insert(card.id) } }
        for id in reviewRecords.keys.sorted() where !seen.contains(id) {
            let exists = ReviewItemID.exerciseID(of: id).map { library.exercise(id: $0) != nil } ?? cardIDs.contains(id)
            if exists { add(id, ReviewItemID.kind(of: id)) }
        }

        let items = candidates.map { id, kind in
            ReviewItem(id: id, kind: kind, scheduling: scheduling(for: id, now: now))
        }
        let introducedToday = reviewRecords.values.filter {
            $0.introducedAt.map { calendar.isDate($0, inSameDayAs: now) } ?? false
        }.count
        return ReviewQueue.today(
            items: items, now: now, calendar: calendar,
            newLimit: newLimit ?? newItemsPerDay, newIntroducedToday: introducedToday)
    }

    /// Runs FSRS for `rating` and saves the result. Returns the new schedule.
    @discardableResult
    public func record(itemID: String, rating: Rating, now: Date) -> SchedulingCard {
        let outcome = scheduler.review(scheduling(for: itemID, now: now), rating: rating, now: now)
        let record = reviewRecord(itemID)
        record.scheduling = outcome.card
        record.lastRatingRaw = rating.rawValue
        record.historyCount += 1
        if record.introducedAt == nil { record.introducedAt = now }
        record.updatedAt = now
        commit()
        return outcome.card
    }

    /// Button labels for each rating ("10m", "3d").
    public func previewIntervals(itemID: String, now: Date) -> [Rating: String] {
        scheduler.nextIntervals(scheduling(for: itemID, now: now), now: now)
            .mapValues(Scheduler.label(for:))
    }

    /// The unit's level, from lessons started, core exercises passed and card stability.
    public func mastery(unit: CourseUnit) -> UnitMasteryLevel {
        let core = unit.exercises.filter { $0.level == .core }
        let now = clock()
        return UnitMastery.level(for: UnitProgress(
            lessonsStarted: unit.lessons.filter { lessonProgress($0.id).state != .notStarted }.count,
            coreExercisesTotal: core.count,
            coreExercisesPassed: core.filter { exerciseProgress($0.id).state == .passed }.count,
            cards: unit.cards.map { scheduling(for: $0.id, now: now) }))
    }

    private func scheduling(for itemID: String, now: Date) -> SchedulingCard {
        reviewRecords[itemID]?.scheduling ?? SchedulingCard(due: now)
    }

    /// The unit of the most recently touched lesson.
    private func currentUnitID(in units: [CourseUnit]) -> String? {
        var best: (unit: String, at: Date)?
        for unit in units {
            for lesson in unit.lessons {
                guard let at = lessonRecords[lesson.id]?.updatedAt else { continue }
                if best.map({ at > $0.at }) ?? true { best = (unit.id, at) }
            }
        }
        return best?.unit
    }
}
#endif
