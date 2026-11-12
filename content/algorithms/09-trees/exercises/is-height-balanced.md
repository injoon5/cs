---
id: is-height-balanced
title: Height-balanced
level: core
---

Return `True` if, at every node, the heights of the left and right subtrees differ by at most 1. This is the rule AVL trees keep. Visit each node once.

`from_list([1, 2, 3, 4, None, None, 5, 6, None, None, 7])` is balanced at the root, but node 2 has a left subtree of height 1 and no right subtree, so the answer is `False`.

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


def is_balanced(root):
    pass
```

```tests
is_balanced(from_list([3, 9, 20, None, None, 15, 7])) == True
is_balanced(from_list([1, 2, 2, 3, 3, None, None, 4, 4])) == False
is_balanced(from_list([1, 2, 3, 4, None, None, 5, 6, None, None, 7])) == False
is_balanced(from_list([1, 2, 3, 4, None, None, None, 5])) == False
is_balanced(None) == True
is_balanced(from_list([1])) == True
is_balanced(from_list([1, 2])) == True
is_balanced(from_list([1, None, 2, None, 3])) == False
is_balanced(from_list([0, -1, -1, -2])) == True
is_balanced(from_list(list(range(1, 1000)))) == True
is_balanced(from_list([v for i in range(200) for v in (i, None)])) == False
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


def is_balanced(root):
    def height(node):
        if node is None:
            return -1
        left = height(node.left)
        right = height(node.right)
        if left is None or right is None:
            return None
        if abs(left - right) > 1:
            return None
        return 1 + max(left, right)

    return height(root) is not None
```

## Hints

1. You need each subtree's height and whether it is balanced. One bottom-up pass can return both.
2. Compute heights in postorder. As soon as some node's two heights differ by more than 1, report failure up the chain instead of a height.
3. Have `height(node)` return `None` for an unbalanced subtree. Return `None` if either child gave `None` or `abs(left - right) > 1`, else `1 + max(left, right)`.
