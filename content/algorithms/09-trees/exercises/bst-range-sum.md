---
id: bst-range-sum
title: Range sum in a BST
level: warmup
---

`root` is a binary search tree. Return the sum of the values between `lo` and `hi`, both included. Skip subtrees that can't hold any value in the range.

In `from_list([10, 5, 15, 3, 7, None, 18])`, the values from 7 to 15 are 7, 10 and 15, so `range_sum(root, 7, 15)` is 32.

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


def range_sum(root, lo, hi):
    pass
```

```tests
range_sum(from_list([10, 5, 15, 3, 7, None, 18]), 7, 15) == 32
range_sum(from_list([10, 5, 15, 3, 7, 13, 18, 1, None, 6]), 6, 10) == 23
range_sum(None, 0, 10) == 0
range_sum(from_list([5]), 5, 5) == 5
range_sum(from_list([5]), 6, 9) == 0
range_sum(from_list([10, 5, 15]), 11, 14) == 0
range_sum(from_list([0, -5, 5, -8, -2]), -6, 0) == -7
range_sum(from_list([10, 5, 15, 3, 7, None, 18]), -100, 100) == 58
```

```python tests
def build(lo, hi):
    if lo > hi:
        return None
    mid = (lo + hi) // 2
    return TreeNode(mid, build(lo, mid - 1), build(mid + 1, hi))

big = build(0, 999)
assert range_sum(big, 0, 999) == sum(range(1000))
assert range_sum(big, 250, 260) == sum(range(250, 261))

visits = 0
original = TreeNode.__getattribute__

def counting(self, name):
    global visits
    if name == "val":
        visits += 1
    return original(self, name)

TreeNode.__getattribute__ = counting
range_sum(big, 500, 501)
TreeNode.__getattribute__ = original
assert visits < 100, "skip subtrees outside the range"
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


def range_sum(root, lo, hi):
    if root is None:
        return 0
    if root.val < lo:
        return range_sum(root.right, lo, hi)
    if root.val > hi:
        return range_sum(root.left, lo, hi)
    return (root.val
            + range_sum(root.left, lo, hi)
            + range_sum(root.right, lo, hi))
```

## Hints

1. The BST rule tells you which side can still hold values in the range.
2. If `root.val < lo`, everything on the left is smaller still, so only the right side matters. If `root.val > hi`, only the left side does.
3. Return 0 for `None`. Handle the two one-sided cases, else return `root.val` plus the sums from both sides.
