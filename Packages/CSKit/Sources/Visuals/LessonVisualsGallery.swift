#if canImport(UIKit) && DEBUG
import Contracts
import Foundation
import SwiftUI

/// Debug screen: inline traces on real recorded traces from the bundled `content/`, and lesson
/// diagrams from units 1 and 2 plus one of every other shape.
///
/// Launch arguments for screenshots:
/// - `-LessonVisualsSection diagrams` scrolls to the diagrams (or a trace id such as `prefix-sums`).
/// - `-LessonVisualsStep N` opens every trace on step N (1-based, clamped); `stop` opens each on its stop.
public struct LessonVisualsGallery: View {
    public init() {}

    private let samples = TraceSample.load()
    private let start = UserDefaults.standard.string(forKey: "LessonVisualsStep")
    private let section = UserDefaults.standard.string(forKey: "LessonVisualsSection")

    public var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    content
                }
                .onAppear {
                    if let section { proxy.scrollTo(section, anchor: .top) }
                }
            }
            .navigationTitle("Lesson visuals")
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 32) {
            if samples.isEmpty {
                ContentUnavailableView("No recorded traces", systemImage: "doc.questionmark")
            }
            ForEach(samples) { sample in
                VStack(alignment: .leading, spacing: 12) {
                    Text(sample.title).font(.headline)
                    InlineTraceView(code: sample.code, trace: sample.trace, stop: sample.stop, startAt: startIndex(for: sample))
                }
                .id(sample.id)
            }
            VStack(alignment: .leading, spacing: 24) {
                Text("Diagrams").font(.title2.bold())
                ForEach(GalleryDiagrams.all) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title).font(.headline)
                        DiagramView(diagram: item.diagram)
                    }
                    .id(item.id)
                }
            }
            .id("diagrams")
        }
        .padding()
    }

    private func startIndex(for sample: TraceSample) -> Int {
        guard let start else { return 0 }
        if start == "stop" { return (sample.stop ?? 1) - 1 }
        return (Int(start) ?? 1) - 1
    }
}

/// A ```python trace block from a bundled lesson and its recorded trace.
struct TraceSample: Identifiable {
    let id: String
    let title: String
    let code: String
    let stop: Int?
    let trace: Trace

    private static let lessons = [
        ("counting-steps", "Counting steps", "algorithms/01-complexity/01-counting-steps.md"),
        ("two-pointers", "Two pointers", "algorithms/02-arrays-and-strings/01-two-pointers.md"),
        ("prefix-sums", "Prefix sums", "algorithms/02-arrays-and-strings/03-prefix-sums.md"),
    ]

    static func load() -> [TraceSample] {
        let root = Bundle.main.bundleURL.appending(path: "content")
        return lessons.compactMap { id, title, path in
            guard let markdown = try? String(contentsOf: root.appending(path: path), encoding: .utf8),
                  let block = firstTraceBlock(markdown) else { return nil }
            let file = root.appending(path: "_recorded/\(recordedHash(block.code)).json")
            guard let data = try? Data(contentsOf: file),
                  let recorded = try? JSONDecoder().decode(Recorded.self, from: data) else { return nil }
            return TraceSample(id: id, title: title, code: block.code, stop: block.stop, trace: recorded.trace)
        } + [bubblePass]
    }

