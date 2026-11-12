---
id: tree-diameter
title: Tree diameter
level: core
---

Return the diameter of the tree: the number of edges on the longest path between any two nodes. The path doesn't have to pass through the root. Visit each node once.

`from_list([1, 2, 3, 4, 5])` has diameter 3, from 4 up to 2, up to 1 and down to 3.

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


def diameter(root):
    pass
```

```tests
diameter(from_list([1, 2, 3, 4, 5])) == 3
diameter(None) == 0
diameter(from_list([1])) == 0
diameter(from_list([1, 2])) == 1
diameter(from_list([1, 2, 9, 3, 4, None, None, 5, None, None, 6, 7, None, None, 8])) == 6
diameter(from_list([1, 1, 1, 1, 1, 1, 1])) == 4
diameter(from_list([-1, -2, None, -3, -4])) == 2
diameter(from_list(list(range(1, 1024)))) == 18
diameter(from_list([v for i in range(200) for v in (i, None)])) == 199
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


def diameter(root):
    best = 0

    def height(node):
        nonlocal best
        if node is None:
            return -1
        left = height(node.left)
        right = height(node.right)
        best = max(best, left + right + 2)
        return 1 + max(left, right)

    height(root)
    return best
```

## Hints

1. Every path has one highest node, where it bends. The longest path bending at a node goes as deep as possible on each side.
2. If the children's subtrees have heights `l` and `r` (an empty one is -1), the best path bending here has `l + r + 2` edges. Compute heights bottom up and keep the best bend seen.
3. Write a nested `height(node)` that returns `1 + max(left, right)` and, before returning, updates a `nonlocal best` with `left + right + 2`.
