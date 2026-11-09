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
| Linux | v86 (x86 emulator, compiles to WebAssembly) in a hidden `WKWebView`, booting a small Buildroot image; Ghostty's terminal via libghostty-spm | A real kernel, so `/proc`, signals and permissions all behave correctly. WebKit's JIT runs it fast, and saved VM state starts in under a second. TinyEMU is the fallback. See Linux track. |
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
- **Motion**: default SwiftUI springs. Visualizer animates by stable identity and explicit positions (see Visuals, Rendering and performance).
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
- Linux track with a real emulated machine (see Linux track).
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

One diagram vocabulary, drawn natively in SwiftUI, used in three places. Same look in lessons, step-through and animations. Step-through comes in two sizes: an inline trace inside lesson text, and the full screen.

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

**Inline trace** (`python trace` blocks in lessons): a compact step-through that sits in the lesson.

- Code block, current line tinted with the accent color at low opacity (not an inverted bar). The tint slides between lines with a spring.
- Under the code: play/pause, back, forward, restart, and a speed menu (0.5×, 1×, 2×). The buttons are plain, not glass, because they sit inside content.
- Under the controls: one chip per variable, `name value`, in SF Mono. A changed value uses `.contentTransition(.numericText())` and a short tint. A list wider than the row shows as an array shape instead of a chip.
- Output appears below only once something prints. No empty-state label.
- The expand button opens the full step-through at the same step, using a zoom transition.
- Traces for lesson blocks are recorded by `tools/` at build time and bundled as JSON, so they appear instantly with no Python startup. Edit opens the code in the Playground, which traces live.

### 2. Algorithm animations

The `viz` module for hand-picked moments, where step-through is too low-level.

- `viz.array(a, pointers={"i": i, "j": j}, range=(lo, hi))`, `viz.grid(dp, highlight=(r, c))`, `viz.tree(root, active=node)`, `viz.graph(adj, visited=seen, frontier=queue)`, `viz.note("swap")`.
- Each call adds a frame; Swift animates between frames by element identity (cells move when swapped, pointers slide).
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

### Rendering and performance

Target: no hitches at 120 Hz on the oldest supported iPhone, while playing or scrubbing the worst case (1,000 steps, 50-cell array, 63-node tree, 30-node graph, 20×20 grid).

Drawn in plain SwiftUI. Scenes are small (under ~500 primitives, capped by the step-through limits), so Metal adds cost without benefit.

| Option | Verdict |
|---|---|
| SwiftUI views | Use for anything that moves or is tapped: cells, nodes, pointers, frames. Free springs, Dynamic Type, VoiceOver, dark mode. |
| `Canvas` | Use for dense static layers: grid cells, bit rows, background lanes. Text via `context.resolve`. Not animatable per element and no per-element accessibility, so never for moving parts. |
| `Shape` with `animatableData` | Use for edges and arrows, so endpoints follow nodes during a spring. |
| Swift Charts | Plot shape only. |
| Metal / SpriteKit | Rejected. Own render loop, no system text or accessibility; SpriteKit inside SwiftUI has reported iOS 26 frame drops. Reconsider only if Instruments shows a case Canvas can't hit. |
| Grape (force-directed graphs) | Rejected. Force layouts shift between frames; step-through needs nodes to stay put. |

