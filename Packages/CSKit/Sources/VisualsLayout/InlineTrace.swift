import Contracts
import Foundation

/// What an inline trace draws at every step, computed once per trace so stepping is a lookup.
///
/// Variables are shown for the innermost frame. Each `(function, name)` pair owns a slot for the
/// whole trace, in first-appearance order, and each slot knows its widest value, so chips keep
/// their size and the chip rows never reflow while stepping.
public struct InlineTraceModel: Sendable, Hashable {
    /// The slots of one function. The view stacks every group in one place and shows the one
    /// whose frame is innermost, so the row is as tall as the tallest group for the whole trace.
    public struct Group: Sendable, Hashable, Identifiable {
        public var id: Int
        /// `<module>` for top-level code.
        public var function: String
        /// Indices into `slots`, in first-appearance order.
        public var slots: [Int]

        public var isModule: Bool { function == "<module>" }
    }

    public struct Slot: Sendable, Hashable, Identifiable {
        public var id: String
        public var group: Int
        public var name: String
        /// The longest value this slot ever shows. Values are SF Mono, so the longest string is
        /// also the widest; the chip reserves its width.
        public var widest: String
        /// Every value it holds is a list or tuple, so it can draw as an array when it's too
        /// wide for a chip.
        public var isSequence: Bool
    }

    public struct Value: Sendable, Hashable {
        public var text: String
        /// Differs from the previous step in the same function.
        public var changed: Bool
        /// List and tuple items, for the array shape.
        public var items: [String]?
    }

    public struct Step: Sendable, Hashable {
        /// 1-based line in the code.
        public var line: Int
        public var event: TraceEvent
        /// The innermost frame's group; nil when the step has no frames.
        public var group: Int?
        /// One entry per slot; nil where the slot isn't shown at this step.
        public var values: [Value?]
        /// All stdout so far.
        public var output: String
    }

    public var groups: [Group]
    public var slots: [Slot]
    public var steps: [Step]

    /// Name of the slot that shows a function's return value.
    public static let returnName = "return"

    public init(trace: Trace) {
        var groups: [Group] = []
        var groupByFunction: [String: Int] = [:]
        var slots: [Slot] = []
        var slotByKey: [String: Int] = [:]
        var steps: [Step] = []
        steps.reserveCapacity(trace.steps.count)
        var previous: (group: Int?, values: [Value?]) = (nil, [])

        for traceStep in trace.steps {
            guard let frame = traceStep.frames.last else {
                steps.append(Step(line: traceStep.line, event: traceStep.event, group: nil, values: [], output: traceStep.stdout))
                previous = (nil, [])
                continue
            }
            let group: Int
            if let existing = groupByFunction[frame.function] {
                group = existing
            } else {
                group = groups.count
                groupByFunction[frame.function] = group
                groups.append(Group(id: group, function: frame.function, slots: []))
            }

            var shown: [(name: String, value: TraceValue)] = []
            for local in frame.locals where Self.isShown(local.value, heap: traceStep.heap) {
                shown.append((local.name, local.value))
            }
            if let returnValue = frame.returnValue {
                shown.append((Self.returnName, returnValue))
            }

            var values = [Value?](repeating: nil, count: slots.count)
            for (name, value) in shown {
                let key = "\(group)/\(name)"
                let index: Int
                if let existing = slotByKey[key] {
                    index = existing
                } else {
                    index = slots.count
                    slotByKey[key] = index
                    slots.append(Slot(id: key, group: group, name: name, widest: "", isSequence: true))
                    groups[group].slots.append(index)
                    values.append(nil)
                }
                let text = TraceValueText.short(value, heap: traceStep.heap)
                let items = TraceValueText.items(value, heap: traceStep.heap)
                let before = previous.group == group && index < previous.values.count ? previous.values[index] : nil
                let changed = previous.group == group && before?.text != text
                values[index] = Value(text: text, changed: changed, items: items)
                if text.count > slots[index].widest.count { slots[index].widest = text }
                if items == nil { slots[index].isSequence = false }
            }
            steps.append(Step(line: traceStep.line, event: traceStep.event, group: group, values: values, output: traceStep.stdout))
            previous = (group, values)
        }

        // Earlier steps were built before later slots existed.
        for index in steps.indices where steps[index].values.count < slots.count {
            steps[index].values += [Value?](repeating: nil, count: slots.count - steps[index].values.count)
        }
        self.groups = groups
        self.slots = slots
        self.steps = steps
    }

