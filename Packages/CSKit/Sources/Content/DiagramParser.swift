import Foundation
import Contracts

// MARK: - Diagram grammar
//
// The body of a ```diagram block. One command per line. A line that starts a shape (`array`,
// `grid`, `tree`, `graph`, `digraph`, `linked-list`, `stack`, `queue`, `bits`) begins a new
// shape; every other command applies to the shape above it. A diagram holds one or more shapes
// and optionally a `code` section.
//
// General rules
//   - Blank lines and lines starting with `#` are ignored.
//   - Lists use brackets and commas: `[1, 3, 5]`. An empty entry is an empty cell: `[1, , 3]`.
//     Wrap a value in double quotes to keep commas, brackets or spaces: `["a, b", "[]"]`.
//     Escape a quote or backslash inside quotes with a backslash.
//   - Commands take space-separated words. Node ids and pointer names are single words.
//   - Indexes are 0-based. `shade 2..4` is inclusive on both ends.
//   - A name after the shape word is optional: `array nums [1, 2]`.
//
// array [name] [values]       pointer NAME INDEX   shade A..B ...   highlight INDEX ...
//
//     array nums [1, 3, 5, 7, 9, 11]
//     pointer lo 0
//     pointer mid 2
//     pointer hi 6          # INDEX may equal the length (one past the end)
//     shade 3..5
//     highlight 2
//
// grid [name]                 row [..]   row-labels [..]   col-labels [..]
//                             highlight R,C ...            arrow R,C -> R,C
//
//     grid dp
//     col-labels [, a, b, c]
//     row-labels [, x, y]
//     row [0, 0, 0, 0]
//     row [0, 1, 1, 2]
//     highlight 1,3
//     arrow 1,3 -> 0,2
//
//   Every row needs the same number of cells, and label lists must match the rows or columns.
//
// tree                        PARENT -> CHILD ...   node ID ["Label"]   highlight ID ...   dim ID ...
//
//     tree
//     8 -> 3 10
//     3 -> 1 6
//     10 -> _ 14            # `_` keeps an empty child slot
//     highlight 6
//     dim 1
//
//   The first node written is the root. Labels default to the id. `highlight` marks active
//   nodes, `dim` draws them faded. Every node must hang from the root.
//
// graph | digraph             A -- B [WEIGHT]  (graph)   A -> B [WEIGHT]  (digraph)
//                             node ID ["Label"] [at X,Y]   highlight ID ...
//                             visited ID ...   frontier ID ...
//
//     digraph
//     node a "A" at 0.1,0.5   # position in 0...1; without it the graph is laid out
//     a -> b 4
//     b -> c 2
//     visited a
//     frontier b
//     highlight b
//
//   Nodes mentioned in an edge are created on the spot. The commands after an edge list must
//   name existing nodes.
//
// linked-list [values]        pointer NAME INDEX|none
//
//     linked-list [1, 2, 3]
//     pointer head 0
//     pointer cur 2
//     pointer prev none
//
//   Node ids are n0, n1, ... in order. Links follow the order of the list.
//
// stack [name] [items]        highlight INDEX ...     (items run bottom to top)
// queue [name] [items]        highlight INDEX ...     (items run front to back)
//
//     stack calls [main, f, g]
//     highlight 2
//
// bits DIGITS                 group N   highlight INDEX ...
//
//     bits 1011 0010        # spaces and _ are ignored; most significant bit first
//     group 4               # cells per group; default 8
//     highlight 0 4         # INDEX counts from the left
//
// code                        an indented section: the code that produced the diagram
//
//     array a [3, 1, 2]
//     code
//         a = [3, 1, 2]
//         a.sort()
//
//   The section ends at the first line that isn't blank or indented. At most one per diagram.
//   Tapping the diagram runs it into a step-through.

