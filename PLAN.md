# CS — iPhone app for learning algorithms

Personal app. Read short lessons, run Python on device, solve exercises checked by tests, watch algorithms step through visually. Offline, no account, no backend.

## Decisions

| Area | Choice | Why |
|---|---|---|
| UI | SwiftUI, with UIKit where it matters | SwiftUI is faster to build lists, navigation, lesson pages and animated visualizations. UIKit only for the code editor, wrapped in `UIViewRepresentable`. |
| Editor | STTextView (`STTextViewUIKit`, TextKit 2) by Marcin Krzyżanowski | TextKit 2 native, gutter with line numbers, current-line highlight, plugin API. Check its license terms (has a commercial option). |
| Highlighting | STTextView-Plugin-Neon (Neon + SwiftTreeSitter + tree-sitter-python) | Incremental, accurate Python highlighting. Same author's plugin. |
| Python | Embedded CPython 3.14 (`Python.xcframework` from BeeWare Python-Apple-support) | Official iOS support since 3.13 (PEP 730). Real CPython, native speed, fully offline, full stdlib. |
| Python, fallback | Pyodide in a hidden `WKWebView` | Only if embedding becomes painful. Slower startup, needs local asset serving, JS bridge. |
| Lessons | Markdown files bundled in the app, rendered with Textual (successor to MarkdownUI) | Easy to write and diff. Code blocks become runnable cells. |
| Storage | SwiftData | Progress, saved code, review schedule. |
| Minimum iOS | 26 | Personal device only, so use the latest APIs. |
| Distribution | Xcode to own phone | Free Apple ID: re-sign every 7 days. Paid developer account: 1 year, plus TestFlight. App Store rules don't matter here. |

### Why not all UIKit
UIKit gives more control but much more code for the parts that are mostly layout. The only place SwiftUI is weak for this app is text editing, so UIKit goes there and nowhere else.

## Design: feels like Apple made it

Rule: use the system's components and defaults before drawing anything custom. If Apple has a control for it, use that control.

- **Structure**: `TabView` (Learn, Practice, Playground, Review) with the iOS 26 Liquid Glass tab bar. `NavigationStack` with large titles. Sheets with detents for hints, results and settings.
- **Materials**: Liquid Glass comes free with system bars, toolbars and sheets. Use `.glassEffect()` only on floating controls (Run button, visualizer playback bar). No custom gradients, shadows or cards.
- **Type**: SF Pro via system text styles (`.title`, `.body`, `.footnote`). SF Mono for code and console. No hard-coded sizes.
- **Color**: semantic colors only (`.primary`, `.secondary`, `Color(.systemBackground)`, grouped backgrounds). One accent color. Light and dark from day one. Editor theme follows Xcode's default light/dark.
- **Icons**: SF Symbols, with symbol effects (`.bounce` on pass, `.replace` on Run/Stop).
- **Lists**: `List` with `.insetGrouped` for topics and settings. Swipe actions, context menus, `ContentUnavailableView` for empty states.
- **Motion**: default SwiftUI springs. Visualizer uses `matchedGeometryEffect` for swaps.
- **Feedback**: `.sensoryFeedback(.success/.error)` on test results. No custom toasts.
- **Keyboard**: input accessory bar above the keyboard for `:`, `()`, `[]`, `{}`, indent, outdent, undo, run. Hardware keyboard shortcuts via `.keyboardShortcut` (⌘R run, ⌘. stop).
- **Copy**: short sentence-case labels, no taglines or helper text. If a screen needs explanation, fix the layout.
- **Reference apps**: Swift Playgrounds, Notes, Settings, Fitness. When unsure, do what they do.

## Features

### v1
1. Lesson reader: Markdown with runnable code blocks (tap Run, output inline).
2. Playground: editor + console. Run, stop, clear. Files saved locally.
3. Exercises: prompt, starter code, hidden tests. Pass/fail per test with the failing input shown.
4. Progress: completed lessons and exercises per topic.

### v2
5. Visuals: step-through execution, algorithm animations and inline lesson diagrams (see Visuals).
6. Review: daily queue of recall cards and re-solves, scheduled with FSRS.
7. On-device AI tutor (see below).
8. Complexity check: run a solution on growing inputs, plot time vs n (Swift Charts).

