#!/usr/bin/env python3
"""Validates `content/` and records predict outputs and trace JSON.

    python3 tools/validate_content.py [--root content] [--dump dump.json] [--check]

1. Loads content through `cs-content dump` (Swift, `Packages/CSKit/Sources/ContentTool`), so parsing
   and block hashing live in one place. `--dump FILE` reads a saved dump instead.
2. Reports loader errors as `path:line: message`.
3. Runs every python exercise's solution against its tests (must pass) and its starter (should not).
4. Runs each `predict` block and writes `<root>/_recorded/<hash>.json` {"output": ...}; records each
   `trace` block as {"trace": ...} and checks that `stop=N` is a step index (0 <= N < steps).
5. Deletes `_recorded` files no block references; checks ids are unique and cards have answers.

`--check` writes nothing and fails if any recorded file would change (for CI).
Shell exercises are skipped until the Linux image exists.
"""

from __future__ import annotations

import argparse
import contextlib
import importlib.util
import io
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PYTHON_SUPPORT = REPO / "Resources" / "python"
TEST_TIMEOUT = 5.0


def load_app_support():
    spec = importlib.util.spec_from_file_location("app_support", PYTHON_SUPPORT / "app_support.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules["app_support"] = module
    spec.loader.exec_module(module)
    return module


def load_dump(root: Path, dump_file: Path | None) -> dict:
    if dump_file is not None:
        return json.loads(dump_file.read_text(encoding="utf-8"))
    cmd = ["swift", "run", "--quiet", "--package-path", str(REPO / "Packages" / "CSKit"), "cs-content", "dump", str(root)]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    try:
        return json.loads(proc.stdout)
    except ValueError:
        sys.exit(f"cs-content failed (exit {proc.returncode}):\n{proc.stderr or proc.stdout}")


class Report:
    def __init__(self) -> None:
        self.errors = 0
        self.warnings = 0

    def error(self, where: str, message: str) -> None:
        self.errors += 1
        print(f"{where}: error: {message}")

    def warn(self, where: str, message: str) -> None:
        self.warnings += 1
        print(f"{where}: warning: {message}")


def encode(value: dict) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":")) + "\n"


# MARK: Checks


def check_ids(tracks: list[dict], report: Report) -> None:
    seen: dict[str, dict[str, str]] = {"track": {}, "lesson": {}, "exercise": {}, "card": {}}

    def claim(kind: str, id_: str, owner: str) -> None:
        if id_ in seen[kind]:
            report.error(owner, f"{kind} id `{id_}` is also used in {seen[kind][id_]}")
        else:
            seen[kind][id_] = owner

    for track in tracks:
        claim("track", track["id"], f"track {track['id']}")
        for unit in track["units"]:
            for lesson in unit["lessons"]:
                claim("lesson", lesson["id"], f"unit {unit['id']}")
            for exercise in unit["exercises"]:
                claim("exercise", exercise["id"], f"unit {unit['id']}")
            for card in unit["cards"]:
                claim("card", card["id"], f"unit {unit['id']}")
                if not card["answer"].strip():
                    report.error(f"unit {unit['id']}", f"card `{card['question']}` has an empty answer")


def check_exercises(app_support, tracks: list[dict], report: Report) -> int:
    skipped = 0
    for track in tracks:
        for unit in track["units"]:
            for ex in unit["exercises"]:
                where = f"exercise {ex['id']}"
                if ex["language"] != "python":
                    skipped += 1
                    continue
                if passes(app_support, ex, ex["solution"], report, where) is not True:
                    report.error(where, "reference solution does not pass its tests")
                if passes(app_support, ex, ex["starter"], report, where) is True:
                    report.warn(where, "starter already passes its tests")
    return skipped


