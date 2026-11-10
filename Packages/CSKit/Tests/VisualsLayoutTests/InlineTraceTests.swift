import Contracts
import Foundation
import Testing
@testable import VisualsLayout

private func int(_ value: Int) -> TraceValue { .primitive(repr: String(value), type: "int") }

private func list(_ id: String, _ values: [Int], omitted: Int = 0) -> HeapObject {
    HeapObject(id: id, type: "list", kind: .list, items: values.map(int), omitted: omitted)
}

private func step(_ line: Int, _ locals: [(String, TraceValue)], heap: [HeapObject] = [], function: String = "<module>", stdout: String = "", outer: [TraceFrame] = []) -> TraceStep {
    let frame = TraceFrame(id: function, function: function, line: line, locals: locals.map { Variable(name: $0.0, value: $0.1) })
    return TraceStep(line: line, event: .line, frames: outer + [frame], heap: Dictionary(uniqueKeysWithValues: heap.map { ($0.id, $0) }), stdout: stdout)
}

@Suite struct TraceValueTextTests {
    @Test func containers() {
        let heap: [String: HeapObject] = [
            "o1": list("o1", [1, 2, 3]),
            "o2": HeapObject(id: "o2", type: "tuple", kind: .tuple, items: [int(1)]),
            "o3": HeapObject(id: "o3", type: "set", kind: .set, items: []),
            "o4": HeapObject(id: "o4", type: "dict", kind: .dict, entries: [DictEntry(key: .primitive(repr: "'a'", type: "str"), value: .ref("o1"))]),
            "o5": list("o5", [1, 2], omitted: 48),
        ]
        #expect(TraceValueText.short(.ref("o1"), heap: heap) == "[1, 2, 3]")
        #expect(TraceValueText.short(.ref("o2"), heap: heap) == "(1,)")
        #expect(TraceValueText.short(.ref("o3"), heap: heap) == "set()")
        #expect(TraceValueText.short(.ref("o4"), heap: heap) == "{'a': [1, 2, 3]}")
        #expect(TraceValueText.short(.ref("o5"), heap: heap) == "[1, 2, …]")
        #expect(TraceValueText.items(.ref("o5"), heap: heap) == ["1", "2", "…"])
        #expect(TraceValueText.items(.ref("o4"), heap: heap) == nil)
    }

    @Test func cyclesStopAtTheDepthLimit() {
        let heap: [String: HeapObject] = [
            "o1": HeapObject(id: "o1", type: "Node", kind: .object, attributes: [Variable(name: "val", value: int(1)), Variable(name: "next", value: .ref("o1"))]),
        ]
        #expect(TraceValueText.short(.ref("o1"), heap: heap) == "Node(val=1, next=Node(val=1, next=Node))")
    }
}

@Suite struct InlineTraceModelTests {
    @Test func slotsKeepFirstAppearanceOrderAndWidestValue() {
        let trace = Trace(steps: [
            step(1, []),
            step(2, [("total", int(0))]),
            step(3, [("total", int(0)), ("x", int(3))]),
            step(2, [("total", int(3)), ("x", int(3))]),
            step(3, [("total", int(3)), ("x", int(10))]),
            step(2, [("total", int(13)), ("x", int(10))], stdout: "13\n"),
        ])
        let model = InlineTraceModel(trace: trace)
        #expect(model.slots.map(\.name) == ["total", "x"])
        #expect(model.slots.map(\.widest) == ["13", "10"])
        #expect(model.steps.allSatisfy { $0.values.count == 2 })
        #expect(model.steps[0].values == [nil, nil])
        #expect(model.steps[1].values[0] == .init(text: "0", changed: true, items: nil))
        #expect(model.steps[2].values[0]?.changed == false)
        #expect(model.steps[2].values[1]?.changed == true)
        #expect(model.steps[3].values[0]?.changed == true)
        #expect(model.steps[3].values[1]?.changed == false)
        #expect(model.steps[5].output == "13\n")
    }

    @Test func listMutationIsAChangeAndMakesArrayFrames() {
        let trace = Trace(steps: [
            step(1, []),
            step(2, [("prefix", .ref("o1"))], heap: [list("o1", [0])]),
            step(3, [("prefix", .ref("o1"))], heap: [list("o1", [0, 3])]),
        ])
        let model = InlineTraceModel(trace: trace)
        #expect(model.slots[0].isSequence)
        #expect(model.steps[2].values[0]?.changed == true)
        #expect(model.steps[2].values[0]?.text == "[0, 3]")
        let frames = model.arrayFrames(slot: 0)
        #expect(frames.count == 3)
        #expect(frames[0].isEmpty)
        #expect(frames[2] == [.array(ArrayShape(name: "prefix", values: ["0", "3"]))])

        // One size for the whole trace, so the row doesn't grow as items are appended.
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        #expect(timeline.scenes.allSatisfy { $0.size == timeline.size })
        #expect(timeline.scenes[0].shapes.isEmpty)
    }

