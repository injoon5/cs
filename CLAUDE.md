# CLAUDE.md

Personal iPhone app for learning algorithms and CS, with embedded Python. `PLAN.md` is the source of truth for scope and decisions. Read it before starting work. If a change contradicts it, update `PLAN.md` in the same commit or ask.

## Standard

This app should feel like Apple made it. Details are the work, not polish after the work.

- Follow the design rules in `PLAN.md` (Design section). System components first. Nothing custom where Apple has a control.
- Every screen: light and dark, smallest and largest current iPhone, keyboard up and down, empty, loading, error and long-content states.
- Motion: springs, interruptible, no linear easing. Animate state changes that move things; don't animate things that only appear.
- Layout: standard system spacing and margins, 44pt minimum tap targets, aligned edges, no layout shift when content loads or numbers change (`.monospacedDigit()` for counters and timers).
- Type: system text styles only, SF Mono for code. Matching SF Symbol weight to adjacent text.
- Feedback: haptics on meaningful results (test pass/fail), never on routine taps.
- Copy: short, sentence case, no taglines or helper text. If a screen needs explanation, fix the layout.
- Code: small views, no force unwraps outside tests, `@Observable` models, Swift 6 strict concurrency, no warnings.
- Before calling UI work done, take simulator screenshots in light and dark and look at them. List what you checked.

## Architecture for parallel work

Code is split so that workstreams touch different files.

```
CS/                      thin app target: entry point, tab view, wiring only
Packages/CSKit/          local Swift package, one target per area
  Sources/
    Content/             content models, Markdown + frontmatter loading, step/block/tests parsers, diagram parser
    Runtime/             PythonRuntime actor, C bridge
    Editor/              STTextView wrapper, editor view controller, highlighting, keyboard bar
    Visuals/             shape views, step-through, animations
    Lessons/             lesson reader, steps
    Exercises/           exercise UI, results
    Review/              FSRS, review queue
    Tutor/               Foundation Models features
    Linux/               v86 web view host, JS bridge, Ghostty terminal, check agent
    Store/               SwiftData models
    Contracts/           shared types only: protocols, Codable structs, JSON schemas
Resources/python/        app_support.py, viz.py, trace.py
Resources/linux/         v86 build, VM image, saved states (built by tools/linux)
content/                 lessons, exercises, cards
tools/                   content validator, Linux image build, scripts
```

Rules:
- Use Xcode synchronized folders for the app target, so adding files never edits `project.pbxproj`.
- `Contracts` holds every type that crosses an area boundary (trace snapshot JSON, viz frame JSON, exercise result, content models). Areas depend on `Contracts`, not on each other, where possible.
- Logic that doesn't need UIKit (content parsing, diagram parser, FSRS, trace models) stays Foundation-only so `swift test` runs on Linux.
- Python support code is tested with plain `python3 -m pytest` on Linux.

## Using subagents

The main agent coordinates. Subagents do scoped work.

### Before fanning out

1. Write or update the contracts first, in the main agent: types in `Contracts/`, JSON schemas, protocol signatures. Commit them.
2. Split work by area directory. One subagent per area. Two subagents never own the same directory in the same round.
3. List shared files that will change (`Package.swift`, `Contracts/`, `PLAN.md`, `CS/` app target). Only the main agent edits these. A subagent that needs a change there reports it back instead of making it.

### Each subagent gets

- **Owns**: exact directories it may edit.
- **Reads**: what it may read for context (contracts, PLAN.md sections).
- **Must not touch**: shared files above, other areas.
- **Task**: one concrete outcome, with the contract it implements.
- **Done when**: specific checks (tests pass, builds, screenshots taken, listed edge cases handled).
- **Report**: files changed, contract changes needed, open questions, what it did not verify.

Run implementation subagents with `isolation: "worktree"`, one branch each. The main agent reviews each diff and merges. Run independent subagents in parallel; run dependent ones after their inputs land.

### Good splits

- Runtime (Python bridge) | Editor | Content parser — no shared files.
- Visuals: Array/Grid views | Tree/Graph views | Step-through screen — share only `Contracts`.
- Content: one subagent per unit folder under `content/`.

### Bad splits

- Two agents on the same screen.
- An agent changing a contract while another implements it.
- "Polish the app" without a list of screens and checks.

## Models

| Work | Model |
|---|---|
| Coordination, contracts, architecture, design and UI implementation, AI tutor prompts | default (strongest) |
| Feature code in one area with a clear contract | default, or `sonnet` for mechanical work |
| Writing tests from a spec, content validation, running test suites, reading logs | `sonnet` |
| Running builds/tests and reporting results, checking screenshots against a checklist, lint, link and schema checks | `haiku` |

Testing and verification agents report results; they don't fix code. Failures go back to the agent that owns the area.

## Verifying

- Linux (cloud sessions): `swift test` for Foundation-only targets, `python3 -m pytest Resources/python`, `python3 tools/validate_content.py` (runs every reference solution against its tests).
- Mac: `xcodebuild test` on the latest iPhone simulator, then screenshots in light and dark.
- iOS build and UI checks need a Mac. In a cloud session, say clearly what was not verified.

## Git

- Small commits, one area each when possible. Message says what and why.
- Content and code in separate commits.
- Don't commit `Python.xcframework` build products to git without asking (size).