def passes(app_support, ex: dict, code: str, report: Report, where: str) -> bool | None:
    """True when every test passes. Prints the first failure for solutions via the caller's message."""
    raw = app_support.run_tests(code, json.dumps(ex["testLines"]), ex.get("pythonTests") or "", TEST_TIMEOUT)
    result = json.loads(raw)
    if result.get("loadError"):
        err = result["loadError"]
        if code is ex["solution"]:
            print(f"  {where}: {err.get('type')}: {err.get('message')}")
        return False
    results = result["results"]
    if not results:
        report.error(where, "no tests ran")
        return None
    failed = [r for r in results if not r["passed"]]
    if failed and code is ex["solution"]:
        for r in failed[:3]:
            detail = r.get("error") and f"{r['error'].get('type')}: {r['error'].get('message')}" or f"expected {r.get('expected')}, got {r.get('got')}"
            print(f"  {where}: {r.get('input') or r.get('name')}: {detail}")
    return not failed


def record_blocks(app_support, blocks: list[dict], report: Report) -> dict[str, str]:
    """Returns {hash: file text} for every predict and trace block."""
    wanted: dict[str, str] = {}
    for block in blocks:
        where = f"lesson {block['lessonId']}"
        if block["role"] == "predict":
            buffer = io.StringIO()
            with contextlib.redirect_stdout(buffer):
                result = json.loads(app_support.run(block["source"]))
            if result["error"]:
                report.error(where, f"predict block raised {result['error']['type']}: {result['error']['message']}")
                continue
            wanted[block["hash"]] = encode({"output": buffer.getvalue()})
        else:
            trace = json.loads(app_support.trace(block["source"]))
            steps = len(trace["steps"])
            if trace["error"]:
                report.warn(where, f"trace block ends with {trace['error']['type']}: {trace['error']['message']}")
            stop = block.get("stop")
            if stop is not None and not 0 <= stop < steps:
                report.error(where, f"trace stop={stop} is outside the trace ({steps} steps, indices 0..{max(steps - 1, 0)})")
            wanted[block["hash"]] = encode({"trace": trace})
    return wanted


def sync_recorded(root: Path, wanted: dict[str, str], check: bool, report: Report) -> tuple[int, int]:
    folder = root / "_recorded"
    existing = {p.stem: p for p in folder.glob("*.json")} if folder.is_dir() else {}
    changed = removed = 0
    for hash_, text in sorted(wanted.items()):
        path = folder / f"{hash_}.json"
        if path.is_file() and path.read_text(encoding="utf-8") == text:
            continue
        changed += 1
        if check:
            report.error(f"_recorded/{hash_}.json", "missing or out of date; run tools/validate_content.py")
        else:
            folder.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
    for hash_, path in sorted(existing.items()):
        if hash_ in wanted:
            continue
        removed += 1
        if check:
            report.error(f"_recorded/{hash_}.json", "stale; no block references it")
        else:
            path.unlink()
    return changed, removed


# MARK: Main


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=REPO / "content", help="content folder (default: content)")
    parser.add_argument("--dump", type=Path, help="read this cs-content dump instead of running Swift")
    parser.add_argument("--check", action="store_true", help="write nothing; fail if recorded files would change")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    dump = load_dump(root, args.dump)
    report = Report()

    for err in dump["errors"]:
        where = err["path"] or str(root)
        if err.get("line") is not None:
            where += f":{err['line']}"
        report.error(where, err["message"])

    app_support = load_app_support()
    tracks = dump["tracks"]
    check_ids(tracks, report)
    skipped = check_exercises(app_support, tracks, report)
    wanted = record_blocks(app_support, dump["blocks"], report)

    if report.errors and not args.check:
        # Don't prune recorded files while blocks may be missing from a partial load.
        changed, removed = 0, 0
    else:
        changed, removed = sync_recorded(root, wanted, args.check, report)

    exercises = sum(len(u["exercises"]) for t in tracks for u in t["units"])
    lessons = sum(len(u["lessons"]) for t in tracks for u in t["units"])
    print(f"{lessons} lessons, {exercises} exercises ({skipped} shell skipped), {len(wanted)} recorded blocks "
          f"({changed} written, {removed} removed), {report.errors} errors, {report.warnings} warnings")
    if skipped:
        print("note: shell exercises are not run yet (needs the Linux image)")
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