/// Parses the body of a ```diagram block. Errors carry a 1-based line within the block.
public enum DiagramParser {
    public static func parse(_ source: String) throws -> Diagram {
        var builder = Builder()
        let lines = SourceLines.split(source)
        var index = 0
        while index < lines.count {
            let line = lines[index]
            index += 1
            let text = line.text.trimmingCharacters(in: .whitespaces)
            if text.isEmpty || text.hasPrefix("#") { continue }
            if text == "code" {
                var body: [Line] = []
                while index < lines.count, lines[index].isBlank || lines[index].text.first == " " || lines[index].text.first == "\t" {
                    body.append(lines[index])
                    index += 1
                }
                try builder.setCode(body, line: line.number)
                continue
            }
            try builder.command(text, line: line.number)
        }
        return try builder.finish()
    }
}

// MARK: - Implementation

private struct Token {
    var text: String
    var quoted: Bool
    var isPlain: Bool { !quoted }
}

private func fail(_ line: Int, _ message: String) -> ContentError {
    ContentError(line: line, message: message)
}

private struct GridDraft {
    var name: String?
    var rows: [[String]] = []
    var rowLabels: [String]?
    var columnLabels: [String]?
    var highlighted: [(cell: GridCell, line: Int)] = []
    var arrows: [(arrow: GridArrow, line: Int)] = []
}

private struct TreeDraft {
    var order: [String] = []
    var labels: [String: String] = [:]
    var lines: [String: Int] = [:]
    var children: [String: [String?]] = [:]
    var hasParent: Set<String> = []
    var active: [String] = []
    var dimmed: [String] = []

    mutating func ensure(_ id: String, line: Int) {
        if labels[id] == nil {
            labels[id] = id
            lines[id] = line
            order.append(id)
        }
    }
}

private struct ListDraft {
    var labels: [String]
    var pointers: [String: String?] = [:]
}

private enum Draft {
    case array(ArrayShape)
    case grid(GridDraft)
    case tree(TreeDraft)
    case graph(GraphShape)
    case list(ListDraft)
    case stack(SequenceShape)
    case queue(SequenceShape)
    case bits(BitsShape)

    var name: String {
        switch self {
        case .array: "array"
        case .grid: "grid"
        case .tree: "tree"
        case .graph(let graph): graph.directed ? "digraph" : "graph"
        case .list: "linked-list"
        case .stack: "stack"
        case .queue: "queue"
        case .bits: "bits"
        }
    }
}

private struct Builder {
    var shapes: [Shape] = []
    var current: Draft?
    var currentLine = 0
    var code: String?

    // MARK: Dispatch

    mutating func command(_ text: String, line: Int) throws {
        let simple = text.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
        if simple.count >= 3, simple[1] == "->" || simple[1] == "--" {
            try relation(try tokenize(text, line: line), line: line)
            return
        }
        let word = simple[0]
        let rest = String(text.dropFirst(word.count)).trimmingCharacters(in: .whitespaces)

        switch word {
        case "array":
            let (name, values) = try namedList(rest, line: line)
            try start(.array(ArrayShape(name: name, values: values)), line: line)
        case "stack", "queue":
            let (name, items) = try namedList(rest, line: line)
            let shape = SequenceShape(name: name, items: items)
            try start(word == "stack" ? .stack(shape) : .queue(shape), line: line)
        case "linked-list":
            let (name, values) = try namedList(rest, line: line)
            guard name == nil else { throw fail(line, "linked-list takes no name") }
            try start(.list(ListDraft(labels: values)), line: line)
        case "grid":
            var draft = GridDraft()
            if !rest.isEmpty {
                let tokens = try tokenize(rest, line: line)
                guard tokens.count == 1 else { throw fail(line, "grid takes at most a name") }
                draft.name = tokens[0].text
            }
            try start(.grid(draft), line: line)
        case "tree":
            guard rest.isEmpty else { throw fail(line, "tree takes no arguments") }
            try start(.tree(TreeDraft()), line: line)
        case "graph", "digraph":
            guard rest.isEmpty else { throw fail(line, "\(word) takes no arguments") }
            try start(.graph(GraphShape(directed: word == "digraph", nodes: [], edges: [])), line: line)
        case "bits":
            try start(.bits(try bits(rest, line: line)), line: line)
        case "row", "row-labels", "col-labels":
            try gridList(word, rest, line: line)
        case "pointer": try pointer(rest, line: line)
        case "shade": try shade(rest, line: line)
        case "highlight": try highlight(rest, line: line)
        case "dim": try dim(rest, line: line)
        case "visited", "frontier": try graphState(word, rest, line: line)
        case "node": try node(rest, line: line)
        case "arrow": try arrow(rest, line: line)
        case "group": try group(rest, line: line)
        default:
            throw fail(line, "unknown command `\(word)`")
        }
    }

