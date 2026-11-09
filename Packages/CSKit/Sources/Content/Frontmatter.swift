import Foundation
import Yams

/// A source line with its 1-based number in the file.
struct Line: Equatable {
    var number: Int
    var text: String

    var isBlank: Bool { text.allSatisfy { $0 == " " || $0 == "\t" } }
}

enum SourceLines {
    /// Splits on LF after normalizing CRLF. Always returns at least one line.
    static func split(_ source: String) -> [Line] {
        let normalized = source.replacingOccurrences(of: "\r\n", with: "\n")
        return normalized.components(separatedBy: "\n").enumerated().map { Line(number: $0.offset + 1, text: $0.element) }
    }
}

/// The YAML block at the top of a Markdown file.
struct Frontmatter {
    let path: String
    private let yamlLines: [Line]
    private let values: [String: Node]

    /// Returns nil when the file doesn't start with `---`. `bodyStart` is the index in `lines`
    /// of the first line after the closing `---`.
    static func extract(from lines: [Line], path: String) throws -> (frontmatter: Frontmatter, bodyStart: Int)? {
        guard let first = lines.first, first.text.trimmingCharacters(in: .whitespaces) == "---" else { return nil }
        var end: Int?
        for index in lines.indices.dropFirst() {
            let text = lines[index].text.trimmingCharacters(in: .whitespaces)
            if text == "---" || text == "..." {
                end = index
                break
            }
        }
        guard let end else {
            throw ContentError(path: path, line: first.number, message: "frontmatter is never closed with ---")
        }
        let yamlLines = Array(lines[1..<end])
        let yaml = yamlLines.map(\.text).joined(separator: "\n")
        var values: [String: Node] = [:]
        do {
            if let node = try Yams.compose(yaml: yaml) {
                guard let mapping = node.mapping else {
                    throw ContentError(path: path, line: first.number, message: "frontmatter must be key: value pairs")
                }
                for (key, value) in mapping {
                    if let name = key.string { values[name] = value }
                }
            }
        } catch let error as ContentError {
            throw error
        } catch {
            let summary = String(describing: error).split(separator: "\n").first.map(String.init) ?? "invalid YAML"
            throw ContentError(path: path, line: first.number, message: "invalid frontmatter: \(summary)")
        }
        return (Frontmatter(path: path, yamlLines: yamlLines, values: values), end + 1)
    }

    /// Line of `key:` in the file, or 1.
    func line(of key: String) -> Int {
        yamlLines.first { $0.text.hasPrefix("\(key):") }?.number ?? 1
    }

    func string(_ key: String) -> String? {
        guard let text = values[key]?.string?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return nil }
        return text
    }

    func requiredString(_ key: String) throws -> String {
        guard let text = string(key) else {
            throw ContentError(path: path, line: 1, message: "frontmatter needs `\(key)`")
        }
        return text
    }

    func int(_ key: String) throws -> Int? {
        guard let text = string(key) else { return nil }
        guard let number = Int(text) else {
            throw ContentError(path: path, line: line(of: key), message: "`\(key)` must be a number")
        }
        return number
    }

    /// A list (`[a, b]` or block form) or a single scalar; missing or empty gives [].
    func strings(_ key: String) throws -> [String] {
        guard let node = values[key] else { return [] }
        if let sequence = node.sequence {
            return try sequence.map { item in
                guard let text = item.string else {
                    throw ContentError(path: path, line: line(of: key), message: "`\(key)` must be a list of names")
                }
                return text
            }
        }
        if let text = string(key) { return [text] }
        return []
    }
}
