"""Step-through tracer. `app_support.trace(code)` calls `trace_code` and returns its JSON.

Records a `TraceStep` (Swift `Contracts/Trace.swift`) for each event in the user's code, using
`sys.monitoring`. Only the user's code objects get `LINE`/`PY_START`/`PY_RETURN` events, so
library code runs at full speed; `RAISE` is a global event and is filtered by code object.

Events:
- `line`: before a line runs.
- `call`: a user function starts (not the module). The frame's locals are its arguments.
- `return`: a user function returns; the top frame carries `returnValue`. The module's own
  return is the last step of a run that finishes (no `returnValue`), so the final output shows.
- `exception`: an exception is raised in user code (also when it is caught later).

Each step snapshots:
- `frames`: user frames, outermost first. Frame ids (`f1`, `f2`, ...) are assigned per call and
  stay stable for its life (the tracer keeps frames alive so their `id()` isn't reused).
- `locals`: in definition order. Dunder names are hidden; so are modules at the top level.
- `heap`: everything reachable from the locals (and the return value), keyed by a run-local label (`o1`, `o2`, ...) given in first-seen order, so recordings are deterministic.
  The tracer holds a reference to every object it has put in a heap, so ids are never reused
  during the run. Primitives (`int`, `float`, `complex`, `bool`, `str`, `bytes`, `None`) are
  inline `{"repr", "type"}` values and never in the heap.
  Kinds: `list` (list, deque), `tuple`, `set` (set, frozenset), `dict` (any dict), `object`
  (instances with `__dict__` or `__slots__`, attributes in definition order), `function`
  (repr is `name(args)`), `other` (repr). Containers keep their first 50 items; `omitted` counts
  the rest. A step's heap holds at most 500 objects; past that, objects are `other` with repr
  `"…"`. Reprs are cut to 200 characters.
- `stdout`: everything printed so far (stderr isn't included), capped at 10,000 characters.

Limits: after 1,000 steps the run stops and `truncated` is true. An exception that escapes the
user's code is `error`; the tracer's own stop is not an error.
"""

from __future__ import annotations

import sys
import types
from collections import deque
from itertools import islice

from app_support import UserIO, _MainModule, compile_user, error_dict

MAX_STEPS = 1000
MAX_ITEMS = 50
MAX_HEAP = 500
MAX_REPR = 200
MAX_STDOUT = 10_000

_PRIMITIVES = (int, float, complex, bool, str, bytes, type(None))
# Safe to cache per type by value: equal values of these types always have the same repr.
# (Not float: 0.0 == -0.0.)
_CACHED = frozenset((int, str, bool, type(None)))
_FUNCTION_TYPES = (
    types.FunctionType,
    types.BuiltinFunctionType,
    types.MethodType,
    types.BuiltinMethodType,
    types.MethodWrapperType,
    types.WrapperDescriptorType,
)

_events = sys.monitoring.events


class _StepLimit(BaseException):
    """Raised into user code to stop the run once the step limit is hit."""


def trace_code(code: str) -> dict:
    """Runs `code` under the tracer. Returns a `Trace` dict."""
    try:
        compiled = compile_user(code)
    except (SyntaxError, ValueError) as exc:
        return {"steps": [], "truncated": False, "error": error_dict(exc)}

    tracer = _Tracer(compiled)
    error = None
    with UserIO(stream=False, limit=MAX_STDOUT, collect_stderr=False) as output, _MainModule() as namespace:
        tracer.output = output
        try:
            tracer.start()
            try:
                exec(compiled, namespace)
            finally:
                tracer.stop()
        except _StepLimit:
            pass
        except SystemExit as exc:
            if exc.code not in (None, 0):
                error = error_dict(exc)
        except BaseException as exc:
            error = error_dict(exc)
    return {"steps": tracer.steps, "truncated": tracer.truncated, "error": error}


