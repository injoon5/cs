"""Algorithm animations. User code calls these; `app_support.visualize` collects the frames.

Each call below adds one frame holding one shape (`Shape` in Swift `Contracts/Shapes.swift`):

    viz.array(a, pointers={"i": i}, range=(lo, hi), highlight=[j], name="a")
    viz.grid(dp, highlight=(r, c), row_labels=None, col_labels=None, arrows=[((r, c), (r - 1, c))])
    viz.tree(root, active=node, dimmed=None)
    viz.graph(adj, visited=seen, frontier=queue, active=node, directed=False)
    viz.linked_list(head, pointers={"prev": prev, "cur": cur})
    viz.stack(items, highlight=None, name=None)
    viz.queue(items, highlight=None, name=None)
    viz.bits(n, width=8, highlight=None, group=8)
    viz.note("swap")

Every shape call also takes `note=` (same as calling `viz.note` just before it).
To put several shapes in one frame:

    with viz.frame():
        viz.array(a)
        viz.stack(st)

Notes: `viz.note(text)` attaches to the next frame. A note with no frame after it attaches to
the last frame (joined with a newline if that frame has one). A note before any frame at all
makes a frame with no shapes.

Values are display strings:
- arrays, stacks, queues: `repr`, like Python prints a list (`'a'`, `1`, `None`).
- grid cells, tree/list node labels, graph labels, edge weights: `str` (`a`, `1`), with `None`
  as an empty cell in grids.
- `float("inf")` shows as `∞` everywhere.

Shape details:
- `array`: `pointers` maps name to index; a `None` index is skipped. `range` is `(lo, hi)`,
  inclusive, or a list of them; an empty range (`lo > hi`) is skipped. `highlight` is an index
  or a list.
- `grid`: rows are lists, or strings (one cell per character). `highlight` is `(r, c)` or a list.
  `arrows` is a list of `((r, c), (r2, c2))`, from the first cell to the second.
- `tree`: nodes with `left`/`right` (a missing side keeps an open slot) or `children`. Label
  from `val`, `value`, `key` or `data`, else `str(node)`. Ids are `id(node)`. A list is drawn
  as a binary heap (children of `i` are `2i+1`, `2i+2`); then ids, `active` and `dimmed` are
  indices.
- `graph`: `adj` maps node to neighbors, `(neighbor, weight)` pairs, or a `{neighbor: weight}`
  dict; a list of lists uses indices as nodes. Node ids are `repr(node)`, labels `str(node)`.
  Undirected graphs drop the reverse copy of each edge.
- `linked_list`: follows `next` from `head`, then from each pointer that isn't in that chain
  yet (so `prev` stays visible during a reversal). A node's `children` is `[next id]`.
  A cycle ends the walk, with the last node pointing back. Ids are `id(node)`.
- `bits`: most significant bit first. Negative numbers are two's complement in `width` bits;
  a positive number wider than `width` widens. `highlight` takes bit positions (0 = least
  significant), as in `n >> i & 1`.

At most 1,000 frames are kept per run; later calls are ignored.
"""

from __future__ import annotations

import builtins
import math
from contextlib import contextmanager

MAX_FRAMES = 1000

_frames: list[dict] = []
_pending_note: list[str] = []
_group: list[dict] | None = None


# MARK: - Collection (used by app_support)


def _reset() -> None:
    global _group
    _frames.clear()
    _pending_note.clear()
    _group = None


def _finish() -> list[dict]:
    global _group
    if _group is not None:
        _emit(_group)
        _group = None
    if _pending_note:
        text = "\n".join(_pending_note)
        _pending_note.clear()
        if _frames:
            last = _frames[-1]
            last["note"] = f"{last['note']}\n{text}" if last.get("note") else text
        else:
            _frames.append({"shapes": [], "note": text})
    frames = list(_frames)
    _frames.clear()
    return frames


def _emit(shapes: list[dict]) -> None:
    note = "\n".join(_pending_note) if _pending_note else None
    _pending_note.clear()
    if len(_frames) >= MAX_FRAMES:
        return
    _frames.append({"shapes": shapes, "note": note})


def _add(shape: dict, note: str | None) -> None:
    if note is not None:
        _pending_note.append(str(note))
    if _group is not None:
        _group.append(shape)
    else:
        _emit([shape])


@contextmanager
def frame():
    """Collects the shapes drawn inside the block into one frame."""
    global _group
    if _group is not None:  # Nested: the outer block owns the frame.
        yield
        return
    _group = []
    try:
        yield
    finally:
        shapes, _group = _group, None
        if shapes:
            _emit(shapes)


