import Foundation

// The output of layout: every element a view draws, already positioned.
// Element coordinates are relative to their shape's `frame` origin. Element ids are unique
// within a shape and stable across frames of one run, so views key `ForEach` by them and a
// changed position animates as a move.

public enum ShapeKind: String, Sendable, Hashable {
    case array, grid, tree, graph, linkedList, stack, queue, bits
}

public struct ElementState: OptionSet, Sendable, Hashable {
    public let rawValue: UInt16
    public init(rawValue: UInt16) { self.rawValue = rawValue }

    public static let highlighted = ElementState(rawValue: 1 << 0)
    public static let active = ElementState(rawValue: 1 << 1)
    public static let visited = ElementState(rawValue: 1 << 2)
    public static let frontier = ElementState(rawValue: 1 << 3)
    public static let dimmed = ElementState(rawValue: 1 << 4)
    /// The array has a shaded range and this cell is outside it.
    public static let outsideRange = ElementState(rawValue: 1 << 5)
    /// Grid cell with an empty string.
    public static let empty = ElementState(rawValue: 1 << 6)
}

public enum BoxStyle: Sendable, Hashable {
    /// Rounded rectangle: array, grid, stack, queue, list cells.
    case cell
    /// Capsule (a circle when the label is short): tree and graph nodes.
    case node
    /// A single bit.
    case bit
}

/// A cell or node with a value.
public struct BoxElement: Sendable, Hashable, Identifiable {
    public var id: String
    public var text: String
    public var center: LayoutPoint
    public var size: LayoutSize
    public var style: BoxStyle
    public var state: ElementState

    public init(id: String, text: String, center: LayoutPoint, size: LayoutSize, style: BoxStyle, state: ElementState = []) {
        self.id = id
        self.text = text
        self.center = center
        self.size = size
        self.style = style
        self.state = state
    }

    public var rect: LayoutRect { LayoutRect(center: center, size: size) }
}

public enum LabelRole: Sendable, Hashable {
    /// Array index under a cell.
    case index
    /// Named pointer above a cell (`lo`, `head`). Its size includes the caret below the name.
    case pointer
    /// Grid row or column label.
    case header
    /// Shape name (`a`, `dp`).
    case name
    /// Edge weight.
    case weight
    /// `None` at the end of a linked list.
    case terminator
}

public struct LabelElement: Sendable, Hashable, Identifiable {
    public var id: String
    public var text: String
    public var center: LayoutPoint
    public var size: LayoutSize
    public var role: LabelRole

    public init(id: String, text: String, center: LayoutPoint, size: LayoutSize, role: LabelRole) {
        self.id = id
        self.text = text
        self.center = center
        self.size = size
        self.role = role
    }
}

public enum EdgeRole: Sendable, Hashable {
    case tree, graph, next, dependency
}

/// A line between two elements. Endpoints are already clipped to the element outlines.
public struct EdgeElement: Sendable, Hashable, Identifiable {
    public var id: String
    public var from: LayoutPoint
    public var to: LayoutPoint
    public var role: EdgeRole
    /// Draw an arrowhead at `to`.
    public var directed: Bool
    public var state: ElementState

    public init(id: String, from: LayoutPoint, to: LayoutPoint, role: EdgeRole, directed: Bool, state: ElementState = []) {
        self.id = id
        self.from = from
        self.to = to
        self.role = role
        self.directed = directed
        self.state = state
    }
}

public enum RegionRole: Sendable, Hashable {
    /// Shaded index range behind array cells.
    case range
    /// Highlighted grid cell, drawn as its own element so it can slide between cells.
    case highlight
}

public struct RegionElement: Sendable, Hashable, Identifiable {
    public var id: String
    public var rect: LayoutRect
    public var role: RegionRole

    public init(id: String, rect: LayoutRect, role: RegionRole) {
        self.id = id
        self.rect = rect
        self.role = role
    }
}

/// One shape in one frame. `frame` is the slot the shape owns for the whole run, in scene
/// coordinates; its elements are relative to `frame`'s origin.
public struct ShapeLayout: Sendable, Hashable, Identifiable {
    public var id: String
    public var kind: ShapeKind
    public var frame: LayoutRect
    /// Drawn first, back to front: regions, edges, boxes, labels.
    public var regions: [RegionElement]
    public var edges: [EdgeElement]
    public var boxes: [BoxElement]
    public var labels: [LabelElement]

    public init(id: String, kind: ShapeKind, frame: LayoutRect, regions: [RegionElement] = [], edges: [EdgeElement] = [], boxes: [BoxElement] = [], labels: [LabelElement] = []) {
        self.id = id
        self.kind = kind
        self.frame = frame
        self.regions = regions
        self.edges = edges
        self.boxes = boxes
        self.labels = labels
    }
}

/// Everything drawn for one frame.
public struct SceneLayout: Sendable, Hashable {
    /// Same for every frame of a run.
    public var size: LayoutSize
    public var shapes: [ShapeLayout]
    public var note: String?

    public init(size: LayoutSize, shapes: [ShapeLayout], note: String? = nil) {
        self.size = size
        self.shapes = shapes
        self.note = note
    }
}

/// Layouts for every frame of a run. Scrubbing is `scenes[index]`.
public struct SceneTimeline: Sendable, Hashable {
    public var size: LayoutSize
    public var scenes: [SceneLayout]

    public init(size: LayoutSize, scenes: [SceneLayout]) {
        self.size = size
        self.scenes = scenes
    }

    public static let empty = SceneTimeline(size: .zero, scenes: [])

    public var isEmpty: Bool { scenes.isEmpty }
}
