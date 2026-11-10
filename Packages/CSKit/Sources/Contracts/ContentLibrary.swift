import Foundation

/// Loaded content plus where it came from, so screens can find exercises by id and read
/// recorded traces. Built by `Content.ContentLibrary.load(root:)`; the app bundles `content/`.
public struct ContentLibrary: Sendable {
    public var tracks: [Track]
    /// The content folder; `CodeBlock.recordedTrace` paths are relative to it.
    public var root: URL

    private var exercisesByID: [String: Exercise]
    private var unitsByExerciseID: [String: CourseUnit]

    public init(tracks: [Track], root: URL) {
        self.tracks = tracks
        self.root = root
        var exercises: [String: Exercise] = [:]
        var units: [String: CourseUnit] = [:]
        for unit in tracks.flatMap(\.units) {
            for exercise in unit.exercises {
                exercises[exercise.id] = exercise
                units[exercise.id] = unit
            }
        }
        exercisesByID = exercises
        unitsByExerciseID = units
    }

    public func exercise(id: String) -> Exercise? {
        exercisesByID[id]
    }

    public func unit(containingExercise id: String) -> CourseUnit? {
        unitsByExerciseID[id]
    }

    /// The bundled trace for a `python trace` block, if tools/ recorded one.
    public func recordedTrace(for block: CodeBlock) -> Trace? {
        guard let path = block.recordedTrace,
              let data = try? Data(contentsOf: root.appending(path: path)),
              let recorded = try? JSONDecoder().decode(RecordedTrace.self, from: data)
        else { return nil }
        return recorded.trace
    }

    private struct RecordedTrace: Decodable {
        var trace: Trace
    }
}