    /// A list too wide for a chip, so it draws as an array. Built the way the tracer records it.
    static let bubblePass: TraceSample = {
        let code = """
        nums = [9, 4, 7, 1, 8, 2, 6, 3, 5, 10, 12, 11]
        for i in range(len(nums) - 1):
            if nums[i] > nums[i + 1]:
                nums[i], nums[i + 1] = nums[i + 1], nums[i]
        print(nums)
        """
        var nums = [9, 4, 7, 1, 8, 2, 6, 3, 5, 10, 12, 11]
        var steps: [TraceStep] = []
        var stdout = ""
        func record(_ line: Int, i: Int?, event: TraceEvent = .line) {
            var locals = [Variable(name: "nums", value: .ref("o1"))]
            if let i { locals.append(Variable(name: "i", value: .primitive(repr: String(i), type: "int"))) }
            let heap = ["o1": HeapObject(id: "o1", type: "list", kind: .list, items: nums.map { .primitive(repr: String($0), type: "int") })]
            steps.append(TraceStep(line: line, event: event, frames: [TraceFrame(id: "f1", function: "<module>", line: line, locals: locals)], heap: heap, stdout: stdout))
        }
        steps.append(TraceStep(line: 1, event: .line, frames: [TraceFrame(id: "f1", function: "<module>", line: 1, locals: [])], heap: [:], stdout: ""))
        record(2, i: nil)
        for i in 0..<(nums.count - 1) {
            record(3, i: i)
            if nums[i] > nums[i + 1] {
                record(4, i: i)
                nums.swapAt(i, i + 1)
            }
            record(2, i: i)
        }
        record(5, i: nums.count - 2)
        stdout = "[" + nums.map(String.init).joined(separator: ", ") + "]\n"
        record(5, i: nums.count - 2, event: .return)
        return TraceSample(id: "bubble-pass", title: "One bubble pass", code: code, stop: nil, trace: Trace(steps: steps))
    }()

    private struct Recorded: Decodable {
        var trace: Trace
    }

    private static func firstTraceBlock(_ markdown: String) -> (code: String, stop: Int?)? {
        var lines = markdown.components(separatedBy: "\n")[...]
        while let line = lines.popFirst() {
            guard line.hasPrefix("```python trace") else { continue }
            let stop = line.split(separator: " ").first { $0.hasPrefix("stop=") }.flatMap { Int($0.dropFirst(5)) }
            var body: [String] = []
            while let next = lines.popFirst(), !next.hasPrefix("```") { body.append(next) }
            return (body.joined(separator: "\n"), stop)
        }
        return nil
    }

    /// FNV-1a 64 of the source with trailing whitespace trimmed (docs/contracts.md, Recorded outputs).
    private static func recordedHash(_ source: String) -> String {
        var lines = source.components(separatedBy: "\n").map { line in
            String(line.reversed().drop { $0 == " " || $0 == "\t" || $0 == "\r" }.reversed())
        }
        while lines.last?.isEmpty == true { lines.removeLast() }
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in lines.joined(separator: "\n").utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        let hex = String(hash, radix: 16)
        return String(repeating: "0", count: 16 - hex.count) + hex
    }
}

/// The diagrams in units 1 and 2 as the parser builds them, plus the shapes those units don't use.
enum GalleryDiagrams {
    struct Item: Identifiable {
        let id: String
        let title: String
        let diagram: Diagram
    }

    private static func array(_ name: String?, _ values: [String], pointers: [(String, Int)] = [], shade: ClosedRange<Int>? = nil, highlight: [Int] = []) -> Contracts.Shape {
        .array(ArrayShape(
            name: name,
            values: values,
            pointers: pointers.map { Pointer(name: $0.0, index: $0.1) },
            shaded: shade.map { [IndexRange(lower: $0.lowerBound, upper: $0.upperBound)] } ?? [],
            highlighted: highlight
        ))
    }

    private static func ints(_ values: [Int]) -> [String] { values.map(String.init) }

