import Foundation
import Testing
import Contracts
@testable import Content

/// The example exercise from PLAN.md, verbatim.
let planExercise = """
---
id: first-true
title: First true
level: core          # warmup | core | stretch
---

Return the index of the first `True` in a sorted list of booleans, or `len(xs)` if there is none.

```python starter
def first_true(xs):
    pass
```

```tests
first_true([False, False, True]) == 2
first_true([]) == 0
first_true([True] * 5) == 0
```

```python solution
def first_true(xs):
    lo, hi = 0, len(xs)
    while lo < hi:
        mid = (lo + hi) // 2
        if xs[mid]: hi = mid
        else: lo = mid + 1
    return lo
```

## Hints

1. The answer is a boundary between two runs.
2. Keep `lo` on the last known `False` side and `hi` on the `True` side.
3. Stop when `lo == hi`.
"""

@Suite struct ExerciseParserTests {
    @Test func planExample() throws {
        let exercise = try ExerciseParser.parse(planExercise, path: "e.md")
        #expect(exercise == Exercise(
            id: "first-true",
            title: "First true",
            level: .core,
            language: .python,
            prompt: "Return the index of the first `True` in a sorted list of booleans, or `len(xs)` if there is none.",
            starter: "def first_true(xs):\n    pass",
            solution: "def first_true(xs):\n    lo, hi = 0, len(xs)\n    while lo < hi:\n        mid = (lo + hi) // 2\n        if xs[mid]: hi = mid\n        else: lo = mid + 1\n    return lo",
            testLines: ["first_true([False, False, True]) == 2", "first_true([]) == 0", "first_true([True] * 5) == 0"],
            pythonTests: nil,
            hints: [
                "The answer is a boundary between two runs.",
                "Keep `lo` on the last known `False` side and `hi` on the `True` side.",
                "Stop when `lo == hi`.",
            ]
        ))
    }

    @Test func testsSkipBlankLinesAndComments() throws {
        let source = planExercise.replacingOccurrences(
            of: "first_true([]) == 0\n",
            with: "\n# edge cases\n  first_true([]) == 0  \n\n"
        )
        let exercise = try ExerciseParser.parse(source, path: "e.md")
        #expect(exercise.testLines == ["first_true([False, False, True]) == 2", "first_true([]) == 0", "first_true([True] * 5) == 0"])
    }

    @Test func pythonTestsBlock() throws {
        let source = """
        ---
        id: x
        title: X
        level: warmup
        ---

        Do it.

        ```python starter
        def f(): pass
        ```

        ```python tests
        import random
        assert f() is None
        ```

        ```python solution
        def f(): return None
        ```
        """
        let exercise = try ExerciseParser.parse(source, path: "e.md")
        #expect(exercise.testLines == [])
        #expect(exercise.pythonTests == "import random\nassert f() is None")
        #expect(exercise.level == .warmup)
        #expect(exercise.hints == [])
    }

    @Test func shellExercise() throws {
        let source = """
        ---
        id: make-dir
        title: Make a directory
        level: warmup
        ---

        Create `~/notes`.

        ```shell setup
        rm -rf ~/notes
        ```

        ```shell check
        test -d ~/notes
        ```

        ```shell solution
        mkdir ~/notes
        ```
        """
        let exercise = try ExerciseParser.parse(source, path: "e.md")
        #expect(exercise.language == .shell)
        #expect(exercise.setup == "rm -rf ~/notes")
        #expect(exercise.check == "test -d ~/notes")
        #expect(exercise.solution == "mkdir ~/notes")
        #expect(exercise.starter == "")
        #expect(exercise.testLines == [])
    }

    @Test func promptKeepsExampleFencesButStopsAtFirstPart() throws {
        let source = planExercise.replacingOccurrences(
            of: "if there is none.\n",
            with: "if there is none.\n\n```text\nfirst_true([False, True]) -> 1\n```\n\nNo sorting needed.\n"
        )
        let exercise = try ExerciseParser.parse(source, path: "e.md")
        #expect(exercise.prompt.hasSuffix("```text\nfirst_true([False, True]) -> 1\n```\n\nNo sorting needed."))
        #expect(!exercise.prompt.contains("def first_true"))
    }

    @Test func hintsSupportContinuationLines() throws {
        let source = planExercise.replacingOccurrences(of: "3. Stop when `lo == hi`.", with: "3. Stop when\n   `lo == hi`.\n4) One more.")
        let exercise = try ExerciseParser.parse(source, path: "e.md")
        #expect(exercise.hints.count == 4)
        #expect(exercise.hints[2] == "Stop when\n`lo == hi`.")
        #expect(exercise.hints[3] == "One more.")
    }

    @Test func errors() {
        func broken(_ edit: (String) -> String) -> ContentError? {
            contentError { try ExerciseParser.parse(edit(planExercise), path: "e.md") }
        }
        #expect(broken { $0.replacingOccurrences(of: "level: core", with: "level: hard") }?.message.contains("warmup, core, stretch") == true)
        #expect(broken { $0.replacingOccurrences(of: "level: core          # warmup | core | stretch\n", with: "") }?.message.contains("level") == true)
        #expect(broken { $0.replacingOccurrences(of: "```python solution", with: "```python scratch") }?.message.contains("scratch") == true)
        #expect(broken { $0.replacingOccurrences(of: "```python solution", with: "```python starter") }?.message.contains("second") == true)
        #expect(broken { $0.replacingOccurrences(of: "```tests", with: "```text") } != nil)
        #expect(broken { $0.replacingOccurrences(of: "1. The answer", with: "The answer") }?.line == 32)
        #expect(contentError { try ExerciseParser.parse("no frontmatter", path: "e.md") }?.line == 1)
    }
}

