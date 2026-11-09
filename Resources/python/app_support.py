"""Runs user code for the app. Called by Swift (`Runtime.PythonRuntime`) on its interpreter thread.

Every public function takes and returns `str`; results are JSON matching the Swift types in
`Packages/CSKit/Sources/Contracts` (camelCase keys). See `docs/contracts.md`.

    run(code)                                           -> {"error": PythonError | null}
    run_tests(code, test_lines_json, python_tests, timeout) -> TestReport
    trace(code)                                         -> Trace
    visualize(code)                                     -> {"frames": [VizFrame], "output": str, "error": PythonError | null}

Behaviour the contract leaves open, decided here:

- User code is compiled with the filename `main.py` and its source is put in `linecache`, so
  tracebacks show the user's lines. Frames from `app_support`, `trace` and `viz` are removed.
- Each call runs in a fresh `__main__` module (also installed in `sys.modules["__main__"]` for
  the duration of the call, so dataclasses, pickle and `typing.get_type_hints` work).
- `run` streams stdout/stderr through `_csbridge.write`. Without `_csbridge` it writes to the
  `sys.stdout`/`sys.stderr` that were current when the call started. `input()` calls
  `_csbridge.readline(prompt)` (falling back to `sys.stdin`); `None` raises `EOFError`. The
  prompt is not echoed; the UI shows it.
- `SystemExit` with code `None` or `0` counts as a normal finish; other codes are an error.
- `run_tests` loads the user code once (with the timeout), then runs every test in that same
  namespace. Output printed during tests is discarded and `input()` raises `EOFError`.

`tests` block lines (`test_lines_json`), one `TestResult` per non-blank, non-`#` line:

- `call == expected`: `expected` is evaluated in the user namespace first, then `call`.
  `input` is the source of the left side, `expected`/`got` are `repr`s, and the test passes when
  `bool(got == expected)` is true. An exception in either side fails the test with `error` set.
- Any other expression passes when it is truthy (`input` = the line, `expected` = `"True"`).
- A line that doesn't parse fails with a `SyntaxError`.

Python tests (`python_tests`), run after the `tests` lines in the same namespace:

- Each top-level `assert` is one test, named by its source. If it's `assert call == expected`,
  `input`/`expected`/`got` are filled in as for `tests` lines.
- Each top-level `def test_*()` is one test, named after the function, run after the whole
  file has been executed (so helpers defined later are visible).
- Any other top-level statement (imports, helpers, setup) runs in order; if it raises, it is
  reported as a failing test named by its source.

Timeouts: each test (and loading the user code) gets `timeout` seconds. A `threading.Timer`
raises `TimeoutError` in the running thread with `PyThreadState_SetAsyncExc`. If the code catches
it and keeps going, a `sys.monitoring` hook raises it again on every user line (see `Deadline`).
A test that finishes after its deadline is reported as timed out even if it caught the
exception. Code blocked inside a C call (`time.sleep`) is only interrupted when it returns to Python.

`KeyboardInterrupt` (Stop from Swift) is reported as `error.type == "KeyboardInterrupt"`;
in `run_tests` it fails the current test and skips the rest.
"""

from __future__ import annotations

import ast
import builtins
import ctypes
import io
import json
import linecache
import os
import sys
import threading
import time
import traceback
import types

USER_FILENAME = "main.py"
TEST_FILENAME = "tests.py"

_HERE = os.path.dirname(os.path.abspath(__file__))
_SUPPORT_FILES = {
    os.path.join(_HERE, name) for name in ("app_support.py", "trace.py", "viz.py")
}

if _HERE not in sys.path:
    sys.path.insert(0, _HERE)


# MARK: - Public API


def run(code: str) -> str:
    """Runs `code`, streaming output. Returns `{"error": PythonError | null}`."""
    with UserIO(stream=True), _MainModule() as namespace:
        error = execute(code, namespace)
    return _dumps({"error": error})