class _Tracer:
    def __init__(self, module_code: types.CodeType):
        self.module_code = module_code
        self.codes: dict[int, types.CodeType] = {}
        _collect_codes(module_code, self.codes)
        self.steps: list[dict] = []
        self.truncated = False
        self.output: UserIO | None = None
        self.tool: int | None = None
        self._busy = False
        self._frame_ids: dict[int, tuple[types.FrameType, str]] = {}
        self._kept: dict[int, tuple[object, str]] = {}
        self._primitives: dict = {}
        self._stdout = ""
        self._stdout_size = 0

    # MARK: Monitoring

    def start(self) -> None:
        monitoring = sys.monitoring
        for tool in (monitoring.DEBUGGER_ID, 1, 2, 3, 4, 5):
            if monitoring.get_tool(tool) is None:
                monitoring.use_tool_id(tool, "cs-trace")
                self.tool = tool
                break
        else:
            raise RuntimeError("no free sys.monitoring tool id")
        tool = self.tool
        monitoring.register_callback(tool, _events.LINE, self._on_line)
        monitoring.register_callback(tool, _events.PY_START, self._on_start)
        monitoring.register_callback(tool, _events.PY_RETURN, self._on_return)
        monitoring.register_callback(tool, _events.RAISE, self._on_raise)
        local = _events.LINE | _events.PY_START | _events.PY_RETURN
        for code in self.codes.values():
            monitoring.set_local_events(tool, code, local)
        monitoring.set_events(tool, _events.RAISE)

    def stop(self) -> None:
        if self.tool is None:
            return
        monitoring = sys.monitoring
        tool = self.tool
        monitoring.set_events(tool, 0)
        for code in self.codes.values():
            monitoring.set_local_events(tool, code, 0)
        for event in (_events.LINE, _events.PY_START, _events.PY_RETURN, _events.RAISE):
            monitoring.register_callback(tool, event, None)
        monitoring.free_tool_id(tool)
        self.tool = None

    def _on_line(self, code, line):
        if self._busy:
            return
        self._record("line", sys._getframe(1), line)

    def _on_start(self, code, offset):
        if self._busy or code is self.module_code:
            return
        frame = sys._getframe(1)
        self._record("call", frame, frame.f_lineno)

    def _on_return(self, code, offset, value):
        if self._busy:
            return
        frame = sys._getframe(1)
        if code is self.module_code:
            # Final step, so output from the last line shows. The module has no return value.
            self._record("return", frame, frame.f_lineno)
        else:
            self._record("return", frame, frame.f_lineno, value)

    def _on_raise(self, code, offset, exc):
        if self._busy or id(code) not in self.codes or isinstance(exc, _StepLimit):
            return
        frame = sys._getframe(1)
        self._record("exception", frame, frame.f_lineno)

    # MARK: Steps

    def _record(self, event: str, frame, line, return_value=_StepLimit) -> None:
        if len(self.steps) >= MAX_STEPS:
            self.truncated = True
            raise _StepLimit()
        self._busy = True
        try:
            self.steps.append(self._snapshot(event, frame, line, return_value))
        finally:
            self._busy = False

    def _snapshot(self, event: str, top, line, return_value) -> dict:
        user_frames = []
        frame = top
        while frame is not None:
            if id(frame.f_code) in self.codes:
                user_frames.append(frame)
            frame = frame.f_back
        user_frames.reverse()

        heap = _Heap(self._kept, self._primitives)
        frames = []
        for frame in user_frames:
            is_module = frame.f_code is self.module_code
            local_vars = []
            for name, value in list(frame.f_locals.items()):
                if name.startswith("__") and name.endswith("__"):
                    continue
                if is_module and isinstance(value, types.ModuleType):
                    continue
                local_vars.append({"name": name, "value": heap.value(value)})
            entry = {
                "id": self._frame_id(frame),
                "function": frame.f_code.co_name,
                "line": (line if frame is top else frame.f_lineno) or 0,
                "locals": local_vars,
            }
            if frame is top and return_value is not _StepLimit:
                entry["returnValue"] = heap.value(return_value)
            frames.append(entry)
        heap.drain()

        return {
            "line": line if line is not None else 0,
            "event": event,
            "frames": frames,
            "heap": heap.objects,
            "stdout": self._current_stdout(),
        }

    def _frame_id(self, frame) -> str:
        known = self._frame_ids.get(id(frame))
        if known is not None and known[0] is frame:
            return known[1]
        frame_id = f"f{len(self._frame_ids) + 1}"
        self._frame_ids[id(frame)] = (frame, frame_id)
        return frame_id

    def _current_stdout(self) -> str:
        output = self.output
        if output is not None and output.size != self._stdout_size:
            self._stdout = output.text()
            self._stdout_size = output.size
        return self._stdout


def _collect_codes(code: types.CodeType, into: dict[int, types.CodeType]) -> None:
    into[id(code)] = code
    for const in code.co_consts:
        if isinstance(const, types.CodeType):
            _collect_codes(const, into)


# MARK: - Heap snapshot


