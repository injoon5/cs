import Foundation
import Contracts

/// A fenced code block. `body` has the fence's indentation removed; `raw` is open + body + close
/// exactly as written (used when a fence stays prose).
struct Fence {
    var open: Line
    var info: String
    var body: [Line]
    var raw: [Line]

    var source: String { body.map(\.text).joined(separator: "\n") }
}

enum Piece {
    case text(Line)
    case fence(Fence)
}

/// CommonMark fence rules: up to 3 spaces of indent, 3+ backticks or tildes, closed by a run of
/// the same character at least as long. A longer fence can contain shorter ones.
private struct FenceMarker {
    var char: Character
    var length: Int
    var indent: Int
    var info: String

    init?(_ text: String) {
        let indent = text.prefix(while: { $0 == " " }).count
        guard indent <= 3 else { return nil }
        let rest = text.dropFirst(indent)
        guard let char = rest.first, char == "`" || char == "~" else { return nil }
        let length = rest.prefix(while: { $0 == char }).count
        guard length >= 3 else { return nil }
        let info = rest.dropFirst(length).trimmingCharacters(in: .whitespaces)
        if char == "`", info.contains("`") { return nil }
        self.char = char
        self.length = length
        self.indent = indent
        self.info = info
    }

    func closes(_ text: String) -> Bool {
        let indent = text.prefix(while: { $0 == " " }).count
        guard indent <= 3 else { return false }
        let rest = text.dropFirst(indent)
        let run = rest.prefix(while: { $0 == char }).count
        guard run >= length else { return false }
        return rest.dropFirst(run).allSatisfy { $0 == " " || $0 == "\t" }
    }
}

enum MarkdownScanner {
    /// Turns lines into text lines and whole fences. A fence that is never closed is an error.
    static func pieces(_ lines: [Line], path: String) throws -> [Piece] {
        var out: [Piece] = []
        var index = 0
        while index < lines.count {
            let line = lines[index]
            guard let marker = FenceMarker(line.text) else {
                out.append(.text(line))
                index += 1
                continue
            }
            var body: [Line] = []
            var close: Line?
            var cursor = index + 1
            while cursor < lines.count {
                if marker.closes(lines[cursor].text) {
                    close = lines[cursor]
                    break
                }
                body.append(lines[cursor])
                cursor += 1
            }
            guard let close else {
                throw ContentError(path: path, line: line.number, message: "code fence is never closed")
            }
            let dedented = body.map { Line(number: $0.number, text: dedent($0.text, by: marker.indent)) }
            out.append(.fence(Fence(open: line, info: marker.info, body: dedented, raw: [line] + body + [close])))
            index = cursor + 1
        }
        return out
    }

    private static func dedent(_ text: String, by count: Int) -> String {
        var remaining = count
        var result = Substring(text)
        while remaining > 0, result.first == " " {
            result = result.dropFirst()
            remaining -= 1
        }
        return String(result)
    }

    /// `## Title` style heading: level and text. Not for lines inside fences.
    static func heading(_ text: String) -> (level: Int, title: String)? {
        let trimmed = text.drop(while: { $0 == " " })
        guard text.count - trimmed.count <= 3 else { return nil }
        let hashes = trimmed.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(hashes) else { return nil }
        let rest = trimmed.dropFirst(hashes)
        guard rest.isEmpty || rest.first == " " else { return nil }
        var title = rest.trimmingCharacters(in: .whitespaces)
        // Closing hashes: `## Title ##`.
        while title.hasSuffix("#") { title.removeLast() }
        return (hashes, title.trimmingCharacters(in: .whitespaces))
    }
}

/// What a fence's info string means.
enum FenceKind {
    case code(language: CodeLanguage, role: CodeRole)
    case diagram
    /// Not something the app runs: stays in the prose.
    case prose
}

enum CodeInfo {
    /// `python`, `python trace stop=N`, `python predict|arrange|starter|solution|tests`, `tests`,
    /// `shell`, `shell setup|check|solution`, `diagram`. Other languages are prose. A known
    /// language with an unknown modifier is an error, so typos don't silently become prose.
    static func parse(_ info: String, path: String, line: Int) throws -> FenceKind {
        let tokens = info.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
        guard let first = tokens.first else { return .prose }
        let rest = Array(tokens.dropFirst())

        func fail(_ message: String) -> ContentError {
            ContentError(path: path, line: line, message: message)
        }

        switch first {
        case "diagram":
            guard rest.isEmpty else { throw fail("`diagram` takes no options") }
            return .diagram
        case "tests":
            guard rest.isEmpty else { throw fail("`tests` takes no options") }
            return .code(language: .python, role: .tests)
        case "python":
            guard let modifier = rest.first else { return .code(language: .python, role: .cell) }
            switch modifier {
            case "trace":
                var stop: Int?
                for option in rest.dropFirst() {
                    guard option.hasPrefix("stop="), let value = Int(option.dropFirst(5)), value >= 0 else {
                        throw fail("unknown trace option `\(option)` (expected stop=N)")
                    }
                    guard stop == nil else { throw fail("`stop` given twice") }
                    stop = value
                }
                return .code(language: .python, role: .trace(stop: stop))
            case "predict", "arrange", "starter", "solution", "tests":
                guard rest.count == 1 else { throw fail("`python \(modifier)` takes no options") }
                let role: CodeRole = switch modifier {
                case "predict": .predict
                case "arrange": .arrange
                case "starter": .starter
                case "solution": .solution
                default: .tests
                }
                return .code(language: .python, role: role)
            default:
                throw fail("unknown python block `\(modifier)` (expected trace, predict, arrange, starter, solution or tests)")
            }
        case "shell":
            guard let modifier = rest.first else { return .code(language: .shell, role: .cell) }
            guard rest.count == 1 else { throw fail("`shell \(modifier)` takes no options") }
            switch modifier {
            case "setup": return .code(language: .shell, role: .setup)
            case "check": return .code(language: .shell, role: .check)
            case "solution": return .code(language: .shell, role: .solution)
            default: throw fail("unknown shell block `\(modifier)` (expected setup, check or solution)")
            }
        default:
            return .prose
        }
    }
}
