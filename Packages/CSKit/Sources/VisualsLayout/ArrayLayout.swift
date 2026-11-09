import Contracts
import Foundation

/// Arrays (and queues, which are arrays without indices): a row of cells, pointers above,
/// indices below, the name on the left, shaded ranges behind.
enum ArrayLayout {
    static func layout(
        slot: String,
        shapes: [ArrayShape?],
        metrics: LayoutMetrics,
        measurer: TextMeasurer,
        kind: ShapeKind = .array,
        showsIndices: Bool = true
    ) -> SlotLayout {
        let present = shapes.compactMap { $0 }
        guard !present.isEmpty else { return SlotLayout(size: .zero, frames: shapes.map { _ in nil }) }

        // Run-wide geometry.
        let cellWidth = measurer.cellWidth(fitting: present.lazy.flatMap(\.values))
        let cellHeight = metrics.cellHeight
        let gap = metrics.cellSpacing
        let margin = gap
        let maxCount = present.map(\.values.count).max() ?? 0

        var minPosition = 0
        var maxPosition = max(maxCount - 1, 0)
        var lanes = 0
        for shape in present where !shape.pointers.isEmpty {
            let placed = PointerLane.place(shape.pointers.map { ($0.name, clamp($0.index, -1, shape.values.count)) })
            for pointer in placed {
                minPosition = min(minPosition, pointer.position)
                maxPosition = max(maxPosition, pointer.position)
                lanes = max(lanes, pointer.row + 1)
            }
        }

        let nameWidth = present.compactMap(\.name).map(measurer.label).max() ?? 0
        let nameColumn = nameWidth > 0 ? nameWidth + 2 * metrics.labelSpacing : 0
        let laneHeight = lanes > 0 ? Double(lanes) * metrics.pointerRowHeight + metrics.labelSpacing : 0
        let cellsTop = margin + laneHeight
        let indexTop = cellsTop + cellHeight + metrics.labelSpacing
        let height = (showsIndices ? indexTop + metrics.labelLineHeight : cellsTop + cellHeight) + margin
        let columns = maxPosition - minPosition + 1
        let width = 2 * margin + nameColumn + Double(columns) * cellWidth + Double(columns - 1) * gap
        let size = LayoutSize(width: width, height: height)
        let cellSize = LayoutSize(width: cellWidth, height: cellHeight)
        let centerY = cellsTop + cellHeight / 2

        func centerX(_ position: Int) -> Double {
            margin + nameColumn + Double(position - minPosition) * (cellWidth + gap) + cellWidth / 2
        }

        // Per frame.
        var matcher = CellIdentityMatcher()
        var cellIDs = IndexedIDs("cell/")
        var indexIDs = IndexedIDs("index/")
        var indexTexts = IndexedIDs("")
        let frames = shapes.map { shape -> ShapeLayout? in
            guard let shape else { return nil }
            let ids = matcher.assign(shape.values)
            let count = shape.values.count

            var regions: [RegionElement] = []
            var inRange = [Bool](repeating: false, count: count)
            for (k, range) in shape.shaded.enumerated() {
                let lower = max(range.lower, 0)
                let upper = min(range.upper, count - 1)
                guard lower <= upper else { continue }
                for i in lower...upper { inRange[i] = true }
                let rect = LayoutRect(
                    x: centerX(lower) - cellWidth / 2 - gap,
                    y: cellsTop - gap,
                    width: centerX(upper) - centerX(lower) + cellWidth + 2 * gap,
                    height: cellHeight + 2 * gap
                )
                regions.append(RegionElement(id: "range/\(k)", rect: rect, role: .range))
            }
            let hasRange = !regions.isEmpty
            let highlighted = shape.highlighted

            var boxes: [BoxElement] = []
            boxes.reserveCapacity(count)
            var labels: [LabelElement] = []
            labels.reserveCapacity(count + shape.pointers.count + 1)
            for i in 0..<count {
                var state: ElementState = []
                if highlighted.contains(i) { state.insert(.highlighted) }
                if hasRange && !inRange[i] { state.insert(.outsideRange) }
                boxes.append(BoxElement(
                    id: cellIDs(ids[i]),
                    text: shape.values[i],
                    center: LayoutPoint(x: centerX(i), y: centerY),
                    size: cellSize,
                    style: .cell,
                    state: state
                ))
                if showsIndices {
                    labels.append(LabelElement(
                        id: indexIDs(i),
                        text: indexTexts(i),
                        center: LayoutPoint(x: centerX(i), y: indexTop + metrics.labelLineHeight / 2),
                        size: LayoutSize(width: cellWidth, height: metrics.labelLineHeight),
                        role: .index
                    ))
                }
            }

            for pointer in PointerLane.place(shape.pointers.map { ($0.name, clamp($0.index, -1, count)) }) {
                labels.append(PointerLane.label(
                    slot: slot, pointer: pointer, x: centerX(pointer.position), cellsTop: cellsTop,
                    metrics: metrics, measurer: measurer
                ))
            }

            if let name = shape.name {
                labels.append(LabelElement(
                    id: "name",
                    text: name,
                    center: LayoutPoint(x: margin + nameWidth / 2, y: centerY),
                    size: LayoutSize(width: nameWidth, height: metrics.labelLineHeight),
                    role: .name
                ))
            }

            return ShapeLayout(
                id: slot, kind: kind, frame: LayoutRect(x: 0, y: 0, width: size.width, height: size.height),
                regions: regions, boxes: boxes, labels: labels
            )
        }
        return SlotLayout(size: size, frames: frames)
    }
}

/// Named pointers above a row of cells. Pointers at the same position stack upward in the
/// order given; each keeps its id (by name) so it slides when its index changes.
enum PointerLane {
    struct Placed {
        var id: String
        var name: String
        var position: Int
        var row: Int
    }

    static func place(_ pointers: [(name: String, position: Int)]) -> [Placed] {
        var rows: [Int: Int] = [:]
        var seen: [String: Int] = [:]
        var placed: [Placed] = []
        placed.reserveCapacity(pointers.count)
        for pointer in pointers {
            let repeatCount = seen[pointer.name, default: 0]
            seen[pointer.name] = repeatCount + 1
            let id = repeatCount == 0 ? pointer.name : "\(pointer.name)#\(repeatCount)"
            let row = rows[pointer.position, default: 0]
            rows[pointer.position] = row + 1
            placed.append(Placed(id: id, name: pointer.name, position: pointer.position, row: row))
        }
        return placed
    }

    static func label(slot: String, pointer: Placed, x: Double, cellsTop: Double, metrics: LayoutMetrics, measurer: TextMeasurer) -> LabelElement {
        let rowHeight = metrics.pointerRowHeight
        return LabelElement(
            id: "pointer/\(pointer.id)",
            text: pointer.name,
            center: LayoutPoint(x: x, y: cellsTop - metrics.labelSpacing - (Double(pointer.row) + 0.5) * rowHeight),
            size: LayoutSize(width: max(measurer.label(pointer.name), metrics.caretHeight * 2), height: rowHeight),
            role: .pointer
        )
    }
}

func clamp(_ value: Int, _ lower: Int, _ upper: Int) -> Int {
    min(max(value, lower), upper)
}