    // MARK: Shapes

    mutating func start(_ draft: Draft, line: Int) throws {
        try closeCurrent()
        current = draft
        currentLine = line
    }

    mutating func closeCurrent() throws {
        guard let draft = current else { return }
        current = nil
        switch draft {
        case .array(let shape): shapes.append(.array(shape))
        case .stack(let shape): shapes.append(.stack(shape))
        case .queue(let shape): shapes.append(.queue(shape))
        case .bits(let shape): shapes.append(.bits(shape))
        case .graph(let shape): shapes.append(.graph(shape))
        case .list(let list):
            let nodes = list.labels.enumerated().map { TreeNode(id: "n\($0.offset)", label: $0.element) }
            shapes.append(.linkedList(LinkedListShape(nodes: nodes, pointers: list.pointers)))
        case .grid(let grid): shapes.append(.grid(try finish(grid)))
        case .tree(let tree): shapes.append(.tree(try finish(tree)))
        }
    }

    mutating func finish() throws -> Diagram {
        try closeCurrent()
        guard !shapes.isEmpty else { throw fail(1, "diagram has no shapes") }
        return Diagram(shapes: shapes, code: code)
    }

    private func finish(_ grid: GridDraft) throws -> GridShape {
        guard let width = grid.rows.first?.count else { throw fail(currentLine, "grid has no rows (add `row [..]`)") }
        for row in grid.rows where row.count != width {
            throw fail(currentLine, "grid rows must all have \(width) cells")
        }
        if let labels = grid.rowLabels, labels.count != grid.rows.count {
            throw fail(currentLine, "row-labels has \(labels.count) entries for \(grid.rows.count) rows")
        }
        if let labels = grid.columnLabels, labels.count != width {
            throw fail(currentLine, "col-labels has \(labels.count) entries for \(width) columns")
        }
        func check(_ cell: GridCell, _ line: Int) throws {
            guard (0..<grid.rows.count).contains(cell.row), (0..<width).contains(cell.column) else {
                throw fail(line, "cell \(cell.row),\(cell.column) is outside the grid")
            }
        }
        for item in grid.highlighted { try check(item.cell, item.line) }
        for item in grid.arrows {
            try check(item.arrow.from, item.line)
            try check(item.arrow.to, item.line)
        }
        return GridShape(
            name: grid.name, rows: grid.rows, rowLabels: grid.rowLabels, columnLabels: grid.columnLabels,
            highlighted: grid.highlighted.map(\.cell), arrows: grid.arrows.map(\.arrow)
        )
    }

    private func finish(_ tree: TreeDraft) throws -> TreeShape {
        guard let root = tree.order.first else { throw fail(currentLine, "tree has no nodes") }
        if tree.hasParent.contains(root) {
            throw fail(tree.lines[root] ?? currentLine, "root `\(root)` can't also be a child")
        }
        var reached: Set<String> = [root]
        var stack = [root]
        while let id = stack.popLast() {
            for case let child? in tree.children[id] ?? [] where reached.insert(child).inserted {
                stack.append(child)
            }
        }
        for id in tree.order where !reached.contains(id) {
            throw fail(tree.lines[id] ?? currentLine, "node `\(id)` isn't connected to the root `\(root)`")
        }
        let nodes = tree.order.map { TreeNode(id: $0, label: tree.labels[$0] ?? $0, children: tree.children[$0] ?? []) }
        return TreeShape(root: root, nodes: nodes, active: tree.active, dimmed: tree.dimmed)
    }

