---
id: node-distance
title: Distance between nodes
level: stretch
---

Return the number of edges on the path between the nodes with values `a` and `b`. Values are unique and both are in the tree.

In `from_list([3, 5, 1, 6, 2, 0, 8, None, None, 7, 4])`, the path from 5 to 0 is 5, 3, 1, 0, so the distance is 3.

Tests build trees with `from_list`, which reads values level by level, left to right, with `None` for a missing child.

```python starter
from collections import deque


class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right


def from_list(values):
    if not values or values[0] is None:
        return None
    root = TreeNode(values[0])
    queue = deque([root])
    i = 1
    while queue and i < len(values):
        node = queue.popleft()
        for side in ("left", "right"):
            if i < len(values) and values[i] is not None:
                child = TreeNode(values[i])
                setattr(node, side, child)
                queue.append(child)
            i += 1
    return root


def distance(root, a, b):
    pass
```

```tests
distance(from_list([3, 5, 1, 6, 2, 0, 8, None, None, 7, 4]), 5, 0) == 3
distance(from_list([3, 5, 1, 6, 2, 0, 8, None, None, 7, 4]), 7, 4) == 2
distance(from_list([3, 5, 1, 6, 2, 0, 8, None, None, 7, 4]), 6, 4) == 3
distance(from_list([3, 5, 1, 6, 2, 0, 8, None, None, 7, 4]), 5, 4) == 2
distance(from_list([3, 5, 1, 6, 2, 0, 8, None, None, 7, 4]), 7, 8) == 5
distance(from_list([1]), 1, 1) == 0
distance(from_list([1, 2]), 2, 1) == 1
distance(from_list([0, -1, -2, -3]), -3, -2) == 3
distance(from_list(list(range(1, 1024))), 512, 1023) == 18
distance(from_list(list(range(1, 1024))), 1, 1023) == 9
```

```python solution
from collections import deque


class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right


def from_list(values):
    if not values or values[0] is None:
        return None
    root = TreeNode(values[0])
    queue = deque([root])
    i = 1
    while queue and i < len(values):
        node = queue.popleft()
        for side in ("left", "right"):
            if i < len(values) and values[i] is not None:
                child = TreeNode(values[i])
                setattr(node, side, child)
                queue.append(child)
            i += 1
    return root


def lca(node, a, b):
    if node is None or node.val in (a, b):
        return node
    left = lca(node.left, a, b)
    right = lca(node.right, a, b)
    if left and right:
        return node
    return left or right


def depth_of(node, val, depth=0):
    if node is None:
        return -1
    if node.val == val:
        return depth
    d = depth_of(node.left, val, depth + 1)
    if d != -1:
        return d
    return depth_of(node.right, val, depth + 1)


def distance(root, a, b):
    meet = lca(root, a, b)
    return depth_of(meet, a) + depth_of(meet, b)
```

## Hints

1. The path from `a` to `b` goes up to their lowest common ancestor and back down.
2. Find the lowest common ancestor as in the lesson, then add the depth of `a` below it and the depth of `b` below it.
3. Write `lca(node, a, b)` that compares values, and `depth_of(node, val)` that returns the depth of `val` under `node` or -1. Answer `depth_of(meet, a) + depth_of(meet, b)`.
