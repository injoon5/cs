#if canImport(SwiftData)
import Foundation
import Contracts
import Review

extension SwiftDataProgress {
    /// All progress, saved code and review state as JSON, sorted by id.
    public func exportJSON() throws -> Data {
        let export = StoreExport(
            version: StoreExport.currentVersion,
            exportedAt: clock(),
            lessons: lessonRecords.values.sorted { $0.lessonID < $1.lessonID }.map {
                .init(lessonID: $0.lessonID, progress: $0.progress, updatedAt: $0.updatedAt)
            },
            exercises: exerciseRecords.values.sorted { $0.exerciseID < $1.exerciseID }.map {
                .init(
                    exerciseID: $0.exerciseID, progress: $0.progress, lastAttemptAt: $0.lastAttemptAt,
                    lastAttemptPassed: $0.lastAttemptPassed, passedAt: $0.passedAt, updatedAt: $0.updatedAt)
            },
            reviews: reviewRecords.values.sorted { $0.itemID < $1.itemID }.map {
                .init(
                    itemID: $0.itemID, kind: $0.kind, scheduling: $0.scheduling, lastRating: $0.lastRating,
                    historyCount: $0.historyCount, introducedAt: $0.introducedAt, updatedAt: $0.updatedAt)
            })
        return try StoreCodec.encoder.encode(export)
    }

    /// Merges an export into the store. A record is replaced when the file's copy is at least
    /// as new as the stored one. Throws on malformed data or a newer file version.
    public func importJSON(_ data: Data) throws {
        let export = try StoreCodec.decoder.decode(StoreExport.self, from: data)
        guard export.version <= StoreExport.currentVersion else { throw StoreImportError.unsupportedVersion(export.version) }

        for item in export.lessons {
            let record = lessonRecord(item.lessonID)
            guard record.updatedAt <= item.updatedAt else { continue }
            record.progress = item.progress
            record.updatedAt = item.updatedAt
            lessons[item.lessonID] = item.progress
        }
        for item in export.exercises {
            let record = exerciseRecord(item.exerciseID)
            guard record.updatedAt <= item.updatedAt else { continue }
            record.progress = item.progress
            record.lastAttemptAt = item.lastAttemptAt
            record.lastAttemptPassed = item.lastAttemptPassed
            record.passedAt = item.passedAt
            record.updatedAt = item.updatedAt
            exercises[item.exerciseID] = item.progress
        }
        for item in export.reviews {
            let record = reviewRecord(item.itemID)
            guard record.updatedAt <= item.updatedAt else { continue }
            record.kindRaw = item.kind.rawValue
            record.scheduling = item.scheduling
            record.lastRatingRaw = item.lastRating?.rawValue
            record.historyCount = item.historyCount
            record.introducedAt = item.introducedAt
            record.updatedAt = item.updatedAt
        }
        commit()
    }
}

public enum StoreImportError: Error, Equatable {
    case unsupportedVersion(Int)
}
#endif