    // MARK: Commands on the current shape

    private func noTarget(_ word: String, line: Int) -> ContentError {
        if let current {
            return fail(line, "`\(word)` doesn't apply to \(current.name)")
        }
        return fail(line, "`\(word)` needs a shape above it (array, grid, tree, ...)")
    }

    mutating func pointer(_ rest: String, line: Int) throws {
        let tokens = try tokenize(rest, line: line)
        guard tokens.count == 2 else { throw fail(line, "expected `pointer NAME INDEX`") }
        let name = tokens[0].text
        switch current {
        case .array(var shape):
            let index = try integer(tokens[1], line: line)
            guard (0...shape.values.count).contains(index) else {
                throw fail(line, "pointer index \(index) is outside 0...\(shape.values.count)")
            }
            guard !shape.pointers.contains(where: { $0.name == name }) else { throw fail(line, "pointer `\(name)` is already set") }
            shape.pointers.append(Pointer(name: name, index: index))
            current = .array(shape)
        case .list(var list):
            guard list.pointers[name] == nil else { throw fail(line, "pointer `\(name)` is already set") }
            if tokens[1].isPlain, tokens[1].text == "none" {
                list.pointers.updateValue(nil, forKey: name)
            } else {
                let index = try integer(tokens[1], line: line)
                guard (0..<list.labels.count).contains(index) else {
                    throw fail(line, "pointer index \(index) is outside 0..<\(list.labels.count) (or use `none`)")
                }
                list.pointers[name] = "n\(index)"
            }
            current = .list(list)
        default:
            throw noTarget("pointer", line: line)
        }
    }

    mutating func shade(_ rest: String, line: Int) throws {
        guard case .array(var shape) = current else { throw noTarget("shade", line: line) }
        let tokens = try tokenize(rest, line: line)
        guard !tokens.isEmpty else { throw fail(line, "expected `shade A..B`") }
        for token in tokens {
            let parts = token.text.components(separatedBy: "..")
            guard parts.count <= 2, let lower = Int(parts[0]), let upper = Int(parts.last ?? "") else {
                throw fail(line, "`\(token.text)` isn't a range (expected A..B)")
            }
            guard lower <= upper, lower >= 0, upper < shape.values.count else {
                throw fail(line, "range \(lower)..\(upper) is outside 0..<\(shape.values.count)")
            }
            shape.shaded.append(IndexRange(lower: lower, upper: upper))
        }
        current = .array(shape)
    }

    mutating func highlight(_ rest: String, line: Int) throws {
        let tokens = try tokenize(rest, line: line)
        guard !tokens.isEmpty else { throw fail(line, "expected something to highlight") }
        switch current {
        case .array(var shape):
            shape.highlighted += try indexes(tokens, count: shape.values.count, line: line)
            current = .array(shape)
        case .stack(var shape):
            shape.highlighted += try indexes(tokens, count: shape.items.count, line: line)
            current = .stack(shape)
        case .queue(var shape):
            shape.highlighted += try indexes(tokens, count: shape.items.count, line: line)
            current = .queue(shape)
        case .bits(var shape):
            shape.highlighted += try indexes(tokens, count: shape.bits.count, line: line)
            current = .bits(shape)
        case .grid(var grid):
            for token in tokens {
                grid.highlighted.append((try cell(token, line: line), line))
            }
            current = .grid(grid)
        case .tree(var tree):
            tree.active += try existing(tokens, in: tree.labels, line: line)
            current = .tree(tree)
        case .graph(var graph):
            graph.active += try existing(tokens, in: graphIDs(graph), line: line)
            current = .graph(graph)
        case .list:
            throw fail(line, "`highlight` doesn't apply to linked-list (use `pointer`)")
        case nil:
            throw noTarget("highlight", line: line)
        }
    }

