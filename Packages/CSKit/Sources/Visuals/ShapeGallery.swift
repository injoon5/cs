#if canImport(UIKit)
import Contracts
import SwiftUI

/// Debug screen: one player per shape, driven by hand-built runs.
/// For screenshots, launch with `-ShapeGallerySection grid` to list from that section on
/// (array, search, grid, tree, graph) and `-ShapeGalleryFrame 5` to open every player on that
/// frame (clamped).
public struct ShapeGallery: View {
    public init() {}

    private let frame = UserDefaults.standard.integer(forKey: "ShapeGalleryFrame")

    private var sections: [GallerySection] {
        let all = GallerySection.all
        guard let first = UserDefaults.standard.string(forKey: "ShapeGallerySection"),
              let index = all.firstIndex(where: { $0.id == first }) else { return all }
        return Array(all[index...])
    }

    public var body: some View {
        NavigationStack {
            List(sections) { section in
                Section(section.title) {
                    VizPlayerView(frames: section.frames, startAt: frame)
                }
            }
            .navigationTitle("Shapes")
        }
    }
}

struct GallerySection: Identifiable {
    let id: String
    let title: String
    let frames: [VizFrame]

    static let all = [
        GallerySection(id: "array", title: "Swap", frames: GalleryRuns.bubbleSort),
        GallerySection(id: "search", title: "Binary search", frames: GalleryRuns.binarySearch),
        GallerySection(id: "grid", title: "Longest common subsequence", frames: GalleryRuns.longestCommonSubsequence),
        GallerySection(id: "tree", title: "Binary search tree", frames: GalleryRuns.binarySearchTree),
        GallerySection(id: "graph", title: "Breadth-first search", frames: GalleryRuns.breadthFirstSearch),
    ]
}

/// Runs built in Swift the way `viz` would record them.
enum GalleryRuns {
    static let bubbleSort: [VizFrame] = {
        var values = [5, 2, 8, 1, 9, 3]
        var frames: [VizFrame] = []
        func frame(_ j: Int, note: String?, sortedFrom: Int) {
            frames.append(VizFrame(shapes: [.array(ArrayShape(
                name: "a",
                values: values.map(String.init),
                pointers: [Pointer(name: "j", index: j)],
                shaded: sortedFrom < values.count ? [IndexRange(lower: 0, upper: sortedFrom - 1)] : [],
                highlighted: j + 1 < values.count ? [j, j + 1] : []
            ))], note: note))
        }
        for end in stride(from: values.count - 1, to: 0, by: -1) {
            for j in 0..<end {
                frame(j, note: "Compare \(values[j]) and \(values[j + 1])", sortedFrom: end + 1)
                if values[j] > values[j + 1] {
                    values.swapAt(j, j + 1)
                    frame(j, note: "Swap", sortedFrom: end + 1)
                }
            }
        }
        frames.append(VizFrame(shapes: [.array(ArrayShape(name: "a", values: values.map(String.init)))], note: "Sorted"))
        return frames
    }()

