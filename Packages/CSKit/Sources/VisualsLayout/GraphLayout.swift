import Contracts
import Foundation

/// Graphs: positions from the content file when every node has them, else a layered layout
/// for directed acyclic graphs, else a circle. Laid out once from every node and edge seen in
/// the run, so nodes stay put while visited/frontier states change.
enum GraphLayout {
    static func layout(slot: String, shapes: [GraphShape?], metrics: LayoutMetrics, measurer: TextMeasurer) -> SlotLayout {
        let present = shapes.compactMap { $0 }
        guard !present.isEmpty else { return SlotLayout(size: .zero, frames: shapes.map { _ in nil }) }

        // Union of the run, in first-seen order.
        var nodes: [GraphNode] = []
        var seenNodes: Set<String> = []
        var edgePairs: [(String, String)] = []
        var seenEdges: Set<String> = []
        for shape in present {
            for node in shape.nodes where seenNodes.insert(node.id).inserted { nodes.append(node) }
            for edge in shape.edges where seenEdges.insert("\(edge.from)\u{0}\(edge.to)").inserted { edgePairs.append((edge.from, edge.to)) }
        }
        edgePairs = edgePairs.filter { seenNodes.contains($0.0) && seenNodes.contains($0.1) }
        let directed = present.contains { $0.directed }

        let nodeSize = LayoutSize(width: measurer.cellWidth(fitting: present.lazy.flatMap { $0.nodes.map(\.label) }), height: metrics.cellHeight)
        let spacing = nodeSize.width + 2 * metrics.nodeSpacing

        var centers: [String: LayoutPoint]
        if nodes.allSatisfy({ $0.x != nil && $0.y != nil }) {
            centers = given(nodes, spacing: spacing)
        } else if directed, !edgePairs.isEmpty, let layered = layered(nodes.map(\.id), edges: edgePairs, spacing: spacing, levelStep: nodeSize.height + metrics.levelSpacing) {
            centers = layered
        } else {
            centers = circular(nodes.map(\.id), spacing: spacing)
        }

        // Normalize into the slot, leaving room for weight labels.
        let hasWeights = present.contains { $0.edges.contains { $0.weight != nil } }
        let margin = metrics.cellSpacing + (hasWeights ? metrics.labelLineHeight : 0)
        let minX = centers.values.map(\.x).min() ?? 0
        let minY = centers.values.map(\.y).min() ?? 0
        let maxX = centers.values.map(\.x).max() ?? 0
        let maxY = centers.values.map(\.y).max() ?? 0
        for (id, point) in centers {
            centers[id] = LayoutPoint(
                x: (point.x - minX + margin + nodeSize.width / 2).rounded(),
                y: (point.y - minY + margin + nodeSize.height / 2).rounded()
            )
        }
        let size = LayoutSize(width: maxX - minX + nodeSize.width + 2 * margin, height: maxY - minY + nodeSize.height + 2 * margin)

        // Positioned elements without state, rebuilt only when nodes or edges change.
        struct Template {
            var nodes: [GraphNode]
            var edgeList: [GraphEdge]
            var directed: Bool
            var boxes: [BoxElement]
            /// Source node id per box.
            var boxNodes: [String]
            var edges: [EdgeElement]
            var ends: [(from: String, to: String)]
            var labels: [LabelElement]
        }
        var nodeIDs = KeyedIDs("node/")
        func makeTemplate(_ shape: GraphShape) -> Template {
            var boxes: [BoxElement] = []
            var boxNodes: [String] = []
            var seen: Set<String> = []
            for node in shape.nodes {
                guard let center = centers[node.id], seen.insert(node.id).inserted else { continue }
                boxes.append(BoxElement(id: nodeIDs(node.id), text: node.label, center: center, size: nodeSize, style: .node))
                boxNodes.append(node.id)
            }
            var edges: [EdgeElement] = []
            var ends: [(from: String, to: String)] = []
            var labels: [LabelElement] = []
            var repeats: [String: Int] = [:]
            for edge in shape.edges {
                guard let a = centers[edge.from], let b = centers[edge.to], edge.from != edge.to else { continue }
                var key = "\(edge.from)>\(edge.to)"
                let repeatCount = repeats[key, default: 0]
                repeats[key] = repeatCount + 1
                if repeatCount > 0 { key += "#\(repeatCount)" }

                let (from, to) = EdgeClipping.nodeEdge(a, nodeSize, b, nodeSize, gap: 2)
                edges.append(EdgeElement(id: "edge/" + key, from: from, to: to, role: .graph, directed: shape.directed))
                ends.append((edge.from, edge.to))

                if let weight = edge.weight {
                    // Beside the midpoint, on the left of the edge's direction.
                    let dx = b.x - a.x
                    let dy = b.y - a.y
                    let length = max((dx * dx + dy * dy).squareRoot(), 1)
                    let offset = metrics.labelLineHeight * 0.7
                    let center = LayoutPoint(x: (a.x + b.x) / 2 + dy / length * offset, y: (a.y + b.y) / 2 - dx / length * offset)
                    labels.append(LabelElement(
                        id: "weight/" + key, text: weight, center: center,
                        size: LayoutSize(width: measurer.label(weight), height: metrics.labelLineHeight), role: .weight
                    ))
                }
            }
            return Template(nodes: shape.nodes, edgeList: shape.edges, directed: shape.directed, boxes: boxes, boxNodes: boxNodes, edges: edges, ends: ends, labels: labels)
        }

        var template: Template?
        let frames = shapes.map { shape -> ShapeLayout? in
            guard let shape else { return nil }
            let current: Template
            if let template, template.nodes == shape.nodes, template.edgeList == shape.edges, template.directed == shape.directed {
                current = template
            } else {
                current = makeTemplate(shape)
                template = current
            }

            var boxes = current.boxes
            var edges = current.edges
            if !shape.visited.isEmpty || !shape.frontier.isEmpty || !shape.active.isEmpty {
                let visited = Set(shape.visited)
                let frontier = Set(shape.frontier)
                let active = Set(shape.active)
                for i in boxes.indices {
                    let id = current.boxNodes[i]
                    if visited.contains(id) { boxes[i].state.insert(.visited) }
                    if frontier.contains(id) { boxes[i].state.insert(.frontier) }
                    if active.contains(id) { boxes[i].state.insert(.active) }
                }
                for i in edges.indices {
                    let (from, to) = current.ends[i]
                    if active.contains(from) && active.contains(to) { edges[i].state.insert(.active) }
                    let fromReached = visited.contains(from) || active.contains(from)
                    let toReached = visited.contains(to) || active.contains(to)
                    if fromReached && toReached { edges[i].state.insert(.visited) }
                }
            }

            return ShapeLayout(
                id: slot, kind: .graph, frame: LayoutRect(x: 0, y: 0, width: size.width, height: size.height),
                edges: edges, boxes: boxes, labels: current.labels
            )
        }
        return SlotLayout(size: size, frames: frames)
    }

