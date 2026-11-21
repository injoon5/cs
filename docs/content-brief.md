# Content unit brief

The brief each content agent gets, one per unit, run in its own worktree. Units 11–18 were written with it. The main agent merges each unit and runs the validator.

## Setup (do this first)

Your worktree may start from an old commit. Bring it up to date before anything else:

```
git merge --ff-only bootstrap
```

If the fast-forward fails, stop and report.

The default `python3` on the Mac is 3.12. The app runs 3.14: run the validator and your own checks with `/opt/homebrew/bin/python3.14`.

## Owns / reads / must not touch

- **Owns**: `content/algorithms/<your unit folder>/` (create it), plus the new `content/_recorded/*.json` files the validator writes for your blocks.
- **Reads**: `CLAUDE.md`, `PLAN.md` (sections "Design", "Visuals", "Content", "How the curriculum works"), `docs/contracts.md`, the grammar comment at the top of `Packages/CSKit/Sources/Content/DiagramParser.swift`, `Resources/python/viz.py` (the `viz` API for animations), and the existing units. Read `content/algorithms/10-heaps/` and `content/algorithms/11-graphs/` in full before writing: they are the style and quality reference. Read the prerequisite units named in your task so you reuse their vocabulary and don't re-teach them.
- **Must not touch**: `PLAN.md`, `CLAUDE.md`, `content/algorithms/track.md`, other units, `tools/`, `Packages/`, `Resources/`, `docs/`. If you need a parser, validator or viz change, don't make it: work around it and report it.

## What to write

- `unit.md`: frontmatter `id`, `title`, `requires: [unit ids]`, then one or two sentences on what the unit is for (see `10-heaps/unit.md`).
- 4–6 lessons, `01-<slug>.md` ... Each is 5–10 minutes and one idea, 90–190 lines like the reference units. Frontmatter `id` (unique across all content), `title` (sentence case).
- 10–14 exercises in `exercises/`: roughly 3–4 warmup, 5–7 core, 2–4 stretch.
- `cards.md`: 12–16 recall cards (`##` question, short answer under it). Concepts, invariants, complexities, "when do you use X".

### Lessons

- Steps are separated by a `---` line with a blank line on each side. Each step is small: a few sentences plus at most one block.
- Use the full range of step types, and use them where they teach something: runnable `python` cells, `diagram` blocks, a `viz` animation for the one or two moments where watching the algorithm move helps most (see `10-heaps/02-sift-up-and-down.md` and `11-graphs/02-breadth-first-search.md`), `python trace stop=N` followed by a question about the state at that step, `python predict`, `python arrange` with a `tests` block, multiple-choice questions (`- [x]` / `- [ ]`) for complexity and concept checks.
- Predict before run, trace before implement. Build the idea from a small concrete example before generalizing.
- A lesson ends with links to its exercises, each alone on a line: `[Title](exercises/<id>.md)`. The link text must match the exercise's title exactly. Every exercise is linked from exactly one lesson.
- Multiple-choice distractors are plausible mistakes a learner actually makes, never jokes. One clearly right answer (or several marked `[x]` when that's the point).
- Keep code small and idiomatic Python 3.14. Use the stdlib where a real programmer would, after showing the idea by hand.

### Known pitfalls

- `predict` and `trace` output must be deterministic: no randomness, timing, `id()`, set iteration order of strings, or generator objects held in variables (their repr has a memory address, so `--check` fails).
- The inline trace shows only the current function's local variables. Ask questions about values visible in the frame at that step.
- The validator runs only `predict`, `trace` and exercises. Run every plain `python` cell, every `viz` animation, and every `arrange` block against its `tests` yourself.
- `viz.array` draws strings with quotes (it uses `repr`); diagrams draw them without.
- `viz.graph` takes no node positions; undirected graphs are laid out in a circle. A graph diagram can't highlight single edges: `visited` styles every edge between two visited nodes.
- After recording, open each `content/_recorded/<hash>.json` for your traces and check that step N (1-based, `steps[N-1]`) is the state the question asks about, and that the marked answer matches it. Check each `predict` output reads as intended.
- Traces stop at 1,000 steps and show 50 items per container; keep traced code small.

### Copy

- Short, plain sentences. Sentence case. No taglines, no "In this lesson we will", no "Let's dive in", no exclamation marks, no emoji. Say the thing.
- Explain in your own words. Don't copy textbook phrasing.
- Name the idea, show it, then say why it works and what it costs.
- Code identifiers in backticks. Complexities as `O(n log n)` in plain text, like the reference units.

### Exercises

Follow the format in `PLAN.md` and the reference units exactly:

- Frontmatter `id` (unique across all content, kebab-case, specific enough not to clash with other units), `title`, `level`.
- Prompt: what to return, with one small worked example. Name the function in the starter.
- ` ```python starter `: signature and `pass`. The starter must fail the tests (the validator checks).
- ` ```tests `: one `call == expected` per line. Cover the edge cases: empty, single item, duplicates, negatives, already-solved inputs, the worst case. Where complexity is the point, add one large input the reference solution runs in well under 0.3 s on a Mac and a naive solution can't finish in 2 s (the app's per-test timeout on the phone). Time the naive version to confirm.
- Where several answers are valid, test that the answer is valid rather than matching one fixed answer.
- ` ```python tests ` with asserts against a brute-force or stdlib reference on random inputs, where the problem allows it.
- ` ```python solution `: clean, idiomatic, the solution you'd want a learner to study.
- `## Hints`: exactly 3, in order nudge → approach → near-solution. No code in hints beyond short expressions.
- Data structures the exercise needs (a class, graph as adjacency dict, etc.) are defined in the starter and solution in the same way, and the tests build inputs from them.

