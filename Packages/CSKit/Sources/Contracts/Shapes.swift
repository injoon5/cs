import Foundation

// The shared diagram vocabulary (PLAN.md, Visuals > Shapes). Used by lesson ```diagram blocks,
// `viz` frames from Python, and shapes detected in step-through traces.
// Values are display strings; ids are only stable where the source gives them (trees, graphs, lists).
// Array cell identity across frames is assigned later by `VisualsLayout`, not here.

public enum Shape: Codable, Sendable, Hashable {
    case array(ArrayShape)
    case grid(GridShape)
    case tree(TreeShape)
    case graph(GraphShape)
    case linkedList(LinkedListShape)
    case stack(SequenceShape)
    case queue(SequenceShape)
    case bits(BitsShape)
}

/// Wire format is flat: `{"kind": "array", "values": [...], ...}`, so Python can emit it directly.
/// Non-optional fields must be present (empty lists are fine).
extension Shape {
    private enum Kind: String, Codable {
        case array, grid, tree, graph, linkedList = "linked_list", stack, queue, bits
    }

    private enum KindKey: String, CodingKey { case kind }

    public init(from decoder: Decoder) throws {
        let kind = try decoder.container(keyedBy: KindKey.self).decode(Kind.self, forKey: .kind)
        switch kind {
        case .array: self = .array(try ArrayShape(from: decoder))
        case .grid: self = .grid(try GridShape(from: decoder))
        case .tree: self = .tree(try TreeShape(from: decoder))
        case .graph: self = .graph(try GraphShape(from: decoder))
        case .linkedList: self = .linkedList(try LinkedListShape(from: decoder))
        case .stack: self = .stack(try SequenceShape(from: decoder))
        case .queue: self = .queue(try SequenceShape(from: decoder))
        case .bits: self = .bits(try BitsShape(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: KindKey.self)
        switch self {
        case .array(let s): try c.encode(Kind.array, forKey: .kind); try s.encode(to: encoder)
        case .grid(let s): try c.encode(Kind.grid, forKey: .kind); try s.encode(to: encoder)
        case .tree(let s): try c.encode(Kind.tree, forKey: .kind); try s.encode(to: encoder)
        case .graph(let s): try c.encode(Kind.graph, forKey: .kind); try s.encode(to: encoder)
        case .linkedList(let s): try c.encode(Kind.linkedList, forKey: .kind); try s.encode(to: encoder)
        case .stack(let s): try c.encode(Kind.stack, forKey: .kind); try s.encode(to: encoder)
        case .queue(let s): try c.encode(Kind.queue, forKey: .kind); try s.encode(to: encoder)
        case .bits(let s): try c.encode(Kind.bits, forKey: .kind); try s.encode(to: encoder)
        }
    }
}

public struct Pointer: Codable, Sendable, Hashable {
    public var name: String
    public var index: Int

    public init(name: String, index: Int) {
        self.name = name
        self.index = index
    }
}

/// Inclusive on both ends.
public struct IndexRange: Codable, Sendable, Hashable {
    public var lower: Int
    public var upper: Int

    public init(lower: Int, upper: Int) {
        self.lower = lower
        self.upper = upper
    }
}

public struct ArrayShape: Codable, Sendable, Hashable {
    public var name: String?
    public var values: [String]
    public var pointers: [Pointer]
    public var shaded: [IndexRange]
    public var highlighted: [Int]

    public init(name: String? = nil, values: [String], pointers: [Pointer] = [], shaded: [IndexRange] = [], highlighted: [Int] = []) {
        self.name = name
        self.values = values
        self.pointers = pointers
        self.shaded = shaded
        self.highlighted = highlighted
    }
}

public struct GridCell: Codable, Sendable, Hashable {
    public var row: Int
    public var column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

public struct GridShape: Codable, Sendable, Hashable {
    public var name: String?
    /// Row-major. Empty string draws an empty cell.
    public var rows: [[String]]
    public var rowLabels: [String]?
    public var columnLabels: [String]?
    public var highlighted: [GridCell]
    /// Dependency arrows, e.g. DP cell to the cells it reads.
    public var arrows: [GridArrow]

    public init(name: String? = nil, rows: [[String]], rowLabels: [String]? = nil, columnLabels: [String]? = nil, highlighted: [GridCell] = [], arrows: [GridArrow] = []) {
        self.name = name
        self.rows = rows
        self.rowLabels = rowLabels
        self.columnLabels = columnLabels
        self.highlighted = highlighted
        self.arrows = arrows
    }
}

public struct GridArrow: Codable, Sendable, Hashable {
    public var from: GridCell
    public var to: GridCell

    public init(from: GridCell, to: GridCell) {
        self.from = from
        self.to = to
    }
}

public struct TreeNode: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var label: String
    /// Child ids in order. `nil` keeps a slot open (a binary node with only a right child).
    public var children: [String?]

    public init(id: String, label: String, children: [String?] = []) {
        self.id = id
        self.label = label
        self.children = children
    }
}

public struct TreeShape: Codable, Sendable, Hashable {
    public var root: String?
    public var nodes: [TreeNode]
    public var active: [String]
    /// Drawn dimmed (repeated calls in a call tree).
    public var dimmed: [String]

    public init(root: String?, nodes: [TreeNode], active: [String] = [], dimmed: [String] = []) {
        self.root = root
        self.nodes = nodes
        self.active = active
        self.dimmed = dimmed
    }
}

public struct GraphNode: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var label: String
    /// Optional position in unit space (0...1) from the content file. Otherwise laid out.
    public var x: Double?
    public var y: Double?

    public init(id: String, label: String, x: Double? = nil, y: Double? = nil) {
        self.id = id
        self.label = label
        self.x = x
        self.y = y
    }
}

public struct GraphEdge: Codable, Sendable, Hashable {
    public var from: String
    public var to: String
    public var weight: String?