    static let all: [Item] = [
        Item(id: "nested-loop", title: "Counting steps", diagram: Diagram(shapes: [.grid(GridShape(
            rows: [["1", "2", "3", "4"], ["5", "6", "7", "8"], ["9", "10", "11", "12"], ["13", "14", "15", "16"]],
            rowLabels: ["i=0", "i=1", "i=2", "i=3"],
            columnLabels: ["j=0", "j=1", "j=2", "j=3"],
            highlighted: [GridCell(row: 3, column: 3)]
        ))])),
        Item(id: "triangle", title: "Counting steps, pairs", diagram: Diagram(shapes: [.grid(GridShape(
            rows: [["", "1", "2", "3"], ["", "", "4", "5"], ["", "", "", "6"], ["", "", "", ""]],
            rowLabels: ["i=0", "i=1", "i=2", "i=3"],
            columnLabels: ["j=0", "j=1", "j=2", "j=3"]
        ))])),
        Item(id: "halving", title: "Growth rates", diagram: Diagram(shapes: [
            array(nil, ints([3, 8, 12, 19, 25, 31, 40, 47]), pointers: [("lo", 4), ("hi", 7)], shade: 4...7),
        ])),
        Item(id: "linear-scan", title: "Best, worst, average", diagram: Diagram(shapes: [
            array(nil, ints([7, 2, 9, 4, 5]), pointers: [("i", 0)], highlight: [0]),
        ])),
        Item(id: "capacity", title: "Amortized append", diagram: Diagram(shapes: [
            array(nil, ["a", "b", "c", "d", "e", "", "", ""], pointers: [("size", 5)], shade: 0...4),
        ])),
        Item(id: "two-pointers", title: "Two pointers", diagram: Diagram(shapes: [
            array("nums", ints([1, 3, 4, 6, 8, 11]), pointers: [("lo", 1), ("hi", 4)], shade: 1...4),
        ])),
        Item(id: "window", title: "Sliding window", diagram: Diagram(shapes: [
            array("steps", ints([3, 1, 2, 7, 4, 2, 1, 1, 5]), pointers: [("left", 4), ("right", 7)], shade: 4...7),
        ])),
        Item(id: "prefix", title: "Prefix sums", diagram: Diagram(shapes: [
            array("nums", ints([3, -1, 4, 1, 5]), shade: 1...3),
            array("prefix", ints([0, 3, 2, 6, 7, 12]), pointers: [("l", 1), ("r+1", 4)]),
        ])),
        Item(id: "tree", title: "Tree", diagram: Diagram(shapes: [.tree(TreeShape(
            root: "8",
            nodes: [
                TreeNode(id: "8", label: "8", children: ["3", "10"]),
                TreeNode(id: "3", label: "3", children: ["1", "6"]),
                TreeNode(id: "10", label: "10", children: [nil, "14"]),
                TreeNode(id: "1", label: "1"),
                TreeNode(id: "6", label: "6"),
                TreeNode(id: "14", label: "14"),
            ],
            active: ["6"]
        ))])),
        Item(id: "graph", title: "Graph", diagram: Diagram(shapes: [.graph(GraphShape(
            directed: true,
            nodes: ["A", "B", "C", "D"].map { GraphNode(id: $0, label: $0) },
            edges: [GraphEdge(from: "A", to: "B", weight: "4"), GraphEdge(from: "A", to: "C", weight: "1"), GraphEdge(from: "C", to: "B", weight: "2"), GraphEdge(from: "B", to: "D", weight: "5")],
            visited: ["A"],
            frontier: ["B", "C"]
        ))])),
        Item(id: "linked-list", title: "Linked list", diagram: Diagram(shapes: [.linkedList(LinkedListShape(
            nodes: [TreeNode(id: "a", label: "1"), TreeNode(id: "b", label: "2"), TreeNode(id: "c", label: "3")],
            pointers: ["head": "a", "cur": "b"]
        ))])),
        Item(id: "stack-queue", title: "Stack and queue", diagram: Diagram(shapes: [
            .stack(SequenceShape(name: "stack", items: ["1", "2", "3"], highlighted: [2])),
            .queue(SequenceShape(name: "queue", items: ["a", "b", "c"])),
        ])),
        Item(id: "bits", title: "Bits", diagram: Diagram(shapes: [
            .bits(BitsShape(bits: [false, false, true, false, true, true, false, true, true, false, false, true], groupSize: 4, highlighted: [2])),
        ])),
    ]
}

#Preview {
    LessonVisualsGallery()
}
#endif
