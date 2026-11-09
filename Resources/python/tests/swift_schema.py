"""Key sets of the Swift `Contracts` types, to check that our JSON decodes into them.

Mirrors Packages/CSKit/Sources/Contracts/{Run,Trace,Shapes}.swift. A struct is
{"key": spec}; `Opt(spec)` may be missing or null; everything else must be present and non-null.
Unknown keys are errors (Swift would ignore them, but they'd mean a typo here).
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Opt:
    spec: object


@dataclass(frozen=True)
class List:
    spec: object


@dataclass(frozen=True)
class Map:
    spec: object


@dataclass(frozen=True)
class Enum:
    values: tuple


INT, DOUBLE, STR, BOOL = "Int", "Double", "String", "Bool"

STRUCTS: dict[str, dict] = {
    # Run.swift
    "PythonError": {"type": STR, "message": STR, "traceback": STR, "line": Opt(INT)},
    "TestResult": {
        "name": STR, "passed": BOOL, "input": Opt(STR), "expected": Opt(STR), "got": Opt(STR),
        "error": Opt("PythonError"), "duration": DOUBLE,
    },
    "TestReport": {"results": List("TestResult"), "loadError": Opt("PythonError")},
    # Trace.swift
    "Trace": {"steps": List("TraceStep"), "truncated": BOOL, "error": Opt("PythonError")},
    "TraceStep": {
        "line": INT, "event": Enum(("line", "call", "return", "exception")),
        "frames": List("TraceFrame"), "heap": Map("HeapObject"), "stdout": STR,
    },
    "TraceFrame": {
        "id": STR, "function": STR, "line": INT, "locals": List("Variable"), "returnValue": Opt("TraceValue"),
    },
    "Variable": {"name": STR, "value": "TraceValue"},
    "HeapObject": {
        "id": STR, "type": STR, "kind": Enum(("list", "tuple", "set", "dict", "object", "function", "other")),
        "items": Opt(List("TraceValue")), "entries": Opt(List("DictEntry")),
        "attributes": Opt(List("Variable")), "repr": Opt(STR), "omitted": INT,
    },
    "DictEntry": {"key": "TraceValue", "value": "TraceValue"},
    # Shapes.swift
    "Pointer": {"name": STR, "index": INT},
    "IndexRange": {"lower": INT, "upper": INT},
    "ArrayShape": {
        "name": Opt(STR), "values": List(STR), "pointers": List("Pointer"),
        "shaded": List("IndexRange"), "highlighted": List(INT),
    },
    "GridCell": {"row": INT, "column": INT},
    "GridArrow": {"from": "GridCell", "to": "GridCell"},
    "GridShape": {
        "name": Opt(STR), "rows": List(List(STR)), "rowLabels": Opt(List(STR)),
        "columnLabels": Opt(List(STR)), "highlighted": List("GridCell"), "arrows": List("GridArrow"),
    },
    "TreeNode": {"id": STR, "label": STR, "children": List(Opt(STR))},
    "TreeShape": {"root": Opt(STR), "nodes": List("TreeNode"), "active": List(STR), "dimmed": List(STR)},
    "GraphNode": {"id": STR, "label": STR, "x": Opt(DOUBLE), "y": Opt(DOUBLE)},
    "GraphEdge": {"from": STR, "to": STR, "weight": Opt(STR)},
    "GraphShape": {
        "directed": BOOL, "nodes": List("GraphNode"), "edges": List("GraphEdge"),
        "visited": List(STR), "frontier": List(STR), "active": List(STR),
    },
    "LinkedListShape": {"nodes": List("TreeNode"), "pointers": Map(Opt(STR))},
    "SequenceShape": {"name": Opt(STR), "items": List(STR), "highlighted": List(INT)},
    "BitsShape": {"bits": List(BOOL), "groupSize": INT, "highlighted": List(INT)},
    "VizFrame": {"shapes": List("Shape"), "note": Opt(STR)},
    # docs/contracts.md
    "RunResponse": {"error": Opt("PythonError")},
    "VisualizeResponse": {"frames": List("VizFrame"), "output": STR, "error": Opt("PythonError")},
}

SHAPE_KINDS = {
    "array": "ArrayShape", "grid": "GridShape", "tree": "TreeShape", "graph": "GraphShape",
    "linked_list": "LinkedListShape", "stack": "SequenceShape", "queue": "SequenceShape", "bits": "BitsShape",
}


def check(value, spec, path: str = "$") -> None:
    """Raises AssertionError with a JSON path if `value` wouldn't decode as `spec`."""
    if isinstance(spec, Opt):
        if value is not None:
            check(value, spec.spec, path)
        return
    assert value is not None, f"{path}: null for non-optional {spec}"
    if spec == INT:
        assert isinstance(value, int) and not isinstance(value, bool), f"{path}: {value!r} is not Int"
    elif spec == DOUBLE:
        assert isinstance(value, (int, float)) and not isinstance(value, bool), f"{path}: {value!r} is not Double"
    elif spec == STR:
        assert isinstance(value, str), f"{path}: {value!r} is not String"
    elif spec == BOOL:
        assert isinstance(value, bool), f"{path}: {value!r} is not Bool"
    elif isinstance(spec, Enum):
        assert value in spec.values, f"{path}: {value!r} not in {spec.values}"
    elif isinstance(spec, List):
        assert isinstance(value, list), f"{path}: not a list"
        for i, item in enumerate(value):
            check(item, spec.spec, f"{path}[{i}]")
    elif isinstance(spec, Map):
        assert isinstance(value, dict), f"{path}: not an object"
        for key, item in value.items():
            assert isinstance(key, str)
            check(item, spec.spec, f"{path}.{key}")
    elif spec == "TraceValue":
        assert isinstance(value, dict), f"{path}: not an object"
        if "ref" in value:
            assert set(value) == {"ref"} and isinstance(value["ref"], str), f"{path}: bad ref {value}"
        else:
            assert set(value) == {"repr", "type"}, f"{path}: bad primitive {value}"
            assert isinstance(value["repr"], str) and isinstance(value["type"], str)
    elif spec == "Shape":
        assert isinstance(value, dict), f"{path}: not an object"
        kind = value.get("kind")
        assert kind in SHAPE_KINDS, f"{path}: unknown kind {kind!r}"
        body = {k: v for k, v in value.items() if k != "kind"}
        check(body, SHAPE_KINDS[kind], path)
    elif isinstance(spec, str):
        fields = STRUCTS[spec]
        assert isinstance(value, dict), f"{path}: {spec} is not an object"
        extra = set(value) - set(fields)
        assert not extra, f"{path}: unknown keys {extra} for {spec}"
        for key, field in fields.items():
            if key not in value:
                assert isinstance(field, Opt), f"{path}: missing {key} for {spec}"
                continue
            check(value[key], field, f"{path}.{key}")
    else:
        raise TypeError(f"bad spec {spec!r}")


def check_trace_refs(trace: dict) -> None:
    """Every ref in a step points into that step's heap, and heap keys match ids."""

    def refs(value):
        if isinstance(value, dict):
            if set(value) == {"ref"}:
                yield value["ref"]
            else:
                for v in value.values():
                    yield from refs(v)
        elif isinstance(value, list):
            for v in value:
                yield from refs(v)

    for n, step in enumerate(trace["steps"]):
        heap = step["heap"]
        for key, obj in heap.items():
            assert obj["id"] == key, f"step {n}: heap key {key} != id {obj['id']}"
        for ref in refs({"frames": step["frames"], "heap": list(heap.values())}):
            assert ref in heap, f"step {n}: dangling ref {ref}"