Rules:
- **Layout is data.** A Foundation-only layout step turns each frame into positions and sizes (tidy tree, layered/circular graph, array cells). It runs off the main actor once per run, and every frame's layout is cached. Scrubbing is an array lookup, never a relayout. Unit-tested on Linux.
- **Views place, they don't measure.** `.position`/`.offset` from the cached layout. No `GeometryReader`, anchor preferences or `onGeometryChange` inside diagrams; arrows read the same cached points.
- **Stable identity.** `ForEach` keyed by element id, so a swap is two position changes under one spring. Traced objects use Python `id()` (the tracer holds references so ids aren't reused mid-run). Array cells get ids by matching equal values between consecutive frames, nearest index first, in the layout step; index-based ids would turn a swap into two value changes. `matchedGeometryEffect` only when an element moves between containers (e.g. array to stack).
- **No identity flips.** State changes (highlight, visited, dimmed) are modifiers on the same view, not `if/else` branches. No `AnyView`.
- **Narrow inputs.** Leaf views take small `Equatable` values (cell value, role, position), not the model. The `@Observable` player exposes `currentIndex`; only the diagram root reads it.
- **Fixed geometry.** Cell size depends on the widest value in the whole run, not the current frame, so nothing reflows mid-animation. `.monospacedDigit()` on values and indices.
- **Scrubbing vs. playing.** Dragging the scrubber updates without animation; step, play and release use a spring. Springs are interruptible, so fast taps never queue.
- **Reduce Motion.** Moves become crossfades.
- **Lessons.** Diagrams inside lesson text are static, laid out once and cached by block hash.
- **Measure, don't guess.** A debug-only benchmark screen loads the worst-case fixtures above. Profile with the Instruments SwiftUI template (Xcode 26) on device: no long view-body updates, no hitches. Try `drawingGroup()` only where a measurement shows it helps.

## Content

### Authoring syntax

Plain Markdown that renders readably on GitHub. One rule: prose is Markdown, and anything the app runs, draws or checks is a fenced block whose info string says what it is. No YAML files except frontmatter.

```
content/
  algorithms/                 # track
    08-binary-search/         # unit
      unit.md                 # frontmatter: id, title, requires
      01-halving.md           # lesson
      02-on-answers.md
      exercises/
        first-true.md
      cards.md
  linux/
    01-files/
      ...
```

**Lesson**: a `---` line, with a blank line on each side, starts a new step. Without the blank line above, Markdown reads it as a heading underline. The step type comes from what the step contains.

````markdown
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
````

| Block | Step | Notes |
|---|---|---|
| ` ```python ` | Read | Runnable cell |
| ` ```python trace ` | Read or Trace | Inline trace. `stop=N` pauses at step N for the question that follows |
| ` ```python predict ` | Predict | The expected answer is the real output, recorded by `tools/`, so authors never type it |
| ` ```python arrange ` | Arrange | Write the lines in order; the app shuffles them. Tests come from the linked exercise or a `tests` block |
| ` ```diagram ` | — | Static diagram (see Visuals) |
| ` ```shell ` | Read | Runs in the Linux machine (see Linux track) |
| `- [x]` / `- [ ]` | Analyze, or the question after a trace | Task-list syntax; one or more correct options |
| A link alone on a line to `exercises/*.md` | Implement | The exercise, embedded |

**Exercise** (`exercises/first-true.md`):

````markdown
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
````

- `tests`: one `call == expected` per line. The runner parses each line with `ast` and reports input, expected and got. For setup or randomized cases, add a ` ```python tests ` block with plain `assert`s.
- Linux exercises use ` ```shell setup `, ` ```shell check ` (exit 0 means pass) and ` ```shell solution ` instead of starter and tests.

**Cards** (`cards.md`): each `##` heading is a question, and the text under it is the answer.

```markdown
## What does `lo` mean when binary search ends?
The first index where the predicate is true.
```

**Validator** (`tools/validate_content.py`, run in CI): checks frontmatter and ids (unique, stable), checks that links resolve, runs every solution against its tests, records `predict` outputs and `trace` JSON, checks that each `stop=N` exists, and boots the Linux image to run each `shell solution` against its `check`.

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
- Tracks: Algorithms, CS foundations, Linux.
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

## Linux track

Teach the shell and how Linux works on a real kernel, not a fake shell.

**Machine**
- v86 (BSD-2) in a hidden `WKWebView`, with all assets bundled and served locally. v86 translates hot x86 code to WebAssembly, and WebKit's JIT is available to any app, so it runs faster than a native interpreter (iOS doesn't let native apps JIT).
- Image: 32-bit Buildroot with BusyBox plus bash, coreutils, grep, sed, gawk, findutils, less, vi, man pages, git and python3. 128 MB RAM, no network. `tools/linux/` builds the image on Linux in CI.
- Instant start: the app ships a saved VM state (`save_state`, zstd) taken after boot and restores it. Reset restores it again, and each lesson can ship its own state with files already in place.
- Files: the user's home is a 9P mount whose handler (`handle9p`) is backed by a folder in app storage through the JS bridge, so work survives resets and app updates and can be read from Swift. 9P handlers aren't covered by save states, so remount after each restore.
- Bridge: `WKScriptMessageHandler` for guest → Swift bytes, `evaluateJavaScript` for Swift → guest. Batch output per animation frame rather than per byte.
- Checks: a small agent on a second serial port runs `shell check` scripts and returns the exit code and output, so they never appear in the user's terminal. CI runs the same build in Node to check every `shell solution`.
- Lifetime: one web view, created when a Linux lesson opens. State is saved when the app goes to the background. If WebKit kills the WebContent process, restore the last state and remount.

