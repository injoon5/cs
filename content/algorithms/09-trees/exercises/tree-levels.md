---
id: tree-levels
title: Values by level
level: core
---

Return the values level by level: a list with one list per depth, each read left to right.

`from_list([3, 9, 20, None, None, 15, 7])` gives `[[3], [9, 20], [15, 7]]`.

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


def levels(root):
    pass
```

```tests
levels(from_list([3, 9, 20, None, None, 15, 7])) == [[3], [9, 20], [15, 7]]
levels(None) == []
levels(from_list([1])) == [[1]]
levels(from_list([1, 2, None, 3])) == [[1], [2], [3]]
levels(from_list([1, 2, 3, None, 4, 5])) == [[1], [2, 3], [4, 5]]
levels(from_list([5, 5, 5, 5])) == [[5], [5, 5], [5]]
levels(from_list([0, -1, -2])) == [[0], [-1, -2]]
len(levels(from_list(list(range(1, 1024))))) == 10
levels(from_list(list(range(1, 1024))))[-1] == list(range(512, 1024))
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


def levels(root):
    if root is None:
        return []
    out = []
    queue = deque([root])
    while queue:
        level = []
        for _ in range(len(queue)):
            node = queue.popleft()
            level.append(node.val)
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        out.append(level)
    return out
```

## Hints

1. Visit nodes with a queue, as in level order. The hard part is knowing where one level ends.
2. When a level starts, the queue holds exactly that level. Read `len(queue)` then and pop that many.
3. Loop while the queue isn't empty: `for _ in range(len(queue))`, pop a node, add its value to `level`, push its children. Then append `level` to the answer.
