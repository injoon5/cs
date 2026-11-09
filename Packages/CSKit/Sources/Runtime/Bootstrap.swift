// Source of the `_csruntime` module, run once when the interpreter starts.
//
// It wires stdout, stderr, stdin and `input()` to `_csbridge` (docs/contracts.md) and
// provides `call(module, function, *args)`, the one entry point Swift uses. `call`
// never raises: it returns `"ok:" + result` or `"err:" + {"missing": bool, "error":
// PythonError}` as JSON. `missing` is true when `module` itself isn't installed.
//
// `run` is a fallback for `app_support.run` while that module isn't bundled.
enum Bootstrap {
    static let source = #"""
import builtins
import importlib
import json
import linecache
import os
import sys
import traceback

import _csbridge

USER_FILE = "main.py"
_scratch = None


class _Output:
    encoding = "utf-8"
    errors = "replace"
    closed = False

    def __init__(self, stream):
        self._stream = stream

    def write(self, text):
        if not isinstance(text, str):
            raise TypeError(f"write() argument must be str, not {type(text).__name__}")
        if text:
            _csbridge.write(self._stream, text)
        return len(text)

    def writelines(self, lines):
        for line in lines:
            self.write(line)

    def flush(self):
        pass

    def isatty(self):
        return False

    def readable(self):
        return False

    def writable(self):
        return True

    def seekable(self):
        return False


class _Input:
    encoding = "utf-8"
    errors = "replace"
    closed = False

    def readline(self, size=-1):
        line = _csbridge.readline("")
        if line is None:
            return ""
        return line if line.endswith("\n") else line + "\n"

    def __iter__(self):
        return self

    def __next__(self):
        line = self.readline()
        if not line:
            raise StopIteration
        return line

    def isatty(self):
        return False

    def readable(self):
        return True

    def writable(self):
        return False


def _input(prompt=""):
    sys.stdout.flush()
    line = _csbridge.readline(str(prompt))
    if line is None:
        raise EOFError("EOF when reading a line")
    return line[:-1] if line.endswith("\n") else line


_stdout = _Output(1)
_stderr = _Output(2)
_stdin = _Input()


def _install_io():
    sys.stdout = _stdout
    sys.stderr = _stderr
    sys.stdin = _stdin
    builtins.input = _input


def configure(scratch):
    global _scratch
    os.makedirs(scratch, exist_ok=True)
    _scratch = scratch
    return "null"


def error_dict(exc):
    """PythonError for `exc`, showing only frames from the user's code."""
    te = traceback.TracebackException.from_exception(exc)
    user_frames = [f for f in te.stack if f.filename == USER_FILE]
    te.stack = traceback.StackSummary.from_list(user_frames)
    line = user_frames[-1].lineno if user_frames else None
    if isinstance(exc, SyntaxError) and exc.filename == USER_FILE:
        line = exc.lineno
    return {
        "type": type(exc).__name__,
        "message": str(exc),
        "traceback": "".join(te.format()),
        "line": line,
    }


def call(module, function, *args):
    try:
        _install_io()
        if _scratch is not None:
            os.chdir(_scratch)
        try:
            mod = importlib.import_module(module)
        except ModuleNotFoundError as exc:
            if exc.name == module:
                return "err:" + json.dumps({"missing": True, "error": error_dict(exc)})
            raise
        result = getattr(mod, function)(*args)
        if not isinstance(result, str):
            raise TypeError(f"{module}.{function} returned {type(result).__name__}, not str")
        return "ok:" + result
    except BaseException as exc:
        return "err:" + json.dumps({"missing": False, "error": error_dict(exc)})


def run(code):
    """Runs `code` in fresh globals. Returns {"error": PythonError | null}."""
    linecache.cache[USER_FILE] = (len(code), None, code.splitlines(True), USER_FILE)
    globals_ = {"__name__": "__main__", "__builtins__": builtins}
    try:
        exec(compile(code, USER_FILE, "exec"), globals_)
    except SystemExit as exc:
        if exc.code not in (None, 0):
            return json.dumps({"error": error_dict(exc)})
    except BaseException as exc:
        return json.dumps({"error": error_dict(exc)})
    return json.dumps({"error": None})


_install_io()
"""#
}