    mutating func dim(_ rest: String, line: Int) throws {
        guard case .tree(var tree) = current else { throw noTarget("dim", line: line) }
        tree.dimmed += try existing(try tokenize(rest, line: line), in: tree.labels, line: line)
        current = .tree(tree)
    }

    mutating func graphState(_ word: String, _ rest: String, line: Int) throws {
        guard case .graph(var graph) = current else { throw noTarget(word, line: line) }
        let ids = try existing(try tokenize(rest, line: line), in: graphIDs(graph), line: line)
        if word == "visited" { graph.visited += ids } else { graph.frontier += ids }
        current = .graph(graph)
    }

    mutating func node(_ rest: String, line: Int) throws {
        let tokens = try tokenize(rest, line: line)
        guard let first = tokens.first else { throw fail(line, "expected `node ID`") }
        let id = first.text
        switch current {
        case .tree(var tree):
            guard tokens.count <= 2 else { throw fail(line, "expected `node ID [\"Label\"]`") }
            tree.ensure(id, line: line)
            if tokens.count == 2 { tree.labels[id] = tokens[1].text }
            current = .tree(tree)
        case .graph(var graph):
            var label: String?
            var position: (Double, Double)?
            var index = 1
            while index < tokens.count {
                let token = tokens[index]
                if token.isPlain, token.text == "at" {
                    guard index + 1 < tokens.count else { throw fail(line, "`at` needs X,Y") }
                    position = try coordinates(tokens[index + 1], line: line)
                    index += 2
                } else if label == nil {
                    label = token.text
                    index += 1
                } else {
                    throw fail(line, "expected `node ID [\"Label\"] [at X,Y]`")
                }
            }
            var node = graph.nodes.first { $0.id == id } ?? GraphNode(id: id, label: id)
            if let label { node.label = label }
            if let position { node.x = position.0; node.y = position.1 }
            if let slot = graph.nodes.firstIndex(where: { $0.id == id }) {
                graph.nodes[slot] = node
            } else {
                graph.nodes.append(node)
            }
            current = .graph(graph)
        default:
            throw noTarget("node", line: line)
        }
    }

    mutating func arrow(_ rest: String, line: Int) throws {
        guard case .grid(var grid) = current else { throw noTarget("arrow", line: line) }
        let tokens = try tokenize(rest, line: line)
        guard tokens.count == 3, tokens[1].text == "->" else { throw fail(line, "expected `arrow R,C -> R,C`") }
        grid.arrows.append((GridArrow(from: try cell(tokens[0], line: line), to: try cell(tokens[2], line: line)), line))
        current = .grid(grid)
    }

    mutating func group(_ rest: String, line: Int) throws {
        guard case .bits(var shape) = current else { throw noTarget("group", line: line) }
        let tokens = try tokenize(rest, line: line)
        guard tokens.count == 1 else { throw fail(line, "expected `group N`") }
        let size = try integer(tokens[0], line: line)
        guard size >= 1 else { throw fail(line, "group size must be at least 1") }
        shape.groupSize = size
        current = .bits(shape)
    }

    mutating func gridList(_ word: String, _ rest: String, line: Int) throws {
        guard case .grid(var grid) = current else { throw noTarget(word, line: line) }
        let values = try list(rest, line: line)
        switch word {
        case "row": grid.rows.append(values)
        case "row-labels": grid.rowLabels = values
        default: grid.columnLabels = values
        }
        current = .grid(grid)
    }

