#if canImport(SwiftData)
import Foundation
import SwiftData
import Testing
import Contracts
import Review
@testable import Store

private let t0 = Date(timeIntervalSince1970: 1_800_000_000.25)
private let day: TimeInterval = 86_400

private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func pass() -> TestReport { TestReport(results: [TestResult(name: "t", passed: true)]) }
private func fail() -> TestReport { TestReport(results: [TestResult(name: "t", passed: false)]) }

@MainActor
private func makeStore(
    container: ModelContainer? = nil, clock: @escaping @MainActor () -> Date = { t0 }
) throws -> (SwiftDataProgress, ModelContainer) {
    let container = try container ?? StoreContainer.make(inMemory: true)
    return (SwiftDataProgress(context: ModelContext(container), clock: clock, saveDelay: .milliseconds(20)), container)
}

private func exercise(_ id: String, _ level: ExerciseLevel) -> Exercise {
    Exercise(id: id, title: id, level: level, prompt: "", starter: "", solution: "")
}

private func lesson(_ id: String) -> Lesson { Lesson(id: id, title: id, steps: []) }

private func card(_ unit: String, _ slug: String) -> Card {
    Card(id: "\(unit)/\(slug)", question: slug, answer: "")
}

private func library() -> ContentLibrary {
    let a = CourseUnit(
        id: "a", title: "A", lessons: [lesson("a1")],
        exercises: [exercise("a-core", .core), exercise("a-warm", .warmup)],
        cards: [card("a", "q1"), card("a", "q2")])
    let b = CourseUnit(
        id: "b", title: "B", lessons: [lesson("b1")],
        exercises: [exercise("b-core", .core)], cards: [card("b", "q1")])
    return ContentLibrary(tracks: [Track(id: "t", title: "T", units: [a, b])], root: URL(fileURLWithPath: "/"))
}

private final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false
    func set() { lock.withLock { flag = true } }
    var value: Bool { lock.withLock { flag } }
}

@MainActor
@Suite struct ProgressTests {
    @Test func parityWithInMemory() throws {
        let (store, _) = try makeStore()
        let reference = InMemoryProgress()
        func both(_ body: (any ProgressRecording) -> Void) {
            body(store)
            body(reference)
        }
        both { $0.recordStep(lessonID: "l", stepIndex: 0, stepCount: 3) }
        both { $0.recordStep(lessonID: "l", stepIndex: 1, stepCount: 3) }
        both { $0.recordStep(lessonID: "l", stepIndex: 0, stepCount: 3) }
        both { $0.recordStep(lessonID: "m", stepIndex: 2, stepCount: 3) }
        both { $0.saveCode("x = 1", exerciseID: "e") }
        both { $0.recordHintsRevealed(2, exerciseID: "e") }
        both { $0.recordHintsRevealed(1, exerciseID: "e") }
        both { $0.recordAttempt(exerciseID: "e", report: fail()) }
        both { $0.recordAttempt(exerciseID: "f", report: fail()) }
        both { $0.recordAttempt(exerciseID: "f", report: pass()) }
        both { $0.recordAttempt(exerciseID: "f", report: fail()) }
        both { $0.recordSolutionViewed(exerciseID: "g") }
        both { $0.recordAttempt(exerciseID: "h", report: TestReport(results: [])) }

        for id in ["l", "m", "unknown"] {
            #expect(store.lessonProgress(id) == reference.lessonProgress(id))
        }
        for id in ["e", "f", "g", "h", "unknown"] {
            #expect(store.exerciseProgress(id) == reference.exerciseProgress(id))
        }
        #expect(store.exerciseProgress("f").state == .passed)
        #expect(store.lessonProgress("m").state == .completed)
    }

    @Test func persistsAcrossContexts() throws {
        var now = t0
        let (store, container) = try makeStore(clock: { now })
        store.recordStep(lessonID: "l", stepIndex: 1, stepCount: 3)
        store.saveCode("code", exerciseID: "e")
        store.recordAttempt(exerciseID: "e", report: fail())
        now = t0.addingTimeInterval(60)
        store.recordAttempt(exerciseID: "e", report: pass())
        store.recordSolutionViewed(exerciseID: "e")
        store.flush()

        let (again, _) = try makeStore(container: container)
        #expect(again.lessonProgress("l") == LessonProgress(state: .inProgress, furthestStep: 1))
        #expect(again.exerciseProgress("e") == ExerciseProgress(state: .passed, hintsRevealed: 0, solutionViewed: true, savedCode: "code"))
        #expect(again.exerciseRecords["e"]?.passedAt == t0.addingTimeInterval(60))
        #expect(again.exerciseRecords["e"]?.lastAttemptPassed == true)
    }

