#if canImport(SwiftData)
import Foundation
import Observation
import SwiftData
import Contracts
import Review

/// Progress, saved code and review state in SwiftData.
///
/// Reads come from an observable in-memory mirror loaded at init, so SwiftUI updates for ids
/// that have no record yet. Writes go through to SwiftData. Behaves like `InMemoryProgress`.
@MainActor
@Observable
public final class SwiftDataProgress: ProgressRecording {
    // Mirror: what views read.
    var lessons: [String: LessonProgress] = [:]
    var exercises: [String: ExerciseProgress] = [:]

    // Newest record per key. Observable so review reads update too.
    var lessonRecords: [String: LessonRecord] = [:]
    var exerciseRecords: [String: ExerciseRecord] = [:]
    var reviewRecords: [String: ReviewRecord] = [:]

    /// The last save failure, if any. Cleared by the next successful save.
    public private(set) var saveError: (any Error)?

    /// New review items allowed per day.
    public var newItemsPerDay = 10
    @ObservationIgnored public var scheduler = Scheduler()

    @ObservationIgnored let context: ModelContext
    @ObservationIgnored let clock: @MainActor () -> Date
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let saveDelay: Duration

    /// - Parameters:
    ///   - clock: time source for record timestamps. Tests inject a fixed one.
    ///   - saveDelay: how long `saveCode` waits before saving. Every other write saves at once.
    public init(
        context: ModelContext,
        clock: @escaping @MainActor () -> Date = { Date() },
        saveDelay: Duration = .seconds(1)
    ) {
        self.context = context
        self.clock = clock
        self.saveDelay = saveDelay
        reload()
    }

    // MARK: Loading

    /// Rebuilds the mirror from the store. Duplicates left by sync are merged: the newest
    /// record stays and older ones are deleted. Call after a remote change arrives.
    public func reload() {
        saveTask?.cancel()
        saveTask = nil
        lessonRecords = Self.newest(fetch(LessonRecord.self), key: \.lessonID, date: \.updatedAt, context: context)
        exerciseRecords = Self.newest(fetch(ExerciseRecord.self), key: \.exerciseID, date: \.updatedAt, context: context)
        reviewRecords = Self.newest(fetch(ReviewRecord.self), key: \.itemID, date: \.updatedAt, context: context)
        lessons = lessonRecords.mapValues(\.progress)
        exercises = exerciseRecords.mapValues(\.progress)
        commit()
    }

    private func fetch<T: PersistentModel>(_ type: T.Type) -> [T] {
        (try? context.fetch(FetchDescriptor<T>())) ?? []
    }

    /// Newest record per key, deleting the rest.
    private static func newest<T: PersistentModel>(
        _ records: [T], key: KeyPath<T, String>, date: KeyPath<T, Date>, context: ModelContext
    ) -> [String: T] {
        var result: [String: T] = [:]
        for record in records {
            guard let current = result[record[keyPath: key]] else {
                result[record[keyPath: key]] = record
                continue
            }
            if record[keyPath: date] > current[keyPath: date] {
                context.delete(current)
                result[record[keyPath: key]] = record
            } else {
                context.delete(record)
            }
        }
        return result
    }

    // MARK: Lessons

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
        let record = lessonRecord(lessonID)
        record.progress = progress
        record.updatedAt = clock()
        commit()
    }

    // MARK: Exercises

    public func exerciseProgress(_ exerciseID: String) -> ExerciseProgress {
        exercises[exerciseID] ?? ExerciseProgress()
    }

    public func saveCode(_ code: String, exerciseID: String) {
        var progress = exerciseProgress(exerciseID)
        progress.savedCode = code
        write(progress, exerciseID: exerciseID, debounced: true)
    }

    public func recordAttempt(exerciseID: String, report: TestReport) {
        var progress = exerciseProgress(exerciseID)
        let wasPassed = progress.state == .passed
        if report.passed {
            progress.state = .passed
        } else if progress.state == .notStarted {
            progress.state = .attempted
        }
        let now = clock()
        write(progress, exerciseID: exerciseID, debounced: false) { record in
            record.lastAttemptAt = now
            record.lastAttemptPassed = report.passed
            if progress.state == .passed, !wasPassed { record.passedAt = now }
        }
    }

    public func recordHintsRevealed(_ count: Int, exerciseID: String) {
        var progress = exerciseProgress(exerciseID)
        progress.hintsRevealed = max(progress.hintsRevealed, count)
        write(progress, exerciseID: exerciseID, debounced: false)
    }

    public func recordSolutionViewed(exerciseID: String) {
        var progress = exerciseProgress(exerciseID)
        progress.solutionViewed = true
        write(progress, exerciseID: exerciseID, debounced: false)
    }

    private func write(
        _ progress: ExerciseProgress, exerciseID: String, debounced: Bool,
        _ extra: (ExerciseRecord) -> Void = { _ in }
    ) {
        exercises[exerciseID] = progress
        let record = exerciseRecord(exerciseID)
        record.progress = progress
        record.updatedAt = clock()
        extra(record)
        if debounced { scheduleSave() } else { commit() }
    }

    // MARK: Records

    func lessonRecord(_ id: String) -> LessonRecord {
        let found = (try? context.fetch(FetchDescriptor<LessonRecord>(predicate: #Predicate { $0.lessonID == id }))) ?? []
        let map = Self.newest(found, key: \.lessonID, date: \.updatedAt, context: context)
        if let record = map[id] {
            lessonRecords[id] = record
            return record
        }
        let record = LessonRecord(lessonID: id)
        context.insert(record)
        lessonRecords[id] = record
        return record
    }

    func exerciseRecord(_ id: String) -> ExerciseRecord {
        let found = (try? context.fetch(FetchDescriptor<ExerciseRecord>(predicate: #Predicate { $0.exerciseID == id }))) ?? []
        let map = Self.newest(found, key: \.exerciseID, date: \.updatedAt, context: context)
        if let record = map[id] {
            exerciseRecords[id] = record
            return record
        }
        let record = ExerciseRecord(exerciseID: id)
        context.insert(record)
        exerciseRecords[id] = record
        return record
    }

    func reviewRecord(_ id: String) -> ReviewRecord {
        let found = (try? context.fetch(FetchDescriptor<ReviewRecord>(predicate: #Predicate { $0.itemID == id }))) ?? []
        let map = Self.newest(found, key: \.itemID, date: \.updatedAt, context: context)
        if let record = map[id] {
            reviewRecords[id] = record
            return record
        }
        let record = ReviewRecord(itemID: id, kind: ReviewItemID.kind(of: id))
        context.insert(record)
        reviewRecords[id] = record
        return record
    }

    // MARK: Saving

    private func scheduleSave() {
        saveTask?.cancel()
        let delay = saveDelay
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.commit()
        }
    }

    /// Saves now, including any pending code. Call when the app goes to the background.
    public func flush() {
        commit()
    }

    func commit() {
        saveTask?.cancel()
        saveTask = nil
        do {
            try context.save()
            saveError = nil
        } catch {
            saveError = error
        }
    }
}
#endif