    static let binarySearch: [VizFrame] = {
        let values = [1, 3, 5, 7, 9, 11, 13, 15]
        let target = 11
        var frames: [VizFrame] = []
        var lo = 0
        var hi = values.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            let note: String
            if values[mid] == target {
                note = "Found \(target) at \(mid)"
            } else if values[mid] < target {
                note = "\(values[mid]) < \(target), go right"
            } else {
                note = "\(values[mid]) > \(target), go left"
            }
            frames.append(VizFrame(shapes: [.array(ArrayShape(
                values: values.map(String.init),
                pointers: [Pointer(name: "lo", index: lo), Pointer(name: "mid", index: mid), Pointer(name: "hi", index: hi)],
                shaded: [IndexRange(lower: lo, upper: hi)],
                highlighted: [mid]
            ))], note: note))
            if values[mid] == target { break }
            if values[mid] < target { lo = mid + 1 } else { hi = mid - 1 }
        }
        return frames
    }()

    static let longestCommonSubsequence: [VizFrame] = {
        let a = Array("ABCBD")
        let b = Array("BDCAB")
        var dp = [[Int?]](repeating: [Int?](repeating: nil, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { dp[i][0] = 0 }
        for j in 0...b.count { dp[0][j] = 0 }
        func rows() -> [[String]] { dp.map { $0.map { $0.map(String.init) ?? "" } } }
        let rowLabels = [""] + a.map(String.init)
        let columnLabels = [""] + b.map(String.init)

        var frames = [VizFrame(shapes: [.grid(GridShape(name: "dp", rows: rows(), rowLabels: rowLabels, columnLabels: columnLabels))])]
        for i in 1...a.count {
            for j in 1...b.count {
                let here = GridCell(row: i, column: j)
                let arrows: [GridArrow]
                let note: String
                if a[i - 1] == b[j - 1] {
                    dp[i][j] = (dp[i - 1][j - 1] ?? 0) + 1
                    arrows = [GridArrow(from: here, to: GridCell(row: i - 1, column: j - 1))]
                    note = "\(a[i - 1]) matches, diagonal + 1"
                } else {
                    dp[i][j] = max(dp[i - 1][j] ?? 0, dp[i][j - 1] ?? 0)
                    arrows = [GridArrow(from: here, to: GridCell(row: i - 1, column: j)), GridArrow(from: here, to: GridCell(row: i, column: j - 1))]
                    note = "No match, best of up and left"
                }
                frames.append(VizFrame(shapes: [.grid(GridShape(
                    name: "dp", rows: rows(), rowLabels: rowLabels, columnLabels: columnLabels,
                    highlighted: [here], arrows: arrows
                ))], note: note))
            }
        }
        return frames
    }()

    static let binarySearchTree: [VizFrame] = {
        var children: [Int: [Int?]] = [:]
        var root: Int?
        var frames: [VizFrame] = []
        func shape(active: [Int]) -> Contracts.Shape {
            let ids = children.keys.sorted()
            return .tree(TreeShape(
                root: root.map { "n\($0)" },
                nodes: ids.map { key in TreeNode(id: "n\(key)", label: String(key), children: (children[key] ?? [nil, nil]).map { $0.map { "n\($0)" } }) },
                active: active.map { "n\($0)" }
            ))
        }
        for value in [8, 3, 10, 1, 6, 14, 4, 7, 13] {
            guard var current = root else {
                root = value
                children[value] = [nil, nil]
                frames.append(VizFrame(shapes: [shape(active: [value])], note: "Insert \(value) as the root"))
                continue
            }
            var path = [current]
            while true {
                let side = value < current ? 0 : 1
                if let next = children[current]?[side] ?? nil {
                    current = next
                    path.append(next)
                } else {
                    children[current]?[side] = value
                    children[value] = [nil, nil]
                    break
                }
            }
            frames.append(VizFrame(shapes: [shape(active: path + [value])], note: "Insert \(value)"))
        }
        return frames
    }()

    static let breadthFirstSearch: [VizFrame] = {
        let nodes = [
            GraphNode(id: "A", label: "A", x: 0.5, y: 0),
            GraphNode(id: "B", label: "B", x: 0.15, y: 0.4),
            GraphNode(id: "C", label: "C", x: 0.85, y: 0.4),
            GraphNode(id: "D", label: "D", x: 0, y: 0.85),
            GraphNode(id: "E", label: "E", x: 0.45, y: 0.85),
            GraphNode(id: "F", label: "F", x: 1, y: 0.85),
        ]
        let adjacency: [String: [String]] = ["A": ["B", "C"], "B": ["A", "D", "E"], "C": ["A", "E", "F"], "D": ["B"], "E": ["B", "C"], "F": ["C"]]
        var edges: [GraphEdge] = []
        for (from, tos) in adjacency.sorted(by: { $0.key < $1.key }) {
            for to in tos where from < to { edges.append(GraphEdge(from: from, to: to)) }
        }

        var frames: [VizFrame] = []
        var visited: [String] = []
        var queue = ["A"]
        var seen: Set<String> = ["A"]
        frames.append(VizFrame(shapes: [.graph(GraphShape(nodes: nodes, edges: edges, frontier: queue)), .queue(SequenceShape(name: "queue", items: queue))], note: "Start at A"))
        while !queue.isEmpty {
            let node = queue.removeFirst()
            for next in adjacency[node] ?? [] where seen.insert(next).inserted { queue.append(next) }
            frames.append(VizFrame(shapes: [
                .graph(GraphShape(nodes: nodes, edges: edges, visited: visited, frontier: queue, active: [node])),
                .queue(SequenceShape(name: "queue", items: queue)),
            ], note: "Visit \(node)"))
            visited.append(node)
        }
        frames.append(VizFrame(shapes: [.graph(GraphShape(nodes: nodes, edges: edges, visited: visited)), .queue(SequenceShape(name: "queue", items: []))], note: "Done"))
        return frames
    }()
}

#Preview {
    ShapeGallery()
}
#endif
