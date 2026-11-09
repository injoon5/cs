# Cross-area contracts (non-Swift)

Swift types live in `Packages/CSKit/Sources/Contracts`. This file pins the parts that aren't Swift types. Only the main agent edits it.

## Python ↔ Swift

The Runtime embeds CPython and registers a built-in module `_csbridge` before importing `app_support`:

| `_csbridge` function | Meaning |
|---|---|
| `write(stream: int, text: str) -> None` | 1 = stdout, 2 = stderr. Streamed to the console. |
| `readline(prompt: str) -> str \| None` | Blocks until the UI answers. `None` means EOF. |

When `_csbridge` can't be imported (pytest, tools/), `app_support` falls back to the real `sys.stdout`/`sys.stdin`.

Runtime calls these functions on its interpreter thread. Every function takes and returns `str`; results are JSON matching the Swift types (camelCase keys).

| Function | Returns (JSON) |
|---|---|
| `app_support.run(code)` | `{"error": PythonError \| null}`. Output already streamed through `_csbridge`. |
| `app_support.run_tests(code, test_lines_json, python_tests, timeout)` | `TestReport`. `test_lines_json` is a JSON list of `call == expected` lines; `python_tests` is assert source or `""`. |
| `app_support.trace(code)` | `Trace` |
| `app_support.visualize(code)` | `{"frames": [VizFrame], "output": str, "error": PythonError \| null}` |

Rules:
- Each call runs user code in a fresh globals dict with `__name__ == "__main__"`, working directory set by Runtime to a scratch folder.
- Line numbers in `PythonError.line`, `TraceStep.line` and `TraceFrame.line` are 1-based lines in the user's code. Tracebacks hide `app_support`, `trace`, `viz` frames.
- Per-test timeout is enforced in Python: a `threading.Timer` raises `TimeoutError` in the run thread via `ctypes.pythonapi.PyThreadState_SetAsyncExc`. A timed-out test reports `error.type == "TimeoutError"`.
- Stop comes from Swift: `PyThreadState_SetAsyncExc(run_thread, KeyboardInterrupt)`. `run` reports it as `error.type == "KeyboardInterrupt"`; Swift maps that to `RunOutcome.stopped`.
- `viz` is importable by user code (`import viz`). Its frames are `Shape` dicts with a `kind` field.
- Trace limits: 1,000 steps (`truncated: true`), skip non-user frames, first 50 items per container (`omitted` counts the rest).

## Recorded outputs

`tools/` runs `predict` and `trace` blocks at build time and writes:

```
content/_recorded/<hash>.json   {"output": str} or {"trace": Trace}
```

`<hash>` is FNV-1a 64-bit of the block's UTF-8 source (trailing whitespace on each line and trailing newlines removed), as 16 lowercase hex digits. The Content loader sets `CodeBlock.recordedOutput` from `output`, and `CodeBlock.recordedTrace` to `_recorded/<hash>.json` when the file has `trace`.

FNV-1a 64: offset basis `0xcbf29ce484222325`, prime `0x100000001b3`, xor each byte then multiply, wrapping at 64 bits.