class _Heap:
    """Builds one step's heap. `kept` holds every object ever referenced with its label, so ids stay unique."""

    def __init__(self, kept: dict[int, tuple[object, str]], primitives: dict):
        self.kept = kept
        self.primitives = primitives  # Shared encodings of ints and short strs, per run.
        self.objects: dict[str, dict] = {}
        self.pending: deque = deque()
        self.filled = 0

    def value(self, value) -> dict:
        kind = type(value)
        if kind in _CACHED:
            # One dict per type: `(int, 1) == (bool, True)`, so a shared tuple key would mix them.
            cache = self.primitives.get(kind)
            if cache is None:
                cache = self.primitives[kind] = {}
            encoded = cache.get(value)
            if encoded is None:
                encoded = {"repr": _short_repr(value), "type": kind.__name__}
                if kind is not str or len(value) <= 64:
                    cache[value] = encoded
            return encoded
        if kind in _PRIMITIVES:
            return {"repr": _short_repr(value), "type": kind.__name__}
        key = id(value)
        entry = self.kept.get(key)
        if entry is None:
            entry = (value, f"o{len(self.kept) + 1}")
            self.kept[key] = entry
        ref = entry[1]
        if ref not in self.objects:
            self.objects[ref] = None  # Reserved; filled in by `drain`.
            self.pending.append(value)
        return {"ref": ref}

    def drain(self) -> None:
        while self.pending:
            obj = self.pending.popleft()
            ref = self.kept[id(obj)][1]
            if self.filled >= MAX_HEAP:
                self.objects[ref] = _heap_object(ref, obj, "other", repr="…")
                continue
            self.objects[ref] = self._encode(ref, obj)
            self.filled += 1

    def _encode(self, ref: str, obj) -> dict:
        if isinstance(obj, (list, deque)):
            return self._sequence(ref, obj, "list")
        if isinstance(obj, tuple):
            return self._sequence(ref, obj, "tuple")
        if isinstance(obj, (set, frozenset)):
            return self._sequence(ref, obj, "set")
        if isinstance(obj, dict):
            entries = [
                {"key": self.value(k), "value": self.value(v)}
                for k, v in islice(list(obj.items()), MAX_ITEMS)
            ]
            return _heap_object(ref, obj, "dict", entries=entries, omitted=max(0, len(obj) - MAX_ITEMS))
        if isinstance(obj, _FUNCTION_TYPES):
            return _heap_object(ref, obj, "function", repr=_function_repr(obj))
        attributes = _attributes(obj)
        if attributes is not None:
            shown = [{"name": name, "value": self.value(v)} for name, v in attributes[:MAX_ITEMS]]
            return _heap_object(ref, obj, "object", attributes=shown, omitted=max(0, len(attributes) - MAX_ITEMS))
        return _heap_object(ref, obj, "other", repr=_short_repr(obj))

    def _sequence(self, ref: str, obj, kind: str) -> dict:
        items = [self.value(item) for item in islice(obj, MAX_ITEMS)]
        return _heap_object(ref, obj, kind, items=items, omitted=max(0, len(obj) - MAX_ITEMS))


def _heap_object(ref, obj, kind, items=None, entries=None, attributes=None, repr=None, omitted=0) -> dict:  # noqa: A002
    out = {"id": ref, "type": type(obj).__name__, "kind": kind, "omitted": omitted}
    if items is not None:
        out["items"] = items
    if entries is not None:
        out["entries"] = entries
    if attributes is not None:
        out["attributes"] = attributes
    if repr is not None:
        out["repr"] = repr
    return out


def _attributes(obj) -> list[tuple[str, object]] | None:
    """Instance attributes in definition order, or None if `obj` isn't a plain instance."""
    if isinstance(obj, (type, types.ModuleType)):
        return None
    try:
        attrs = object.__getattribute__(obj, "__dict__")
    except (AttributeError, TypeError):
        attrs = None
    pairs: list[tuple[str, object]] = []
    has_slots = False
    for klass in type(obj).__mro__:
        slots = klass.__dict__.get("__slots__")
        if slots is None:
            continue
        for name in (slots,) if isinstance(slots, str) else slots:
            if name in ("__dict__", "__weakref__"):
                continue
            has_slots = True
            try:
                pairs.append((name, object.__getattribute__(obj, name)))
            except AttributeError:
                pass
    if isinstance(attrs, dict):
        pairs.extend((k, v) for k, v in list(attrs.items()) if isinstance(k, str))
    elif not has_slots:
        return None
    return pairs


def _function_repr(fn) -> str:
    code = getattr(fn, "__code__", None)
    name = getattr(fn, "__name__", None) or type(fn).__name__
    if isinstance(code, types.CodeType):
        count = code.co_argcount + code.co_kwonlyargcount
        names = list(code.co_varnames[:count])
        if code.co_flags & 0x04:  # *args
            names.append("*" + code.co_varnames[count])
            count += 1
        if code.co_flags & 0x08:  # **kwargs
            names.append("**" + code.co_varnames[count])
        if isinstance(fn, types.MethodType) and names:
            names = names[1:]
        return f"{name}({', '.join(names)})"
    return f"{name}(…)"


def _short_repr(value) -> str:
    try:
        text = repr(value)
    except BaseException:
        text = f"<{type(value).__name__}>"
    if len(text) > MAX_REPR:
        text = text[: MAX_REPR - 1] + "…"
    return text
