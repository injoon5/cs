import json

import app_support
from swift_schema import check


def visualize(code):
    out = json.loads(app_support.visualize(code))
    check(out, "VisualizeResponse")
    return out


def shapes(code):
    out = visualize(code)
    assert out["error"] is None, out["error"]
    return [frame["shapes"] for frame in out["frames"]]


def only(code):
    frames = shapes(code)
    assert len(frames) == 1 and len(frames[0]) == 1
    return frames[0][0]


def test_array():
    shape = only(
        "import viz\n"
        "a = [3, 'x', None, float('inf')]\n"
        "viz.array(a, pointers={'i': 0, 'j': 3, 'k': None}, range=(1, 2), highlight=[0, 3], name='a')\n"
    )
    assert shape == {
        "kind": "array",
        "name": "a",
        "values": ["3", "'x'", "None", "∞"],
        "pointers": [{"name": "i", "index": 0}, {"name": "j", "index": 3}],
        "shaded": [{"lower": 1, "upper": 2}],
        "highlighted": [0, 3],
    }


def test_array_ranges_and_single_highlight():
    shape = only("import viz\nviz.array([1, 2, 3], range=[(0, 0), (2, 1)], highlight=2)")
    assert shape["shaded"] == [{"lower": 0, "upper": 0}]
    assert shape["highlighted"] == [2]
    assert shape["name"] is None


def test_grid():
    shape = only(
        "import viz\n"
        "dp = [[0, 1], [None, 'a']]\n"
        "viz.grid(dp, highlight=(1, 1), row_labels=['', 'a'], col_labels='xy', arrows=[((1, 1), (0, 0))])\n"
    )
    assert shape == {
        "kind": "grid",
        "name": None,
        "rows": [["0", "1"], ["", "a"]],
        "rowLabels": ["", "a"],
        "columnLabels": ["x", "y"],
        "highlighted": [{"row": 1, "column": 1}],
        "arrows": [{"from": {"row": 1, "column": 1}, "to": {"row": 0, "column": 0}}],
    }


def test_grid_from_strings_and_many_highlights():
    shape = only("import viz\nviz.grid(['#.', '.#'], highlight=[(0, 1), (1, 0)])")
    assert shape["rows"] == [["#", "."], [".", "#"]]
    assert len(shape["highlighted"]) == 2
    assert shape["rowLabels"] is None


BST = """
import viz
class Node:
    def __init__(self, val, left=None, right=None):
        self.val, self.left, self.right = val, left, right
leaf = Node(7)
root = Node(5, None, leaf)
root.left = Node(2)
other = Node(1, right=Node(9))
"""


def test_tree_binary():
    shape = only(BST + "viz.tree(root, active=leaf)\n")
    assert shape["kind"] == "tree"
    nodes = {n["id"]: n for n in shape["nodes"]}
    root = nodes[shape["root"]]
    assert root["label"] == "5"
    left, right = root["children"]
    assert nodes[left]["label"] == "2" and nodes[right]["label"] == "7"
    assert nodes[left]["children"] == []
    assert shape["active"] == [right]
    assert shape["dimmed"] == []
    assert [n["label"] for n in shape["nodes"]] == ["5", "2", "7"]  # Pre-order.


def test_tree_keeps_open_slot():
    shape = only(BST + "viz.tree(other)\n")
    nodes = {n["id"]: n for n in shape["nodes"]}
    assert nodes[shape["root"]]["children"][0] is None
    assert nodes[shape["root"]]["children"][1] is not None


def test_tree_children_and_labels():
    shape = only(
        "import viz\n"
        "class T:\n"
        "    def __init__(self, key, children=()):\n"
        "        self.key, self.children = key, list(children)\n"
        "viz.tree(T('r', [T('a'), T('b', [T('c')])]))\n"
    )
    assert [n["label"] for n in shape["nodes"]] == ["r", "a", "b", "c"]
    assert len(shape["nodes"][0]["children"]) == 2


def test_tree_from_heap_list_and_empty():
    shape = only("import viz\nviz.tree([1, 3, 2, 7], active=1, dimmed=[3])")
    assert shape["root"] == "0"
    assert [n["children"] for n in shape["nodes"]] == [["1", "2"], ["3", None], [], []]
    assert shape["active"] == ["1"] and shape["dimmed"] == ["3"]
    assert only("import viz\nviz.tree(None)") == {"kind": "tree", "root": None, "nodes": [], "active": [], "dimmed": []}


def test_graph_undirected_with_weights():
    shape = only(
        "import viz\n"
        "adj = {'A': [('B', 4), ('C', 1)], 'B': [('A', 4)], 'C': [('A', 1), ('D', float('inf'))]}\n"
        "viz.graph(adj, visited={'A'}, frontier=['B', 'C'], active='A')\n"
    )
    assert shape["directed"] is False
    assert [n["label"] for n in shape["nodes"]] == ["A", "B", "C", "D"]
    assert [(e["from"], e["to"], e["weight"]) for e in shape["edges"]] == [
        ("'A'", "'B'", "4"), ("'A'", "'C'", "1"), ("'C'", "'D'", "∞"),
    ]
    assert shape["visited"] == ["'A'"]
    assert shape["frontier"] == ["'B'", "'C'"]
    assert shape["active"] == ["'A'"]