def note(text) -> None:
    """Caption for the next frame."""
    _pending_note.append(str(text))


# MARK: - Shapes


def array(a, pointers=None, range=None, highlight=None, name=None, note=None) -> None:  # noqa: A002
    values = [_show(v) for v in a]
    shape = {
        "kind": "array",
        "name": None if name is None else str(name),
        "values": values,
        "pointers": [
            {"name": str(key), "index": int(index)}
            for key, index in _pairs(pointers)
            if index is not None
        ],
        "shaded": _ranges(range),
        "highlighted": _indices(highlight),
    }
    _add(shape, note)


def grid(rows, highlight=None, row_labels=None, col_labels=None, arrows=None, name=None, note=None) -> None:
    table = [[_cell(v) for v in row] for row in rows]
    shape = {
        "kind": "grid",
        "name": None if name is None else str(name),
        "rows": table,
        "rowLabels": None if row_labels is None else [_label(v) for v in row_labels],
        "columnLabels": None if col_labels is None else [_label(v) for v in col_labels],
        "highlighted": [_grid_cell(c) for c in _cells(highlight)],
        "arrows": [{"from": _grid_cell(a), "to": _grid_cell(b)} for a, b in (arrows or [])],
    }
    _add(shape, note)


def tree(root, active=None, dimmed=None, note=None) -> None:
    if isinstance(root, list):
        shape = _heap_tree(root, active, dimmed)
    else:
        shape = _object_tree(root, active, dimmed)
    _add(shape, note)


def graph(adj, visited=None, frontier=None, active=None, directed=False, note=None) -> None:
    if isinstance(adj, (list, tuple)):
        adj = dict(enumerate(adj))
    nodes: dict[str, dict] = {}
    edges: list[dict] = []
    seen_edges: set = set()

    def add_node(n) -> str:
        node_id = _node_id(n)
        if node_id not in nodes:
            nodes[node_id] = {"id": node_id, "label": _label(n), "x": None, "y": None}
        return node_id

    for source in adj:
        add_node(source)
    for source, neighbors in adj.items():
        source_id = _node_id(source)
        for target, weight in _neighbors(neighbors):
            target_id = add_node(target)
            key = (source_id, target_id) if directed else frozenset((source_id, target_id))
            if not directed and source_id == target_id:
                key = (source_id, source_id)
            if key in seen_edges:
                continue
            seen_edges.add(key)
            edges.append({"from": source_id, "to": target_id, "weight": None if weight is None else _label(weight)})

    shape = {
        "kind": "graph",
        "directed": bool(directed),
        "nodes": list(nodes.values()),
        "edges": edges,
        "visited": [_node_id(n) for n in _many(visited, nodes)],
        "frontier": [_node_id(n) for n in _many(frontier, nodes)],
        "active": [_node_id(n) for n in _many(active, nodes)],
    }
    _add(shape, note)


def linked_list(head, pointers=None, note=None) -> None:
    order: list = []
    seen: dict[int, dict] = {}

    def walk(node) -> None:
        previous = None
        while node is not None and id(node) not in seen:
            entry = {"id": str(id(node)), "label": _node_label(node), "children": []}
            seen[id(node)] = entry
            order.append(entry)
            if previous is not None:
                previous["children"] = [entry["id"]]
            previous = entry
            node = getattr(node, "next", None)
        if previous is not None and node is not None:
            previous["children"] = [str(id(node))]  # Joins a chain already drawn, or a cycle.

    walk(head)
    pairs = _pairs(pointers)
    for _, node in pairs:
        walk(node)
    shape = {
        "kind": "linked_list",
        "nodes": order,
        "pointers": {str(key): (None if node is None else str(id(node))) for key, node in pairs},
    }
    _add(shape, note)


def stack(items, highlight=None, name=None, note=None) -> None:
    _add(_sequence("stack", items, highlight, name), note)


def queue(items, highlight=None, name=None, note=None) -> None:
    _add(_sequence("queue", items, highlight, name), note)


def bits(n, width=8, highlight=None, group=8, note=None) -> None:
    n = int(n)
    width = max(1, int(width))
    if n < 0:
        n &= (1 << width) - 1
    else:
        width = max(width, n.bit_length())
    values = [bool(n >> (width - 1 - i) & 1) for i in builtins.range(width)]
    shape = {
        "kind": "bits",
        "bits": values,
        "groupSize": max(1, int(group)),
        "highlighted": sorted(width - 1 - p for p in _indices(highlight) if 0 <= p < width),
    }
    _add(shape, note)


# MARK: - Helpers