def run_tests(code: str, test_lines_json: str, python_tests: str, timeout: float) -> str:
    """Runs exercise tests against `code`. Returns `TestReport`."""
    try:
        lines = json.loads(test_lines_json) if test_lines_json else []
    except ValueError:
        lines = []
    with UserIO(stream=False, interactive=False), _MainModule() as namespace:
        runner = _TestRunner(namespace, float(timeout))
        load_error = runner.load(code)
        if load_error is None:
            runner.run_lines([line for line in lines if isinstance(line, str)])
            if python_tests and not runner.stopped:
                runner.run_python_tests(python_tests)
    return _dumps({"results": runner.results, "loadError": load_error})


def trace(code: str) -> str:
    """Runs `code` under the tracer. Returns `Trace`."""
    tracer = _load_sibling("trace")
    return _dumps(tracer.trace_code(code))


def visualize(code: str) -> str:
    """Runs `code` and collects `viz` frames."""
    viz = _load_sibling("viz")
    viz._reset()
    with UserIO(stream=False) as io_, _MainModule() as namespace:
        error = execute(code, namespace)
    return _dumps({"frames": viz._finish(), "output": io_.text(), "error": error})


# MARK: - Executing user code


def compile_user(code: str, filename: str = USER_FILENAME):
    """Compiles user code and registers its source with `linecache` for tracebacks."""
    register_source(code, filename)
    return compile(code, filename, "exec", dont_inherit=True)


def register_source(code: str, filename: str) -> None:
    lines = code.splitlines(keepends=True)
    if lines and not lines[-1].endswith("\n"):
        lines[-1] += "\n"
    linecache.cache[filename] = (len(code), None, lines, filename)


def execute(code: str, namespace: dict) -> dict | None:
    """Compiles and runs `code` in `namespace`. Returns a PythonError dict or None."""
    try:
        compiled = compile_user(code)
    except (SyntaxError, ValueError) as exc:
        return error_dict(exc)
    try:
        exec(compiled, namespace)
    except SystemExit as exc:
        if exc.code not in (None, 0):
            return error_dict(exc)
    except BaseException as exc:  # KeyboardInterrupt included: Swift maps it to `.stopped`.
        return error_dict(exc)
    return None


def error_dict(exc: BaseException, filenames: tuple[str, ...] = (USER_FILENAME,)) -> dict:
    """`PythonError` for `exc`, with support frames removed and the user's line found."""
    te = traceback.TracebackException.from_exception(exc, compact=True)
    _strip_support_frames(te)
    lines = "".join(te.format())
    line = None
    if isinstance(exc, SyntaxError) and exc.filename in filenames:
        line = exc.lineno
    else:
        for frame in reversed(te.stack):
            if frame.filename in filenames:
                line = frame.lineno
                break
    message = _safe_str(exc)
    if isinstance(exc, SyntaxError):
        message = exc.msg or message
    return {
        "type": type(exc).__name__,
        "message": message,
        "traceback": lines,
        "line": line,
    }


def _strip_support_frames(te: traceback.TracebackException, seen: set | None = None) -> None:
    seen = set() if seen is None else seen
    if id(te) in seen:
        return
    seen.add(id(te))
    kept = [f for f in te.stack if f.filename not in _SUPPORT_FILES]
    te.stack = traceback.StackSummary.from_list(kept)
    nested = [te.__cause__, te.__context__, *(getattr(te, "exceptions", None) or ())]
    for child in nested:
        if child is not None:
            _strip_support_frames(child, seen)


def _safe_str(value) -> str:
    try:
        return str(value)
    except BaseException:
        return f"<{type(value).__name__}>"


def _safe_repr(value) -> str:
    try:
        return repr(value)
    except BaseException:
        return f"<{type(value).__name__}>"


def _dumps(value) -> str:
    return json.dumps(value, ensure_ascii=False, allow_nan=False, default=str)


def _load_sibling(name: str):
    """Imports one of our modules, even if a stdlib module of the same name was loaded first."""
    module = sys.modules.get(name)
    path = os.path.join(_HERE, f"{name}.py")
    if module is not None and getattr(module, "__file__", None) == path:
        return module
    import importlib.util

    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


