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
- **Type**: SF Pro via system text styles (`.title`, `.body`, `.footnote`), so Dynamic Type works. SF Mono for code and console. No hard-coded sizes.
- **Color**: semantic colors only (`.primary`, `.secondary`, `Color(.systemBackground)`, grouped backgrounds). One accent color. Light and dark from day one. Editor theme follows Xcode's default light/dark.
- **Icons**: SF Symbols, with symbol effects (`.bounce` on pass, `.replace` on Run/Stop).
- **Lists**: `List` with `.insetGrouped` for topics and settings. Swipe actions, context menus, `ContentUnavailableView` for empty states.
- **Motion**: default SwiftUI springs. Visualizer uses `matchedGeometryEffect` for swaps. Respect Reduce Motion.
- **Feedback**: `.sensoryFeedback(.success/.error)` on test results. No custom toasts.
- **Keyboard**: input accessory bar above the keyboard for `:`, `()`, `[]`, `{}`, indent, outdent, undo, run. Hardware keyboard shortcuts via `.keyboardShortcut` (⌘R run, ⌘. stop).
- **Platform touches**: Spotlight indexing of lessons, App Intents ("Continue lesson"), a widget showing today's review count, Share sheet for code.
- **Copy**: short sentence-case labels, no taglines or helper text. If a screen needs explanation, fix the layout.
- **Reference apps**: Swift Playgrounds, Notes, Settings, Fitness. When unsure, do what they do.

## Features

### v1
1. Lesson reader: Markdown with runnable code blocks (tap Run, output inline).
2. Playground: editor + console. Run, stop, clear. Files saved locally.
3. Exercises: prompt, starter code, hidden tests. Pass/fail per test with the failing input shown.
4. Progress: completed lessons and exercises per topic.

### v2
5. Visualizer: step through an algorithm on arrays, trees and graphs. Python reports states, SwiftUI draws them (see below).
6. Review: short recall cards per lesson, scheduled with FSRS.
7. Complexity check: run a solution on growing inputs, plot time vs n (Swift Charts).

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
- **Visualizer hook**: algorithms call `viz.array(a, highlight=[i, j])`, `viz.tree(root)`, `viz.graph(adj, visited=…)`. Each call appends a frame; Swift receives the frame list and animates between them. Explicit calls beat `sys.settrace` guessing.

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

## Project layout

```
CS.xcodeproj
CS/
  App/            entry, navigation
  Lessons/        reader, Markdown + runnable cells
  Editor/         STTextView wrapper, Neon highlighting, keyboard accessory bar
  Runtime/        PythonRuntime actor, C bridge
  Exercises/      runner UI, results
  Visualizer/     frame model, array/tree/graph views
  Review/         FSRS scheduler, cards
  Store/          SwiftData models
Resources/
  python/         stdlib + app_support.py
  content/        lessons
Frameworks/
  Python.xcframework
```

Highlighting: STTextView-Plugin-Neon with tree-sitter-python. Map tree-sitter capture names to Xcode's default theme colors.

## Milestones

1. **Hello Python**: Xcode project, embed `Python.xcframework`, run `print(sum(range(10)))` from a button. Verify on device. This is the riskiest step; do it first.
2. **Playground**: STTextView editor with Neon highlighting, streamed output, stop button, saved files. Check typing, selection and keyboard behavior on device early; STTextView is macOS-first.
3. **Lessons**: content loader, Markdown rendering, runnable cells. Write lessons 1–3.
4. **Exercises**: YAML loader, test runner, results view. 5 exercises per lesson.
5. **Progress**: SwiftData models, topic list with completion.
6. **Visualizer**: `viz` module, array view with swaps and pointers, then trees and graphs.
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
