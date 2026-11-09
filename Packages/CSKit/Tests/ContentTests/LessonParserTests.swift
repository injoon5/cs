import Foundation
import Testing
import Contracts
@testable import Content

/// The example lesson from PLAN.md, verbatim.
let planLesson = """
---
id: halving
title: Halving the range
---

One comparison with the middle throws away half the candidates.

```python
nums = [1, 3, 5, 7, 9, 11]
print(nums[len(nums) // 2])
```

---

```python trace stop=4
lo, hi = 0, 5
while lo <= hi:
    mid = (lo + hi) // 2
    ...
```

What is `mid` now?

- [ ] 1
- [x] 2
- [ ] 5

---

```python predict
print([1, 2, 3][1:])
```

---

Binary search on a sorted list of length n is

- [ ] O(n)
- [x] O(log n)

---

[First true](exercises/first-true.md)
"""

private func parse(
    _ source: String,
    exercises: [String: String] = ["exercises/first-true.md": "first-true"],
    recorded: @escaping RecordedLookup = { _ in nil }
) throws -> Lesson {
    try LessonParser.parse(source, path: "lesson.md", resolveExercise: { exercises[$0] }, recorded: recorded)
}

/// A lesson body wrapped in frontmatter.
private func lesson(_ body: String) -> String {
    "---\nid: t\ntitle: T\n---\n\n\(body)\n"
}

private func code(_ language: CodeLanguage, _ role: CodeRole, _ source: String) -> Block {
    .code(CodeBlock(language: language, role: role, source: source))
}