    @Test func debouncedSaveCodeReachesStore() async throws {
        let (store, container) = try makeStore()
        store.saveCode("a", exerciseID: "e")
        store.saveCode("ab", exerciseID: "e")
        try await Task.sleep(for: .milliseconds(200))
        let other = ModelContext(container)
        let rows = try other.fetch(FetchDescriptor<ExerciseRecord>())
        #expect(rows.count == 1)
        #expect(rows.first?.savedCode == "ab")
        #expect(store.saveError == nil)
    }

    @Test func duplicatesTakeNewestAndMerge() throws {
        let container = try StoreContainer.make(inMemory: true)
        let context = ModelContext(container)
        for (step, at) in [(1, 10.0), (4, 30.0), (2, 20.0)] {
            let record = LessonRecord(lessonID: "l")
            record.stateRaw = LessonState.inProgress.rawValue
            record.furthestStep = step
            record.updatedAt = Date(timeIntervalSince1970: at)
            context.insert(record)
        }
        try context.save()

        let store = SwiftDataProgress(context: context)
        #expect(store.lessonProgress("l").furthestStep == 4)
        #expect(try context.fetch(FetchDescriptor<LessonRecord>()).count == 1)

        // A duplicate that arrives later is merged on the next write.
        let late = LessonRecord(lessonID: "l")
        late.updatedAt = Date(timeIntervalSince1970: 5)
        context.insert(late)
        store.recordStep(lessonID: "l", stepIndex: 5, stepCount: 9)
        #expect(try context.fetch(FetchDescriptor<LessonRecord>()).count == 1)
        #expect(store.lessonProgress("l").furthestStep == 5)
    }

    @Test func observationFiresForMissingIDs() async throws {
        let (store, _) = try makeStore()
        let fired = Flag()
        withObservationTracking {
            _ = store.lessonProgress("new")
        } onChange: {
            fired.set()
        }
        store.recordStep(lessonID: "new", stepIndex: 0, stepCount: 2)
        #expect(fired.value)
    }
}

@MainActor
@Suite struct ReviewTests {
    @Test func nothingDueBeforeStarting() throws {
        let (store, _) = try makeStore()
        #expect(store.dueItems(library: library(), now: t0, calendar: calendar).isEmpty)
    }

    @Test func cardsAppearOnceALessonStarts() throws {
        let (store, _) = try makeStore()
        store.recordStep(lessonID: "a1", stepIndex: 0, stepCount: 3)
        let items = store.dueItems(library: library(), now: t0, calendar: calendar)
        #expect(items.map(\.id).sorted() == ["a/q1", "a/q2"])
        #expect(items.allSatisfy { $0.kind == .card && $0.scheduling.state == .new })
    }

    @Test func newLimitCapsNewItems() throws {
        let (store, _) = try makeStore()
        store.recordStep(lessonID: "a1", stepIndex: 0, stepCount: 3)
        #expect(store.dueItems(library: library(), now: t0, calendar: calendar, newLimit: 1).count == 1)
        store.record(itemID: "a/q1", rating: .good, now: t0)
        // One introduced today: no more new items today, learning card is due again within the day.
        let items = store.dueItems(library: library(), now: t0.addingTimeInterval(3600), calendar: calendar, newLimit: 1)
        #expect(items.allSatisfy { $0.scheduling.state != .new })
    }

    @Test func resolveAndInterleaved() throws {
        var now = t0
        let (store, _) = try makeStore(clock: { now })
        let lib = library()
        // Unit b passed a day ago, then unit a is studied: b's core exercise interleaves.
        store.recordAttempt(exerciseID: "b-core", report: pass())
        store.recordStep(lessonID: "b1", stepIndex: 0, stepCount: 3)
        now = t0.addingTimeInterval(2 * day)
        store.recordStep(lessonID: "a1", stepIndex: 0, stepCount: 3)
        store.recordSolutionViewed(exerciseID: "a-warm")

        let ids = Set(store.dueItems(library: lib, now: now, calendar: calendar).map(\.id))
        #expect(ids.contains(ReviewItemID.resolve(exerciseID: "b-core")))
        #expect(ids.contains(ReviewItemID.interleaved(exerciseID: "b-core")))
        #expect(ids.contains(ReviewItemID.resolve(exerciseID: "a-warm")))
        #expect(!ids.contains(ReviewItemID.interleaved(exerciseID: "a-warm")))
        #expect(ids.contains("b/q1") && ids.contains("a/q1"))
    }