    mutating func relation(_ tokens: [Token], line: Int) throws {
        let op = tokens[1].text
        switch current {
        case .tree(var tree):
            guard op == "->" else { throw fail(line, "tree edges use ->") }
            let parent = tokens[0].text
            guard tree.children[parent] == nil else { throw fail(line, "children of `\(parent)` are already given") }
            tree.ensure(parent, line: line)
            var children: [String?] = []
            for token in tokens.dropFirst(2) {
                if token.isPlain, token.text == "_" {
                    children.append(nil)
                    continue
                }
                let child = token.text
                guard tree.hasParent.insert(child).inserted else { throw fail(line, "`\(child)` already has a parent") }
                tree.ensure(child, line: line)
                children.append(child)
            }
            tree.children[parent] = children
            current = .tree(tree)
        case .graph(var graph):
            guard op == (graph.directed ? "->" : "--") else {
                throw fail(line, graph.directed ? "digraph edges use ->" : "graph edges use --")
            }
            guard tokens.count <= 4 else { throw fail(line, "expected `A \(op) B [WEIGHT]`") }
            for id in [tokens[0].text, tokens[2].text] where !graph.nodes.contains(where: { $0.id == id }) {
                graph.nodes.append(GraphNode(id: id, label: id))
            }
            graph.edges.append(GraphEdge(from: tokens[0].text, to: tokens[2].text, weight: tokens.count == 4 ? tokens[3].text : nil))
            current = .graph(graph)
        default:
            throw fail(line, current == nil ? "`\(op)` needs a tree or graph above it" : "`\(op)` doesn't apply to \(current?.name ?? "this shape")")
        }
    }

    mutating func setCode(_ body: [Line], line: Int) throws {
        guard code == nil else { throw fail(line, "a diagram can have only one `code` section") }
        var lines = body.map(\.text)
        while lines.last.map({ $0.allSatisfy { $0 == " " || $0 == "\t" } }) == true { lines.removeLast() }
        guard !lines.isEmpty else { throw fail(line, "`code` needs an indented section below it") }
        let indent = lines.filter { !$0.allSatisfy { $0 == " " || $0 == "\t" } }
            .map { $0.prefix(while: { $0 == " " || $0 == "\t" }).count }.min() ?? 0
        code = lines.map { $0.allSatisfy { $0 == " " || $0 == "\t" } ? "" : String($0.dropFirst(indent)) }.joined(separator: "\n")
    }

    // MARK: Values