def test_graph_directed_list_and_tuple_nodes():
    shape = only("import viz\nviz.graph([[1], [0, 2], []], directed=True, active=1)")
    assert shape["directed"] is True
    assert [(e["from"], e["to"]) for e in shape["edges"]] == [("0", "1"), ("1", "0"), ("1", "2")]
    assert all(e["weight"] is None for e in shape["edges"])

    shape = only(
        "import viz\n"
        "adj = {(0, 0): {(0, 1): 2}, (0, 1): {}}\n"
        "viz.graph(adj, active=(0, 1), visited=[(0, 0)])\n"
    )
    assert shape["active"] == ["(0, 1)"]
    assert shape["visited"] == ["(0, 0)"]
    assert shape["edges"] == [{"from": "(0, 0)", "to": "(0, 1)", "weight": "2"}]


LIST = """
import viz
class ListNode:
    def __init__(self, val, next=None):
        self.val, self.next = val, next
head = ListNode(1, ListNode(2, ListNode(3)))
"""


def test_linked_list_reversal_keeps_ids_and_detached_part():
    out = shapes(
        LIST
        + "prev, cur = None, head\n"
        + "viz.linked_list(head, pointers={'prev': prev, 'cur': cur})\n"
        + "while cur:\n"
        + "    cur.next, prev, cur = prev, cur, cur.next\n"
        + "    viz.linked_list(None, pointers={'prev': prev, 'cur': cur})\n"
    )
    first, *_, last = [frame[0] for frame in out]
    assert first["kind"] == "linked_list"
    assert [n["label"] for n in first["nodes"]] == ["1", "2", "3"]
    assert first["nodes"][0]["children"] == [first["nodes"][1]["id"]]
    assert first["nodes"][2]["children"] == []
    assert first["pointers"]["prev"] is None
    assert first["pointers"]["cur"] == first["nodes"][0]["id"]

    middle = out[2][0]  # After two steps: prev -> 2 -> 1, cur -> 3.
    assert [n["label"] for n in middle["nodes"]] == ["2", "1", "3"]

    assert [n["label"] for n in last["nodes"]] == ["3", "2", "1"]
    assert {n["id"] for n in last["nodes"]} == {n["id"] for n in first["nodes"]}
    assert last["pointers"] == {"prev": last["nodes"][0]["id"], "cur": None}


def test_linked_list_cycle_ends():
    shape = only(LIST + "head.next.next.next = head\nviz.linked_list(head)\n")
    assert len(shape["nodes"]) == 3
    assert shape["nodes"][2]["children"] == [shape["nodes"][0]["id"]]
    assert shape["pointers"] == {}


def test_stack_and_queue():
    frames = shapes(
        "import viz\nfrom collections import deque\n"
        "viz.stack(['(', '['], highlight=1, name='st')\n"
        "viz.queue(deque([1, 2]))\n"
    )
    assert frames[0][0] == {"kind": "stack", "name": "st", "items": ["'('", "'['"], "highlighted": [1]}
    assert frames[1][0] == {"kind": "queue", "name": None, "items": ["1", "2"], "highlighted": []}


def test_bits():
    shape = only("import viz\nviz.bits(5, width=4, highlight=0)")
    assert shape == {"kind": "bits", "bits": [False, True, False, True], "groupSize": 8, "highlighted": [3]}
    assert only("import viz\nviz.bits(-1, width=4)")["bits"] == [True] * 4
    assert len(only("import viz\nviz.bits(256)")["bits"]) == 9


def test_notes_attach_to_next_frame_and_trailing_note_to_last():
    out = visualize(
        "import viz\n"
        "viz.note('start')\n"
        "viz.array([2, 1])\n"
        "viz.array([1, 2], note='swap')\n"
        "viz.note('done')\n"
    )
    assert [f["note"] for f in out["frames"]] == ["start", "swap\ndone"]


def test_note_without_frames():
    out = visualize("import viz\nviz.note('nothing to draw')")
    assert out["frames"] == [{"shapes": [], "note": "nothing to draw"}]


def test_frame_groups_shapes():
    frames = shapes(
        "import viz\n"
        "with viz.frame():\n"
        "    viz.array([1])\n"
        "    viz.stack([1])\n"
        "viz.bits(1)\n"
    )
    assert [[s["kind"] for s in f] for f in frames] == [["array", "stack"], ["bits"]]


def test_frames_reset_between_runs_and_output_collected():
    first = visualize("import viz\nviz.array([1])\nprint('hi')")
    assert len(first["frames"]) == 1
    assert first["output"] == "hi\n"
    second = visualize("print('no viz')")
    assert second["frames"] == []


def test_error_keeps_frames_drawn_so_far():
    out = visualize("import viz\nviz.array([1])\n1 / 0\n")
    assert len(out["frames"]) == 1
    assert out["error"]["type"] == "ZeroDivisionError"
    assert out["error"]["line"] == 3
    assert "viz.py" not in out["error"]["traceback"]


def test_frame_limit():
    out = visualize("import viz\nfor i in range(1500):\n    viz.bits(i)\n")
    assert len(out["frames"]) == 1000


def test_viz_calls_outside_visualize_are_harmless():
    out = json.loads(app_support.run("import viz\nviz.array([1])\nviz.note('x')"))
    assert out["error"] is None