### Later
- Bundle `numpy`-free pure-Python helpers only; skip binary wheels unless needed.
- iPad layout (editor and lesson side by side).
- Generate new exercises with an LLM API, checked against a reference solution before saving.

## Python runtime design

```
SwiftUI views
   │ async run(code, tests)
PythonRuntime (Swift actor)
   │ owns one interpreter on a dedicated thread
CPython (embedded)
   ├─ app_support.py   stdout/stderr capture, test runner, tracer
   └─ stdlib
```

- **Startup**: initialize once at launch on a background thread with `PyConfig` (isolated, `home` = bundled `python/`). Warm import of the support module.
- **Isolation per run**: fresh `dict` as globals for each run, so runs don't leak state. Full interpreter reset isn't needed.
- **Output**: replace `sys.stdout`/`sys.stderr` with a writer that calls back into Swift (via a small C extension or `ctypes` callback), streamed to the console.
- **Stop / infinite loops**: `PyThreadState_SetAsyncExc` raising `KeyboardInterrupt` on the run thread, plus a timeout per exercise test. Recursion limit kept at default.
- **Input**: `input()` patched to request a line from the UI and block until answered.
- **Tests**: exercises ship a test file; `app_support.run_tests(user_code, tests)` returns JSON (name, passed, input, expected, got, error, duration).
- **Visuals**: execution tracing and `viz` frames, see Visuals.

## Visuals

One diagram vocabulary, drawn natively in SwiftUI, used in three places. Same look in lessons, step-through and animations.

### Shapes

| Shape | Drawn as | Used for |
|---|---|---|
| Array | Row of cells, index labels, named pointers (`i`, `lo`, `hi`) above cells, ranges shaded | Two pointers, sliding window, sorting, binary search |
| Grid | Table with row/col labels, filled cells, arrows to dependencies | DP tables, matrices, BFS on grids |
| Linked list | Boxes with `next` arrows | Linked lists, reversal |
| Tree | Layered layout, highlighted nodes/edges | BST, heaps, recursion trees, tries |
| Graph | Nodes and edges, weights, visited/frontier colors | BFS, DFS, Dijkstra, MST |
| Hash table | Buckets with chains | Hashing |
| Stack / queue | Vertical stack, horizontal queue | Stacks, queues, call stack |
| Call tree | Tree of calls with args and return values; repeated calls dimmed | Recursion, memoization |
| Bits | Row of 0/1 cells, grouped by byte | Bit manipulation, number representation |
| Plot | Swift Charts line chart | Big-O growth, measured runtimes |

Layout: trees with a simple tidy-tree algorithm; graphs use positions from the content file or a circular/layered layout. No layout library.

### 1. Step-through execution

Run any code and step through it line by line, forward and back.

- **Screen**: code on top with the current line highlighted, below it the frames (one card per function call, local variables) and the objects they point to, with arrows for references. Scrubber at the bottom with step back/forward and play.
- **Shows**: aliasing (`b = a` → two arrows to one list), mutation, the call stack growing and shrinking in recursion, return values.
- **How**: `sys.monitoring` (Python 3.12+, faster than `settrace`) records a snapshot per line in user code: frames, locals, and the reachable object graph by `id()`. Sent to Swift as JSON once the run ends.
- **Shape detection**: lists draw as arrays, lists of lists as grids, dicts as tables, objects with `left`/`right` as trees, objects with `next` as linked lists.
- **Limits**: stop at 1,000 steps, skip stdlib frames, show the first 50 items of a big container.

### 2. Algorithm animations

The `viz` module for hand-picked moments, where step-through is too low-level.

- `viz.array(a, pointers={"i": i, "j": j}, range=(lo, hi))`, `viz.grid(dp, highlight=(r, c))`, `viz.tree(root, active=node)`, `viz.graph(adj, visited=seen, frontier=queue)`, `viz.note("swap")`.
- Each call adds a frame; Swift animates between frames with `matchedGeometryEffect` (cells move when swapped, pointers slide).
- Lessons ship animations as code, so they double as runnable examples.

### 3. Lesson diagrams

Small static diagrams inside lesson text, written as fenced blocks:

````
```diagram
array [1, 3, 5, 7, 9, 11]
pointer lo 0
pointer mid 2
pointer hi 5
shade 3..5
```
````

