import Contracts
import Foundation
import Testing
@testable import VisualsLayout

let metrics = LayoutMetrics.monospaced()

func cells(_ scene: SceneLayout, slot: Int = 0) -> [BoxElement] {
    scene.shapes[slot].boxes
}

// MARK: Cell identity

@Suite struct CellIdentityTests {
    @Test func swapIsTwoMoves() {
        var matcher = CellIdentityMatcher()
        let first = matcher.assign(["5", "2", "8"])
        let second = matcher.assign(["2", "5", "8"])
        #expect(second == [first[1], first[0], first[2]])
    }

    @Test func duplicatesMatchNearestIndex() {
        var matcher = CellIdentityMatcher()
        let first = matcher.assign(["1", "1", "2", "1"])
        // The 2 moves to the end; the 1s shift left by at most one place each.
        let second = matcher.assign(["1", "1", "1", "2"])
        #expect(second[0] == first[0])
        #expect(second[1] == first[1])
        #expect(second[2] == first[3])
        #expect(second[3] == first[2])
    }

    @Test func newValuesGetFreshIDs() {
        var matcher = CellIdentityMatcher()
        let first = matcher.assign(["1", "2"])
        let second = matcher.assign(["1", "9", "2"])
        #expect(second[0] == first[0])
        #expect(second[2] == first[1])
        #expect(!first.contains(second[1]))
        let third = matcher.assign(["4"])
        #expect(!(first + second).contains(third[0]))
    }

    @Test func idsAreUniqueWithinAFrame() {
        var matcher = CellIdentityMatcher()
        var values = (0..<20).map { String($0 % 4) }
        for step in 0..<50 {
            values.swapAt(step % 20, (step * 7) % 20)
            if step % 5 == 0 { values.append(String(step)) }
            let ids = matcher.assign(values)
            #expect(Set(ids).count == ids.count)
        }
    }

