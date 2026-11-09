import Foundation
import Contracts

/// Parses one exercise file (PLAN.md, "Authoring syntax").
///
/// - Frontmatter: `id`, `title`, `level` (warmup | core | stretch).
/// - Prompt: the prose before the first exercise block (starter, tests, solution, setup, check),
///   not counting `## Hints`. Fences of other kinds before that point (an example in ```text, a
///   plain ```python cell) stay in the prompt.
/// - ` ```python starter `, ` ```tests ` (one `call == expected` per line; blank lines and `#`
///   comments skipped), ` ```python tests `, ` ```python solution `.
/// - Linux exercises: ` ```shell setup `, ` ```shell check `, ` ```shell solution `.
/// - `## Hints`: a numbered list, in order.
public enum ExerciseParser {
    public static func parse(_ source: String, path: String) throws -> Exercise {
        let lines = SourceLines.split(source)
        guard let (frontmatter, bodyStart) = try Frontmatter.extract(from: lines, path: path) else {
            throw ContentError(path: path, line: 1, message: "exercise needs frontmatter with `id`, `title` and `level`")
        }
        let id = try frontmatter.requiredString("id")
        let title = try frontmatter.requiredString("title")
        let levelName = try frontmatter.requiredString("level")
        guard let level = ExerciseLevel(rawValue: levelName) else {
            let options = ExerciseLevel.allCases.map(\.rawValue).joined(separator: ", ")
            throw ContentError(path: path, line: frontmatter.line(of: "level"), message: "level must be one of: \(options)")
        }

        let pieces = try MarkdownScanner.pieces(Array(lines[bodyStart...]), path: path)

        var prompt: [String] = []
        var seenPart = false
        var inHints = false
        var hints: [[String]] = []
        var parts: [String: (source: String, line: Int)] = [:]
        var languages: Set<CodeLanguage> = []

        for piece in pieces {
            switch piece {
            case .text(let line):
                if let heading = MarkdownScanner.heading(line.text) {
                    inHints = heading.title.lowercased() == "hints"
                    if inHints { hints = []; continue }
                }
                if inHints {
                    try addHintLine(line, to: &hints, path: path)
                } else if !seenPart {
                    prompt.append(line.text)
                }
            case .fence(let fence):
                if inHints {
                    guard !hints.isEmpty else {
                        throw ContentError(path: path, line: fence.open.number, message: "hints must be a numbered list")
                    }
                    hints[hints.count - 1].append(contentsOf: fence.raw.map(\.text))
                    continue
                }
                let kind = try CodeInfo.parse(fence.info, path: path, line: fence.open.number)
                guard case .code(let language, let role) = kind, let key = partKey(role) else {
                    if !seenPart { prompt.append(contentsOf: fence.raw.map(\.text)) }
                    continue
                }
                seenPart = true
                let name = language == .shell ? "shell \(key)" : (key == "tests" && fence.info == "tests" ? "tests" : "python \(key)")
                if parts[name] != nil {
                    throw ContentError(path: path, line: fence.open.number, message: "second ```\(fence.info) block")
                }
                parts[name] = (fence.source, fence.open.number)
                languages.insert(language)
            }
        }

        guard languages.count <= 1 else {
            throw ContentError(path: path, line: 1, message: "mix of python and shell blocks")
        }
        let isShell = languages.contains(.shell)
        func need(_ name: String) throws -> String {
            guard let part = parts[name] else {
                throw ContentError(path: path, line: 1, message: "exercise needs a ```\(name) block")
            }
            return part.source
        }

        let promptText = LessonParser.trimmedProse(prompt)
        let hintTexts = hints.compactMap { LessonParser.trimmedProse($0) }

        if isShell {
            return Exercise(
                id: id, title: title, level: level, language: .shell,
                prompt: promptText, starter: "", solution: try need("shell solution"),
                setup: parts["shell setup"]?.source, check: try need("shell check"),
                hints: hintTexts
            )
        }

        let testLines = (parts["tests"]?.source ?? "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        let pythonTests = parts["python tests"]?.source
        guard !testLines.isEmpty || pythonTests != nil else {
            throw ContentError(path: path, line: 1, message: "exercise needs a ```tests or ```python tests block")
        }
        return Exercise(
            id: id, title: title, level: level, language: .python,
            prompt: promptText, starter: try need("python starter"), solution: try need("python solution"),
            testLines: testLines, pythonTests: pythonTests, hints: hintTexts
        )
    }

    private static func partKey(_ role: CodeRole) -> String? {
        switch role {
        case .starter: "starter"
        case .solution: "solution"
        case .tests: "tests"
        case .setup: "setup"
        case .check: "check"
        default: nil
        }
    }

    /// A line starting `1.` or `1)` begins a hint; other lines continue the current one.
    private static func addHintLine(_ line: Line, to hints: inout [[String]], path: String) throws {
        let trimmed = line.text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            if !hints.isEmpty { hints[hints.count - 1].append("") }
            return
        }
        let digits = trimmed.prefix(while: { $0.isASCII && $0.isNumber })
        let afterDigits = trimmed.dropFirst(digits.count)
        if !digits.isEmpty, afterDigits.hasPrefix(". ") || afterDigits.hasPrefix(") ") {
            hints.append([String(afterDigits.dropFirst(2)).trimmingCharacters(in: .whitespaces)])
        } else if hints.isEmpty {
            throw ContentError(path: path, line: line.number, message: "hints must be a numbered list")
        } else {
            hints[hints.count - 1].append(trimmed)
        }
    }
}

extension LessonParser {
    /// Joins lines and trims blank lines at both ends; nil if nothing is left.
    static func trimmedProse(_ lines: [String]) -> String {
        func blank(_ line: String) -> Bool { line.allSatisfy { $0 == " " || $0 == "\t" } }
        guard let first = lines.firstIndex(where: { !blank($0) }),
              let last = lines.lastIndex(where: { !blank($0) }) else { return "" }
        return lines[first...last].joined(separator: "\n")
    }
}
