import Contracts
import Foundation

/// A spoken summary of a static diagram for VoiceOver, one sentence per shape.
public enum ShapeDescription {
    public static func describe(_ diagram: Diagram) -> String {
        diagram.shapes.map(describe).joined(separator: " ")
    }

    public static func describe(_ shape: Shape) -> String {
        switch shape {
        case .array(let s):
            var parts = [named("Array", s.name) + ": " + values(s.values) + "."]
            for pointer in s.pointers { parts.append("\(pointer.name) at \(pointer.index).") }
            for range in s.shaded { parts.append("Shaded \(range.lower) to \(range.upper).") }
            if !s.highlighted.isEmpty { parts.append("Highlighted " + s.highlighted.map(String.init).joined(separator: ", ") + ".") }
            return parts.joined(separator: " ")
        case .grid(let s):
            let columns = s.rows.map(\.count).max() ?? 0
            var parts = [named("Grid", s.name) + ", \(s.rows.count) by \(columns)."]
            for (index, row) in s.rows.enumerated() {
                let label = s.rowLabels.flatMap { index < $0.count ? $0[index] : nil } ?? "Row \(index)"
                parts.append("\(label): " + values(row) + ".")
            }
            for cell in s.highlighted { parts.append("Highlighted \(cell.row), \(cell.column).") }
            return parts.joined(separator: " ")
        case .tree(let s):
            let labels = Dictionary(s.nodes.map { ($0.id, $0.label) }, uniquingKeysWith: { first, _ in first })
            var parts = ["Tree with \(s.nodes.count) nodes."]
            if let root = s.root, let label = labels[root] { parts.append("Root \(label).") }
            for node in s.nodes {
                let children = node.children.compactMap { $0.flatMap { labels[$0] } }
                if !children.isEmpty { parts.append("\(node.label) has " + children.joined(separator: " and ") + ".") }
            }
            return parts.joined(separator: " ")
        case .graph(let s):
            let labels = Dictionary(s.nodes.map { ($0.id, $0.label) }, uniquingKeysWith: { first, _ in first })
            let link = s.directed ? " to " : " and "
            let edges = s.edges.map { (labels[$0.from] ?? $0.from) + link + (labels[$0.to] ?? $0.to) + ($0.weight.map { ", \($0)" } ?? "") }
            return "Graph with \(s.nodes.count) nodes. Edges: " + edges.joined(separator: "; ") + "."
        case .linkedList(let s):
            return "Linked list: " + s.nodes.map(\.label).joined(separator: ", ") + "."
        case .stack(let s):
            return named("Stack", s.name) + ", bottom to top: " + values(s.items) + "."
        case .queue(let s):
            return named("Queue", s.name) + ", front to back: " + values(s.items) + "."
        case .bits(let s):
            return "Bits " + s.bits.map { $0 ? "1" : "0" }.joined() + "."
        }
    }

    private static func named(_ kind: String, _ name: String?) -> String {
        name.map { "\(kind) \($0)" } ?? kind
    }

    private static func values(_ values: [String]) -> String {
        values.isEmpty ? "empty" : values.map { $0.isEmpty ? "blank" : $0 }.joined(separator: ", ")
    }
}