    /// Array shapes for one sequence slot, one frame per step (empty where it isn't shown).
    /// Lay them out with `SceneLayoutEngine` so the slot has one size for the whole trace.
    public func arrayFrames(slot index: Int) -> [[Shape]] {
        let name = slots[index].name
        return steps.map { step in
            guard index < step.values.count, let items = step.values[index]?.items else { return [] }
            return [.array(ArrayShape(name: name, values: items))]
        }
    }

    /// Function definitions and classes are noise next to the data they work on.
    static func isShown(_ value: TraceValue, heap: [String: HeapObject]) -> Bool {
        guard case .ref(let id) = value, let object = heap[id] else { return true }
        if object.kind == .function { return false }
        if object.kind == .other && object.type == "type" { return false }
        return true
    }
}

/// Short, Python-like text for a traced value: `3`, `'hi'`, `[1, 2, 3]`, `{'a': 1}`,
/// `Node(val=1, next=Node)`. Nested containers past two levels show as `[…]`.
public enum TraceValueText {
    public static func short(_ value: TraceValue, heap: [String: HeapObject]) -> String {
        text(value, heap: heap, depth: 0)
    }

    /// Items of a list or tuple, each in short form; nil for anything else.
    public static func items(_ value: TraceValue, heap: [String: HeapObject]) -> [String]? {
        guard case .ref(let id) = value, let object = heap[id], object.kind == .list || object.kind == .tuple else { return nil }
        var items = (object.items ?? []).map { text($0, heap: heap, depth: 1) }
        if object.omitted > 0 { items.append("…") }
        return items
    }

    private static let maxDepth = 2

    private static func text(_ value: TraceValue, heap: [String: HeapObject], depth: Int) -> String {
        switch value {
        case .primitive(let repr, _):
            return repr
        case .ref(let id):
            guard let object = heap[id] else { return "…" }
            return text(object, heap: heap, depth: depth)
        }
    }

    private static func text(_ object: HeapObject, heap: [String: HeapObject], depth: Int) -> String {
        let nested = depth >= maxDepth
        let more = object.omitted > 0 ? ", …" : ""
        func list(_ values: [TraceValue]?) -> String {
            (values ?? []).map { text($0, heap: heap, depth: depth + 1) }.joined(separator: ", ")
        }
        switch object.kind {
        case .list:
            return nested ? "[…]" : "[\(list(object.items))\(more)]"
        case .tuple:
            if nested { return "(…)" }
            let single = object.items?.count == 1 && object.omitted == 0 ? "," : ""
            return "(\(list(object.items))\(single)\(more))"
        case .set:
            if (object.items ?? []).isEmpty && object.omitted == 0 { return "set()" }
            return nested ? "{…}" : "{\(list(object.items))\(more)}"
        case .dict:
            if nested { return "{…}" }
            let entries = (object.entries ?? []).map {
                "\(text($0.key, heap: heap, depth: depth + 1)): \(text($0.value, heap: heap, depth: depth + 1))"
            }
            return "{\(entries.joined(separator: ", "))\(more)}"
        case .object:
            if nested { return object.type }
            let attributes = (object.attributes ?? []).map { "\($0.name)=\(text($0.value, heap: heap, depth: depth + 1))" }
            return "\(object.type)(\(attributes.joined(separator: ", ")))"
        case .function, .other:
            return object.repr ?? object.type
        }
    }
}