    /// Unit-space positions from the content file, scaled so the closest pair doesn't overlap.
    static func given(_ nodes: [GraphNode], spacing: Double) -> [String: LayoutPoint] {
        var closest = Double.infinity
        for i in nodes.indices {
            for j in nodes.indices where j > i {
                let dx = (nodes[i].x ?? 0) - (nodes[j].x ?? 0)
                let dy = (nodes[i].y ?? 0) - (nodes[j].y ?? 0)
                closest = min(closest, (dx * dx + dy * dy).squareRoot())
            }
        }
        let scale = closest.isFinite && closest > 0 ? min(max(spacing / closest, 240), 1000) : 240
        var centers: [String: LayoutPoint] = [:]
        for node in nodes {
            centers[node.id] = LayoutPoint(x: (node.x ?? 0) * scale, y: (node.y ?? 0) * scale)
        }
        return centers
    }

    /// Evenly around a circle, first node at the top, clockwise.
    static func circular(_ ids: [String], spacing: Double) -> [String: LayoutPoint] {
        guard ids.count > 1 else { return ids.first.map { [$0: .zero] } ?? [:] }
        let radius = max(Double(ids.count) * spacing / (2 * Double.pi), spacing * 0.75)
        var centers: [String: LayoutPoint] = [:]
        for (i, id) in ids.enumerated() {
            let angle = -Double.pi / 2 + 2 * Double.pi * Double(i) / Double(ids.count)
            centers[id] = LayoutPoint(x: radius * cos(angle), y: radius * sin(angle))
        }
        return centers
    }