def _sequence(kind: str, items, highlight, name) -> dict:
    return {
        "kind": kind,
        "name": None if name is None else str(name),
        "items": [_show(v) for v in items],
        "highlighted": _indices(highlight),
    }


def _object_tree(root, active, dimmed) -> dict:
    nodes: list[dict] = []
    seen: set[int] = set()
    stack_ = [root] if root is not None else []
    while stack_:
        node = stack_.pop()
        if id(node) in seen:
            continue
        seen.add(id(node))
        kids = _tree_children(node)
        nodes.append({
            "id": str(id(node)),
            "label": _node_label(node),
            "children": [None if k is None else str(id(k)) for k in kids],
        })
        stack_.extend(k for k in reversed(kids) if k is not None)
    return {
        "kind": "tree",
        "root": None if root is None else str(id(root)),
        "nodes": nodes,
        "active": [str(id(n)) for n in _many(active)],
        "dimmed": [str(id(n)) for n in _many(dimmed)],
    }


def _tree_children(node) -> list:
    children = getattr(node, "children", None)
    if children is not None and not isinstance(children, (str, bytes)):
        if isinstance(children, dict):
            children = children.values()
        return [c for c in children if c is not None]
    left = getattr(node, "left", None)
    right = getattr(node, "right", None)
    if left is None and right is None:
        return []
    return [left, right]


def _heap_tree(values: list, active, dimmed) -> dict:
    count = len(values)
    nodes = []
    for i, value in enumerate(values):
        kids = [str(c) if c < count else None for c in (2 * i + 1, 2 * i + 2)]
        nodes.append({"id": str(i), "label": _label(value), "children": kids if kids[0] else []})
    return {
        "kind": "tree",
        "root": "0" if count else None,
        "nodes": nodes,
        "active": [str(i) for i in _indices(active)],
        "dimmed": [str(i) for i in _indices(dimmed)],
    }


def _node_label(node) -> str:
    for attr in ("val", "value", "key", "data"):
        if hasattr(node, attr):
            return _label(getattr(node, attr))
    return _label(node)


def _node_id(n) -> str:
    return _safe(repr, n)


def _neighbors(neighbors):
    if isinstance(neighbors, dict):
        return list(neighbors.items())
    out = []
    for item in neighbors or ():
        if isinstance(item, (tuple, list)) and len(item) == 2:
            out.append((item[0], item[1]))
        else:
            out.append((item, None))
    return out


def _pairs(mapping) -> list:
    if not mapping:
        return []
    if isinstance(mapping, dict):
        return list(mapping.items())
    return [tuple(pair) for pair in mapping]


def _ranges(spec) -> list[dict]:
    if spec is None:
        return []
    if isinstance(spec, (tuple, list)) and len(spec) == 2 and all(isinstance(v, int) for v in spec):
        spec = [spec]
    out = []
    for lo, hi in spec:
        if lo is None or hi is None or lo > hi:
            continue
        out.append({"lower": int(lo), "upper": int(hi)})
    return out


def _indices(spec) -> list[int]:
    if spec is None:
        return []
    if isinstance(spec, int):
        return [spec]
    return [int(i) for i in spec if i is not None]


def _cells(spec) -> list:
    if spec is None:
        return []
    if isinstance(spec, tuple) and len(spec) == 2 and all(isinstance(v, int) for v in spec):
        return [spec]
    return list(spec)


def _grid_cell(cell) -> dict:
    r, c = cell
    return {"row": int(r), "column": int(c)}


def _many(spec, known_ids=None) -> list:
    """`None`, one node, or an iterable of nodes. A tuple that is itself a node counts as one."""
    if spec is None:
        return []
    if known_ids is not None and isinstance(spec, tuple) and _node_id(spec) in known_ids:
        return [spec]
    if isinstance(spec, (list, tuple, set, frozenset)) or type(spec).__name__ == "deque":
        return list(spec)
    if isinstance(spec, dict):
        return list(spec.keys())
    return [spec]


def _inf(value) -> str | None:
    if isinstance(value, float) and math.isinf(value):
        return "∞" if value > 0 else "-∞"
    return None


def _show(value) -> str:
    """Array, stack and queue values: `repr`."""
    return _inf(value) or _safe(repr, value)


def _label(value) -> str:
    """Labels and weights: `str`."""
    return _inf(value) or _safe(str, value)


def _cell(value) -> str:
    """Grid cells: `str`, `None` is empty."""
    return "" if value is None else _label(value)


def _safe(fn, value) -> str:
    try:
        return fn(value)
    except Exception:
        return f"<{type(value).__name__}>"