class _MainModule:
    """A fresh `__main__` module for one run."""

    def __enter__(self) -> dict:
        self._saved = sys.modules.get("__main__")
        module = types.ModuleType("__main__")
        module.__dict__["__builtins__"] = builtins
        sys.modules["__main__"] = module
        return module.__dict__

    def __exit__(self, *exc) -> None:
        if self._saved is not None:
            sys.modules["__main__"] = self._saved
        else:
            sys.modules.pop("__main__", None)


# MARK: - Output and input


class _Writer(io.TextIOBase):
    """A text stream that forwards writes to `sink(text)`."""

    def __init__(self, sink, name: str):
        self._sink = sink
        self._name = name

    @property
    def name(self) -> str:
        return self._name

    @property
    def encoding(self) -> str:
        return "utf-8"

    def writable(self) -> bool:
        return True

    def isatty(self) -> bool:
        return False

    def write(self, text) -> int:
        if not isinstance(text, str):
            raise TypeError(f"write() argument must be str, not {type(text).__name__}")
        if text:
            self._sink(text)
        return len(text)

    def flush(self) -> None:
        pass


class UserIO:
    """Swaps `sys.stdout`, `sys.stderr` and `input()` for the length of a run.

    stream=True: writes go to `_csbridge.write` (or the previous streams when it's missing).
    stream=False: writes are collected; `text()` returns them, stdout and stderr interleaved.
    interactive=False: `input()` raises `EOFError`.
    limit: caps collected text (characters); the rest is dropped.
    collect_stderr=False: collected mode drops stderr.
    """

    def __init__(self, stream: bool, interactive: bool = True, limit: int | None = None, collect_stderr: bool = True):
        self.stream = stream
        self.interactive = interactive
        self.limit = limit
        self.collect_stderr = collect_stderr
        self.chunks: list[str] = []
        self.size = 0

    def text(self) -> str:
        return "".join(self.chunks)

    def _collect(self, text: str) -> None:
        if self.limit is not None:
            room = self.limit - self.size
            if room <= 0:
                return
            text = text[:room]
        self.chunks.append(text)
        self.size += len(text)

    def __enter__(self) -> "UserIO":
        self._saved = (sys.stdout, sys.stderr, builtins.input)
        bridge = _bridge()
        out, err = sys.stdout, sys.stderr
        if not self.stream:
            stdout_sink = self._collect
            stderr_sink = self._collect if self.collect_stderr else (lambda text: None)
        elif bridge is not None:
            stdout_sink = lambda text: bridge.write(1, text)  # noqa: E731
            stderr_sink = lambda text: bridge.write(2, text)  # noqa: E731
        else:
            stdout_sink = lambda text: out.write(text)  # noqa: E731
            stderr_sink = lambda text: err.write(text)  # noqa: E731
        sys.stdout = _Writer(stdout_sink, "<stdout>")
        sys.stderr = _Writer(stderr_sink, "<stderr>")
        builtins.input = _make_input(bridge, self.interactive, self._saved[0])
        return self

    def __exit__(self, *exc) -> None:
        sys.stdout, sys.stderr, builtins.input = self._saved


def _bridge():
    try:
        import _csbridge
    except ImportError:
        return None
    return _csbridge


def _make_input(bridge, interactive: bool, fallback_out):
    def input(prompt=""):  # noqa: A001 - replaces the builtin on purpose
        prompt = str(prompt)
        if not interactive:
            raise EOFError("EOF when reading a line")
        if bridge is not None:
            line = bridge.readline(prompt)
        else:
            if prompt:
                fallback_out.write(prompt)
                fallback_out.flush()
            line = sys.stdin.readline() if sys.stdin is not None else ""
            if line == "":
                line = None
        if line is None:
            raise EOFError("EOF when reading a line")
        return line[:-1] if line.endswith("\n") else line

    return input


# MARK: - Timeouts


