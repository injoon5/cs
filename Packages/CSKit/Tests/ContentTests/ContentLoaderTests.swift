import Foundation
import Testing
import Contracts
@testable import Content

/// A throwaway content folder built from `[relative path: text]`.
private struct Fixture {
    let root: URL

    init(_ files: [String: String]) throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("content-tests-\(UUID().uuidString)", isDirectory: true)
        for (path, text) in files {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
        if files.isEmpty { try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }
    }

    func cleanup() { try? FileManager.default.removeItem(at: root) }
}

private func unitFile(id: String, title: String = "Unit", requires: [String] = []) -> String {
    "---\nid: \(id)\ntitle: \(title)\nrequires: [\(requires.joined(separator: ", "))]\n---\n"
}

private let simpleLesson = "---\nid: l\ntitle: L\n---\n\nHello.\n"

@Suite struct ContentLoaderTests {
    @Test func loadsPlanLayout() throws {
        let predictHash = RecordedHash.hash(source: "print([1, 2, 3][1:])")
        let fixture = try Fixture([
            "algorithms/08-binary-search/unit.md": unitFile(id: "binary-search", title: "Binary search", requires: ["arrays"]),
            "algorithms/08-binary-search/01-halving.md": planLesson,
            "algorithms/08-binary-search/02-on-answers.md": "---\nid: on-answers\ntitle: On answers\n---\n\nText.\n",
            "algorithms/08-binary-search/notes.md": "not a lesson, no frontmatter",
            "algorithms/08-binary-search/exercises/first-true.md": planExercise,
            "algorithms/08-binary-search/cards.md": "## What does `lo` mean?\nThe first true index.\n",
            "algorithms/02-arrays/unit.md": unitFile(id: "arrays", title: "Arrays"),
            "algorithms/02-arrays/01-intro.md": simpleLesson,
            "_recorded/\(predictHash).json": #"{"output": "[2, 3]\n"}"#,
            "_recorded/readme.txt": "ignored",
        ])
        defer { fixture.cleanup() }

        let tracks = try ContentLoader.load(root: fixture.root)
        #expect(tracks.map(\.id) == ["algorithms"])
        #expect(tracks[0].title == "Algorithms")
        #expect(tracks[0].units.map(\.id) == ["arrays", "binary-search"])

        let unit = tracks[0].units[1]
        #expect(unit.title == "Binary search")
        #expect(unit.requires == ["arrays"])
        #expect(unit.lessons.map(\.id) == ["halving", "on-answers"])
        #expect(unit.exercises.map(\.id) == ["first-true"])
        #expect(unit.cards.map(\.id) == ["binary-search/what-does-lo-mean"])

        let steps = unit.lessons[0].steps
        #expect(steps.last?.blocks == [.exercise(id: "first-true")])
        guard case .code(let predict) = steps[2].blocks[0] else {
            Issue.record("expected predict block")
            return
        }
        #expect(predict.recordedOutput == "[2, 3]\n")
    }

    @Test func tracksOrderAndTitles() throws {
        let fixture = try Fixture([
            "zeta/track.md": "---\nid: z\ntitle: Zeta Track\norder: 1\n---\n",
            "zeta/01-a/unit.md": unitFile(id: "za"),
            "alpha/01-a/unit.md": unitFile(id: "aa"),
            "linux/track.md": "---\norder: 0\n---\n",
            "cs-foundations/01-a/unit.md": unitFile(id: "ca"),
            "mid/track.md": "---\ntitle: Mid\norder: 1\n---\n",
            ".hidden/01-a/unit.md": unitFile(id: "hidden"),
        ])
        defer { fixture.cleanup() }

        let tracks = try ContentLoader.load(root: fixture.root)
        // order 0, then order 1 by folder name (mid, zeta), then unordered by name.
        #expect(tracks.map(\.id) == ["linux", "mid", "z", "alpha", "cs-foundations"])
        #expect(tracks.map(\.title) == ["Linux", "Mid", "Zeta Track", "Alpha", "Cs Foundations"])
    }

