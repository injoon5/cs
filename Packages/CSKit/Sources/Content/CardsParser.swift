import Foundation
import Contracts

/// Parses `cards.md`: each `##` heading is a question, the text up to the next `##` the answer.
/// Text before the first `##` (a title, say) is ignored. Ids are `<unit id>/<slug>`.
public enum CardsParser {
    public static func parse(_ source: String, path: String, unitID: String) throws -> [Card] {
        var lines = SourceLines.split(source)
        if let (_, bodyStart) = try Frontmatter.extract(from: lines, path: path) {
            lines = Array(lines[bodyStart...])
        }
        let pieces = try MarkdownScanner.pieces(lines, path: path)

        var cards: [Card] = []
        var seen: Set<String> = []
        var question: (text: String, line: Int)?
        var answer: [String] = []

        func finish() throws {
            guard let question else { return }
            let text = LessonParser.trimmedProse(answer)
            guard !text.isEmpty else {
                throw ContentError(path: path, line: question.line, message: "card has no answer")
            }
            let slug = Self.slug(question.text)
            guard !slug.isEmpty else {
                throw ContentError(path: path, line: question.line, message: "question needs letters or digits to make an id")
            }
            let id = "\(unitID)/\(slug)"
            guard seen.insert(id).inserted else {
                throw ContentError(path: path, line: question.line, message: "duplicate card id `\(id)`")
            }
            cards.append(Card(id: id, question: question.text, answer: text))
        }

        for piece in pieces {
            switch piece {
            case .text(let line):
                if let heading = MarkdownScanner.heading(line.text), heading.level == 2 {
                    try finish()
                    guard !heading.title.isEmpty else {
                        throw ContentError(path: path, line: line.number, message: "empty question")
                    }
                    question = (heading.title, line.number)
                    answer = []
                } else if question != nil {
                    answer.append(line.text)
                }
            case .fence(let fence):
                if question != nil { answer.append(contentsOf: fence.raw.map(\.text)) }
            }
        }
        try finish()
        return cards
    }

    /// Lowercase ASCII letters and digits, with runs of anything else collapsed to one hyphen.
    public static func slug(_ text: String) -> String {
        var out = ""
        var pendingHyphen = false
        for char in text {
            if char.isASCII, char.isLetter || char.isNumber {
                if pendingHyphen, !out.isEmpty { out.append("-") }
                pendingHyphen = false
                out.append(contentsOf: char.lowercased())
            } else {
                pendingHyphen = true
            }
        }
        return out
    }
}
