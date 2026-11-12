---
id: kth-smallest-bst
title: Kth smallest in a BST
level: core
---

`root` is a binary search tree. Return its `k`th smallest value, counting from 1. `k` is always between 1 and the number of nodes.

In `from_list([3, 1, 4, None, 2])` the values in order are 1, 2, 3, 4, so `kth_smallest(root, 3)` is 3.

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


def kth_smallest(root, k):
    pass
```

```tests
kth_smallest(from_list([3, 1, 4, None, 2]), 1) == 1
kth_smallest(from_list([3, 1, 4, None, 2]), 3) == 3
kth_smallest(from_list([3, 1, 4, None, 2]), 4) == 4
kth_smallest(from_list([5, 3, 6, 2, 4, None, None, 1]), 3) == 3
kth_smallest(from_list([5, 3, 6, 2, 4, None, None, 1]), 6) == 6
kth_smallest(from_list([7]), 1) == 7
kth_smallest(from_list([0, -5, 5, -8]), 2) == -5
kth_smallest(from_list([1, None, 2, None, 3]), 2) == 2
```

```python tests
def build(lo, hi):
    if lo > hi:
        return None
    mid = (lo + hi) // 2
    return TreeNode(mid, build(lo, mid - 1), build(mid + 1, hi))

big = build(0, 999)
assert kth_smallest(big, 1) == 0
assert kth_smallest(big, 500) == 499
assert kth_smallest(big, 1000) == 999
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


def kth_smallest(root, k):
    stack = []
    node = root
    while True:
        while node:
            stack.append(node)
            node = node.left
        node = stack.pop()
        k -= 1
        if k == 0:
            return node.val
        node = node.right
```

## Hints

1. In-order visits a BST's values from smallest to largest.
2. Walk in-order and count. You can stop as soon as you reach the `k`th value.
3. Use the stack version of in-order: go left pushing nodes, pop one, decrement `k`, return its value when `k` hits 0, else go right.
