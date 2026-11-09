#if canImport(UIKit)
import SwiftUI
import VisualsLayout

// Leaf views take small Equatable values, never the layout or the player. State changes are
// modifiers on the same view (fill, stroke, opacity), so a highlight animates instead of
// swapping views.

/// A cell or node.
struct BoxView: View, Equatable {
    let text: String
    let size: CGSize
    let style: BoxStyle
    let state: ElementState

    var body: some View {
        let outline = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Text(text)
            .font(SceneFont.value)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(textStyle)
            .contentTransition(.numericText())
            .frame(width: size.width, height: size.height)
            .background(fill, in: outline)
            .overlay {
                outline.strokeBorder(Color.accentColor, lineWidth: 1.5)
                    .opacity(hasStroke ? 1 : 0)
            }
            .opacity(opacity)
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .node: min(size.width, size.height) / 2
        case .cell, .bit: 8
        }
    }

    private var fill: Color {
        if state.contains(.active) { return .accentColor }
        if state.contains(.highlighted) { return .accentColor.opacity(0.18) }
        if state.contains(.visited) { return .accentColor.opacity(0.12) }
        if state.contains(.empty) { return Color(.quaternarySystemFill) }
        return Color(.secondarySystemFill)
    }

    private var hasStroke: Bool {
        !state.contains(.active) && (state.contains(.highlighted) || state.contains(.frontier))
    }

    private var textStyle: Color {
        if state.contains(.active) { return .white }
        if style == .bit && text == "0" { return .secondary }
        return .primary
    }

    private var opacity: Double {
        if state.contains(.outsideRange) { return 0.35 }
        if state.contains(.dimmed) { return 0.4 }
        return 1
    }
}

struct LabelView: View, Equatable {
    let text: String
    let role: LabelRole

    var body: some View {
        switch role {
        case .pointer:
            VStack(spacing: 0) {
                Text(text)
                    .font(SceneFont.label)
                    .lineLimit(1)
                    .fixedSize()
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.caption2)
                    .imageScale(.small)
            }
            .foregroundStyle(.tint)
        case .index:
            Text(text)
                .font(SceneFont.index)
                .foregroundStyle(.secondary)
        case .header, .terminator, .weight:
            Text(text)
                .font(SceneFont.secondaryLabel)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
        case .name:
            Text(text)
                .font(SceneFont.label)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
        }
    }
}

struct RegionView: View, Equatable {
    let role: RegionRole

    var body: some View {
        switch role {
        case .range:
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.accentColor.opacity(0.1))
        case .highlight:
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.accentColor.opacity(0.18))
                .strokeBorder(Color.accentColor, lineWidth: 1.5)
        }
    }
}

struct EdgeView: View, Equatable {
    let edge: EdgeElement

    var body: some View {
        EdgeShape(from: edge.from.cgPoint, to: edge.to.cgPoint, arrowhead: edge.directed)
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .opacity(edge.state.contains(.dimmed) ? 0.4 : 1)
    }

    private var color: Color {
        if edge.state.contains(.active) { return .accentColor }
        if edge.state.contains(.visited) { return .accentColor.opacity(0.5) }
        switch edge.role {
        case .dependency: return .accentColor
        case .next: return .secondary
        case .tree, .graph: return Color(.tertiaryLabel)
        }
    }
}

/// A line with an optional open arrowhead. Endpoints animate, so edges follow their nodes
/// through a spring.
struct EdgeShape: Shape {
    var from: CGPoint
    var to: CGPoint
    var arrowhead: Bool

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(from.x, from.y), AnimatablePair(to.x, to.y)) }
        set {
            from = CGPoint(x: newValue.first.first, y: newValue.first.second)
            to = CGPoint(x: newValue.second.first, y: newValue.second.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        guard arrowhead else { return path }
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = max((dx * dx + dy * dy).squareRoot(), 0.001)
        let head = min(6, length * 0.5)
        let ux = dx / length
        let uy = dy / length
        // Two strokes at ±30° back from the tip.
        let cosA = 0.866
        let sinA = 0.5
        let left = CGPoint(x: to.x - head * (ux * cosA - uy * sinA), y: to.y - head * (uy * cosA + ux * sinA))
        let right = CGPoint(x: to.x - head * (ux * cosA + uy * sinA), y: to.y - head * (uy * cosA - ux * sinA))
        path.move(to: left)
        path.addLine(to: to)
        path.addLine(to: right)
        return path
    }
}

/// Grid cells in one Canvas: up to 400 cells that never move. Fills and text are separate
/// layers so the highlight view slides between them.
struct GridCellsCanvas: View, Equatable {
    enum Layer { case fills, text }

    let boxes: [BoxElement]
    let layer: Layer

    var body: some View {
        Canvas { context, _ in
            switch layer {
            case .fills:
                let filled = Color(.secondarySystemFill)
                let empty = Color(.quaternarySystemFill)
                for box in boxes {
                    let path = Path(roundedRect: box.rect.cgRect, cornerRadius: 8, style: .continuous)
                    context.fill(path, with: .color(box.state.contains(.empty) ? empty : filled))
                }
            case .text:
                for box in boxes where !box.text.isEmpty {
                    let text = context.resolve(Text(box.text).font(SceneFont.value).monospacedDigit())
                    context.draw(text, at: box.center.cgPoint, anchor: .center)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
#endif