@Suite struct CardsParserTests {
    @Test func planExample() throws {
        let source = """
        ## What does `lo` mean when binary search ends?
        The first index where the predicate is true.
        """
        let cards = try CardsParser.parse(source, path: "cards.md", unitID: "binary-search")
        #expect(cards == [
            Card(
                id: "binary-search/what-does-lo-mean-when-binary-search-ends",
                question: "What does `lo` mean when binary search ends?",
                answer: "The first index where the predicate is true."
            ),
        ])
    }

    @Test func multipleCardsAndLongAnswers() throws {
        let source = """
        # Cards for the unit

        Ignored intro.

        ## First?

        Line one.

        ### Not a new card

        ```python
        ## not a heading
        ```

        ## Second? (O(log n))
        Short.
        """
        let cards = try CardsParser.parse(source, path: "cards.md", unitID: "u")
        #expect(cards.map(\.id) == ["u/first", "u/second-o-log-n"])
        #expect(cards[0].answer == "Line one.\n\n### Not a new card\n\n```python\n## not a heading\n```")
        #expect(cards[1].answer == "Short.")
    }

    @Test func slugs() {
        #expect(CardsParser.slug("What's  O(n log n)?") == "what-s-o-n-log-n")
        #expect(CardsParser.slug("  --Hello-- ") == "hello")
        #expect(CardsParser.slug("日本語") == "")
        #expect(CardsParser.slug("a1 B2") == "a1-b2")
    }

    @Test func errors() {
        #expect(contentError { try CardsParser.parse("## Q?\n\n## R?\nA", path: "c.md", unitID: "u") }?.line == 1)
        #expect(contentError { try CardsParser.parse("## Q?\nA\n## q!\nB", path: "c.md", unitID: "u") }?.message.contains("duplicate") == true)
        #expect(contentError { try CardsParser.parse("## ???\nA", path: "c.md", unitID: "u") } != nil)
        #expect(contentError { try CardsParser.parse("## \nA", path: "c.md", unitID: "u") } != nil)
    }
}
