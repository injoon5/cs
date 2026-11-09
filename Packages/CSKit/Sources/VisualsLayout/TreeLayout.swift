import Contracts
import Foundation

/// Tidy tree layout (Reingold–Tilford style): each subtree is placed as close to its left
/// sibling as their contours allow, and parents sit centered over their first and last child.
/// A `nil` child slot keeps its space, so a lone right child sits to the right.
enum TreeLayout {
    static func layout(slot: String, shapes: [TreeShape?], metrics: LayoutMetrics, measurer: TextMeasurer) -> SlotLayout {
        let present = shapes.compactMap { $0 }
        guard !present.isEmpty else { return SlotLayout(size: .zero, frames: shapes.map { _ in nil }) }

        let nodeSize = LayoutSize(width: measurer.cellWidth(fitting: present.lazy.flatMap { $0.nodes.map(\.label) }), height: metrics.cellHeight)
        let separation = nodeSize.width + metrics.nodeSpacing
        let levelStep = nodeSize.height + metrics.levelSpacing
        let margin = metrics.cellSpacing

        // Place each distinct structure once. Consecutive frames that only change active or
        // dimmed nodes (the common case while stepping) share a placement.
        var placements: [Placement] = []
        var placementForFrame: [Int?] = []
        placementForFrame.reserveCapacity(shapes.count)
        var widest = 0.0
        var deepest = 0
        for shape in shapes {
            guard let shape else {
                placementForFrame.append(nil)
                continue
            }
            if let last = placements.last, last.root == shape.root, last.nodes == shape.nodes {
                placementForFrame.append(placements.count - 1)
                continue
            }
            let placement = Placement(shape, separation: separation)
            widest = max(widest, placement.maxX - placement.minX)
            deepest = max(deepest, placement.deepest)
            placements.append(placement)
            placementForFrame.append(placements.count - 1)
        }

        let size = LayoutSize(
            width: widest + nodeSize.width + 2 * margin,
            height: Double(deepest) * levelStep + nodeSize.height + 2 * margin
        )

        // Positioned elements per placement, without state.
        var nodeIDs = KeyedIDs("node/")
        var edgeIDs = KeyedIDs("edge/")
        let templates = placements.map { placement -> (boxes: [BoxElement], nodes: [String], edges: [EdgeElement], ends: [(String, String)]) in
            // Center the tree in the run-wide slot.
            let dx = margin + nodeSize.width / 2 + (widest - (placement.maxX - placement.minX)) / 2 - placement.minX
            func point(_ id: String) -> LayoutPoint? {
                placement.positions[id].map { LayoutPoint(x: ($0.x + dx).rounded(), y: margin + nodeSize.height / 2 + Double($0.depth) * levelStep) }
            }
            var boxes: [BoxElement] = []
            var nodes: [String] = []
            boxes.reserveCapacity(placement.positions.count)
            var seen: Set<String> = []
            for node in placement.nodes {
                // Duplicate ids would break view identity; the first one wins.
                guard let center = point(node.id), seen.insert(node.id).inserted else { continue }
                boxes.append(BoxElement(id: nodeIDs(node.id), text: node.label, center: center, size: nodeSize, style: .node))
                nodes.append(node.id)
            }
            var edges: [EdgeElement] = []
            var ends: [(String, String)] = []
            for edge in placement.edges {
                guard let a = point(edge.parent), let b = point(edge.child) else { continue }
                let (from, to) = EdgeClipping.nodeEdge(a, nodeSize, b, nodeSize, gap: 2)
                edges.append(EdgeElement(id: edgeIDs("\(edge.parent)>\(edge.child)"), from: from, to: to, role: .tree, directed: false))
                ends.append((edge.parent, edge.child))
            }
            return (boxes, nodes, edges, ends)
        }

        var frames: [ShapeLayout?] = []
        frames.reserveCapacity(shapes.count)
        for (index, shape) in shapes.enumerated() {
            guard let shape, let placementIndex = placementForFrame[index] else {
                frames.append(nil)
                continue
            }
            let template = templates[placementIndex]
            var boxes = template.boxes
            var edges = template.edges
            if !shape.active.isEmpty || !shape.dimmed.isEmpty {
                let active = Set(shape.active)
                let dimmed = Set(shape.dimmed)
                for i in boxes.indices {
                    let id = template.nodes[i]
                    if active.contains(id) { boxes[i].state.insert(.active) }
                    if dimmed.contains(id) { boxes[i].state.insert(.dimmed) }
                }
                for i in edges.indices {
                    let (parent, child) = template.ends[i]
                    if active.contains(parent) && active.contains(child) { edges[i].state.insert(.active) }
                    if dimmed.contains(child) { edges[i].state.insert(.dimmed) }
                }
            }
            frames.append(ShapeLayout(
                id: slot, kind: .tree, frame: LayoutRect(x: 0, y: 0, width: size.width, height: size.height),
                edges: edges, boxes: boxes
            ))
        }
        return SlotLayout(size: size, frames: frames)
    }

