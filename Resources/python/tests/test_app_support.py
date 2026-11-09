import json
import sys
import threading
import time
import types

import pytest

import app_support
from swift_schema import check


def run(code):
    out = json.loads(app_support.run(code))
    check(out, "RunResponse")
    return out


def run_tests(code, lines=(), python_tests="", timeout=1.0):
    out = json.loads(app_support.run_tests(code, json.dumps(list(lines)), python_tests, timeout))
    check(out, "TestReport")
    return out


@pytest.fixture
def bridge(monkeypatch):
    """A fake `_csbridge` that records writes and answers `readline` from a list."""
    module = types.ModuleType("_csbridge")
    module.writes = []
    module.prompts = []
    module.answers = []

    def write(stream, text):
        module.writes.append((stream, text))

    def readline(prompt):
        module.prompts.append(prompt)
        return module.answers.pop(0) if module.answers else None

    module.write = write
    module.readline = readline
    monkeypatch.setitem(sys.modules, "_csbridge", module)
    return module


# MARK: run


def test_run_falls_back_to_real_streams_without_bridge(capsys):
    assert "_csbridge" not in sys.modules
    out = run("print('hi')\nimport sys\nprint('oops', file=sys.stderr)")
    assert out == {"error": None}
    captured = capsys.readouterr()
    assert captured.out == "hi\n"
    assert captured.err == "oops\n"


def test_run_streams_through_bridge(bridge, capsys):
    run("print('a', 1)\nimport sys\nsys.stderr.write('e')")
    assert "".join(t for s, t in bridge.writes if s == 1) == "a 1\n"
    assert [t for s, t in bridge.writes if s == 2] == ["e"]
    assert capsys.readouterr().out == ""


def test_run_restores_streams_and_input():
    import builtins

    before = (sys.stdout, sys.stderr, builtins.input)
    run("print(1)")
    assert (sys.stdout, sys.stderr, builtins.input) == before


def test_input_reads_from_bridge(bridge):
    bridge.answers = ["Ada\n"]
    out = run("name = input('Name? ')\nprint('hi', name)")
    assert out["error"] is None
    assert bridge.prompts == ["Name? "]
    assert "".join(t for s, t in bridge.writes if s == 1) == "hi Ada\n"


def test_input_eof_raises(bridge):
    out = run("input()")
    assert out["error"]["type"] == "EOFError"
    assert out["error"]["line"] == 1


def test_fresh_globals_per_run():
    run("x = 1")
    out = run("print(x)")
    assert out["error"]["type"] == "NameError"


def test_name_is_main_and_dataclasses_work(capsys):
    out = run(
        "from dataclasses import dataclass\n"
        "@dataclass\nclass P:\n    x: int\n"
        "assert __name__ == '__main__'\nprint(P(1))"
    )
    assert out["error"] is None
    assert capsys.readouterr().out == "P(x=1)\n"


def test_error_line_and_traceback_hide_support_frames():
    out = run("def f(xs):\n    return xs[3]\n\nf([1, 2])\n")
    error = out["error"]
    assert error["type"] == "IndexError"
    assert error["message"] == "list index out of range"
    assert error["line"] == 2
    assert "app_support" not in error["traceback"]
    assert 'File "main.py", line 4' in error["traceback"]
    assert "return xs[3]" in error["traceback"]  # Source lines come from linecache.


def test_syntax_error_line():
    error = run("x = 1\ny = (\n")["error"]
    assert error["type"] == "SyntaxError"
    assert error["line"] == 2
    assert "app_support" not in error["traceback"]


def test_error_raised_inside_library_points_at_user_line():
    error = run("import json\n\njson.loads('{')\n")["error"]
    assert error["type"] == "JSONDecodeError"
    assert error["line"] == 3


def test_system_exit():
    assert run("import sys\nsys.exit()")["error"] is None
    assert run("import sys\nsys.exit(0)")["error"] is None
    assert run("import sys\nsys.exit(2)")["error"]["type"] == "SystemExit"


