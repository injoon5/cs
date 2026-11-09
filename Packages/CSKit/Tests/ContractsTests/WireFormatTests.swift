import Foundation
import Testing
@testable import Contracts

// Locks the JSON shapes that Python emits. Keys are camelCase on the wire.

@Test func shapeDecodesFlatKind() throws {
    let json = #"{"kind": "array", "values": ["1", "3"], "pointers": [{"name": "i", "index": 0}], "shaded": [], "highlighted": [1]}"#
    let shape = try JSONDecoder().decode(Shape.self, from: Data(json.utf8))
    #expect(shape == .array(ArrayShape(values: ["1", "3"], pointers: [Pointer(name: "i", index: 0)], highlighted: [1])))
}

@Test func linkedListKindIsSnakeCase() throws {
    let json = #"{"kind": "linked_list", "nodes": [{"id": "a", "label": "1", "children": []}], "pointers": {"head": "a", "prev": null}}"#
    let shape = try JSONDecoder().decode(Shape.self, from: Data(json.utf8))
    guard case .linkedList(let list) = shape else {
        Issue.record("expected linked list")
        return
    }
    #expect(list.pointers["prev"] == .some(nil))
}

@Test func shapeRoundTrips() throws {
    let shapes: [Shape] = [
        .grid(GridShape(rows: [["0", "1"]], highlighted: [GridCell(row: 0, column: 1)])),
        .tree(TreeShape(root: "a", nodes: [TreeNode(id: "a", label: "5", children: [nil, "b"]), TreeNode(id: "b", label: "7")])),
        .bits(BitsShape(bits: [true, false])),
    ]
    let data = try JSONEncoder().encode(shapes)
    #expect(try JSONDecoder().decode([Shape].self, from: data) == shapes)
}

@Test func traceValueDecodesRefAndPrimitive() throws {
    let json = #"[{"repr": "3", "type": "int"}, {"ref": "140"}]"#
    let values = try JSONDecoder().decode([TraceValue].self, from: Data(json.utf8))
    #expect(values == [.primitive(repr: "3", type: "int"), .ref("140")])
}

@Test func testReportDecodesFromPython() throws {
    let json = #"""
    {"results": [{"name": "f([]) == 0", "passed": false, "input": "f([])", "expected": "0", "got": "None", "duration": 0.001}]}
    """#
    let report = try JSONDecoder().decode(TestReport.self, from: Data(json.utf8))
    #expect(report.results.count == 1)
    #expect(!report.passed)
}
