import Contracts
import Foundation

/// Grids: one cell size for the whole run, row labels on the left, column labels on top,
/// highlights as separate regions so they slide between cells, dependency arrows.
enum GridLayout {
    static func layout(slot: String, shapes: [GridShape?], metrics: LayoutMetrics, measurer: TextMeasurer) -> SlotLayout {
        let present = shapes.compactMap { $0 }
        guard !present.isEmpty else { return SlotLayout(size: .zero, frames: shapes.map { _ in nil }) }

        let cellWidth = measurer.cellWidth(fitting: present.lazy.flatMap { $0.rows.joined() })
        let cellHeight = metrics.cellHeight
        let gap = metrics.cellSpacing
        let margin = gap
        let maxRows = present.map { max($0.rows.count, $0.rowLabels?.count ?? 0) }.max() ?? 0
        let maxColumns = present.map { max($0.rows.map(\.count).max() ?? 0, $0.columnLabels?.count ?? 0) }.max() ?? 0

        let rowLabelWidth = present.flatMap { $0.rowLabels ?? [] }.map(measurer.label).max() ?? 0
        let hasRowLabels = present.contains { $0.rowLabels != nil }
        let hasColumnLabels = present.contains { $0.columnLabels != nil }
        let nameWidth = present.compactMap(\.name).map(measurer.label).max() ?? 0
        let hasName = present.contains { $0.name != nil }

        let nameRow = hasName ? metrics.labelLineHeight + metrics.labelSpacing : 0
        let headerColumn = hasRowLabels ? rowLabelWidth + 2 * metrics.labelSpacing : 0
        let headerRow = hasColumnLabels ? metrics.labelLineHeight + metrics.labelSpacing : 0
        let cellsLeft = margin + headerColumn
        let cellsTop = margin + nameRow + headerRow
        let cellsWidth = Double(maxColumns) * cellWidth + Double(max(maxColumns - 1, 0)) * gap
        let cellsHeight = Double(maxRows) * cellHeight + Double(max(maxRows - 1, 0)) * gap
        let size = LayoutSize(
            width: max(cellsLeft + cellsWidth, margin + nameWidth) + margin,
            height: cellsTop + cellsHeight + margin
        )
        let cellSize = LayoutSize(width: cellWidth, height: cellHeight)

        func center(_ row: Int, _ column: Int) -> LayoutPoint {
            LayoutPoint(
                x: cellsLeft + Double(column) * (cellWidth + gap) + cellWidth / 2,
                y: cellsTop + Double(row) * (cellHeight + gap) + cellHeight / 2
            )
        }

        var cellIDs: [String] = []
        cellIDs.reserveCapacity(maxRows * maxColumns)
        for r in 0..<maxRows {
            for c in 0..<maxColumns { cellIDs.append("cell/\(r),\(c)") }
        }
        var rowIDs = IndexedIDs("row/")
        var columnIDs = IndexedIDs("column/")
        var highlightIDs = IndexedIDs("highlight/")

        let frames = shapes.map { shape -> ShapeLayout? in
            guard let shape else { return nil }
            let highlighted = Set(shape.highlighted)
            let anyHighlighted = !highlighted.isEmpty
            func contains(_ cell: GridCell) -> Bool {
                cell.row >= 0 && cell.row < shape.rows.count && cell.column >= 0 && cell.column < shape.rows[cell.row].count
            }

            var boxes: [BoxElement] = []
            boxes.reserveCapacity(shape.rows.count * (shape.rows.first?.count ?? 0))
            for (r, row) in shape.rows.enumerated() {
                for (c, value) in row.enumerated() {
                    var state: ElementState = []
                    if value.isEmpty { state.insert(.empty) }
                    if anyHighlighted && highlighted.contains(GridCell(row: r, column: c)) { state.insert(.highlighted) }
                    boxes.append(BoxElement(id: cellIDs[r * maxColumns + c], text: value, center: center(r, c), size: cellSize, style: .cell, state: state))
                }
            }

            var regions: [RegionElement] = []
            for (k, cell) in shape.highlighted.enumerated() where contains(cell) {
                regions.append(RegionElement(id: highlightIDs(k), rect: LayoutRect(center: center(cell.row, cell.column), size: cellSize), role: .highlight))
            }

            var edges: [EdgeElement] = []
            for arrow in shape.arrows where contains(arrow.from) && contains(arrow.to) && arrow.from != arrow.to {
                let a = center(arrow.from.row, arrow.from.column)
                let b = center(arrow.to.row, arrow.to.column)
                let (from, to) = dependencyEndpoints(a, b, cellSize: cellSize)
                edges.append(EdgeElement(
                    id: "arrow/\(arrow.from.row),\(arrow.from.column)>\(arrow.to.row),\(arrow.to.column)",
                    from: from, to: to, role: .dependency, directed: true
                ))
            }

            var labels: [LabelElement] = []
            if let rowLabels = shape.rowLabels {
                for (r, text) in rowLabels.enumerated() {
                    labels.append(LabelElement(
                        id: rowIDs(r), text: text,
                        center: LayoutPoint(x: margin + rowLabelWidth / 2, y: center(r, 0).y),
                        size: LayoutSize(width: rowLabelWidth, height: metrics.labelLineHeight), role: .header
                    ))
                }
            }
            if let columnLabels = shape.columnLabels {
                for (c, text) in columnLabels.enumerated() {
                    labels.append(LabelElement(
                        id: columnIDs(c), text: text,
                        center: LayoutPoint(x: center(0, c).x, y: margin + nameRow + metrics.labelLineHeight / 2),
                        size: LayoutSize(width: cellWidth, height: metrics.labelLineHeight), role: .header
                    ))
                }
            }
            if let name = shape.name {
                labels.append(LabelElement(
                    id: "name", text: name,
                    center: LayoutPoint(x: margin + nameWidth / 2, y: margin + metrics.labelLineHeight / 2),
                    size: LayoutSize(width: nameWidth, height: metrics.labelLineHeight), role: .name
                ))
            }

            return ShapeLayout(
                id: slot, kind: .grid, frame: LayoutRect(x: 0, y: 0, width: size.width, height: size.height),
                regions: regions, edges: edges, boxes: boxes, labels: labels
            )
        }
        return SlotLayout(size: size, frames: frames)
    }

