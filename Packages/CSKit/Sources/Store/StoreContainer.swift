#if canImport(SwiftData)
import SwiftData

public enum StoreContainer {
    // Schema version 1. To change the schema later, wrap these models in a `VersionedSchema`
    // (V1 = this list), add V2 and a `SchemaMigrationPlan`. Keep CloudKit's rules: new
    // properties optional or defaulted, nothing unique. The JSON export is the safety net.
    static let models: [any PersistentModel.Type] = [LessonRecord.self, ExerciseRecord.self, ReviewRecord.self]

    public static func make(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
#endif
