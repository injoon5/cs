import Foundation
import Testing
import Contracts
@testable import Content

/// Throws-and-returns helper: the error a closure throws, or fails the test.
func contentError(_ body: () throws -> some Any, sourceLocation: SourceLocation = #_sourceLocation) -> ContentError? {
    do {
        _ = try body()
        Issue.record("expected a ContentError", sourceLocation: sourceLocation)
        return nil
    } catch let error as ContentError {
        return error
    } catch {
        Issue.record("unexpected error \(error)", sourceLocation: sourceLocation)
        return nil
    }
}

@Suite struct HashTests {
    /// Standard FNV-1a 64 vectors, plus a few block sources. tools/ must produce the same values.
    @Test(arguments: [
        ("", "cbf29ce484222325"),
        ("a", "af63dc4c8601ec8c"),
        ("b", "af63df4c8601f1a5"),
        ("foobar", "85944171f73967e8"),
        ("hello", "a430d84680aabd0b"),
        ("print(1)", "26610971178c87de"),
        ("x = 1\ny = 2", "e982f2860494bff7"),
    ])
    func vectors(source: String, expected: String) {
        #expect(RecordedHash.hash(source: source) == expected)
    }

    @Test func normalization() {
        let canonical = RecordedHash.hash(source: "x = 1\ny = 2")
        #expect(RecordedHash.hash(source: "x = 1  \ny = 2\t\n\n\n") == canonical)
        #expect(RecordedHash.hash(source: "x = 1\r\ny = 2\r\n") == canonical)
        // Leading whitespace and inner blank lines are significant.
        #expect(RecordedHash.hash(source: " x = 1\ny = 2") != canonical)
        #expect(RecordedHash.hash(source: "x = 1\n\ny = 2") != canonical)
    }

    @Test func hexIsPadded() {
        #expect(RecordedHash.hex(0xab) == "00000000000000ab")
        #expect(RecordedHash.relativePath(forHash: "00000000000000ab") == "_recorded/00000000000000ab.json")
    }
}
