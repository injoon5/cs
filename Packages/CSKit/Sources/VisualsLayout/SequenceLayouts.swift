import Contracts
import Foundation

/// Linked list: boxes in `next` order joined by arrows, ending in `None`, pointers above.
enum LinkedListLayout {
    static func layout(slot: String, shapes: [LinkedListShape?], metrics: LayoutMetrics, measurer: TextMeasurer) -> SlotLayout {
        let present = shapes.compactMap { $0 }
        guard !present.isEmpty else { return SlotLayout(size: .zero, frames: shapes.map { _ in nil }) }

        let cellWidth = measurer.cellWidth(fitting: present.lazy.flatMap { $0.nodes.map(\.label) })
        let cellHeight = metrics.cellHeight
        let link = metrics.linkLength
        let margin = metrics.cellSpacing
        let noneText = "None"
        let noneWidth = measurer.label(noneText)
        let maxCount = present.map(\.nodes.count).max() ?? 0

        func positions(_ shape: LinkedListShape) -> [PointerLane.Placed] {
            var index: [String: Int] = [:]
            for (i, node) in shape.nodes.enumerated() where index[node.id] == nil { index[node.id] = i }
            let pointers: [(name: String, position: Int)] = shape.pointers.keys.sorted().compactMap { name in
                guard let target = shape.pointers[name] else { return nil }
                guard let id = target else { return (name, shape.nodes.count) }
                return index[id].map { (name, $0) }
            }
            return PointerLane.place(pointers)
        }

        let lanes = present.map { positions($0).map { $0.row + 1 }.max() ?? 0 }.max() ?? 0
        let laneHeight = lanes > 0 ? Double(lanes) * metrics.pointerRowHeight + metrics.labelSpacing : 0
        let cellsTop = margin + laneHeight
        let centerY = cellsTop + cellHeight / 2
        let size = LayoutSize(
            width: 2 * margin + Double(maxCount) * (cellWidth + link) + max(noneWidth, cellWidth),
            height: cellsTop + cellHeight + margin
        )
        let cellSize = LayoutSize(width: cellWidth, height: cellHeight)
        func centerX(_ i: Int) -> Double { margin + Double(i) * (cellWidth + link) + cellWidth / 2 }

        let frames = shapes.map { shape -> ShapeLayout? in
            guard let shape else { return nil }
            var boxes: [BoxElement] = []
            var edges: [EdgeElement] = []
            var labels: [LabelElement] = []
            var seen: Set<String> = []
            let nodes = shape.nodes.filter { seen.insert($0.id).inserted }
            for (i, node) in nodes.enumerated() {
                boxes.append(BoxElement(id: "node/\(node.id)", text: node.label, center: LayoutPoint(x: centerX(i), y: centerY), size: cellSize, style: .cell))
                let next = i + 1 < nodes.count ? nodes[i + 1].id : "none"
                let endX = i + 1 < nodes.count ? centerX(i + 1) - cellWidth / 2 - 2 : centerX(i + 1) - noneWidth / 2 - 4
                edges.append(EdgeElement(
                    id: "next/\(node.id)>\(next)",
                    from: LayoutPoint(x: centerX(i) + cellWidth / 2 + 2, y: centerY),
                    to: LayoutPoint(x: endX, y: centerY),
                    role: .next, directed: true
                ))
            }
            labels.append(LabelElement(
                id: "none", text: noneText,
                center: LayoutPoint(x: centerX(nodes.count), y: centerY),
                size: LayoutSize(width: noneWidth, height: metrics.labelLineHeight), role: .terminator
            ))
            for pointer in positions(shape) {
                labels.append(PointerLane.label(slot: slot, pointer: pointer, x: centerX(pointer.position), cellsTop: cellsTop, metrics: metrics, measurer: measurer))
            }
            return ShapeLayout(
                id: slot, kind: .linkedList, frame: LayoutRect(x: 0, y: 0, width: size.width, height: size.height),
                edges: edges, boxes: boxes, labels: labels
            )
        }
        return SlotLayout(size: size, frames: frames)
    }
}