**Emulator comparison**

| | TinyEMU | v86 |
|---|---|---|
| Author, license | Fabrice Bellard, MIT | Fabian Hemmer (copy), BSD-2 |
| CPU | RISC-V 32/64/128. Its x86 mode needs KVM, so on iOS it's RISC-V only | 32-bit x86, about Pentium 4 with SSE3. No 64-bit |
| Execution on iOS | Native C interpreter (`riscv_cpu_interp`, TLB, no translation), compiled ahead of time | Translates hot x86 pages to WebAssembly, which WebKit then JITs. Needs `WKWebView` |
| Speed | Not published for RISC-V. JSLinux on the same core ran x86 at ~100 MIPS in a 2017 browser. Measure on device | Not published. Likely faster on CPU-heavy work because of the JIT |
| Save/restore state | No (disk copy-on-write only). We add it | Yes (`save_state`/`restore_state`, zstd) |
| Devices | VirtIO console, block, net, 9P, input | NE2000, IDE, VGA, PS/2, VirtIO 9P/net/balloon, serial |
| Size and code | ~21k lines of C, few dependencies; small, readable, easy to change | Rust + JS, Closure Compiler build, larger |
| Maintenance | Last release 2019-12-21. Bellard still develops the closed JSLinux core (x86-64 and AVX-512 in 2026), not the public RISC-V one | Active, ~24k stars |
| Integration | Swift ↔ C directly. Runs in-process on a thread; `swift test` can boot it on Linux | JS bridge through `WKScriptMessageHandler`. Assets served locally. WebContent process can be killed under memory pressure |
| Images | Must build our own current kernel + OpenSBI (shipped images are from 2018) | Buildroot, Alpine x86, Arch 32 images available |

**Choice: v86.** Save state, ready-made images and a JIT that works on iOS are already there and maintained. TinyEMU fits the app more neatly (native, in-process), but needs a save-state patch, a current kernel port and an unmaintained fork we'd own.

**Switch to TinyEMU if the spike shows**: WebContent process kills that restore can't hide, bridge latency you can feel while typing, or memory use that gets the app killed.

**Other options**
| Option | Verdict |
|---|---|
| iSH | Rejected. User-mode only (syscall translation, no real kernel, so `/proc`, signals and process states are approximations). Pure interpreter. GPLv3 plus extra iOS terms. |
| WebVM / CheerpX | Rejected. Proprietary license, wants network. |
| Simulated shell | Rejected. Teaches the simulator, not Linux. |

**Terminal**
- Ghostty's terminal through libghostty-spm (`GhosttyTerminal`, MIT). Its host-managed I/O backend (`InMemoryTerminalSession`) takes bytes from any source with no pty, so the guest's serial console connects to it through the JS bridge. Metal rendering, touch selection and a SwiftUI view are included. We add a keyboard bar (Tab, Ctrl, Esc, arrows, `|`, `~`, `/`).
- Pin an exact version (the package releases weekly). Check VoiceOver and the app size increase in the Linux spike. If either fails, fall back to SwiftTerm.