    @Test func innermostFrameGetsItsOwnGroup() {
        let module = TraceFrame(id: "f0", function: "<module>", line: 4, locals: [Variable(name: "n", value: int(3))])
        var returning = step(2, [("n", int(2))], function: "double", outer: [module])
        returning.event = .return
        returning.frames[1].returnValue = int(4)
        let trace = Trace(steps: [
            step(4, [("n", int(3))]),
            step(2, [("n", int(2))], function: "double", outer: [module]),
            returning,
            step(5, [("n", int(3)), ("m", int(4))]),
        ])
        let model = InlineTraceModel(trace: trace)
        #expect(model.groups.map(\.function) == ["<module>", "double"])
        #expect(model.groups[1].slots.map { model.slots[$0].name } == ["n", InlineTraceModel.returnName])
        #expect(model.steps[1].group == 1)
        // Entering a call isn't a change; the module's chips just hide.
        #expect(model.steps[1].values[model.groups[1].slots[0]]?.changed == false)
        #expect(model.steps[1].values[model.groups[0].slots[0]] == nil)
        #expect(model.steps[2].values[model.groups[1].slots[1]]?.text == "4")
        #expect(model.steps[3].values[model.groups[0].slots[0]]?.changed == false)
    }

    @Test func functionsAndClassesAreHidden() {
        let trace = Trace(steps: [
            step(3, [("f", .ref("o1")), ("Node", .ref("o2")), ("x", int(1))], heap: [
                HeapObject(id: "o1", type: "function", kind: .function, repr: "f(n)"),
                HeapObject(id: "o2", type: "type", kind: .other, repr: "<class 'Node'>"),
            ]),
        ])
        #expect(InlineTraceModel(trace: trace).slots.map(\.name) == ["x"])
    }

    @Test func recordedLessonTraceDecodes() throws {
        // Two pointers, as tools/ records it: list items stay the same; lo and hi move.
        let json = """
        {"steps": [
          {"line": 1, "event": "line", "frames": [{"id": "f1", "function": "<module>", "line": 1, "locals": []}], "heap": {}, "stdout": ""},
          {"line": 2, "event": "line", "frames": [{"id": "f1", "function": "<module>", "line": 2, "locals": [{"name": "nums", "value": {"ref": "o1"}}]}],
           "heap": {"o1": {"id": "o1", "type": "list", "kind": "list", "items": [{"repr": "1", "type": "int"}, {"repr": "3", "type": "int"}], "omitted": 0}}, "stdout": ""}
        ], "truncated": false, "error": null}
        """
        let trace = try JSONDecoder().decode(Trace.self, from: Data(json.utf8))
        let model = InlineTraceModel(trace: trace)
        #expect(model.steps.map(\.line) == [1, 2])
        #expect(model.steps[1].values[0]?.text == "[1, 3]")
    }
}

@Suite struct LayeredEdgeTests {
    @Test func edgeSkippingALayerDoesNotRunThroughANode() throws {
        let edges = [("A", "B"), ("A", "C"), ("C", "B")]
        let centers = try #require(GraphLayout.layered(["A", "B", "C"], edges: edges, spacing: 40, levelStep: 50))
        let a = try #require(centers["A"]), b = try #require(centers["B"]), c = try #require(centers["C"])
        #expect(c.y > a.y && b.y > c.y)
        let lineX = a.x + (b.x - a.x) * (c.y - a.y) / (b.y - a.y)
        #expect(abs(c.x - lineX) >= 40)
    }
}

@Suite struct ShapeDescriptionTests {
    @Test func arrayWithPointersAndShade() {
        let diagram = Diagram(shapes: [.array(ArrayShape(name: "nums", values: ["1", "3", "4"], pointers: [Pointer(name: "lo", index: 0)], shaded: [IndexRange(lower: 0, upper: 1)]))])
        #expect(ShapeDescription.describe(diagram) == "Array nums: 1, 3, 4. lo at 0. Shaded 0 to 1.")
    }
}