    struct Placement {
        var root: String?
        var nodes: [TreeNode]
        var positions: [String: (x: Double, depth: Int)]
        var edges: [(parent: String, child: String)]
        var minX: Double
        var maxX: Double
        var deepest: Int

        init(_ shape: TreeShape, separation: Double) {
            root = shape.root
            nodes = shape.nodes
            (positions, edges) = TreeLayout.place(shape, separation: separation)
            minX = positions.values.map(\.x).min() ?? 0
            maxX = positions.values.map(\.x).max() ?? 0
            deepest = positions.values.map(\.depth).max() ?? 0
        }
    }

    /// Positions for one tree (or forest), x in points relative to the first root.
    static func place(_ shape: TreeShape, separation: Double) -> (positions: [String: (x: Double, depth: Int)], edges: [(parent: String, child: String)]) {
        var byID: [String: TreeNode] = [:]
        for node in shape.nodes where byID[node.id] == nil { byID[node.id] = node }

        // Roots: the given root, else every node nobody points at (a forest sits side by side).
        let roots: [String]
        if let root = shape.root, byID[root] != nil {
            roots = [root]
        } else if shape.root == nil {
            let children = Set(shape.nodes.flatMap { $0.children.compactMap { $0 } })
            roots = shape.nodes.map(\.id).filter { !children.contains($0) }
        } else {
            roots = []
        }
        guard !roots.isEmpty else { return ([:], []) }

        let virtualRoot = "\u{0}root"
        if roots.count > 1 { byID[virtualRoot] = TreeNode(id: virtualRoot, label: "", children: roots) }
        let top = roots.count > 1 ? virtualRoot : roots[0]

        var tidy = Tidy(byID: byID, separation: separation)
        _ = tidy.walk(top)

        // Offsets to absolute positions, breadth first.
        var positions: [String: (x: Double, depth: Int)] = [:]
        var edges: [(parent: String, child: String)] = []
        let rootDepth = roots.count > 1 ? -1 : 0
        var queue: [(id: String, x: Double, depth: Int)] = [(top, 0, rootDepth)]
        var head = 0
        while head < queue.count {
            let (id, x, depth) = queue[head]
            head += 1
            if id != virtualRoot { positions[id] = (x, depth) }
            for child in tidy.placedChildren[id] ?? [] {
                queue.append((child, x + (tidy.offsets[child] ?? 0), depth + 1))
                if id != virtualRoot { edges.append((id, child)) }
            }
        }
        return (positions, edges)
    }

    struct Tidy {
        let byID: [String: TreeNode]
        let separation: Double
        /// Child x relative to its parent.
        var offsets: [String: Double] = [:]
        /// Real children in order, after cycle and missing-id checks.
        var placedChildren: [String: [String]] = [:]
        var visited: Set<String> = []

        init(byID: [String: TreeNode], separation: Double) {
            self.byID = byID
            self.separation = separation
        }

        /// Lays out the subtree at `id`; returns its left and right contours per depth,
        /// relative to the subtree root's x.
        mutating func walk(_ id: String) -> (left: [Double], right: [Double]) {
            visited.insert(id)
            guard let node = byID[id] else { return ([0], [0]) }

            var kids: [(id: String?, left: [Double], right: [Double])] = []
            for slot in node.children {
                if let child = slot, byID[child] != nil, !visited.contains(child) {
                    let contour = walk(child)
                    kids.append((child, contour.left, contour.right))
                } else {
                    // An empty slot holds one node's width so binary shapes read correctly.
                    kids.append((nil, [0], [0]))
                }
            }
            guard kids.contains(where: { $0.id != nil }) else { return ([0], [0]) }

            var positions: [Double] = []
            var accLeft: [Double] = []
            var accRight: [Double] = []
            for (n, kid) in kids.enumerated() {
                var x = 0.0
                if n > 0 {
                    x = -Double.infinity
                    for depth in 0..<min(accRight.count, kid.left.count) {
                        x = max(x, accRight[depth] + separation - kid.left[depth])
                    }
                }
                positions.append(x)
                for depth in kid.left.indices where depth >= accLeft.count { accLeft.append(x + kid.left[depth]) }
                for depth in kid.right.indices {
                    if depth < accRight.count { accRight[depth] = x + kid.right[depth] } else { accRight.append(x + kid.right[depth]) }
                }
            }
            let mid = (positions[0] + positions[positions.count - 1]) / 2
            var children: [String] = []
            for (n, kid) in kids.enumerated() {
                guard let child = kid.id else { continue }
                offsets[child] = positions[n] - mid
                children.append(child)
            }
            placedChildren[id] = children
            return ([0] + accLeft.map { $0 - mid }, [0] + accRight.map { $0 - mid })
        }
    }
}
