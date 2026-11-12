---
id: has-path-sum
title: Path with a sum
level: warmup
---

Return `True` if some path from the root down to a leaf adds up to `target`. The path must end at a leaf, and an empty tree has no paths.

In `from_list([5, 4, 8, 11, None, 13, 4, 7, 2, None, None, None, 1])`, the path 5, 4, 11, 2 adds up to 22, so `has_path_sum(root, 22)` is `True`.

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


def has_path_sum(root, target):
    pass
```

```tests
has_path_sum(from_list([5, 4, 8, 11, None, 13, 4, 7, 2, None, None, None, 1]), 22) == True
has_path_sum(from_list([5, 4, 8, 11, None, 13, 4, 7, 2, None, None, None, 1]), 26) == True
has_path_sum(from_list([5, 4, 8, 11, None, 13, 4, 7, 2, None, None, None, 1]), 9) == False
has_path_sum(None, 0) == False
has_path_sum(from_list([1]), 1) == True
has_path_sum(from_list([1, 2]), 1) == False
has_path_sum(from_list([1, 2, 3]), 4) == True
has_path_sum(from_list([-2, None, -3]), -5) == True
has_path_sum(from_list([1, -1, -1]), 0) == True
has_path_sum(from_list(list(range(1, 1024))), 1023) == True
has_path_sum(from_list(list(range(1, 1024))), 1022) == False
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


def has_path_sum(root, target):
    if root is None:
        return False
    left_over = target - root.val
    if root.left is None and root.right is None:
        return left_over == 0
    return (has_path_sum(root.left, left_over)
            or has_path_sum(root.right, left_over))
```

## Hints

1. Walking down one step uses up `root.val` of the target. Pass what is left to the children.
2. At a leaf, the path works if nothing is left over. An empty subtree is never a path.
3. Return `False` for `None`. Compute `left_over = target - root.val`. At a leaf return `left_over == 0`, else try both children with `or`.