    @Test func freshPassWaitsADay() throws {
        let (store, _) = try makeStore()
        store.recordAttempt(exerciseID: "a-core", report: pass())
        let soon = store.dueItems(library: library(), now: t0.addingTimeInterval(3600), calendar: calendar)
        #expect(!soon.contains { ReviewItemID.exerciseID(of: $0.id) == "a-core" })
        let later = store.dueItems(library: library(), now: t0.addingTimeInterval(day + 1), calendar: calendar)
        #expect(later.contains { $0.id == ReviewItemID.resolve(exerciseID: "a-core") })
    }

    @Test func recordingAdvancesDueDate() throws {
        let (store, container) = try makeStore()
        store.recordStep(lessonID: "a1", stepIndex: 0, stepCount: 3)
        let first = store.record(itemID: "a/q1", rating: .easy, now: t0)
        #expect(first.due > t0)
        #expect(first.reps == 1)
        let second = store.record(itemID: "a/q1", rating: .good, now: first.due)
        #expect(second.due.timeIntervalSince(first.due) > first.due.timeIntervalSince(t0) * 0.99)
        #expect(second.reps == 2)

        let (again, _) = try makeStore(container: container)
        #expect(again.reviewRecords["a/q1"]?.historyCount == 2)
        #expect(again.reviewRecords["a/q1"]?.lastRating == .good)
        #expect(again.reviewRecords["a/q1"]?.scheduling == second)

        // Not due until its date, due after.
        let early = again.dueItems(library: library(), now: first.due.addingTimeInterval(-3 * day), calendar: calendar, newLimit: 0)
        #expect(!early.contains { $0.id == "a/q1" })
        let late = again.dueItems(library: library(), now: second.due.addingTimeInterval(60), calendar: calendar, newLimit: 0)
        #expect(late.contains { $0.id == "a/q1" })
    }

    @Test func previewIntervalsLabelEveryRating() throws {
        let (store, _) = try makeStore()
        let labels = store.previewIntervals(itemID: "a/q1", now: t0)
        #expect(Set(labels.keys) == Set(Rating.allCases))
        #expect(labels.values.allSatisfy { !$0.isEmpty })
    }

    @Test func masteryFollowsProgress() throws {
        let (store, _) = try makeStore()
        let unit = library().tracks[0].units[0]
        #expect(store.mastery(unit: unit) == .new)
        store.recordStep(lessonID: "a1", stepIndex: 0, stepCount: 3)
        #expect(store.mastery(unit: unit) == .learning)
        store.recordAttempt(exerciseID: "a-core", report: pass())
        #expect(store.mastery(unit: unit) == .practiced)
    }
}

@MainActor
@Suite struct ExportTests {
    @Test func roundTrip() throws {
        let (source, _) = try makeStore()
        source.recordStep(lessonID: "a1", stepIndex: 1, stepCount: 4)
        source.saveCode("print(1)", exerciseID: "a-core")
        source.recordHintsRevealed(2, exerciseID: "a-core")
        source.recordAttempt(exerciseID: "a-core", report: pass())
        source.recordSolutionViewed(exerciseID: "a-warm")
        source.record(itemID: "a/q1", rating: .good, now: t0)
        source.record(itemID: ReviewItemID.resolve(exerciseID: "a-core"), rating: .hard, now: t0)

        let data = try source.exportJSON()
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("2027-"))

        let (target, _) = try makeStore()
        try target.importJSON(data)
        #expect(target.lessonProgress("a1") == source.lessonProgress("a1"))
        #expect(target.exerciseProgress("a-core") == source.exerciseProgress("a-core"))
        #expect(target.exerciseProgress("a-warm").solutionViewed)
        #expect(target.reviewRecords["a/q1"]?.scheduling == source.reviewRecords["a/q1"]?.scheduling)
        #expect(target.exerciseRecords["a-core"]?.passedAt == source.exerciseRecords["a-core"]?.passedAt)
        #expect(try target.exportJSON() == data)
    }

    @Test func importKeepsNewerLocalRecords() throws {
        var now = t0
        let (source, _) = try makeStore(clock: { now })
        source.recordStep(lessonID: "l", stepIndex: 0, stepCount: 5)
        let data = try source.exportJSON()

        now = t0.addingTimeInterval(100)
        let (target, _) = try makeStore(clock: { now })
        target.recordStep(lessonID: "l", stepIndex: 3, stepCount: 5)
        try target.importJSON(data)
        #expect(target.lessonProgress("l").furthestStep == 3)
    }

    @Test func rejectsGarbageAndFutureVersions() throws {
        let (store, _) = try makeStore()
        #expect(throws: (any Error).self) { try store.importJSON(Data("nope".utf8)) }
        let future = #"{"version":99,"exportedAt":"2027-01-01T00:00:00Z","lessons":[],"exercises":[],"reviews":[]}"#
        #expect(throws: StoreImportError.unsupportedVersion(99)) { try store.importJSON(Data(future.utf8)) }
    }
}
#endif