| Option | Verdict |
|---|---|
| libghostty-spm | Use. Full Ghostty renderer as a prebuilt XCFramework (no Zig needed), host-managed I/O, iOS touch selection, most mature (~120 stars, weekly releases). |
| Termini | Rejected for now. A cleaner SwiftUI API (`processRemoteOutput`, `onTransportWrite`), but young (~20 stars, 0.x) and focused on SSH on iOS. Revisit if it matures. |
| libghostty-vt alone | Later option. Stable C ABI (1.0), parser and screen state only, so we would draw cells ourselves in SwiftUI. Only worth it if the full renderer fails on size or accessibility. |
| SwiftTerm | Fallback. Mature, pure Swift. Weaker escape-sequence coverage and rendering than Ghostty. |

**Units**: files and paths; reading files (`cat`, `less`, `head`); permissions and users; pipes and redirection; text tools (`grep`, `sed`, `awk`, `sort`, `uniq`); `find` and globbing; processes, jobs and signals; environment and `PATH`; shell scripting; `/proc` and `/sys`; git basics.

**Visuals**: the same vocabulary. Directory trees use the Tree shape, and a pipeline uses a new Pipe shape (boxes with byte counts on the arrows). The process tree comes from `ps -o pid,ppid`.

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
| Frontmatter | Yams (YAML) | MIT |
| Linux machine | v86 (in `WKWebView`) | BSD-2 |
| Terminal | libghostty-spm (`GhosttyTerminal`, pinned) | MIT |
| Spaced repetition | open-spaced-repetition/swift-fsrs (FSRS-5; last push Dec 2024) or port FSRS-6, ~200 lines | MIT |

Apple frameworks, no dependency: SwiftData (+ CloudKit sync), Swift Charts (complexity plots), Foundation Models (on-device hints), App Intents, WidgetKit, Core Spotlight. Skip TipKit (it adds helper text).

Keep the list this short. Visuals, test runner and console are custom; no libraries for those (graph and Metal options checked, see Rendering and performance).

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
- **Content tooling**: write on Mac in any editor; `tools/validate_content.py` checks everything (see Authoring syntax). Run it in CI.

## Milestones

1. **Hello Python**: Xcode project, embed `Python.xcframework`, run `print(sum(range(10)))` from a button. Verify on device. This is the riskiest step; do it first.
2. **Playground**: STTextView editor with Neon highlighting, streamed output, stop button, saved files. Check typing, selection and keyboard behavior on device early; STTextView is macOS-first.
3. **Lessons**: content loader for the authoring syntax, Markdown rendering, runnable cells, steps. Write lessons 1–3.
4. **Exercises**: exercise files, `tests` line parser, test runner, results view. 5 exercises per lesson.
5. **Progress**: SwiftData models, topic list with completion.
6. **Visuals**: inline trace first, then array and grid views, lesson diagram blocks, full step-through with frames and arrows, then `viz` animations, trees, graphs.
7. **Review + complexity plots**.
8. **Linux spike**: v86 + saved state + libghostty-spm on device. Measure restore time, typing latency, `grep -r` over the man pages, `git log`, `python3 -c 'print(1)'`, memory, app size and VoiceOver. Switch criteria are in the Linux track.
9. **Linux track**: image build in CI, check agent, 9P home, units 1–4.
10. Remaining content, ongoing.

## Risks

- Embedding friction (signing `.so` extension modules, build phase script). Mitigation: follow the CPython iOS guide exactly; milestone 1 is a spike.
- App size: stdlib is tens of MB. Fine for personal use; strip `test/`, `idlelib/`, `tkinter/`.
- Killing runaway C-level loops: async exceptions only fire between bytecodes. Acceptable for learning code.
- Linux in `WKWebView`: the WebContent process can be killed under memory pressure. Mitigation: save state on background, restore and remount on return; free the web view when leaving the Linux track.
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
