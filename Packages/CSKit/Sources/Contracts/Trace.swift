import Foundation

// Step-through trace, emitted by `Resources/python/trace.py` as JSON once a run ends.
// Also bundled for lesson `python trace` blocks, recorded by tools/ at build time.
//
// {
//   "steps": [{
//     "line": 3, "event": "line",
//     "frames": [{"id": "f1", "function": "<module>", "line": 3,
//                 "locals": [{"name": "a", "value": {"ref": "140234"}}]}],
//     "heap": {"140234": {"id": "140234", "type": "list", "kind": "list",
//                         "items": [{"repr": "1", "type": "int"}], "omitted": 0}},
//     "stdout": "hello\n"
//   }],
//   "truncated": false,
//   "error": null
// }

public struct Trace: Codable, Sendable, Hashable {
    public var steps: [TraceStep]
    /// True when the 1,000 step limit was hit.
    public var truncated: Bool
    public var error: PythonError?

    public init(steps: [TraceStep], truncated: Bool = false, error: PythonError? = nil) {
        self.steps = steps
        self.truncated = truncated
        self.error = error
    }
}

public enum TraceEvent: String, Codable, Sendable, Hashable {
    case line, call, `return`, exception
}

public struct TraceStep: Codable, Sendable, Hashable {
    /// 1-based line in the user's code.
    public var line: Int
    public var event: TraceEvent
    /// Outermost first. Only frames in user code.
    public var frames: [TraceFrame]
    /// Objects reachable from the frames, keyed by Python `id()` as a string.
    public var heap: [String: HeapObject]
    /// All stdout up to and including this step.
    public var stdout: String

    public init(line: Int, event: TraceEvent, frames: [TraceFrame], heap: [String: HeapObject], stdout: String) {
        self.line = line
        self.event = event
        self.frames = frames
        self.heap = heap
        self.stdout = stdout
    }
}

public struct TraceFrame: Codable, Sendable, Hashable, Identifiable {
    /// Stable for the life of the call.
    public var id: String
    public var function: String
    public var line: Int
    /// In definition order.
    public var locals: [Variable]
    /// Set on `return` events.
    public var returnValue: TraceValue?

    public init(id: String, function: String, line: Int, locals: [Variable], returnValue: TraceValue? = nil) {
        self.id = id
        self.function = function
        self.line = line
        self.locals = locals
        self.returnValue = returnValue
    }
}

public struct Variable: Codable, Sendable, Hashable {
    public var name: String
    public var value: TraceValue

    public init(name: String, value: TraceValue) {
        self.name = name
        self.value = value
    }
}

/// A primitive shown inline (`repr` + `type`), or a reference into the heap (`ref`).
public enum TraceValue: Codable, Sendable, Hashable {
    case primitive(repr: String, type: String)
    case ref(String)

    private enum CodingKeys: String, CodingKey { case repr, type, ref }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let ref = try c.decodeIfPresent(String.self, forKey: .ref) {
            self = .ref(ref)
        } else {
            self = .primitive(repr: try c.decode(String.self, forKey: .repr), type: try c.decode(String.self, forKey: .type))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .primitive(let repr, let type):
            try c.encode(repr, forKey: .repr)
            try c.encode(type, forKey: .type)
        case .ref(let id):
            try c.encode(id, forKey: .ref)
        }
    }
}

public enum HeapKind: String, Codable, Sendable, Hashable {
    case list, tuple, set, dict, object, function, other
}

public struct HeapObject: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    /// Python type name, e.g. `list`, `Node`.
    public var type: String
    public var kind: HeapKind
    /// list, tuple, set: first 50 items.
    public var items: [TraceValue]?
    /// dict: first 50 entries.
    public var entries: [DictEntry]?
    /// object: instance attributes in definition order.
    public var attributes: [Variable]?
    /// function, other: `repr`.
    public var repr: String?
    /// Items past the first 50.
    public var omitted: Int

    public init(id: String, type: String, kind: HeapKind, items: [TraceValue]? = nil, entries: [DictEntry]? = nil, attributes: [Variable]? = nil, repr: String? = nil, omitted: Int = 0) {
        self.id = id
        self.type = type
        self.kind = kind
        self.items = items
        self.entries = entries
        self.attributes = attributes
        self.repr = repr
        self.omitted = omitted
    }
}

public struct DictEntry: Codable, Sendable, Hashable {
    public var key: TraceValue
    public var value: TraceValue

    public init(key: TraceValue, value: TraceValue) {
        self.key = key
        self.value = value
    }
}