- Rendered by the same SwiftUI views, so they match the theme and dark mode.
- Diffable text, no image files.
- Tap a diagram to open it full screen; if it has a `code` field, run it into a step-through.

## Content

Format, one folder per lesson:

```
content/
  03-binary-search/
    lesson.md        # prose + ```python cells
    exercises.yaml   # id, prompt, starter, tests, hints, solution
    cards.yaml       # review questions
```

Curriculum (first pass):
1. Complexity: Big-O, amortized cost
2. Arrays and strings: two pointers, sliding window, prefix sums
3. Hashing
4. Stacks and queues, monotonic stack
5. Linked lists
6. Recursion and backtracking
7. Sorting: insertion, merge, quick, heap, counting
8. Binary search, on answers too
9. Trees: traversal, BST, balanced trees overview
10. Heaps and priority queues
11. Graphs: BFS, DFS, topological sort
12. Shortest paths: Dijkstra, Bellman-Ford, Floyd-Warshall
13. Union-find, MST
14. Dynamic programming: 1D, 2D, knapsack, LIS, intervals
15. Greedy
16. Tries, segment trees, Fenwick trees
17. Bits and number representation
18. Extras: how CPython runs code, memory, caching

Write lessons in my own words (draft with Claude, then edit). Don't copy textbook text.

## How the curriculum works

**Structure**: Track → Unit → Lesson → Step.
- Tracks: Algorithms, CS foundations.
- Unit: one topic from the list above, with `requires: [unit ids]`. Prerequisites suggest the next unit; nothing is locked.
- Lesson: 5–10 minutes, one idea.
- Step: the smallest thing on screen. A lesson is a sequence of steps.

**Step types**

| Step | What happens | Checked by |
|---|---|---|
| Read | Short prose, runnable code cell | — |
| Predict | "What does this print?" Answer, then run to see | String match |
| Trace | Step through the visualizer, answer "what's in the array after step 3?" | Value match |
| Arrange | Reorder shuffled lines into a working function (Parsons problem) | Tests |
| Implement | Write the function from starter code | Hidden tests, edge cases |
| Analyze | Pick the time/space complexity | Choice |

Predict before run, and trace before implement: reading and predicting code builds the model that writing code needs.

**Exercises per unit**: warm-up → core → stretch. Hints unlock one at a time (nudge, approach, near-solution), then the solution. Seeing the solution marks the exercise for re-solve later.

**Progress per unit**: New → Learning (lessons started) → Practiced (core exercises pass) → Mastered (review cards stable over weeks per FSRS).

**Review**: one daily queue, mixing
- recall cards (concepts, complexities, invariants)
- re-solving an old exercise from a blank editor
- interleaved problems that don't say which technique to use.

**Content rules**
- Stable slug ids for units, lessons, exercises and cards, so edits never reset progress.
- Every exercise has a reference solution. CI in this repo runs every solution against its tests with CPython 3.14 on Linux, so broken content never reaches the app.
- Content is versioned with the app; no download server.

## Project layout

See `CLAUDE.md` (Architecture for parallel work). The app target is thin; areas live as targets in a local `CSKit` Swift package, with shared types in `Contracts`.

Highlighting: STTextView-Plugin-Neon with tree-sitter-python. Map tree-sitter capture names to Xcode's default theme colors.

## Libraries

| Need | Library | License |
|---|---|---|
| Python runtime | `Python.xcframework` (BeeWare Python-Apple-support, 3.14) | PSF |
| Editor | STTextView (`STTextViewUIKit`) | GPLv3 or commercial |
| Highlighting | STTextView-Plugin-Neon → Neon, SwiftTreeSitter, tree-sitter-python | MIT / BSD-3 / MIT |
| Bracket pairing, auto-indent | STTextView-Plugin-TextFormation (TextFormation) | MIT / BSD-3 |
| Lesson Markdown | Textual | MIT |
| Content files | Yams (YAML) | MIT |
| Spaced repetition | open-spaced-repetition/swift-fsrs (FSRS-5; last push Dec 2024) or port FSRS-6, ~200 lines | MIT |

Apple frameworks, no dependency: SwiftData (+ CloudKit sync), Swift Charts (complexity plots), Foundation Models (on-device hints), App Intents, WidgetKit, Core Spotlight. Skip TipKit (it adds helper text).

Keep the list this short. Visuals, test runner and console are custom; no libraries for those.

## On-device AI tutor (Foundation Models)

Apple's on-device model (~3B parameters, iOS 26, needs an Apple Intelligence iPhone). Offline, free, private. Small, so it explains and nudges; tests and reference solutions stay the source of truth. Never grades.

Features, in order of value:
1. **Explain a failure**: on a failed test, send the code, the failing input, expected vs got, and the traceback. Get a short explanation of what went wrong, without fixed code.
2. **Hint ladder**: when the hand-written hints run out, generate one more nudge from the exercise, the reference solution (hidden from the user) and the current code. Instruction: point at the idea, don't write code.
3. **Explain this line**: select code in a lesson or the editor, ask what it does.
4. **Review grading help**: for free-text recall cards, compare the answer to the card's answer and suggest Again/Hard/Good/Easy. The user confirms.
5. **Variations**: generate new test inputs or a twist on a solved exercise. Validate by running the reference solution before showing.

Design:
- `@Generable` structs for every response (e.g. `Hint { text, focusLine? }`), so output is typed, not parsed.
- Tools the model can call: `runCode(code, input)` and `runTests()` against the embedded Python, so explanations are checked against real execution.
- Short prompts with the lesson's key idea included; the model's context is small (~4k tokens), so send only the relevant function, not whole files.
- Stream responses into a sheet. A "Tutor" button appears only when `SystemLanguageModel.default.availability` is available.
- Prompts live in one Swift file, tested with fixed examples from the content repo.

## Other things to decide

- **Sync**: SwiftData with CloudKit so iPhone and iPad share progress. Decide at milestone 5; adding it later means model constraints (all properties optional or defaulted, no unique constraints).
- **Export**: progress and saved code as JSON, so a schema change or reinstall loses nothing.
- **Timing**: complexity plots need repeated runs and a warm-up; show shape, not exact numbers.
- **User code access**: Python can read/write app files. Fine for personal use; run code with the working directory set to a scratch folder.
- **iPad**: plan layouts with `NavigationSplitView` from the start even if iPhone ships first.
- **Content tooling**: write on Mac in any editor; a script validates YAML, runs solutions, and lints Markdown. Run it in CI.

## Milestones

1. **Hello Python**: Xcode project, embed `Python.xcframework`, run `print(sum(range(10)))` from a button. Verify on device. This is the riskiest step; do it first.
2. **Playground**: STTextView editor with Neon highlighting, streamed output, stop button, saved files. Check typing, selection and keyboard behavior on device early; STTextView is macOS-first.
3. **Lessons**: content loader, Markdown rendering, runnable cells. Write lessons 1–3.
4. **Exercises**: YAML loader, test runner, results view. 5 exercises per lesson.
5. **Progress**: SwiftData models, topic list with completion.
6. **Visuals**: array and grid views, lesson diagram blocks, step-through with frames and arrows, then `viz` animations, trees, graphs.
7. **Review + complexity plots**.
8. Remaining content, ongoing.

## Risks

- Embedding friction (signing `.so` extension modules, build phase script). Mitigation: follow the CPython iOS guide exactly; milestone 1 is a spike.
- App size: stdlib is tens of MB. Fine for personal use; strip `test/`, `idlelib/`, `tkinter/`.
- Killing runaway C-level loops: async exceptions only fire between bytecodes. Acceptable for learning code.
- Content is the real work. Budget more time for lessons than for code.

## Development note

iOS builds need a Mac with Xcode. This repo can hold the plan and content anywhere; building and running happens on the Mac.

## References

- Using Python on iOS: https://docs.python.org/3.14/using/ios.html
- BeeWare Python-Apple-support: https://github.com/beeware/Python-apple-support
- Textual: https://github.com/gonzalezreal/textual
- STTextView: https://github.com/krzyzanowskim/STTextView
- STTextView-Plugin-Neon: https://github.com/krzyzanowskim/STTextView-Plugin-Neon
- Neon: https://github.com/ChimeHQ/Neon
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines
- Pyodide offline on iOS discussion: https://github.com/pyodide/pyodide/discussions/2188
