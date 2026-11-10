// cs-content: dumps loaded content as JSON for tools/validate_content.py.
//
//     cs-content dump <content root>
//
// Prints {"tracks": [...], "errors": [{path, line?, message}], "blocks": [{hash, lessonId, role, stop?, source}]}
// to stdout. `blocks` lists every predict and trace block with its recorded-output hash, so the
// Python side never re-implements parsing or hashing. Exits 1 when there are errors.
import Contracts
import Content
import Foundation

struct ErrorEntry: Encodable {
    var path: String
    var line: Int?
    var message: String
}

struct BlockEntry: Encodable {
    var hash: String
    var lessonId: String
    var role: String
    var stop: Int?
    var source: String
}

struct Dump: Encodable {
    var tracks: [Track]
    var errors: [ErrorEntry]
    var blocks: [BlockEntry]
}

func blocks(in tracks: [Track]) -> [BlockEntry] {
    var entries: [BlockEntry] = []
    for lesson in tracks.flatMap(\.units).flatMap(\.lessons) {
        for case .code(let code) in lesson.steps.flatMap(\.blocks) {
            let role: String
            var stop: Int?
            switch code.role {
            case .predict: role = "predict"
            case .trace(let value): role = "trace"; stop = value
            default: continue
            }
            entries.append(BlockEntry(hash: RecordedHash.hash(source: code.source), lessonId: lesson.id, role: role, stop: stop, source: code.source))
        }
    }
    return entries
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(2)
}

let arguments = CommandLine.arguments
guard arguments.count == 3, arguments[1] == "dump" else { fail("usage: cs-content dump <content root>") }

let result = ContentLoader.loadAll(root: URL(fileURLWithPath: arguments[2], isDirectory: true))
let dump = Dump(
    tracks: result.tracks,
    errors: result.errors.map { ErrorEntry(path: $0.path, line: $0.line, message: $0.message) },
    blocks: blocks(in: result.tracks)
)
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
do {
    FileHandle.standardOutput.write(try encoder.encode(dump))
    FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
    fail("encoding failed: \(error)")
}
exit(dump.errors.isEmpty ? 0 : 1)