## Done when

1. `/opt/homebrew/bin/python3.14 tools/validate_content.py` reports 0 errors and 0 warnings, then the same with `--check` passes. (It builds a small Swift tool on first run; that takes a minute.)
2. You checked every trace stop and predict output by reading the recorded JSON, and ran every cell, animation and arrange block.
3. You did a final read of every lesson start to finish as a learner who just finished the prerequisite units: each step follows from the one before, nothing is used before it's introduced, every claim is true, no step is padded. Fix what you find.
4. One commit on your branch containing only your unit folder and its `_recorded` files: `Content: <Unit title> unit`, with a short body listing what the lessons cover and the exercise and card counts.

## Report back

- Branch name and commit hash.
- Lessons (id, title, one line each), exercises (id, level), card count.
- Anything you wanted from the parser, validator or `viz` and worked around.
- Open questions and anything you couldn't verify (you can't see the app render; say which diagrams you're least sure about).

## Unit tasks

Each agent got the brief above plus its unit's task. Done units keep their task here as a record of the scope they were given.

| # | Folder | id | requires | Status |
|---|---|---|---|---|
| 11 | `11-graphs` | `graphs` | trees, hashing | done |
| 12 | `12-shortest-paths` | `shortest-paths` | graphs, heaps | done |
| 13 | `13-union-find` | `union-find` | graphs, heaps | done |
| 14 | `14-dynamic-programming` | `dynamic-programming` | recursion, binary-search | done |
| 15 | `15-greedy` | `greedy` | sorting, heaps, dynamic-programming | done |
| 16 | `16-tries-and-range-queries` | `tries-and-range-queries` | trees, arrays-and-strings | done |
| 17 | `17-strings` | `strings` | hashing, arrays-and-strings | done |
| 18 | `18-bits` | `bits` | complexity | done |
| 19 | `19-math` | `math` | recursion, bits | to do |
| 20 | `20-under-the-hood` | `under-the-hood` | complexity, hashing | to do |

**11 Graphs.** Representations (adjacency dict, matrix, edge list, degree); BFS with `deque`, seen marked on enqueue, distances and parents, O(V + E); grids as graphs and multi-source BFS; DFS recursive and with a stack, components, flood fill, recursion limits; cycles with three-colour DFS, topological sort with Kahn and DFS post-order.

**12 Shortest paths.** Weighted adjacency and relaxation; Dijkstra with `heapq` and stale entries skipped; using Dijkstra (paths, early stop, grids, bottleneck and max-product variants); Bellman-Ford, negative cycles, at most k edges; Floyd-Warshall with `k` outermost; DAG shortest paths and 0-1 BFS.

