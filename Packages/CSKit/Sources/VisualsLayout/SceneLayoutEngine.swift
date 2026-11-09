import Contracts
import Foundation

/// Turns a run of frames into cached layouts. Pure and synchronous: call it off the main actor
/// once per run, then index into `SceneTimeline.scenes` while playing or scrubbing.
///
/// Each shape owns a slot for the whole run. Slots are matched across frames by kind and order
/// (the second array in a frame is always the same slot), sized to the largest thing they hold
/// in any frame, and stacked vertically, centered. Nothing reflows between frames.
public enum SceneLayoutEngine {
    public static func layout(_ frames: [[Shape]], notes: [String?] = [], metrics: LayoutMetrics) -> SceneTimeline {
        let measurer = TextMeasurer(metrics)
        let slots = collectSlots(frames)

        var laidOut: [(id: String, layout: SlotLayout)] = []
        laidOut.reserveCapacity(slots.count)
        for slot in slots {
            let layout: SlotLayout
            switch slot.kind {
            case .array:
                layout = ArrayLayout.layout(slot: slot.id, shapes: slot.shapes.map { if case .array(let s)? = $0 { s } else { nil } }, metrics: metrics, measurer: measurer)
            case .queue:
                layout = ArrayLayout.layout(slot: slot.id, shapes: slot.shapes.map { if case .queue(let s)? = $0 { ArrayShape(name: s.name, values: s.items, highlighted: s.highlighted) } else { nil } }, metrics: metrics, measurer: measurer, kind: .queue, showsIndices: false)
            case .grid:
                layout = GridLayout.layout(slot: slot.id, shapes: slot.shapes.map { if case .grid(let s)? = $0 { s } else { nil } }, metrics: metrics, measurer: measurer)
            case .tree:
                layout = TreeLayout.layout(slot: slot.id, shapes: slot.shapes.map { if case .tree(let s)? = $0 { s } else { nil } }, metrics: metrics, measurer: measurer)
            case .graph:
                layout = GraphLayout.layout(slot: slot.id, shapes: slot.shapes.map { if case .graph(let s)? = $0 { s } else { nil } }, metrics: metrics, measurer: measurer)
            case .linkedList:
                layout = LinkedListLayout.layout(slot: slot.id, shapes: slot.shapes.map { if case .linkedList(let s)? = $0 { s } else { nil } }, metrics: metrics, measurer: measurer)
            case .stack:
                layout = StackLayout.layout(slot: slot.id, shapes: slot.shapes.map { if case .stack(let s)? = $0 { s } else { nil } }, metrics: metrics, measurer: measurer)
            case .bits:
                layout = BitsLayout.layout(slot: slot.id, shapes: slot.shapes.map { if case .bits(let s)? = $0 { s } else { nil } }, metrics: metrics, measurer: measurer)
            }
            laidOut.append((slot.id, layout))
        }

        // Stack slots vertically, centered on the widest.
        let width = laidOut.map(\.layout.size.width).max() ?? 0
        var offsets: [(dx: Double, dy: Double)] = []
        var y = 0.0
        for (index, slot) in laidOut.enumerated() {
            if index > 0 { y += metrics.shapeSpacing }
            offsets.append(((width - slot.layout.size.width) / 2, y))
            y += slot.layout.size.height
        }
        let size = LayoutSize(width: width.rounded(.up), height: y.rounded(.up))

        var scenes: [SceneLayout] = []
        scenes.reserveCapacity(frames.count)
        for frameIndex in frames.indices {
            var shapes: [ShapeLayout] = []
            for (slotIndex, slot) in laidOut.enumerated() {
                guard var shape = slot.layout.frames[frameIndex] else { continue }
                shape.frame.x = offsets[slotIndex].dx.rounded()
                shape.frame.y = offsets[slotIndex].dy
                shapes.append(shape)
            }
            let note = frameIndex < notes.count ? notes[frameIndex] : nil
            scenes.append(SceneLayout(size: size, shapes: shapes, note: note))
        }
        return SceneTimeline(size: size, scenes: scenes)
    }

    /// `viz` frames with their notes.
    public static func layout(_ frames: [VizFrame], metrics: LayoutMetrics) -> SceneTimeline {
        layout(frames.map(\.shapes), notes: frames.map(\.note), metrics: metrics)
    }

    /// A static lesson diagram: one frame.
    public static func layout(_ diagram: Diagram, metrics: LayoutMetrics) -> SceneLayout {
        layout([diagram.shapes], metrics: metrics).scenes.first ?? SceneLayout(size: .zero, shapes: [])
    }

    // MARK: Slots

    struct Slot {
        var id: String
        var kind: ShapeKind
        /// One entry per frame; nil where the frame has no shape in this slot.
        var shapes: [Shape?]
    }

    static func collectSlots(_ frames: [[Shape]]) -> [Slot] {
        var slots: [Slot] = []
        var indexByKey: [String: Int] = [:]
        for (frameIndex, frame) in frames.enumerated() {
            var ordinals: [ShapeKind: Int] = [:]
            for shape in frame {
                let kind = shape.kind
                let ordinal = ordinals[kind, default: 0]
                ordinals[kind] = ordinal + 1
                let key = "\(kind.rawValue)\(ordinal)"
                let slotIndex: Int
                if let existing = indexByKey[key] {
                    slotIndex = existing
                } else {
                    slotIndex = slots.count
                    indexByKey[key] = slotIndex
                    slots.append(Slot(id: key, kind: kind, shapes: Array(repeating: nil, count: frames.count)))
                }
                slots[slotIndex].shapes[frameIndex] = shape
            }
        }
        return slots
    }
}

/// One slot's layouts for the whole run, in slot-local coordinates.
struct SlotLayout {
    var size: LayoutSize
    var frames: [ShapeLayout?]
}

extension Shape {
    var kind: ShapeKind {
        switch self {
        case .array: .array
        case .grid: .grid
        case .tree: .tree
        case .graph: .graph
        case .linkedList: .linkedList
        case .stack: .stack
        case .queue: .queue
        case .bits: .bits
        }
    }
}
