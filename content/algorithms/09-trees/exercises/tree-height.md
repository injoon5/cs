---
id: tree-height
title: Tree height
level: warmup
---

Return the height of the tree: the number of edges on the longest path from the root down to a leaf. A single node has height 0 and an empty tree has height -1.

`from_list([3, 9, 20, None, None, 15, 7])` is 3 with children 9 and 20, and 20 has children 15 and 7. Its height is 2.

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


def tree_height(root):
    pass
```

```tests
tree_height(from_list([3, 9, 20, None, None, 15, 7])) == 2
tree_height(None) == -1
tree_height(from_list([1])) == 0
tree_height(from_list([1, 2])) == 1
tree_height(from_list([1, None, 2, None, 3])) == 2
tree_height(from_list([1, 2, 3, 4, None, None, None, 5])) == 3
tree_height(from_list([-1, -1, -1])) == 1
tree_height(from_list(list(range(1, 1024)))) == 9
tree_height(from_list([v for i in range(200) for v in (i, None)])) == 199
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


def tree_height(root):
    if root is None:
        return -1
    left = tree_height(root.left)
    right = tree_height(root.right)
    return 1 + max(left, right)
```

## Hints

1. The height of a tree is one more than the height of its taller subtree.
2. Return -1 for `None`. Otherwise ask both children for their heights.
3. `return 1 + max(tree_height(root.left), tree_height(root.right))`.
