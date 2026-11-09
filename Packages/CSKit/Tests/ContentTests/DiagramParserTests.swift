import Foundation
import Testing
import Contracts
@testable import Content

private func shapes(_ source: String) throws -> [Shape] {
    try DiagramParser.parse(source).shapes
}

private func failure(_ source: String) -> ContentError? {
    contentError { try DiagramParser.parse(source) }
}

@Suite struct DiagramParserTests {
    @Test func planArrayExample() throws {
        let diagram = try DiagramParser.parse("""
        array [1, 3, 5, 7, 9, 11]
        pointer lo 0
        pointer mid 2
        pointer hi 5
        shade 3..5
        """)
        #expect(diagram == Diagram(shapes: [
            .array(ArrayShape(
                values: ["1", "3", "5", "7", "9", "11"],
                pointers: [Pointer(name: "lo", index: 0), Pointer(name: "mid", index: 2), Pointer(name: "hi", index: 5)],
                shaded: [IndexRange(lower: 3, upper: 5)]
            )),
        ]))
    }

    @Test func arrayWithNameHighlightsAndOnePastEnd() throws {
        let result = try shapes("""
        # a comment

        array nums [4, 8]
        pointer hi 2
        shade 0 1..1
        highlight 1 0
        """)
        #expect(result == [.array(ArrayShape(
            name: "nums", values: ["4", "8"],
            pointers: [Pointer(name: "hi", index: 2)],
            shaded: [IndexRange(lower: 0, upper: 0), IndexRange(lower: 1, upper: 1)],
            highlighted: [1, 0]
        ))])
    }

    @Test func listValues() throws {
        #expect(try shapes("array []") == [.array(ArrayShape(values: []))])
        #expect(try shapes("array [ ]") == [.array(ArrayShape(values: []))])
        #expect(try shapes("array [1, , 3]") == [.array(ArrayShape(values: ["1", "", "3"]))])
        #expect(try shapes(#"array ["a, b", "say \"hi\"", [1,2], x y]"#) == [.array(ArrayShape(values: ["a, b", "say \"hi\"", "[1,2]", "x y"]))])
    }

    @Test func grid() throws {
        let result = try shapes("""
        grid dp
        col-labels [, a, b]
        row-labels [x, y]
        row [0, 0, 0]
        row [1, , 3]
        highlight 1,2
        arrow 1,2 -> 0,1
        """)
        // Column labels have three entries (leading empty one), rows three cells.
        #expect(result == [.grid(GridShape(
            name: "dp",
            rows: [["0", "0", "0"], ["1", "", "3"]],
            rowLabels: ["x", "y"],
            columnLabels: ["", "a", "b"],
            highlighted: [GridCell(row: 1, column: 2)],
            arrows: [GridArrow(from: GridCell(row: 1, column: 2), to: GridCell(row: 0, column: 1))]
        ))])
    }

    @Test func tree() throws {
        let result = try shapes("""
        tree
        8 -> 3 10
        3 -> 1 6
        10 -> _ 14
        node 14 "fourteen"
        highlight 6
        dim 1
        """)
        #expect(result == [.tree(TreeShape(
            root: "8",
            nodes: [
                TreeNode(id: "8", label: "8", children: ["3", "10"]),
                TreeNode(id: "3", label: "3", children: ["1", "6"]),
                TreeNode(id: "10", label: "10", children: [nil, "14"]),
                TreeNode(id: "1", label: "1"),
                TreeNode(id: "6", label: "6"),
                TreeNode(id: "14", label: "fourteen"),
            ],
            active: ["6"],
            dimmed: ["1"]
        ))])
    }

    @Test func treeWithSingleNode() throws {
        #expect(try shapes("tree\nnode a \"Root\"") == [.tree(TreeShape(root: "a", nodes: [TreeNode(id: "a", label: "Root")]))])
    }

    @Test func undirectedGraph() throws {
        let result = try shapes("""
        graph
        node a "A" at 0.1,0.5
        a -- b 4
        b -- c
        visited a
        frontier b
        highlight c
        """)
        #expect(result == [.graph(GraphShape(
            directed: false,
            nodes: [GraphNode(id: "a", label: "A", x: 0.1, y: 0.5), GraphNode(id: "b", label: "b"), GraphNode(id: "c", label: "c")],
            edges: [GraphEdge(from: "a", to: "b", weight: "4"), GraphEdge(from: "b", to: "c")],
            visited: ["a"], frontier: ["b"], active: ["c"]
        ))])
    }

    @Test func directedGraph() throws {
        let result = try shapes("digraph\na -> b 2\nb -> a")
        #expect(result == [.graph(GraphShape(
            directed: true,
            nodes: [GraphNode(id: "a", label: "a"), GraphNode(id: "b", label: "b")],
            edges: [GraphEdge(from: "a", to: "b", weight: "2"), GraphEdge(from: "b", to: "a")]
        ))])
    }

    @Test func linkedList() throws {
        let result = try shapes("""
        linked-list [1, 2, 3]
        pointer head 0
        pointer cur 2
        pointer prev none
        """)
        var pointers: [String: String?] = ["head": "n0", "cur": "n2"]
        pointers.updateValue(nil, forKey: "prev")
        #expect(result == [.linkedList(LinkedListShape(
            nodes: [TreeNode(id: "n0", label: "1"), TreeNode(id: "n1", label: "2"), TreeNode(id: "n2", label: "3")],
            pointers: pointers
        ))])
    }

    @Test func stackAndQueue() throws {
        let result = try shapes("""
        stack calls [main, f, g]
        highlight 2
        queue [1, 2]
        highlight 0
        """)
        #expect(result == [
            .stack(SequenceShape(name: "calls", items: ["main", "f", "g"], highlighted: [2])),
            .queue(SequenceShape(items: ["1", "2"], highlighted: [0])),
        ])
    }

    @Test func bits() throws {
        #expect(try shapes("bits 1011 0010") == [.bits(BitsShape(bits: [true, false, true, true, false, false, true, false]))])
        #expect(try shapes("bits 1010_0001\ngroup 4\nhighlight 0 7") == [
            .bits(BitsShape(bits: [true, false, true, false, false, false, false, true], groupSize: 4, highlighted: [0, 7])),
        ])
    }

    @Test func multipleShapesAndCode() throws {
        let diagram = try DiagramParser.parse("""
        array a [3, 1, 2]
        pointer i 0
        stack s [1]
        highlight 0
        code
            a = [3, 1, 2]

            a.sort()
        """)
        #expect(diagram.shapes.count == 2)
        #expect(diagram.code == "a = [3, 1, 2]\n\na.sort()")
    }

    @Test func codeSectionEndsAtUnindentedLine() throws {
        let diagram = try DiagramParser.parse("array [1]\ncode\n  x = 1\nstack [2]")
        #expect(diagram.code == "x = 1")
        #expect(diagram.shapes.count == 2)
    }

    // MARK: Errors

    @Test func errorsCarryLines() {
        let cases: [(String, Int, String)] = [
            ("", 1, "no shapes"),
            ("# only a comment", 1, "no shapes"),
            ("pointer i 0", 1, "needs a shape"),
            ("array [1]\nshade 0..3", 2, "outside"),
            ("array [1]\nshade 1..0", 2, "outside"),
            ("array [1]\nshade a..b", 2, "range"),
            ("array [1, 2]\npointer i 3", 2, "outside"),
            ("array [1]\npointer i 0\npointer i 1", 3, "already"),
            ("array [1]\nhighlight 4", 2, "outside"),
            ("array [1\n", 1, "list"),
            ("array [1] extra", 1, "list"),
            ("array [\"a]", 1, "quote"),
            ("array [[1]", 1, "unbalanced"),
            ("array\n", 1, "list"),
            ("stack [1]\nshade 0", 2, "doesn't apply to stack"),
            ("stack [1]\npointer p 0", 2, "doesn't apply to stack"),
            ("linked-list [1]\nhighlight 0", 2, "pointer"),
            ("linked-list [1]\npointer p 1", 2, "outside"),
            ("linked-list x [1]", 1, "no name"),
            ("wibble", 1, "unknown command `wibble`"),
            ("grid\nrow [1]\nrow [1, 2]", 3, "must all have 1"),
            ("grid", 1, "no rows"),
            ("grid\nrow [1]\nrow-labels [a, b]", 1, "row-labels"),
            ("grid\nrow [1]\ncol-labels [a, b]", 1, "col-labels"),
            ("grid\nrow [1]\nhighlight 1,0", 3, "outside"),
            ("grid\nrow [1]\narrow 0,0 -> 0,5", 3, "outside"),
            ("grid\nrow [1]\narrow 0,0 0,0", 3, "arrow"),
            ("grid\nrow [1]\nhighlight x", 3, "cell"),
            ("tree", 1, "no nodes"),
            ("tree\na -> b\nb -> a", 2, "root"),
            ("tree\na -> b\nc -> d", 3, "connected"),
            ("tree\na -> b\na -> c", 3, "already given"),
            ("tree\na -> c\nb -> c", 3, "already has a parent"),
            ("tree\na -- b", 2, "->"),
            ("tree\na -> b\nhighlight z", 3, "no node `z`"),
            ("graph\na -> b", 2, "--"),
            ("digraph\na -- b", 2, "->"),
            ("graph\na -- b 1 2", 2, "WEIGHT"),
            ("graph\nvisited a", 2, "no node"),
            ("graph\nnode a at 2,2", 2, "position"),
            ("graph\nnode a b c", 2, "node"),
            ("a -> b", 1, "tree or graph"),
            ("array [1]\na -> b", 2, "doesn't apply"),
            ("bits 102", 1, "0 and 1"),
            ("bits", 1, "bits"),
            ("bits 1\ngroup 0", 2, "at least 1"),
            ("array [1]\ncode\nstack [1]", 2, "indented"),
            ("array [1]\ncode\n  a\ncode\n  b", 4, "only one"),
        ]
        for (source, line, fragment) in cases {
            let error = failure(source)
            #expect(error?.line == line, "\(source.debugDescription): line \(String(describing: error?.line)), \(String(describing: error?.message))")
            #expect(error?.message.contains(fragment) == true, "\(source.debugDescription): \(String(describing: error?.message))")
        }
    }
}
