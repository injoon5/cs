---
id: count-leaves
title: Count the leaves
level: warmup
---

Return how many leaves the tree has. A leaf is a node with no children.

`from_list([3, 9, 20, None, None, 15, 7])` has leaves 9, 15 and 7, so the answer is 3.

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


def count_leaves(root):
    pass
```

```tests
count_leaves(from_list([3, 9, 20, None, None, 15, 7])) == 3
count_leaves(None) == 0
count_leaves(from_list([1])) == 1
count_leaves(from_list([1, 2])) == 1
count_leaves(from_list([1, None, 2, None, 3])) == 1
count_leaves(from_list([1, 2, 3, 4, 5, 6, 7])) == 4
count_leaves(from_list([2, 2, 2])) == 2
count_leaves(from_list([0, -1, 1, None, -5])) == 2
count_leaves(from_list(list(range(1, 1024)))) == 512
count_leaves(from_list([v for i in range(200) for v in (i, None)])) == 1
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


def count_leaves(root):
    if root is None:
        return 0
    if root.left is None and root.right is None:
        return 1
    return count_leaves(root.left) + count_leaves(root.right)
```

## Hints

1. An empty tree has no leaves. A node with no children is exactly one leaf.
2. Any other node isn't a leaf itself, so its count comes only from its two subtrees.
3. Check `root is None`, then `root.left is None and root.right is None`, else add the two recursive counts.