def test_keyboard_interrupt_is_reported():
    error = run("raise KeyboardInterrupt")["error"]
    assert error["type"] == "KeyboardInterrupt"


def test_stop_from_another_thread_interrupts_loop():
    tid = threading.get_ident()
    timer = threading.Timer(0.2, app_support._async_raise, (tid, KeyboardInterrupt))
    timer.start()
    start = time.perf_counter()
    error = run("while True:\n    pass\n")["error"]
    assert error["type"] == "KeyboardInterrupt"
    assert error["line"] in (1, 2)
    assert time.perf_counter() - start < 2


# MARK: run_tests


FIRST_TRUE = """
def first_true(xs):
    lo, hi = 0, len(xs)
    while lo < hi:
        mid = (lo + hi) // 2
        if xs[mid]: hi = mid
        else: lo = mid + 1
    return lo
"""


def test_tests_lines_pass():
    report = run_tests(FIRST_TRUE, [
        "first_true([False, False, True]) == 2",
        "first_true([]) == 0",
        "",
        "# comment",
        "first_true([True] * 5) == 0",
    ])
    assert report["loadError"] is None
    results = report["results"]
    assert [r["passed"] for r in results] == [True, True, True]
    first = results[0]
    assert first["name"] == "first_true([False, False, True]) == 2"
    assert first["input"] == "first_true([False, False, True])"
    assert first["expected"] == "2"
    assert first["got"] == "2"
    assert first["error"] is None
    assert first["duration"] >= 0


def test_unequal_result_fails_with_reprs():
    report = run_tests("def f(x):\n    return None", ["f('a') == 'a'"])
    result = report["results"][0]
    assert result["passed"] is False
    assert result["expected"] == "'a'"
    assert result["got"] == "None"
    assert result["error"] is None


def test_unhashable_and_nested_results_compare_by_equality():
    code = "def f():\n    return [{'a': [1, 2]}, {3}]"
    report = run_tests(code, ["f() == [{'a': [1, 2]}, {3}]", "f() == []"])
    assert [r["passed"] for r in report["results"]] == [True, False]
    assert report["results"][1]["got"] == "[{'a': [1, 2]}, {3}]"


def test_exception_in_call_fails_test_and_continues():
    code = "def f(xs):\n    return xs[0]"
    report = run_tests(code, ["f([]) == 0", "f([5]) == 5"])
    failed, passed = report["results"]
    assert failed["passed"] is False
    assert failed["error"]["type"] == "IndexError"
    assert failed["error"]["line"] == 2
    assert failed["expected"] == "0"
    assert failed["got"] is None
    assert failed["input"] == "f([])"
    assert passed["passed"] is True


def test_eq_that_raises_or_returns_non_bool():
    code = (
        "class Weird:\n"
        "    def __eq__(self, other):\n"
        "        raise ValueError('no')\n"
        "def f():\n    return Weird()\n"
    )
    result = run_tests(code, ["f() == 1"])["results"][0]
    assert result["passed"] is False
    assert result["error"]["type"] == "ValueError"


def test_truthy_expression_line():
    report = run_tests("def ok(s):\n    return s == '()'", ["ok('()')", "ok('(')"])
    assert [r["passed"] for r in report["results"]] == [True, False]
    assert report["results"][1]["got"] == "False"
    assert report["results"][1]["expected"] == "True"


def test_bad_test_line_is_a_failing_result():
    result = run_tests("x = 1", ["x == (1"])["results"][0]
    assert result["passed"] is False
    assert result["error"]["type"] == "SyntaxError"


def test_load_error():
    report = run_tests("def f(:\n    pass", ["f() == 1"])
    assert report["results"] == []
    assert report["loadError"]["type"] == "SyntaxError"
    assert report["loadError"]["line"] == 1

    report = run_tests("x = 1 / 0", ["x == 1"])
    assert report["loadError"]["type"] == "ZeroDivisionError"
    assert report["loadError"]["line"] == 1