    @Test func lessonsSortByFilename() throws {
        let lesson = { (id: String) in "---\nid: \(id)\ntitle: \(id)\n---\n\nx\n" }
        let fixture = try Fixture([
            "t/01-u/unit.md": unitFile(id: "u"),
            "t/01-u/10-last.md": lesson("last"),
            "t/01-u/02-second.md": lesson("second"),
            "t/01-u/01-first.md": lesson("first"),
        ])
        defer { fixture.cleanup() }
        let unit = try #require(try ContentLoader.load(root: fixture.root).first?.units.first)
        #expect(unit.lessons.map(\.id) == ["first", "second", "last"])
    }

    @Test func traceRecordingIsLinked() throws {
        let hash = RecordedHash.hash(source: "x = 1")
        let fixture = try Fixture([
            "t/01-u/unit.md": unitFile(id: "u"),
            "t/01-u/01-a.md": "---\nid: a\ntitle: A\n---\n\n```python trace\nx = 1\n```\n",
            "_recorded/\(hash).json": #"{"trace": {"steps": []}}"#,
        ])
        defer { fixture.cleanup() }
        let lesson = try #require(try ContentLoader.load(root: fixture.root).first?.units.first?.lessons.first)
        guard case .code(let trace) = lesson.steps[0].blocks[0] else {
            Issue.record("expected trace block")
            return
        }
        #expect(trace.recordedTrace == "_recorded/\(hash).json")
    }

    @Test func linkToMissingExerciseFails() throws {
        let fixture = try Fixture([
            "t/01-u/unit.md": unitFile(id: "u"),
            "t/01-u/01-a.md": planLesson,
        ])
        defer { fixture.cleanup() }
        let error = try #require(contentError { try ContentLoader.load(root: fixture.root) })
        #expect(error.path == "t/01-u/01-a.md")
        #expect(error.message.contains("exercises/first-true.md"))
        #expect(error.line != nil)
    }

    @Test func reportsAllErrors() throws {
        let fixture = try Fixture([
            "t/01-u/unit.md": unitFile(id: "u", requires: ["nope"]),
            "t/01-u/01-a.md": "no frontmatter",
            "t/01-u/exercises/broken.md": "---\nid: b\ntitle: B\nlevel: core\n---\nno blocks",
            "t/01-u/02-b.md": "---\nid: b\ntitle: B\n---\n\n[Go](exercises/broken.md)\n",
            "t/02-empty/readme.md": "no unit.md here",
        ])
        defer { fixture.cleanup() }
        let result = ContentLoader.loadAll(root: fixture.root)
        let paths = result.errors.map(\.path)
        #expect(paths.contains("t/01-u/01-a.md"))
        #expect(paths.contains("t/01-u/exercises/broken.md"))
        #expect(paths.contains("t/01-u/unit.md"))
        #expect(paths.contains("t/02-empty/unit.md"))
        // The link to a broken exercise doesn't add a second error.
        #expect(!paths.contains("t/01-u/02-b.md"))
        #expect(result.errors.count == 4)
    }

    @Test func duplicateIDs() throws {
        let fixture = try Fixture([
            "t/01-a/unit.md": unitFile(id: "same"),
            "t/02-b/unit.md": unitFile(id: "same"),
        ])
        defer { fixture.cleanup() }
        let error = try #require(contentError { try ContentLoader.load(root: fixture.root) })
        #expect(error.message.contains("already used"))
    }

    @Test func missingRootFails() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("nope-\(UUID().uuidString)")
        #expect(contentError { try ContentLoader.load(root: missing) }?.message.contains("not found") == true)
    }

    @Test func emptyRootIsNoTracks() throws {
        let fixture = try Fixture([:])
        defer { fixture.cleanup() }
        #expect(try ContentLoader.load(root: fixture.root).isEmpty)
    }

    @Test func unitFrontmatterErrors() throws {
        let fixture = try Fixture(["t/01-u/unit.md": "---\nid: u\n---\n"])
        defer { fixture.cleanup() }
        let error = try #require(contentError { try ContentLoader.load(root: fixture.root) })
        #expect(error.path == "t/01-u/unit.md")
        #expect(error.message.contains("title"))
    }
}