    /// Arrows between cell centers, starting and ending partway inside each cell so they clear
    /// the value text and stay visible between neighbors.
    static func dependencyEndpoints(_ a: LayoutPoint, _ b: LayoutPoint, cellSize: LayoutSize) -> (LayoutPoint, LayoutPoint) {
        let inset = 0.8
        let start = EdgeClipping.rect(from: a, toward: b, halfWidth: cellSize.width / 2 * inset, halfHeight: cellSize.height / 2 * inset)
        let end = EdgeClipping.rect(from: b, toward: a, halfWidth: cellSize.width / 2 * inset, halfHeight: cellSize.height / 2 * inset)
        return (start, end)
    }
}

enum EdgeClipping {
    /// Where the ray from `center` toward `target` leaves a rectangle centered on `center`.
    static func rect(from center: LayoutPoint, toward target: LayoutPoint, halfWidth: Double, halfHeight: Double) -> LayoutPoint {
        let dx = target.x - center.x
        let dy = target.y - center.y
        guard dx != 0 || dy != 0 else { return center }
        let tx = dx == 0 ? Double.infinity : halfWidth / abs(dx)
        let ty = dy == 0 ? Double.infinity : halfHeight / abs(dy)
        let t = min(tx, ty)
        return LayoutPoint(x: center.x + dx * t, y: center.y + dy * t)
    }

    /// Where the ray from `center` toward `target` leaves a horizontal capsule (a circle when
    /// width equals height), pushed `gap` further along the ray.
    static func capsule(from center: LayoutPoint, toward target: LayoutPoint, size: LayoutSize, gap: Double = 0) -> LayoutPoint {
        let dx = target.x - center.x
        let dy = target.y - center.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0 else { return center }
        let ux = dx / length
        let uy = dy / length
        let radius = min(size.width, size.height) / 2
        let straight = max(size.width / 2 - radius, 0)

        // Distance along the ray to the flat top/bottom, if the ray hits it.
        var distance: Double
        if uy != 0, abs(ux * radius / abs(uy)) <= straight {
            distance = radius / abs(uy)
        } else {
            // The rounded end: circle centered at (±straight, 0).
            let cx = ux >= 0 ? straight : -straight
            let projection = ux * cx
            let discriminant = projection * projection - (cx * cx - radius * radius)
            distance = projection + max(discriminant, 0).squareRoot()
        }
        distance += gap
        return LayoutPoint(x: center.x + ux * distance, y: center.y + uy * distance)
    }

    /// Edge between two node outlines, with a small gap at each end.
    static func nodeEdge(_ a: LayoutPoint, _ aSize: LayoutSize, _ b: LayoutPoint, _ bSize: LayoutSize, gap: Double) -> (LayoutPoint, LayoutPoint) {
        (capsule(from: a, toward: b, size: aSize, gap: gap), capsule(from: b, toward: a, size: bSize, gap: gap))
    }
}