    public init(from: String, to: String, weight: String? = nil) {
        self.from = from
        self.to = to
        self.weight = weight
    }
}

public struct GraphShape: Codable, Sendable, Hashable {
    public var directed: Bool
    public var nodes: [GraphNode]
    public var edges: [GraphEdge]
    public var visited: [String]
    public var frontier: [String]
    public var active: [String]

    public init(directed: Bool = false, nodes: [GraphNode], edges: [GraphEdge], visited: [String] = [], frontier: [String] = [], active: [String] = []) {
        self.directed = directed
        self.nodes = nodes
        self.edges = edges
        self.visited = visited
        self.frontier = frontier
        self.active = active
    }
}

public struct LinkedListShape: Codable, Sendable, Hashable {
    /// In `next` order. Ids stay stable across frames so reversal animates.
    public var nodes: [TreeNode]
    /// Named pointers (`head`, `prev`, `cur`) by node id. `nil` points at None.
    public var pointers: [String: String?]

    public init(nodes: [TreeNode], pointers: [String: String?] = [:]) {
        self.nodes = nodes
        self.pointers = pointers
    }
}

/// Stack draws bottom to top, queue front to back.
public struct SequenceShape: Codable, Sendable, Hashable {
    public var name: String?
    public var items: [String]
    public var highlighted: [Int]

    public init(name: String? = nil, items: [String], highlighted: [Int] = []) {
        self.name = name
        self.items = items
        self.highlighted = highlighted
    }
}

public struct BitsShape: Codable, Sendable, Hashable {
    /// Most significant first.
    public var bits: [Bool]
    public var groupSize: Int
    public var highlighted: [Int]

    public init(bits: [Bool], groupSize: Int = 8, highlighted: [Int] = []) {
        self.bits = bits
        self.groupSize = groupSize
        self.highlighted = highlighted
    }
}

/// A ```diagram block in a lesson.
public struct Diagram: Codable, Sendable, Hashable {
    public var shapes: [Shape]
    /// If set, tapping runs it into a step-through.
    public var code: String?

    public init(shapes: [Shape], code: String? = nil) {
        self.shapes = shapes
        self.code = code
    }
}

/// One `viz` call.
public struct VizFrame: Codable, Sendable, Hashable {
    public var shapes: [Shape]
    /// From `viz.note("swap")`.
    public var note: String?

    public init(shapes: [Shape], note: String? = nil) {
        self.shapes = shapes
        self.note = note
    }
}

public struct VizRun: Codable, Sendable, Hashable {
    public var frames: [VizFrame]
    public var output: String
    public var result: RunResult

    public init(frames: [VizFrame], output: String, result: RunResult) {
        self.frames = frames
        self.output = output
        self.result = result
    }
}