@Suite struct LessonParserTests {
    @Test func planExample() throws {
        let result = try parse(planLesson)
        #expect(result.id == "halving")
        #expect(result.title == "Halving the range")
        #expect(result.steps == [
            Step(kind: .read, blocks: [
                .markdown("One comparison with the middle throws away half the candidates."),
                code(.python, .cell, "nums = [1, 3, 5, 7, 9, 11]\nprint(nums[len(nums) // 2])"),
            ]),
            Step(kind: .trace, blocks: [
                code(.python, .trace(stop: 4), "lo, hi = 0, 5\nwhile lo <= hi:\n    mid = (lo + hi) // 2\n    ..."),
                .markdown("What is `mid` now?"),
                .choice(ChoiceQuestion(options: [
                    .init(text: "1", isCorrect: false),
                    .init(text: "2", isCorrect: true),
                    .init(text: "5", isCorrect: false),
                ])),
            ]),
            Step(kind: .predict, blocks: [code(.python, .predict, "print([1, 2, 3][1:])")]),
            Step(kind: .analyze, blocks: [
                .markdown("Binary search on a sorted list of length n is"),
                .choice(ChoiceQuestion(options: [
                    .init(text: "O(n)", isCorrect: false),
                    .init(text: "O(log n)", isCorrect: true),
                ])),
            ]),
            Step(kind: .implement, blocks: [.exercise(id: "first-true")]),
        ])
    }

    // MARK: Step splitting

    @Test func dashesUnderTextAreAHeading() throws {
        let result = try parse(lesson("Title\n---\n\nMore text."))
        #expect(result.steps.count == 1)
        #expect(result.steps[0].blocks == [.markdown("Title\n---\n\nMore text.")])
    }

    @Test func dashesNeedBlankLineOnBothSides() throws {
        #expect(try parse(lesson("One\n\n---\nTwo")).steps.count == 1)
        #expect(try parse(lesson("One\n---\n\nTwo")).steps.count == 1)
        #expect(try parse(lesson("One\n\n---\n\nTwo")).steps.count == 2)
    }

    @Test func dashesInsideFencesDoNotSplit() throws {
        let result = try parse(lesson("```python\na = 1\n\n---\n\nb = 2\n```"))
        #expect(result.steps.count == 1)
        #expect(result.steps[0].blocks == [code(.python, .cell, "a = 1\n\n---\n\nb = 2")])
    }

    @Test func emptyStepsAreDropped() throws {
        let result = try parse(lesson("One\n\n---\n\n---\n\nTwo\n\n---\n"))
        #expect(result.steps.count == 2)
    }

    @Test func frontmatterIsNotAStep() throws {
        let result = try parse("---\nid: a\ntitle: A\n---\nText\n\n---\n\nMore")
        #expect(result.steps.count == 2)
    }

    @Test func crlfLineEndings() throws {
        let source = lesson("One\n\n---\n\n```python\nx = 1\n```").replacingOccurrences(of: "\n", with: "\r\n")
        let result = try parse(source)
        #expect(result.steps.count == 2)
        #expect(result.steps[1].blocks == [code(.python, .cell, "x = 1")])
    }

    // MARK: Fences

    @Test func longerFencesContainShorterOnes() throws {
        let body = "````python\nprint(\"\"\"\n```\ninner\n```\n\"\"\")\n````"
        let result = try parse(lesson(body))
        #expect(result.steps[0].blocks == [code(.python, .cell, "print(\"\"\"\n```\ninner\n```\n\"\"\")")])
    }

    @Test func tildeFences() throws {
        let result = try parse(lesson("~~~python\nx = 1\n~~~"))
        #expect(result.steps[0].blocks == [code(.python, .cell, "x = 1")])
    }

    @Test func otherLanguagesStayProse() throws {
        let body = "Before.\n\n```text\n- [x] not a choice\n[Ex](exercises/first-true.md)\n```\n\nAfter."
        let result = try parse(lesson(body))
        #expect(result.steps[0].kind == .read)
        #expect(result.steps[0].blocks == [
            .markdown("Before.\n\n```text\n- [x] not a choice\n[Ex](exercises/first-true.md)\n```\n\nAfter."),
        ])
    }

    @Test func fenceWithoutLanguageIsProse() throws {
        let result = try parse(lesson("```\nplain\n```"))
        #expect(result.steps[0].blocks == [.markdown("```\nplain\n```")])
    }

    @Test func indentedFenceIsDedented() throws {
        let result = try parse(lesson("  ```python\n  if x:\n      y\n  ```"))
        #expect(result.steps[0].blocks == [code(.python, .cell, "if x:\n    y")])
    }

    @Test func unclosedFenceReportsOpeningLine() {
        let error = contentError { try parse(lesson("Text\n\n```python\nx = 1")) }
        #expect(error?.line == 8)
        #expect(error?.path == "lesson.md")
        #expect(error?.message.contains("never closed") == true)
    }

    @Test func unknownPythonModifierIsAnError() {
        let error = contentError { try parse(lesson("```python predct\nx\n```")) }
        #expect(error?.line == 6)
        #expect(error?.message.contains("predct") == true)
    }

    // MARK: Blocks

    @Test func codeBlockRoles() throws {
        let cases: [(String, CodeLanguage, CodeRole, StepKind)] = [
            ("python", .python, .cell, .read),
            ("python trace", .python, .trace(stop: nil), .trace),
            ("python trace stop=0", .python, .trace(stop: 0), .trace),
            ("python predict", .python, .predict, .predict),
            ("python arrange", .python, .arrange, .arrange),
            ("python tests", .python, .tests, .read),
            ("tests", .python, .tests, .read),
            ("shell", .shell, .cell, .read),
            ("shell check", .shell, .check, .read),
        ]
        for (info, language, role, kind) in cases {
            let result = try parse(lesson("```\(info)\nx\n```"))
            #expect(result.steps[0].blocks == [code(language, role, "x")], "\(info)")
            #expect(result.steps[0].kind == kind, "\(info)")
        }
    }

    @Test func badTraceOptions() {
        #expect(contentError { try parse(lesson("```python trace stop=x\nx\n```")) } != nil)
        #expect(contentError { try parse(lesson("```python trace speed=2\nx\n```")) } != nil)
    }

    @Test func choiceKeepsProseBeforeAsMarkdown() throws {
        let result = try parse(lesson("Which?\n\n- [x] A\n- [X] B\n- [ ] C\n\nAfter."))
        #expect(result.steps[0].blocks == [
            .markdown("Which?"),
            .choice(ChoiceQuestion(options: [
                .init(text: "A", isCorrect: true),
                .init(text: "B", isCorrect: true),
                .init(text: "C", isCorrect: false),
            ])),
            .markdown("After."),
        ])
        guard case .choice(let question) = result.steps[0].blocks[1] else { return }
        #expect(question.allowsMultiple)
    }

    @Test func choiceNeedsACorrectOption() {
        let error = contentError { try parse(lesson("Which?\n\n- [ ] A\n- [ ] B")) }
        #expect(error?.line == 8)
        #expect(error?.message.contains("no correct option") == true)
    }

    @Test func plainBulletsAreNotChoices() throws {
        let result = try parse(lesson("- one\n- two"))
        #expect(result.steps[0].blocks == [.markdown("- one\n- two")])
    }

    @Test func exerciseLinkResolvesToFrontmatterID() throws {
        let result = try parse(lesson("[Go](./exercises/first-true.md)"), exercises: ["exercises/first-true.md": "ft"])
        #expect(result.steps[0].blocks == [.exercise(id: "ft")])
        #expect(result.steps[0].kind == .implement)
    }

    @Test func linkInsideASentenceStaysProse() throws {
        let result = try parse(lesson("Try [it](exercises/first-true.md) now."))
        #expect(result.steps[0].blocks == [.markdown("Try [it](exercises/first-true.md) now.")])
    }

    @Test func otherLinksAloneStayProse() throws {
        let result = try parse(lesson("[Docs](https://example.com/exercises/a.md)\n\n[Notes](notes.md)"))
        #expect(result.steps[0].blocks == [.markdown("[Docs](https://example.com/exercises/a.md)\n\n[Notes](notes.md)")])
    }

    @Test func unresolvedExerciseLink() {
        let error = contentError { try parse(lesson("Text\n\n[Go](exercises/missing.md)")) }
        #expect(error?.line == 8)
        #expect(error?.message.contains("exercises/missing.md") == true)
    }

    @Test func proseAroundBlocksMerges() throws {
        let result = try parse(lesson("One.\n\nTwo.\n\n```python\nx\n```\n\nThree.\n\n\nFour."))
        #expect(result.steps[0].blocks == [
            .markdown("One.\n\nTwo."),
            code(.python, .cell, "x"),
            .markdown("Three.\n\n\nFour."),
        ])
    }

    @Test func stepKindPriority() throws {
        // arrange with a linked exercise is still arrange
        let arrange = try parse(lesson("```python arrange\nx\n```\n\n[Go](exercises/first-true.md)"))
        #expect(arrange.steps[0].kind == .arrange)
        // a choice next to a predict block stays predict
        let predict = try parse(lesson("```python predict\nx\n```\n\n- [x] a\n- [ ] b"))
        #expect(predict.steps[0].kind == .predict)
        // diagrams and prose alone are read
        let diagram = try parse(lesson("```diagram\narray [1]\n```"))
        #expect(diagram.steps[0].kind == .read)
    }

    @Test func diagramBlock() throws {
        let result = try parse(lesson("```diagram\narray [1, 2]\npointer i 1\n```"))
        #expect(result.steps[0].blocks == [
            .diagram(Diagram(shapes: [.array(ArrayShape(values: ["1", "2"], pointers: [Pointer(name: "i", index: 1)]))])),
        ])
    }

    @Test func diagramErrorsUseFileLines() {
        let error = contentError { try parse(lesson("Text\n\n```diagram\narray [1, 2]\nshade 5..6\n```")) }
        // Fence opens on line 8; the bad line is the 2nd line of the block.
        #expect(error?.line == 10)
        #expect(error?.path == "lesson.md")
    }

    // MARK: Recorded outputs

    @Test func recordedOutputAndTrace() throws {
        let predictHash = RecordedHash.hash(source: "print(1)")
        let traceHash = RecordedHash.hash(source: "x = 1")
        let recorded: RecordedLookup = { hash in
            switch hash {
            case predictHash: RecordedEntry(output: "1\n")
            case traceHash: RecordedEntry(hasTrace: true)
            default: nil
            }
        }
        let result = try parse(lesson("```python predict\nprint(1)  \n```\n\n---\n\n```python trace\nx = 1\n```\n\n---\n\n```python predict\nprint(2)\n```"), recorded: recorded)
        guard case .code(let predict) = result.steps[0].blocks[0],
              case .code(let trace) = result.steps[1].blocks[0],
              case .code(let missing) = result.steps[2].blocks[0] else {
            Issue.record("unexpected blocks")
            return
        }
        #expect(predict.recordedOutput == "1\n")
        #expect(trace.recordedTrace == "_recorded/\(traceHash).json")
        #expect(trace.recordedOutput == nil)
        #expect(missing.recordedOutput == nil)
    }

    // MARK: Frontmatter

    @Test func frontmatterErrors() {
        #expect(contentError { try parse("Just text") }?.line == 1)
        #expect(contentError { try parse("---\ntitle: T\n---\n\nText") }?.message.contains("id") == true)
        #expect(contentError { try parse("---\nid: a\ntitle: A\n\nText") }?.message.contains("never closed") == true)
        #expect(contentError { try parse("---\nid: a\ntitle: A\n---\n\n") }?.message.contains("no steps") == true)
    }

    @Test func errorDescriptionIsCompilerStyle() {
        let error = ContentError(path: "a/b.md", line: 3, message: "bad")
        #expect(error.description == "a/b.md:3: bad")
        #expect(ContentError(line: 2, message: "bad").description == "line 2: bad")
    }
}