    private func graphIDs(_ graph: GraphShape) -> [String: String] {
        Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0.label) })
    }

    private func existing(_ tokens: [Token], in nodes: [String: String], line: Int) throws -> [String] {
        guard !tokens.isEmpty else { throw fail(line, "expected node ids") }
        return try tokens.map { token in
            guard nodes[token.text] != nil else { throw fail(line, "no node `\(token.text)` yet") }
            return token.text
        }
    }

    private func integer(_ token: Token, line: Int) throws -> Int {
        guard let value = Int(token.text) else { throw fail(line, "`\(token.text)` isn't a whole number") }
        return value
    }

    private func indexes(_ tokens: [Token], count: Int, line: Int) throws -> [Int] {
        try tokens.map { token in
            let value = try integer(token, line: line)
            guard (0..<count).contains(value) else { throw fail(line, "index \(value) is outside 0..<\(count)") }
            return value
        }
    }

    private func cell(_ token: Token, line: Int) throws -> GridCell {
        let parts = token.text.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2, let row = Int(parts[0]), let column = Int(parts[1]) else {
            throw fail(line, "`\(token.text)` isn't a cell (expected ROW,COLUMN)")
        }
        return GridCell(row: row, column: column)
    }

    private func coordinates(_ token: Token, line: Int) throws -> (Double, Double) {
        let parts = token.text.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2, let x = Double(parts[0]), let y = Double(parts[1]),
              (0.0...1.0).contains(x), (0.0...1.0).contains(y) else {
            throw fail(line, "`\(token.text)` isn't a position (expected X,Y between 0 and 1)")
        }
        return (x, y)
    }

    private func bits(_ rest: String, line: Int) throws -> BitsShape {
        var values: [Bool] = []
        for char in rest where char != " " && char != "_" && char != "\t" {
            switch char {
            case "0": values.append(false)
            case "1": values.append(true)
            default: throw fail(line, "bits can only contain 0 and 1, not `\(char)`")
            }
        }
        guard !values.isEmpty else { throw fail(line, "expected `bits 1011 0010`") }
        return BitsShape(bits: values)
    }

    // MARK: Tokens and lists

    private func tokenize(_ text: String, line: Int) throws -> [Token] {
        let chars = Array(text)
        var tokens: [Token] = []
        var index = 0
        while index < chars.count {
            if chars[index] == " " || chars[index] == "\t" {
                index += 1
            } else if chars[index] == "\"" {
                index += 1
                var value = ""
                var closed = false
                while index < chars.count {
                    let char = chars[index]
                    if char == "\\", index + 1 < chars.count, chars[index + 1] == "\"" || chars[index + 1] == "\\" {
                        value.append(chars[index + 1])
                        index += 2
                    } else if char == "\"" {
                        closed = true
                        index += 1
                        break
                    } else {
                        value.append(char)
                        index += 1
                    }
                }
                guard closed else { throw fail(line, "missing closing quote") }
                tokens.append(Token(text: value, quoted: true))
            } else {
                var value = ""
                while index < chars.count, chars[index] != " ", chars[index] != "\t" {
                    value.append(chars[index])
                    index += 1
                }
                tokens.append(Token(text: value, quoted: false))
            }
        }
        return tokens
    }

    /// `[name] [a, b, c]`.
    private func namedList(_ rest: String, line: Int) throws -> (name: String?, values: [String]) {
        guard let open = rest.firstIndex(of: "[") else { throw fail(line, "expected a list like [1, 2, 3]") }
        let head = rest[..<open].trimmingCharacters(in: .whitespaces)
        var name: String?
        if !head.isEmpty {
            let tokens = try tokenize(head, line: line)
            guard tokens.count == 1 else { throw fail(line, "expected at most one name before the list") }
            name = tokens[0].text
        }
        return (name, try list(String(rest[open...]), line: line))
    }

    /// `[a, b, "c, d"]`. Commas inside nested brackets or quotes don't split.
    private func list(_ text: String, line: Int) throws -> [String] {
        let chars = Array(text.trimmingCharacters(in: .whitespaces))
        guard chars.first == "[", chars.last == "]", chars.count >= 2 else {
            throw fail(line, "expected a list like [1, 2, 3]")
        }
        let inner = chars[1..<(chars.count - 1)]
        var pieces: [String] = []
        var piece = ""
        var depth = 0
        var inQuote = false
        var escaped = false
        for char in inner {
            if inQuote {
                piece.append(char)
                if escaped { escaped = false } else if char == "\\" { escaped = true } else if char == "\"" { inQuote = false }
                continue
            }
            switch char {
            case "\"": inQuote = true; piece.append(char)
            case "[": depth += 1; piece.append(char)
            case "]":
                depth -= 1
                guard depth >= 0 else { throw fail(line, "unbalanced ] in list") }
                piece.append(char)
            case "," where depth == 0:
                pieces.append(piece)
                piece = ""
            default: piece.append(char)
            }
        }
        guard !inQuote else { throw fail(line, "missing closing quote") }
        guard depth == 0 else { throw fail(line, "unbalanced [ in list") }
        if pieces.isEmpty, piece.allSatisfy({ $0 == " " || $0 == "\t" }) { return [] }
        pieces.append(piece)
        return try pieces.map { raw in
            let value = raw.trimmingCharacters(in: .whitespaces)
            guard value.hasPrefix("\"") else { return value }
            guard value.count >= 2, value.hasSuffix("\"") else { throw fail(line, "text after a closing quote in list") }
            let tokens = try tokenize(value, line: line)
            guard tokens.count == 1 else { throw fail(line, "text after a closing quote in list") }
            return tokens[0].text
        }
    }
}
