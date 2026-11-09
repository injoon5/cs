import json
import random
import sys
import time

import app_support
from swift_schema import check, check_trace_refs


def trace(code):
    out = json.loads(app_support.trace(code))
    check(out, "Trace")
    check_trace_refs(out)
    return out


def local(frame, name):
    for var in frame["locals"]:
        if var["name"] == name:
            return var["value"]
    raise KeyError(name)


def names(frame):
    return [v["name"] for v in frame["locals"]]


FACT = """\
def fact(n):
    if n <= 1:
        return 1
    return n * fact(n - 1)

print(fact(3))
"""


def test_recursion_frames_grow_and_shrink():
    result = trace(FACT)
    assert result["error"] is None
    assert result["truncated"] is False
    steps = result["steps"]
    depths = [len(s["frames"]) for s in steps]
    assert max(depths) == 4  # <module> + fact(3), fact(2), fact(1)
    assert depths[0] == 1 and depths[-1] == 1

    deepest = next(s for s in steps if len(s["frames"]) == 4)
    assert [f["function"] for f in deepest["frames"]] == ["<module>", "fact", "fact", "fact"]
    assert [local(f, "n")["repr"] for f in deepest["frames"][1:]] == ["3", "2", "1"]
    # Outer frames sit on the line that made the call.
    assert [f["line"] for f in deepest["frames"][:-1]] == [6, 4, 4]

    returns = [s for s in steps if s["event"] == "return" and len(s["frames"]) > 1]
    assert [s["frames"][-1]["returnValue"]["repr"] for s in returns] == ["1", "2", "6"]
    assert all("returnValue" not in f for s in returns for f in s["frames"][:-1])

    calls = [s for s in steps if s["event"] == "call"]
    assert len(calls) == 3
    assert calls[0]["line"] == 1
    assert names(calls[0]["frames"][-1]) == ["n"]

    assert steps[-1]["event"] == "return"
    assert steps[-1]["stdout"] == "6\n"
    assert all(s["stdout"] == "" for s in steps[:-1])


def test_frame_ids_are_stable_per_call_and_unique_across_calls():
    steps = trace(FACT)["steps"]
    ids_by_depth: dict[int, set] = {}
    for step in steps:
        for depth, frame in enumerate(step["frames"]):
            ids_by_depth.setdefault(depth, set()).add(frame["id"])
    assert all(len(ids) == 1 for ids in ids_by_depth.values())
    assert len({next(iter(ids)) for ids in ids_by_depth.values()}) == 4

    loop = trace("def f(x):\n    return x\n\nfor i in range(3):\n    f(i)\n")["steps"]
    call_ids = [s["frames"][-1]["id"] for s in loop if s["event"] == "call"]
    assert len(set(call_ids)) == 3


def test_aliasing_two_names_one_object():
    code = "a = [1, 2]\nb = a\nb.append(3)\nc = [1, 2, 3]\n"
    steps = trace(code)["steps"]
    last = steps[-1]
    module = last["frames"][0]
    a, b, c = local(module, "a"), local(module, "b"), local(module, "c")
    assert a == b
    assert a != c
    items = last["heap"][a["ref"]]["items"]
    assert [i["repr"] for i in items] == ["1", "2", "3"]

    # Mutation shows up in later steps only.
    before = next(s for s in steps if s["line"] == 3 and s["event"] == "line")
    assert len(before["heap"][a["ref"]]["items"]) == 2


def test_locals_in_definition_order_and_dunders_hidden():
    code = "import math\nzeta = 1\nalpha = 2\ndef f():\n    pass\nmiddle = 3\n"
    last = trace(code)["steps"][-1]
    assert names(last["frames"][0]) == ["zeta", "alpha", "f", "middle"]


def test_heap_kinds():
    code = (
        "from collections import deque\n"
        "class Node:\n"
        "    def __init__(self, val):\n"
        "        self.val = val\n"
        "        self.next = None\n"
        "class P:\n"
        "    __slots__ = ('x', 'y')\n"
        "    def __init__(self):\n"
        "        self.x = 1\n"
        "        self.y = 2\n"
        "n = Node(5)\n"
        "n.next = Node(6)\n"
        "t = (1, 'a')\n"
        "s = {3}\n"
        "d = {'k': [1]}\n"
        "q = deque([1])\n"
        "p = P()\n"
        "r = range(3)\n"
        "z = None\n"
    )
    last = trace(code)["steps"][-1]
    module = last["frames"][0]
    heap = last["heap"]

    def obj(name):
        return heap[local(module, name)["ref"]]

    node = obj("n")
    assert node["kind"] == "object" and node["type"] == "Node"
    assert [a["name"] for a in node["attributes"]] == ["val", "next"]
    nxt = heap[node["attributes"][1]["value"]["ref"]]
    assert nxt["attributes"][1]["value"] == {"repr": "None", "type": "NoneType"}
    assert obj("t")["kind"] == "tuple"
    assert obj("t")["items"][1] == {"repr": "'a'", "type": "str"}
    assert obj("s")["kind"] == "set"
    d = obj("d")
    assert d["kind"] == "dict"
    assert d["entries"][0]["key"] == {"repr": "'k'", "type": "str"}
    assert heap[d["entries"][0]["value"]["ref"]]["kind"] == "list"
    assert obj("q")["kind"] == "list" and obj("q")["type"] == "deque"
    assert [a["name"] for a in obj("p")["attributes"]] == ["x", "y"]
    assert obj("r")["kind"] == "other" and obj("r")["repr"] == "range(0, 3)"
    assert obj("Node")["kind"] == "other"
    init = trace("def f(a, *rest, k=1, **kw):\n    pass\n")["steps"][-1]
    fn = init["heap"][local(init["frames"][0], "f")["ref"]]
    assert fn["kind"] == "function" and fn["repr"] == "f(a, k, *rest, **kw)"
    assert local(module, "z") == {"repr": "None", "type": "NoneType"}


