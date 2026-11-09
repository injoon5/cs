#if canImport(UIKit)
import SwiftUI
import VisualsLayout

/// Draws one cached scene. Views only place what layout computed: no measuring, no
/// GeometryReader. Every element is keyed by its layout id, so when the scene changes inside
/// an animation, cells and pointers move instead of being replaced.
public struct SceneView: View, Equatable {
    let scene: SceneLayout

    public init(scene: SceneLayout) {
        self.scene = scene
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(scene.shapes) { shape in
                ShapeLayerView(shape: shape)
                    .offset(x: shape.frame.x, y: shape.frame.y)
            }
        }
        .frame(width: scene.size.width, height: scene.size.height, alignment: .topLeading)
    }
}

/// One shape, drawn back to front: regions, edges, boxes, labels. Grids draw their cells in a
/// Canvas (dense, and cells never move), with highlights and arrows as views on top.
struct ShapeLayerView: View, Equatable {
    let shape: ShapeLayout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { lhs.shape == rhs.shape }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if shape.kind == .grid {
                GridCellsCanvas(boxes: shape.boxes, layer: .fills)
                regions
                GridCellsCanvas(boxes: shape.boxes, layer: .text)
                edges
            } else {
                regions
                edges
                boxes
            }
            labels
        }
        .frame(width: shape.frame.width, height: shape.frame.height, alignment: .topLeading)
    }

    // Under Reduce Motion an element that moves gets a new identity, so it crossfades from its
    // old place to its new one instead of sliding.

    private var regions: some View {
        ForEach(shape.regions, id: reduceMotion ? \.motionKey : \.id) { region in
            RegionView(role: region.role)
                .frame(width: region.rect.width, height: region.rect.height)
                .position(region.rect.center.cgPoint)
                .transition(.opacity)
        }
    }

    private var edges: some View {
        ForEach(shape.edges, id: reduceMotion ? \.motionKey : \.id) { edge in
            EdgeView(edge: edge)
                .transition(.opacity)
        }
    }

    private var boxes: some View {
        ForEach(shape.boxes, id: reduceMotion ? \.motionKey : \.id) { box in
            BoxView(text: box.text, size: box.size.cgSize, style: box.style, state: box.state)
                .position(box.center.cgPoint)
                .transition(.opacity)
        }
    }

    private var labels: some View {
        ForEach(shape.labels, id: reduceMotion ? \.motionKey : \.id) { label in
            LabelView(text: label.text, role: label.role)
                .frame(width: label.size.width, height: label.size.height, alignment: label.role == .pointer ? .bottom : .center)
                .position(label.center.cgPoint)
                .transition(.opacity)
        }
    }
}

extension BoxElement {
    var motionKey: String { "\(id)@\(Int(center.x)),\(Int(center.y))" }
}

extension LabelElement {
    var motionKey: String { "\(id)@\(Int(center.x)),\(Int(center.y))" }
}

extension EdgeElement {
    var motionKey: String { "\(id)@\(Int(from.x)),\(Int(from.y)),\(Int(to.x)),\(Int(to.y))" }
}

extension RegionElement {
    var motionKey: String { "\(id)@\(Int(rect.x)),\(Int(rect.y)),\(Int(rect.width))" }
}
#endif