/// Stack: a column of cells, bottom item at the bottom, name underneath.
enum StackLayout {
    static func layout(slot: String, shapes: [SequenceShape?], metrics: LayoutMetrics, measurer: TextMeasurer) -> SlotLayout {
        let present = shapes.compactMap { $0 }
        guard !present.isEmpty else { return SlotLayout(size: .zero, frames: shapes.map { _ in nil }) }

        let cellWidth = measurer.cellWidth(fitting: present.lazy.flatMap(\.items))
        let cellHeight = metrics.cellHeight
        let gap = metrics.cellSpacing
        let margin = gap
        let rows = max(present.map(\.items.count).max() ?? 0, 1)
        let nameWidth = present.compactMap(\.name).map(measurer.label).max() ?? 0
        let hasName = present.contains { $0.name != nil }
        let cellsHeight = Double(rows) * cellHeight + Double(rows - 1) * gap
        let width = max(cellWidth, nameWidth) + 2 * margin
        let size = LayoutSize(
            width: width,
            height: margin + cellsHeight + (hasName ? metrics.labelSpacing + metrics.labelLineHeight : 0) + margin
        )
        let cellSize = LayoutSize(width: cellWidth, height: cellHeight)

        var matcher = CellIdentityMatcher()
        let frames = shapes.map { shape -> ShapeLayout? in
            guard let shape else { return nil }
            let ids = matcher.assign(shape.items)
            let highlighted = Set(shape.highlighted)
            var boxes: [BoxElement] = []
            for (i, item) in shape.items.enumerated() {
                let y = margin + Double(rows - 1 - i) * (cellHeight + gap) + cellHeight / 2
                boxes.append(BoxElement(
                    id: "cell/\(ids[i])", text: item, center: LayoutPoint(x: width / 2, y: y),
                    size: cellSize, style: .cell, state: highlighted.contains(i) ? .highlighted : []
                ))
            }
            var labels: [LabelElement] = []
            if let name = shape.name {
                labels.append(LabelElement(
                    id: "name", text: name,
                    center: LayoutPoint(x: width / 2, y: margin + cellsHeight + metrics.labelSpacing + metrics.labelLineHeight / 2),
                    size: LayoutSize(width: nameWidth, height: metrics.labelLineHeight), role: .name
                ))
            }
            return ShapeLayout(
                id: slot, kind: .stack, frame: LayoutRect(x: 0, y: 0, width: size.width, height: size.height),
                boxes: boxes, labels: labels
            )
        }
        return SlotLayout(size: size, frames: frames)
    }
}

/// Bits: a row of square cells, right-aligned so bit ids follow significance, grouped from
/// the least significant end.
enum BitsLayout {
    static func layout(slot: String, shapes: [BitsShape?], metrics: LayoutMetrics, measurer: TextMeasurer) -> SlotLayout {
        let present = shapes.compactMap { $0 }
        guard !present.isEmpty else { return SlotLayout(size: .zero, frames: shapes.map { _ in nil }) }

        let side = measurer.cellWidth(fitting: ["0", "1"])
        let gap = metrics.cellSpacing
        let groupGap = gap * 3
        let margin = gap
        let width = present.map(\.bits.count).max() ?? 0
        let groupSize = present.first?.groupSize ?? 8
        let groups = groupSize > 0 ? (width + groupSize - 1) / groupSize : 1
        let size = LayoutSize(
            width: 2 * margin + Double(width) * side + Double(max(width - 1, 0)) * gap + Double(max(groups - 1, 0)) * (groupGap - gap),
            height: 2 * margin + side
        )

        func centerX(_ position: Int) -> Double {
            let significance = width - 1 - position
            let breaks = groupSize > 0 ? (groups - 1) - significance / groupSize : 0
            return margin + Double(position) * (side + gap) + Double(breaks) * (groupGap - gap) + side / 2
        }

        let frames = shapes.map { shape -> ShapeLayout? in
            guard let shape else { return nil }
            let shift = width - shape.bits.count
            let highlighted = Set(shape.highlighted)
            var boxes: [BoxElement] = []
            for (i, bit) in shape.bits.enumerated() {
                let position = i + shift
                boxes.append(BoxElement(
                    id: "bit/\(width - 1 - position)", text: bit ? "1" : "0",
                    center: LayoutPoint(x: centerX(position), y: margin + side / 2),
                    size: LayoutSize(width: side, height: side), style: .bit,
                    state: highlighted.contains(i) ? .highlighted : []
                ))
            }
            return ShapeLayout(id: slot, kind: .bits, frame: LayoutRect(x: 0, y: 0, width: size.width, height: size.height), boxes: boxes)
        }
        return SlotLayout(size: size, frames: frames)
    }
}