    @Test func swapMovesCellsInLayout() throws {
        let frames: [[Shape]] = [
            [.array(ArrayShape(values: ["5", "2", "8"]))],
            [.array(ArrayShape(values: ["2", "5", "8"]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        let before = cells(timeline.scenes[0])
        let after = cells(timeline.scenes[1])
        #expect(Set(before.map(\.id)) == Set(after.map(\.id)))
        let five = try #require(before.first { $0.text == "5" })
        let fiveAfter = try #require(after.first { $0.id == five.id })
        #expect(fiveAfter.text == "5")
        #expect(fiveAfter.center.x > five.center.x)
        #expect(fiveAfter.center.y == five.center.y)
    }
}

// MARK: Arrays

@Suite struct ArrayLayoutTests {
    @Test func cellWidthIsFixedAcrossTheRun() throws {
        let frames: [[Shape]] = [
            [.array(ArrayShape(values: ["1", "2"]))],
            [.array(ArrayShape(values: ["1", "123456"]))],
            [.array(ArrayShape(values: ["1"]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        let widths = Set(timeline.scenes.flatMap { $0.shapes.flatMap(\.boxes) }.map(\.size.width))
        #expect(widths.count == 1)
        let width = try #require(widths.first)
        #expect(width >= metrics.measureValue("123456") + 2 * metrics.cellPadding)
        // Index 0 stays put and the scene never resizes.
        let firstX = Set(timeline.scenes.map { $0.shapes[0].boxes[0].center.x })
        #expect(firstX.count == 1)
        #expect(Set(timeline.scenes.map(\.size)).count == 1)
        #expect(Set(timeline.scenes.map { $0.shapes[0].frame }).count == 1)
    }

    @Test func shortValuesMakeSquareCells() {
        let scene = SceneLayoutEngine.layout([[.array(ArrayShape(values: ["1", "2"]))]], metrics: metrics).scenes[0]
        for box in scene.shapes[0].boxes {
            #expect(box.size.width == box.size.height)
        }
    }

    @Test func pointersSlideAndStack() throws {
        let frames: [[Shape]] = [
            [.array(ArrayShape(values: ["1", "3", "5", "7"], pointers: [Pointer(name: "lo", index: 0), Pointer(name: "hi", index: 3)]))],
            [.array(ArrayShape(values: ["1", "3", "5", "7"], pointers: [Pointer(name: "lo", index: 2), Pointer(name: "hi", index: 2)]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        let first = timeline.scenes[0].shapes[0]
        let second = timeline.scenes[1].shapes[0]
        let lo0 = try #require(first.labels.first { $0.id.hasSuffix("pointer/lo") })
        let lo1 = try #require(second.labels.first { $0.id.hasSuffix("pointer/lo") })
        let hi1 = try #require(second.labels.first { $0.id.hasSuffix("pointer/hi") })
        #expect(lo1.center.x > lo0.center.x)
        #expect(lo1.center.x == hi1.center.x)
        #expect(hi1.center.y < lo1.center.y)
        // The lane is sized for two rows in every frame, so cells don't move.
        #expect(first.boxes[0].center.y == second.boxes[0].center.y)
        #expect(lo0.center.y + lo0.size.height / 2 <= first.boxes[0].rect.minY)
    }

    @Test func pointerPastTheEndGetsASlot() throws {
        let scene = SceneLayoutEngine.layout([[.array(ArrayShape(values: ["1", "2"], pointers: [Pointer(name: "i", index: 2), Pointer(name: "j", index: -1)]))]], metrics: metrics).scenes[0]
        let shape = scene.shapes[0]
        let i = try #require(shape.labels.first { $0.id.hasSuffix("pointer/i") })
        let j = try #require(shape.labels.first { $0.id.hasSuffix("pointer/j") })
        #expect(i.center.x > shape.boxes[1].center.x)
        #expect(j.center.x < shape.boxes[0].center.x)
        #expect(j.center.x - j.size.width / 2 >= 0)
        #expect(i.center.x + i.size.width / 2 <= shape.frame.maxX)
    }

    @Test func shadedRangeDimsCellsOutside() {
        let scene = SceneLayoutEngine.layout([[.array(ArrayShape(values: ["1", "2", "3", "4"], shaded: [IndexRange(lower: 1, upper: 2)], highlighted: [2]))]], metrics: metrics).scenes[0]
        let shape = scene.shapes[0]
        #expect(shape.regions.count == 1)
        #expect(shape.boxes.map { $0.state.contains(.outsideRange) } == [true, false, false, true])
        #expect(shape.boxes[2].state.contains(.highlighted))
        let region = shape.regions[0].rect
        #expect(region.minX < shape.boxes[1].rect.minX)
        #expect(region.maxX > shape.boxes[2].rect.maxX)
    }

    @Test func emptyAndOutOfRangeInputsDontCrash() {
        let frames: [[Shape]] = [
            [.array(ArrayShape(values: [], pointers: [Pointer(name: "i", index: 5)], shaded: [IndexRange(lower: 3, upper: 1)], highlighted: [9]))],
            [.grid(GridShape(rows: [], highlighted: [GridCell(row: 2, column: 2)], arrows: [GridArrow(from: GridCell(row: 0, column: 0), to: GridCell(row: 1, column: 1))]))],
            [.tree(TreeShape(root: "missing", nodes: []))],
            [.graph(GraphShape(nodes: [], edges: [GraphEdge(from: "a", to: "b")]))],
            [.linkedList(LinkedListShape(nodes: [], pointers: ["head": nil]))],
            [.stack(SequenceShape(items: [])), .queue(SequenceShape(items: [])), .bits(BitsShape(bits: [], groupSize: 0))],
            [],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        #expect(timeline.scenes.count == frames.count)
        #expect(SceneLayoutEngine.layout([], metrics: metrics).isEmpty)
    }

    @Test func slotsKeepTheirPlaceWhenAShapeIsMissing() {
        let frames: [[Shape]] = [
            [.array(ArrayShape(values: ["1"])), .array(ArrayShape(values: ["2"]))],
            [.array(ArrayShape(values: ["1"]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        #expect(timeline.scenes[0].shapes[0].frame == timeline.scenes[1].shapes[0].frame)
        #expect(timeline.scenes[1].shapes.count == 1)
        #expect(timeline.scenes[0].shapes[1].frame.minY > timeline.scenes[0].shapes[0].frame.maxY)
    }

    @Test func notesFollowFrames() {
        let frames = [VizFrame(shapes: [.array(ArrayShape(values: ["1"]))], note: "swap"), VizFrame(shapes: [.array(ArrayShape(values: ["1"]))])]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        #expect(timeline.scenes.map(\.note) == ["swap", nil])
    }
}

// MARK: Grids

@Suite struct GridLayoutTests {
    @Test func cellsLabelsHighlightsAndArrows() throws {
        let grid = GridShape(
            name: "dp",
            rows: [["0", "0", "0"], ["0", "1", ""], ["0", "1", "2"]],
            rowLabels: ["", "a", "b"],
            columnLabels: ["", "x", "y"],
            highlighted: [GridCell(row: 2, column: 2)],
            arrows: [GridArrow(from: GridCell(row: 2, column: 2), to: GridCell(row: 1, column: 1)), GridArrow(from: GridCell(row: 9, column: 9), to: GridCell(row: 0, column: 0))]
        )
        let shape = SceneLayoutEngine.layout([[.grid(grid)]], metrics: metrics).scenes[0].shapes[0]
        #expect(shape.boxes.count == 9)
        #expect(shape.regions.count == 1)
        #expect(shape.edges.count == 1)
        #expect(shape.labels.filter { $0.role == .header }.count == 6)
        let empty = try #require(shape.boxes.first { $0.id.hasSuffix("cell/1,2") })
        #expect(empty.state.contains(.empty))
        let target = try #require(shape.boxes.first { $0.id.hasSuffix("cell/2,2") })
        #expect(target.state.contains(.highlighted))
        #expect(shape.regions[0].rect == target.rect)

        // Rows go down, columns go right, aligned.
        let a = try #require(shape.boxes.first { $0.id.hasSuffix("cell/0,0") })
        let b = try #require(shape.boxes.first { $0.id.hasSuffix("cell/0,1") })
        let c = try #require(shape.boxes.first { $0.id.hasSuffix("cell/1,0") })
        #expect(b.center.x > a.center.x && b.center.y == a.center.y)
        #expect(c.center.y > a.center.y && c.center.x == a.center.x)

        // The arrow starts inside the source cell and ends inside the target, pointing up-left.
        let arrow = shape.edges[0]
        #expect(arrow.from.x < target.rect.maxX && arrow.from.x > target.rect.minX)
        #expect(arrow.to.x < arrow.from.x && arrow.to.y < arrow.from.y)
        #expect(arrow.from.distance(to: arrow.to) > metrics.cellSpacing * 2)

        // Labels sit outside the cells.
        for label in shape.labels {
            let rect = LayoutRect(center: label.center, size: label.size)
            #expect(!shape.boxes.contains { $0.rect.intersects(rect) })
        }
    }

    @Test func highlightKeepsItsIDAsItMoves() {
        let rows = [["1", "2"], ["3", "4"]]
        let frames: [[Shape]] = [
            [.grid(GridShape(rows: rows, highlighted: [GridCell(row: 0, column: 0)]))],
            [.grid(GridShape(rows: rows, highlighted: [GridCell(row: 1, column: 1)]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        let first = timeline.scenes[0].shapes[0].regions[0]
        let second = timeline.scenes[1].shapes[0].regions[0]
        #expect(first.id == second.id)
        #expect(first.rect != second.rect)
    }

    @Test func cellWidthIsFixedAcrossTheRun() {
        let frames: [[Shape]] = [
            [.grid(GridShape(rows: [["", ""], ["", ""]]))],
            [.grid(GridShape(rows: [["1", ""], ["", ""]]))],
            [.grid(GridShape(rows: [["1", "1000"], ["", ""]]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        let widths = Set(timeline.scenes.flatMap { $0.shapes[0].boxes.map(\.size.width) })
        #expect(widths.count == 1)
        #expect(Set(timeline.scenes.map { $0.shapes[0].boxes.map(\.center) }).count == 1)
    }
}

// MARK: Trees

func completeBinaryTree(nodes count: Int) -> TreeShape {
    let nodes = (0..<count).map { i in
        TreeNode(id: "n\(i)", label: String(i), children: [2 * i + 1, 2 * i + 2].map { $0 < count ? "n\($0)" : nil })
    }
    return TreeShape(root: "n0", nodes: nodes)
}

func assertNoOverlaps(_ boxes: [BoxElement], sourceLocation: SourceLocation = #_sourceLocation) {
    for i in boxes.indices {
        for j in boxes.indices where j > i {
            #expect(!boxes[i].rect.intersects(boxes[j].rect), "\(boxes[i].id) overlaps \(boxes[j].id)", sourceLocation: sourceLocation)
        }
    }
}

@Suite struct TreeLayoutTests {
    @Test func sixtyThreeNodesDontOverlap() {
        let shape = SceneLayoutEngine.layout([[.tree(completeBinaryTree(nodes: 63))]], metrics: metrics).scenes[0].shapes[0]
        #expect(shape.boxes.count == 63)
        #expect(shape.edges.count == 62)
        assertNoOverlaps(shape.boxes)
        // Every box inside the slot.
        for box in shape.boxes {
            #expect(box.rect.minX >= 0 && box.rect.maxX <= shape.frame.maxX + 0.5)
            #expect(box.rect.minY >= 0 && box.rect.maxY <= shape.frame.maxY)
        }
    }

    @Test func parentsAreCenteredAboveChildren() throws {
        let shape = SceneLayoutEngine.layout([[.tree(completeBinaryTree(nodes: 15))]], metrics: metrics).scenes[0].shapes[0]
        let byID = Dictionary(uniqueKeysWithValues: shape.boxes.map { ($0.id, $0) })
        for i in 0..<7 {
            let parent = try #require(byID["node/n\(i)"])
            let left = try #require(byID["node/n\(2 * i + 1)"])
            let right = try #require(byID["node/n\(2 * i + 2)"])
            #expect(abs(parent.center.x - (left.center.x + right.center.x) / 2) <= 1)
            #expect(left.center.y > parent.center.y && left.center.y == right.center.y)
        }
    }

    @Test func nilSlotsKeepSides() throws {
        let tree = TreeShape(root: "a", nodes: [
            TreeNode(id: "a", label: "8", children: [nil, "b"]),
            TreeNode(id: "b", label: "10", children: ["c", nil]),
            TreeNode(id: "c", label: "9"),
        ])
        let shape = SceneLayoutEngine.layout([[.tree(tree)]], metrics: metrics).scenes[0].shapes[0]
        let byID = Dictionary(uniqueKeysWithValues: shape.boxes.map { ($0.id, $0) })
        let a = try #require(byID["node/a"])
        let b = try #require(byID["node/b"])
        let c = try #require(byID["node/c"])
        #expect(b.center.x > a.center.x)
        #expect(c.center.x < b.center.x)
    }

    @Test func randomTreesDontOverlap() {
        var generator = SeededGenerator(seed: 7)
        for _ in 0..<100 {
            // Random binary search trees and random n-ary trees.
            var nodes: [String: TreeNode] = [:]
            var order: [String] = []
            let count = Int.random(in: 1...63, using: &generator)
            nodes["r"] = TreeNode(id: "r", label: "r", children: [])
            order.append("r")
            for k in 1..<count {
                let parentID = order.randomElement(using: &generator) ?? "r"
                guard var parent = nodes[parentID] else { continue }
                let id = "x\(k)"
                if Bool.random(using: &generator) {
                    // Binary with possible nil slot.
                    if parent.children.isEmpty { parent.children = [nil, nil] }
                    if let slot = parent.children.firstIndex(where: { $0 == nil }) { parent.children[slot] = id } else { continue }
                } else if parent.children.count < 4 {
                    parent.children.append(id)
                } else {
                    continue
                }
                nodes[parentID] = parent
                nodes[id] = TreeNode(id: id, label: String(Int.random(in: 0...999, using: &generator)), children: [])
                order.append(id)
            }
            let shape = SceneLayoutEngine.layout([[.tree(TreeShape(root: "r", nodes: order.compactMap { nodes[$0] }))]], metrics: metrics).scenes[0].shapes[0]
            #expect(shape.boxes.count == order.count)
            assertNoOverlaps(shape.boxes)
        }
    }

    @Test func forestAndCycles() {
        let tree = TreeShape(root: nil, nodes: [
            TreeNode(id: "a", label: "a", children: ["b"]),
            TreeNode(id: "b", label: "b", children: ["a"]),
            TreeNode(id: "c", label: "c", children: ["d"]),
            TreeNode(id: "d", label: "d"),
            TreeNode(id: "e", label: "e", children: ["d"]),
        ])
        let shape = SceneLayoutEngine.layout([[.tree(tree)]], metrics: metrics).scenes[0].shapes[0]
        // a/b form a cycle with no root, so only c and e's trees show; d is drawn once.
        #expect(Set(shape.boxes.map(\.text)) == ["c", "d", "e"])
        assertNoOverlaps(shape.boxes)
    }

    @Test func treeSlotFitsTheLargestFrame() {
        let frames: [[Shape]] = [
            [.tree(completeBinaryTree(nodes: 1))],
            [.tree(completeBinaryTree(nodes: 31))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        #expect(timeline.scenes[0].shapes[0].frame == timeline.scenes[1].shapes[0].frame)
        let single = timeline.scenes[0].shapes[0].boxes[0]
        #expect(abs(single.center.x - timeline.size.width / 2) <= 1)
    }
}

// MARK: Graphs, lists, stacks, queues, bits

@Suite struct OtherShapeTests {
    @Test func givenPositionsKeepTheirArrangement() throws {
        let graph = GraphShape(nodes: [
            GraphNode(id: "a", label: "A", x: 0, y: 0),
            GraphNode(id: "b", label: "B", x: 1, y: 0),
            GraphNode(id: "c", label: "C", x: 0.5, y: 1),
        ], edges: [GraphEdge(from: "a", to: "b", weight: "4")])
        let shape = SceneLayoutEngine.layout([[.graph(graph)]], metrics: metrics).scenes[0].shapes[0]
        let byID = Dictionary(uniqueKeysWithValues: shape.boxes.map { ($0.id, $0) })
        let a = try #require(byID["node/a"])
        let b = try #require(byID["node/b"])
        let c = try #require(byID["node/c"])
        #expect(a.center.y == b.center.y && b.center.x > a.center.x)
        #expect(c.center.y > a.center.y)
        #expect(shape.labels.count == 1)
        assertNoOverlaps(shape.boxes)
    }

    @Test func circularAndLayered() throws {
        let ids = (0..<30).map { "v\($0)" }
        let ring = GraphShape(nodes: ids.map { GraphNode(id: $0, label: $0) }, edges: zip(ids, ids.dropFirst() + ["v0"]).map { GraphEdge(from: $0, to: $1) })
        let ringShape = SceneLayoutEngine.layout([[.graph(ring)]], metrics: metrics).scenes[0].shapes[0]
        #expect(ringShape.boxes.count == 30)
        assertNoOverlaps(ringShape.boxes)

        let dag = GraphShape(directed: true, nodes: ["a", "b", "c", "d"].map { GraphNode(id: $0, label: $0) }, edges: [
            GraphEdge(from: "a", to: "b"), GraphEdge(from: "a", to: "c"), GraphEdge(from: "b", to: "d"), GraphEdge(from: "c", to: "d"),
        ])
        let dagShape = SceneLayoutEngine.layout([[.graph(dag)]], metrics: metrics).scenes[0].shapes[0]
        let y = Dictionary(uniqueKeysWithValues: dagShape.boxes.map { ($0.text, $0.center.y) })
        #expect(y["a"]! < y["b"]! && y["b"] == y["c"] && y["c"]! < y["d"]!)
        #expect(dagShape.edges.allSatisfy { $0.directed })
        assertNoOverlaps(dagShape.boxes)
    }

    @Test func graphNodesStayPutAcrossFrames() {
        let nodes = ["a", "b", "c"].map { GraphNode(id: $0, label: $0) }
        let edges = [GraphEdge(from: "a", to: "b"), GraphEdge(from: "b", to: "c")]
        let frames: [[Shape]] = [
            [.graph(GraphShape(nodes: nodes, edges: edges, frontier: ["a"]))],
            [.graph(GraphShape(nodes: nodes, edges: edges, visited: ["a"], frontier: ["b"]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        #expect(timeline.scenes[0].shapes[0].boxes.map(\.center) == timeline.scenes[1].shapes[0].boxes.map(\.center))
        #expect(timeline.scenes[1].shapes[0].boxes[0].state.contains(.visited))
    }

    @Test func linkedListReversalKeepsIDs() throws {
        let nodes = ["1", "2", "3"].map { TreeNode(id: "n\($0)", label: $0) }
        let frames: [[Shape]] = [
            [.linkedList(LinkedListShape(nodes: nodes, pointers: ["head": "n1"]))],
            [.linkedList(LinkedListShape(nodes: nodes.reversed(), pointers: ["head": "n3", "prev": String?.none]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        let before = timeline.scenes[0].shapes[0]
        let after = timeline.scenes[1].shapes[0]
        #expect(Set(before.boxes.map(\.id)) == Set(after.boxes.map(\.id)))
        let first = try #require(before.boxes.first { $0.text == "1" })
        let moved = try #require(after.boxes.first { $0.id == first.id })
        #expect(moved.center.x > first.center.x)
        #expect(before.edges.count == 3 && after.edges.count == 3)
        let none = try #require(after.labels.first { $0.role == .terminator })
        let prev = try #require(after.labels.first { $0.id.hasSuffix("pointer/prev") })
        #expect(prev.center.x == none.center.x)
    }

    @Test func stackGrowsUpAndQueueShifts() throws {
        let frames: [[Shape]] = [
            [.stack(SequenceShape(name: "stack", items: ["a"])), .queue(SequenceShape(items: ["1", "2", "3"]))],
            [.stack(SequenceShape(name: "stack", items: ["a", "b"])), .queue(SequenceShape(items: ["2", "3"]))],
        ]
        let timeline = SceneLayoutEngine.layout(frames, metrics: metrics)
        let stack = timeline.scenes[1].shapes[0]
        let a = try #require(stack.boxes.first { $0.text == "a" })
        let b = try #require(stack.boxes.first { $0.text == "b" })
        #expect(b.center.y < a.center.y)
        #expect(timeline.scenes[0].shapes[0].boxes[0].center == a.center)

        let queueBefore = timeline.scenes[0].shapes[1]
        let queueAfter = timeline.scenes[1].shapes[1]
        let two = try #require(queueBefore.boxes.first { $0.text == "2" })
        let twoAfter = try #require(queueAfter.boxes.first { $0.id == two.id })
        #expect(twoAfter.center.x < two.center.x)
    }

    @Test func bitsGroupFromTheRight() {
        let bits = BitsShape(bits: [true, false, true, true, false, false, true, false, true, true], groupSize: 4)
        let shape = SceneLayoutEngine.layout([[.bits(bits)]], metrics: metrics).scenes[0].shapes[0]
        let xs = shape.boxes.map(\.center.x)
        let steps = zip(xs, xs.dropFirst()).map { $1 - $0 }
        // 10 bits in groups of 4 from the right: 2 | 4 | 4, so wider steps after index 1 and 5.
        let wide = steps.enumerated().filter { $0.element > steps.min()! + 0.5 }.map(\.offset)
        #expect(wide == [1, 5])
        #expect(shape.boxes.last?.id == "bit/0")
    }
}

// MARK: Worst case timing

@Suite struct TimingTests {
    @Test func worstCaseRunsFast() {
        var generator = SeededGenerator(seed: 1)
        let clock = ContinuousClock()

        // 1,000 frames of a 50-cell array with pointers, a range and a highlight.
        var values = (0..<50).map { _ in String(Int.random(in: 0...999, using: &generator)) }
        var arrayFrames: [[Shape]] = []
        for step in 0..<1000 {
            let i = Int.random(in: 0..<50, using: &generator)
            let j = Int.random(in: 0..<50, using: &generator)
            values.swapAt(i, j)
            arrayFrames.append([.array(ArrayShape(
                name: "a", values: values,
                pointers: [Pointer(name: "i", index: i), Pointer(name: "j", index: j)],
                shaded: [IndexRange(lower: min(i, j), upper: max(i, j))],
                highlighted: [step % 50]
            ))])
        }
        let arrayTime = clock.measure { _ = SceneLayoutEngine.layout(arrayFrames, metrics: metrics) }

        // 1,000 frames of a 20×20 grid filling in, with a highlight and two arrows.
        var grid = [[String]](repeating: [String](repeating: "", count: 20), count: 20)
        var gridFrames: [[Shape]] = []
        for step in 0..<1000 {
            let r = (step / 20) % 20
            let c = step % 20
            grid[r][c] = String(step)
            gridFrames.append([.grid(GridShape(
                rows: grid, rowLabels: (0..<20).map(String.init), columnLabels: (0..<20).map(String.init),
                highlighted: [GridCell(row: r, column: c)],
                arrows: [GridArrow(from: GridCell(row: r, column: c), to: GridCell(row: max(r - 1, 0), column: c)),
                         GridArrow(from: GridCell(row: r, column: c), to: GridCell(row: r, column: max(c - 1, 0)))]
            ))])
        }
        let gridTime = clock.measure { _ = SceneLayoutEngine.layout(gridFrames, metrics: metrics) }

        // 1,000 frames of a 63-node tree with a moving active node.
        let tree = completeBinaryTree(nodes: 63)
        let treeFrames: [[Shape]] = (0..<1000).map { step in
            var frame = tree
            frame.active = ["n\(step % 63)"]
            return [.tree(frame)]
        }
        let treeTime = clock.measure { _ = SceneLayoutEngine.layout(treeFrames, metrics: metrics) }

        // Worst case for trees: the structure changes every frame (BST built one node at a time,
        // then torn down), so no placement is reused.
        let growing: [[Shape]] = (0..<1000).map { step in
            let count = 1 + (step % 126 < 63 ? step % 63 : 62 - step % 63)
            return [.tree(completeBinaryTree(nodes: count))]
        }
        let growingTime = clock.measure { _ = SceneLayoutEngine.layout(growing, metrics: metrics) }

        // 1,000 frames of a 30-node graph.
        let ids = (0..<30).map { "v\($0)" }
        let graphNodes = ids.map { GraphNode(id: $0, label: $0) }
        let graphEdges = ids.indices.flatMap { i in [GraphEdge(from: ids[i], to: ids[(i + 1) % 30]), GraphEdge(from: ids[i], to: ids[(i + 7) % 30], weight: "3")] }
        let graphFrames: [[Shape]] = (0..<1000).map { step in
            [.graph(GraphShape(nodes: graphNodes, edges: graphEdges, visited: Array(ids.prefix(step % 30)), frontier: [ids[step % 30]]))]
        }
        let graphTime = clock.measure { _ = SceneLayoutEngine.layout(graphFrames, metrics: metrics) }

        print("VisualsLayout timing, 1,000 frames each: array 50 cells \(arrayTime), grid 20×20 \(gridTime), tree 63 nodes \(treeTime), tree changing every frame \(growingTime), graph 30 nodes \(graphTime)")
        // Generous bounds so debug builds on slow CI pass; the report carries real numbers.
        #expect(arrayTime < .seconds(3))
        #expect(gridTime < .seconds(10))
        #expect(treeTime < .seconds(5))
        #expect(growingTime < .seconds(10))
        #expect(graphTime < .seconds(5))
    }
}

/// SplitMix64, so random tests are repeatable.
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
