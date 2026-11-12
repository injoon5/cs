---
id: validate-bst
title: Validate a BST
level: core
---

Return `True` if the tree is a binary search tree: for every node, all values in its left subtree are smaller and all values in its right subtree are bigger. Equal values are not allowed.

`from_list([5, 3, 8, 1, 6])` is not a BST. Every parent and child pair looks right, but 6 sits in the left subtree of 5.

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


def is_bst(root):
    pass
```

```tests
is_bst(from_list([2, 1, 3])) == True
is_bst(from_list([5, 3, 8, 1, 6])) == False
is_bst(from_list([5, 1, 4, None, None, 3, 6])) == False
is_bst(from_list([10, 5, 15, None, None, 6, 20])) == False
is_bst(None) == True
is_bst(from_list([1])) == True
is_bst(from_list([1, 1])) == False
is_bst(from_list([2, None, 2])) == False
is_bst(from_list([-1, -2, 0])) == True
is_bst(from_list([8, 3, 10, 1, 6, None, 14, None, None, 4, 7, 13])) == True
```

```python tests
def build(lo, hi):
    if lo > hi:
        return None
    mid = (lo + hi) // 2
    return TreeNode(mid, build(lo, mid - 1), build(mid + 1, hi))

big = build(0, 999)
assert is_bst(big) is True
big.right.left.val = 2000
assert is_bst(big) is False
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


def is_bst(root, lo=float("-inf"), hi=float("inf")):
    if root is None:
        return True
    if not lo < root.val < hi:
        return False
    return (is_bst(root.left, lo, root.val)
            and is_bst(root.right, root.val, hi))
```

## Hints

1. Checking each node against its children isn't enough. A node far down can break the rule for an ancestor.
2. Every node has a range it must fit in. Going left, the current value becomes the upper bound; going right, it becomes the lower bound.
3. Recurse with `is_bst(node, lo, hi)`, starting at minus and plus infinity. Fail if not `lo < node.val < hi`, else check `(left, lo, node.val)` and `(right, node.val, hi)`.
