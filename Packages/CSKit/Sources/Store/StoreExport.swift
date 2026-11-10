import Foundation
import Contracts
import Review

/// Everything the Store keeps, as plain Codable values. Dates are ISO 8601.
public struct StoreExport: Codable, Sendable, Hashable {
    public static let currentVersion = 1

    public struct Lesson: Codable, Sendable, Hashable {
        public var lessonID: String
        public var progress: LessonProgress
        public var updatedAt: Date
    }

    public struct Exercise: Codable, Sendable, Hashable {
        public var exerciseID: String
        public var progress: ExerciseProgress
        public var lastAttemptAt: Date?
        public var lastAttemptPassed: Bool?
        public var passedAt: Date?
        public var updatedAt: Date
    }

    public struct Review: Codable, Sendable, Hashable {
        public var itemID: String
        public var kind: ReviewItemKind
        public var scheduling: SchedulingCard?
        public var lastRating: Rating?
        public var historyCount: Int
        public var introducedAt: Date?
        public var updatedAt: Date
    }

    public var version: Int
    public var exportedAt: Date
    public var lessons: [Lesson]
    public var exercises: [Exercise]
    public var reviews: [Review]
}