class Deadline:
    """Raises `TimeoutError` in the current thread after `seconds`, until the block exits.

    `expired` is True when the deadline passed while the block was running.

    The first raise is an async exception. If the code is still running `_RETRY` later (it
    caught the error), a `sys.monitoring` LINE hook raises `TimeoutError` on every line of user
    and test code in this thread, so even the body of an `except` clause raises and the error
    escapes. The hook never fires in support or library code, so their locks stay consistent.
    """

    _RETRY = 0.1

    def __init__(self, seconds: float):
        self.seconds = seconds
        self.expired = False
        self._lock = threading.Lock()
        self._armed = False
        self._timer: threading.Timer | None = None
        self._thread_id = threading.get_ident()
        self._hook_tool: int | None = None

    def __enter__(self) -> "Deadline":
        if self.seconds and self.seconds > 0:
            self._armed = True
            self._schedule(self.seconds)
        return self

    def _schedule(self, delay: float) -> None:
        timer = threading.Timer(delay, self._fire)
        timer.daemon = True
        self._timer = timer
        timer.start()

    def _fire(self) -> None:
        with self._lock:
            if not self._armed:
                return
            if self.expired:
                self._install_hook()
            self.expired = True
            _async_raise(self._thread_id, TimeoutError)
            self._schedule(self._RETRY)

    def _install_hook(self) -> None:
        if self._hook_tool is not None:
            return
        monitoring = sys.monitoring
        tool = next((t for t in (5, 4, 3, 2, 1) if monitoring.get_tool(t) is None), None)
        if tool is None:
            return
        thread_id = self._thread_id
        user_files = (USER_FILENAME, TEST_FILENAME)

        def on_line(code, line):
            if code.co_filename in user_files and threading.get_ident() == thread_id:
                raise TimeoutError("timed out")

        monitoring.use_tool_id(tool, "cs-timeout")
        monitoring.register_callback(tool, monitoring.events.LINE, on_line)
        monitoring.set_events(tool, monitoring.events.LINE)
        self._hook_tool = tool

    def _remove_hook(self) -> None:
        tool = self._hook_tool
        if tool is None:
            return
        monitoring = sys.monitoring
        monitoring.set_events(tool, 0)
        monitoring.register_callback(tool, monitoring.events.LINE, None)
        monitoring.free_tool_id(tool)
        self._hook_tool = None

    def __exit__(self, *exc) -> None:
        with self._lock:
            self._armed = False
            self._remove_hook()
            if self._timer is not None:
                self._timer.cancel()
            if self.expired:
                _async_raise(self._thread_id, None)  # Clear one that hasn't been delivered yet.


def _async_raise(thread_id: int, exc_type) -> None:
    exc = ctypes.py_object(exc_type) if exc_type is not None else None
    ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_ulong(thread_id), exc)


def _timeout_error(seconds: float) -> dict:
    return {
        "type": "TimeoutError",
        "message": f"took longer than {seconds:g} s",
        "traceback": "",
        "line": None,
    }


# MARK: - Test runner


class _Stop(Exception):
    pass