def test_timeout_in_test():
    code = "def spin():\n    while True:\n        pass\n\ndef ok():\n    return 1"
    start = time.perf_counter()
    report = run_tests(code, ["spin() == 1", "ok() == 1"], timeout=0.3)
    elapsed = time.perf_counter() - start
    assert elapsed < 2
    timed_out, ok = report["results"]
    assert timed_out["passed"] is False
    assert timed_out["error"]["type"] == "TimeoutError"
    assert 0.25 < timed_out["duration"] < 1.5
    assert ok["passed"] is True


def test_timeout_cannot_be_swallowed():
    code = (
        "def spin():\n"
        "    while True:\n"
        "        try:\n"
        "            while True:\n"
        "                pass\n"
        "        except Exception:\n"
        "            pass\n"
    )
    start = time.perf_counter()
    result = run_tests(code, ["spin() == 1"], timeout=0.2)["results"][0]
    assert time.perf_counter() - start < 2
    assert result["error"]["type"] == "TimeoutError"


def test_timeout_while_loading():
    start = time.perf_counter()
    report = run_tests("while True:\n    pass", ["1 == 1"], timeout=0.2)
    assert time.perf_counter() - start < 2
    assert report["loadError"]["type"] == "TimeoutError"
    assert report["results"] == []


def test_no_stray_timeout_after_tests():
    run_tests("def f():\n    return 1", ["f() == 1"] * 20, timeout=0.01)
    time.sleep(0.1)  # A late async exception would raise here.


def test_output_during_tests_is_not_streamed(bridge):
    report = run_tests("def f():\n    print('noise')\n    return input()", ["f() == ''"])
    assert bridge.writes == []
    assert report["results"][0]["error"]["type"] == "EOFError"


def test_python_tests_asserts_and_functions():
    tests = (
        "from math import inf\n"
        "assert first_true([True]) == 0\n"
        "assert first_true([False]) == 0, 'none'\n"
        "def helper(n):\n"
        "    return [False] * n + [True]\n"
        "def test_long():\n"
        "    assert first_true(helper(100)) == 100\n"
        "def test_broken():\n"
        "    assert first_true(helper(2)) == 3\n"
    )
    report = run_tests(FIRST_TRUE, [], tests)
    results = {r["name"]: r for r in report["results"]}
    assert list(results) == [
        "assert first_true([True]) == 0",
        "assert first_true([False]) == 0, 'none'",
        "test_long",
        "test_broken",
    ]
    assert results["assert first_true([True]) == 0"]["passed"] is True
    assert results["assert first_true([True]) == 0"]["input"] == "first_true([True])"
    wrong = results["assert first_true([False]) == 0, 'none'"]
    assert wrong["passed"] is False and wrong["got"] == "1" and wrong["expected"] == "0"
    assert results["test_long"]["passed"] is True
    assert results["test_broken"]["passed"] is False
    assert results["test_broken"]["error"]["type"] == "AssertionError"


def test_python_tests_setup_failure_is_reported():
    report = run_tests("x = 1", [], "import does_not_exist\nassert x == 1\n")
    names = [(r["name"], r["passed"]) for r in report["results"]]
    assert names == [("import does_not_exist", False), ("assert x == 1", True)]


def test_lines_and_python_tests_together():
    report = run_tests("def f():\n    return 2", ["f() == 2"], "assert f() > 1")
    assert [r["passed"] for r in report["results"]] == [True, True]


def test_keyboard_interrupt_stops_remaining_tests():
    report = run_tests("def f():\n    raise KeyboardInterrupt", ["f() == 1", "f() == 2"])
    assert len(report["results"]) == 1
    assert report["results"][0]["error"]["type"] == "KeyboardInterrupt"