**13 Union-find and spanning trees.** Disjoint sets as a `parent` forest; union by size and path compression; counting components, cycles in undirected graphs, grouping by shared keys; MST, cut property, Kruskal; Prim with a heap. Large tests defeat a union-find without size or compression.

**14 Dynamic programming.** Overlapping subproblems and memoization; 1D tabulation and rolling variables; 2D tables (grid paths, LCS, edit distance) and rebuilding answers; 0/1 knapsack and the backward 1D loop; LIS in O(n^2) and with `bisect`; interval DP filled by length. Large tests defeat exponential recursion.

**15 Greedy algorithms.** Greedy choices and where they fail (coins, knapsack); the exchange argument; interval scheduling by earliest end; merging and covering intervals; sweep line with tie order; greedy with a heap (Huffman, deadlines). Don't repeat the heaps unit's meeting rooms.

**16 Tries and range queries.** Tries and their uses; why prefix sums break under updates; bottom-up segment tree; other associative combines, lazy propagation named only; Fenwick trees with `i & -i` explained locally.

**17 Strings.** Building strings and `join`; naive matching and its worst case; rolling hash and Rabin-Karp; prefix hashes and longest repeated substring; the prefix function; KMP search and periods.

**18 Bits and number representation.** Bases and `bit_length`; bitwise operators; two's complement and Python's unbounded ints; bit tricks (`x & (x - 1)`, `x & -x`, xor); bitmasks as sets and submasks; floating point.

**19 Math.** To do. Suggested scope: gcd and lcm (Euclid, why it's O(log n)), primes by trial division to √n and the sieve of Eratosthenes, prime factorization, modular arithmetic (`%` on negatives in Python, adding and multiplying mod m), fast power by squaring and `pow(b, e, m)`, modular inverse with `pow(a, -1, m)`, counting (permutations, combinations, `math.comb`, Pascal's triangle mod p). Recursion's `euclid-gcd` and `power-mod` exercises exist: build on them, don't repeat them.

**20 Under the hood.** To do. Suggested scope: how CPython runs code (source to bytecode, `dis`, the eval loop), names and objects (references, `is` vs `==`, small int caching, mutability), memory (reference counting, `sys.getsizeof`, garbage collection of cycles), how `list` and `dict` are laid out and what that means for cost (over-allocation, open addressing with insertion order), caching (`functools.cache`, `lru_cache`, the cost of a cache miss), and measuring with `timeit`. Outputs that vary by build or run (addresses, sizes, timings) can't be `predict` or `trace` blocks.

## Accepted trade-offs

Decisions on the open questions the unit agents raised. Revisit if they cause trouble in use.

- **Recursion depth traps.** `island-count` and `friend-groups` (graphs) have one test too deep for recursive DFS, and `rob-houses` and `split-into-words` (DP) overflow a memoized recursion. Kept: the lessons and prompts say to use a stack or a loop, and Python's recursion limit is a real constraint worth meeting.
- **`longest-repeated-substring` (strings).** A binary search over slices without hashing passes. Kept the input size: a larger one could use hundreds of MB on the phone.
- **`subset-sums-by-mask` (bits).** n = 20. The O(2^n · n) version takes 1.2 s on the Mac and may pass on the phone. Kept: n = 22 would need about 150 MB.
- **`connect-points-cost` (union-find).** Kruskal over all pairs takes about 1 s on the Mac and may pass. Kept: it's a correct, reasonable solution; the prompt asks for O(n²).
- **`block-range-sums` (tries).** No large test, so a slice sum passes. Kept: it's a warmup, and summing slices in C is faster than square-root blocks in Python at any size that fits the time limit.
- **`fenwick-inversions` (tries).** Repeats sorting's `count-inversions` with a different tool. Kept on purpose: the same answer two ways.
- **`add-without-plus` (bits).** The starter includes the given mask constants and the signed conversion around `pass`. Kept: the masking isn't the point of the exercise.
- **Long lessons.** Several lessons run 195–245 lines against the 190 guide, mostly from class code and diagrams. Kept unless they read long on the phone.
- **Diagrams not yet seen in the app.** The 15-node segment tree, the 9–10 column greedy timelines, the Dijkstra animation (graph plus two arrays), and the Prim diagram, where `visited` also styles the non-tree edge 0–1. Check these on the simulator next.