class _TestRunner:
    def __init__(self, namespace: dict, timeout: float):
        self.namespace = namespace
        self.timeout = timeout
        self.results: list[dict] = []
        self.stopped = False

    def load(self, code: str) -> dict | None:
        try:
            compiled = compile_user(code)
        except (SyntaxError, ValueError) as exc:
            return error_dict(exc)
        deadline = Deadline(self.timeout)
        error = None
        try:
            with deadline:
                exec(compiled, self.namespace)
        except SystemExit as exc:
            if exc.code not in (None, 0):
                error = error_dict(exc)
        except BaseException as exc:
            error = error_dict(exc)
        if deadline.expired:
            return _timeout_error(self.timeout)
        return error

    # `tests` block lines

    def run_lines(self, lines: list[str]) -> None:
        for raw in lines:
            if self.stopped:
                return
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            self._run_line(line)

    def _run_line(self, line: str) -> None:
        try:
            tree = ast.parse(line, filename=TEST_FILENAME, mode="eval")
        except SyntaxError as exc:
            register_source(line, TEST_FILENAME)
            self.results.append(_result(line, error=error_dict(exc)))
            return
        register_source(line, TEST_FILENAME)
        self.results.append(self._check_expression(line, tree.body, line))

    def _check_expression(self, name: str, node: ast.expr, source: str) -> dict:
        """One test from an expression: `call == expected`, or anything truthy."""
        compare = _as_equality(node)
        if compare is not None:
            call, expected = compare
            return self._timed(name, lambda out: self._compare(out, source, call, expected))
        return self._timed(name, lambda out: self._truthy(out, source, node))

    def _compare(self, out: dict, source: str, call: ast.expr, expected: ast.expr) -> None:
        out["input"] = ast.get_source_segment(source, call) or ast.unparse(call)
        expected_value = self._eval(expected)
        out["expected"] = _safe_repr(expected_value)
        got = self._eval(call)
        out["got"] = _safe_repr(got)
        out["passed"] = bool(got == expected_value)

    def _truthy(self, out: dict, source: str, node: ast.expr) -> None:
        out["input"] = source
        out["expected"] = "True"
        got = self._eval(node)
        out["got"] = _safe_repr(got)
        out["passed"] = bool(got)

    def _eval(self, node: ast.expr):
        expression = ast.Expression(body=node)
        ast.fix_missing_locations(expression)
        return eval(compile(expression, TEST_FILENAME, "eval"), self.namespace)

    def _timed(self, name: str, body) -> dict:
        """Runs `body(fields)` under the deadline. `body` fills in result fields as it goes,
        so `input`/`expected` survive an exception in the call; it sets `passed` last."""
        fields: dict = {}
        error = None
        deadline = Deadline(self.timeout)
        start = time.perf_counter()
        try:
            with deadline:
                body(fields)
        except KeyboardInterrupt as exc:
            error = error_dict(exc)
            self.stopped = True
        except BaseException as exc:
            error = error_dict(exc)
        duration = time.perf_counter() - start
        if deadline.expired:
            error = _timeout_error(self.timeout)
        passed = bool(fields.pop("passed", False)) and error is None
        return _result(name, passed=passed, error=error, duration=duration, **fields)

    # Python tests

    def run_python_tests(self, source: str) -> None:
        register_source(source, TEST_FILENAME)
        try:
            module = ast.parse(source, filename=TEST_FILENAME)
        except SyntaxError as exc:
            self.results.append(_result("tests", error=error_dict(exc)))
            return
        test_functions: list[str] = []
        for statement in module.body:
            if self.stopped:
                return
            segment = ast.get_source_segment(source, statement) or ast.unparse(statement)
            if isinstance(statement, ast.Assert):
                self.results.append(self._run_assert(source, segment, statement))
                continue
            if isinstance(statement, (ast.FunctionDef, ast.AsyncFunctionDef)) and statement.name.startswith("test"):
                test_functions.append(statement.name)
            failure = self._run_statement(segment, statement)
            if failure is not None:
                self.results.append(failure)
        for name in test_functions:
            if self.stopped:
                return
            self.results.append(self._timed(name, lambda out, name=name: self._call_test(out, name)))

    def _run_assert(self, source: str, name: str, statement: ast.Assert) -> dict:
        compare = _as_equality(statement.test)
        if compare is not None:
            call, expected = compare
            return self._timed(name, lambda out: self._compare(out, source, call, expected))
        return self._timed(name, lambda out: self._exec(statement, out))

    def _run_statement(self, name: str, statement: ast.stmt) -> dict | None:
        result = self._timed(name, lambda out: self._exec(statement, out))
        return None if result["passed"] else result

    def _call_test(self, out: dict, name: str) -> None:
        self.namespace[name]()
        out["passed"] = True

    def _exec(self, statement: ast.stmt, out: dict) -> None:
        module = ast.Module(body=[statement], type_ignores=[])
        exec(compile(module, TEST_FILENAME, "exec"), self.namespace)
        out["passed"] = True


def _as_equality(node: ast.expr):
    if isinstance(node, ast.Compare) and len(node.ops) == 1 and isinstance(node.ops[0], ast.Eq):
        return node.left, node.comparators[0]
    return None


def _result(name, passed=False, input=None, expected=None, got=None, error=None, duration=0.0) -> dict:  # noqa: A002
    return {
        "name": name,
        "passed": passed,
        "input": input,
        "expected": expected,
        "got": got,
        "error": error,
        "duration": duration,
    }