    /// Layers by longest path from a source; one barycenter pass orders each layer.
    /// Returns nil when the graph has a cycle.
    static func layered(_ ids: [String], edges: [(String, String)], spacing: Double, levelStep: Double) -> [String: LayoutPoint]? {
        var successors: [String: [String]] = [:]
        var predecessors: [String: [String]] = [:]
        var indegree: [String: Int] = Dictionary(uniqueKeysWithValues: ids.map { ($0, 0) })
        for (from, to) in edges {
            successors[from, default: []].append(to)
            predecessors[to, default: []].append(from)
            indegree[to, default: 0] += 1
        }

        var layer: [String: Int] = [:]
        var ready = ids.filter { indegree[$0] == 0 }
        for id in ready { layer[id] = 0 }
        var processed = 0
        var head = 0
        while head < ready.count {
            let id = ready[head]
            head += 1
            processed += 1
            for next in successors[id] ?? [] {
                layer[next] = max(layer[next] ?? 0, (layer[id] ?? 0) + 1)
                indegree[next, default: 0] -= 1
                if indegree[next] == 0 { ready.append(next) }
            }
        }
        guard processed == ids.count else { return nil }

        let layerCount = (layer.values.max() ?? 0) + 1
        var layers = [[String]](repeating: [], count: layerCount)
        for id in ids { layers[layer[id] ?? 0].append(id) }

        var order: [String: Double] = [:]
        for (l, members) in layers.enumerated() {
            if l > 0 {
                layers[l] = members.enumerated().sorted { lhs, rhs in
                    let a = barycenter(lhs.element, predecessors, order) ?? Double(lhs.offset)
                    let b = barycenter(rhs.element, predecessors, order) ?? Double(rhs.offset)
                    return (a, lhs.offset) < (b, rhs.offset)
                }.map(\.element)
            }
            for (i, id) in layers[l].enumerated() { order[id] = Double(i) - Double(layers[l].count - 1) / 2 }
        }

        // Edges are straight, so an edge that skips layers can run through a node in between
        // (A→B over A→C→B in one column). Shift that node's layer aside, top to bottom.
        var x: [String: Double] = order.mapValues { $0 * spacing }
        for l in layers.indices.dropFirst() {
            for (from, to) in edges {
                guard let a = layer[from], let b = layer[to], a < l, l < b,
                      let x0 = x[from], let x1 = x[to] else { continue }
                let lineX = x0 + (x1 - x0) * Double(l - a) / Double(b - a)
                // A full spacing off the line leaves room for the edge's weight label.
                guard let hit = layers[l].first(where: { abs((x[$0] ?? 0) - lineX) < spacing }) else { continue }
                let distance = (x[hit] ?? 0) - lineX
                let shift = (distance >= 0 ? 1.0 : -1.0) * spacing - distance
                for id in layers[l] { x[id, default: 0] += shift }
            }
        }

        var centers: [String: LayoutPoint] = [:]
        for (l, members) in layers.enumerated() {
            for id in members {
                centers[id] = LayoutPoint(x: x[id] ?? 0, y: Double(l) * levelStep)
            }
        }
        return centers
    }

    private static func barycenter(_ id: String, _ predecessors: [String: [String]], _ order: [String: Double]) -> Double? {
        let positions = (predecessors[id] ?? []).compactMap { order[$0] }
        guard !positions.isEmpty else { return nil }
        return positions.reduce(0, +) / Double(positions.count)
    }
}