def test_first_50_items_and_omitted():
    last = trace("a = list(range(120))\nd = {i: i for i in range(60)}\n")["steps"][-1]
    heap = last["heap"]
    a = heap[local(last["frames"][0], "a")["ref"]]
    assert len(a["items"]) == 50 and a["omitted"] == 70
    d = heap[local(last["frames"][0], "d")["ref"]]
    assert len(d["entries"]) == 50 and d["omitted"] == 10


def test_ids_not_reused_during_run():
    # Each list dies right away; without held references CPython would reuse the address.
    code = "for i in range(20):\n    x = [i]\n"
    steps = trace(code)["steps"]
    refs = {}
    for step in steps:
        frame = step["frames"][0]
        if "x" in names(frame):
            ref = local(frame, "x")["ref"]
            value = step["heap"][ref]["items"][0]["repr"]
            refs.setdefault(ref, set()).add(value)
    assert len(refs) == 20
    assert all(len(values) == 1 for values in refs.values())


def test_step_limit_truncates():
    result = trace("i = 0\nwhile True:\n    i += 1\n")
    assert result["truncated"] is True
    assert result["error"] is None
    assert len(result["steps"]) == 1000


def test_step_limit_survives_bare_except():
    code = "while True:\n    try:\n        x = 1\n    except BaseException:\n        pass\n"
    result = trace(code)
    assert result["truncated"] is True
    assert len(result["steps"]) == 1000


def test_exception_event_and_error():
    code = "def f(xs):\n    return xs[5]\n\ntry:\n    f([])\nexcept IndexError:\n    pass\nf([1])\n"
    result = trace(code)
    exceptions = [s for s in result["steps"] if s["event"] == "exception"]
    # One event per frame the exception passes through, like settrace.
    assert [s["line"] for s in exceptions] == [2, 5, 2, 8]
    assert exceptions[0]["frames"][-1]["function"] == "f"
    error = result["error"]
    assert error["type"] == "IndexError"
    assert error["line"] == 2
    assert "trace.py" not in error["traceback"]


def test_syntax_error():
    result = trace("x = (\n")
    assert result["steps"] == []
    assert result["error"]["type"] == "SyntaxError"


def test_stdout_accumulates_and_library_code_is_skipped():
    code = "import json\nprint('a')\ns = json.dumps([1])\nprint(s)\n"
    steps = trace(code)["steps"]
    assert {len(s["frames"]) for s in steps} == {1}
    assert [s["line"] for s in steps if s["event"] == "line"] == [1, 2, 3, 4]
    assert steps[-1]["stdout"] == "a\n[1]\n"
    line3 = next(s for s in steps if s["line"] == 3)
    assert line3["stdout"] == "a\n"


def test_user_repr_does_not_recurse_into_tracer():
    code = (
        "class R:\n"
        "    def __repr__(self):\n"
        "        return 'R!'\n"
        "class Weird(int):\n"
        "    pass\n"
        "r = [R()]\n"
        "w = Weird(3)\n"
    )
    result = trace(code)
    assert result["error"] is None
    assert not any(s["frames"][-1]["function"] == "__repr__" for s in result["steps"])


def test_monitoring_tool_released():
    trace("x = 1")
    assert sys.monitoring.get_tool(sys.monitoring.DEBUGGER_ID) is None


def test_bubble_sort_50_items_is_fast():
    random.seed(1)
    data = list(range(50))
    random.shuffle(data)
    code = (
        f"a = {data}\n"
        "n = len(a)\n"
        "for i in range(n):\n"
        "    for j in range(n - 1 - i):\n"
        "        if a[j] > a[j + 1]:\n"
        "            a[j], a[j + 1] = a[j + 1], a[j]\n"
    )
    start = time.perf_counter()
    out = app_support.trace(code)
    elapsed = time.perf_counter() - start
    result = json.loads(out)
    assert result["truncated"] is True
    assert len(result["steps"]) == 1000
    print(f"bubble sort 50 items: {elapsed * 1000:.0f} ms, {len(out) / 1024:.0f} KB JSON")
    assert elapsed < 1.0


def test_equal_values_of_different_types_keep_their_type():
    last = trace("a = [1, True, 1.0, '1', 0.0, -0.0]\n")["steps"][-1]
    items = last["heap"][local(last["frames"][0], "a")["ref"]]["items"]
    assert [(i["repr"], i["type"]) for i in items] == [
        ("1", "int"), ("True", "bool"), ("1.0", "float"), ("'1'", "str"), ("0.0", "float"), ("-0.0", "float"),
    ]
