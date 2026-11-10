"""Tests for tools/validate_content.py against a tiny fixture content tree.

They go through the real `cs-content dump` (Swift), so they are skipped without `swift`.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import validate_content  # noqa: E402

pytestmark = pytest.mark.skipif(shutil.which("swift") is None, reason="needs swift to build cs-content")

UNIT = "---\nid: u1\ntitle: Unit\n---\n"

LESSON = """---
id: l1
title: Lesson
---

Intro.

---

```python predict
print(1 + 2)
```
"""

TRACE_LESSON = """---
id: l2
title: Trace
---

```python trace stop={stop}
x = 1
y = x + 1
```

What is `y`?

- [x] 2
- [ ] 3
"""


def exercise(id_: str, solution: str) -> str:
    return f"""---
id: {id_}
title: Double
level: warmup
---

Double it.

```python starter
def double(x):
    pass
```

```tests
double(2) == 4
```

```python solution
{solution}
```
"""


def make_tree(tmp_path: Path, *, solution: str = "def double(x):\n    return x * 2", stop: int = 1, trace: bool = True) -> Path:
    root = tmp_path / "content"
    unit = root / "algos" / "01-unit"
    (unit / "exercises").mkdir(parents=True)
    (unit / "unit.md").write_text(UNIT)
    (unit / "01-intro.md").write_text(LESSON)
    if trace:
        (unit / "02-trace.md").write_text(TRACE_LESSON.format(stop=stop))
    (unit / "exercises" / "double.md").write_text(exercise("double", solution))
    return root


def run(root: Path, *extra: str) -> int:
    return validate_content.main(["--root", str(root), *extra])


def recorded(root: Path) -> dict[str, dict]:
    return {p.stem: json.loads(p.read_text()) for p in (root / "_recorded").glob("*.json")}


def test_valid_tree_records_outputs(tmp_path, capsys):
    root = make_tree(tmp_path)
    assert run(root) == 0
    files = recorded(root)
    assert len(files) == 2
    assert {"output": "3\n"} in files.values()
    trace = next(v["trace"] for v in files.values() if "trace" in v)
    assert len(trace["steps"]) >= 2
    assert "0 errors" in capsys.readouterr().out


def test_check_mode(tmp_path, capsys):
    root = make_tree(tmp_path)
    assert run(root, "--check") == 1  # nothing recorded yet
    assert not (root / "_recorded").exists()
    assert run(root) == 0
    assert run(root, "--check") == 0
    # Changing a block makes its recorded file stale.
    lesson = root / "algos" / "01-unit" / "01-intro.md"
    lesson.write_text(lesson.read_text().replace("1 + 2", "2 + 2"))
    assert run(root, "--check") == 1
    out = capsys.readouterr().out
    assert "out of date" in out and "stale" in out


def test_stale_recorded_files_are_deleted(tmp_path):
    root = make_tree(tmp_path)
    (root / "_recorded").mkdir()
    stale = root / "_recorded" / "0123456789abcdef.json"
    stale.write_text('{"output": "old"}\n')
    assert run(root) == 0
    assert not stale.exists()


def test_failing_solution(tmp_path, capsys):
    root = make_tree(tmp_path, solution="def double(x):\n    return x + 3")
    assert run(root) == 1
    assert "exercise double: error: reference solution does not pass" in capsys.readouterr().out


def test_bad_trace_stop(tmp_path, capsys):
    root = make_tree(tmp_path, stop=99)
    assert run(root) == 1
    assert "stop=99 is outside the trace" in capsys.readouterr().out


def test_loader_errors_use_path_line_message(tmp_path, capsys):
    root = make_tree(tmp_path, trace=False)
    (root / "algos" / "01-unit" / "unit.md").write_text("no frontmatter\n")
    assert run(root) == 1
    assert "unit.md:1: error:" in capsys.readouterr().out


def test_dump_lists_blocks_with_hashes(tmp_path):
    root = make_tree(tmp_path)
    package = validate_content.REPO / "Packages" / "CSKit"
    proc = subprocess.run(
        ["swift", "run", "--quiet", "--package-path", str(package), "cs-content", "dump", str(root)],
        capture_output=True, text=True,
    )
    dump = json.loads(proc.stdout)
    assert sorted(b["role"] for b in dump["blocks"]) == ["predict", "trace"]
    assert all(len(b["hash"]) == 16 for b in dump["blocks"])
    assert next(b for b in dump["blocks"] if b["role"] == "trace")["stop"] == 1
