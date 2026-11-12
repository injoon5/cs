---
id: inorder-iterative
title: In-order with a stack
level: stretch
---

Return the values of the tree in in-order (left subtree, node, right subtree) without recursion. A tree can be deeper than Python's recursion limit, and the tests include one 5,000 levels deep.

`from_list([1, None, 2, 3])` is 1 with right child 2, and 2 has left child 3. The answer is `[1, 3, 2]`.

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


def inorder_values(root):
    pass
```

```tests
inorder_values(from_list([1, None, 2, 3])) == [1, 3, 2]
inorder_values(None) == []
inorder_values(from_list([1])) == [1]
inorder_values(from_list([4, 2, 6, 1, 3, 5, 7])) == [1, 2, 3, 4, 5, 6, 7]
inorder_values(from_list([1, 2, None, 3])) == [3, 2, 1]
inorder_values(from_list([2, 2, 2])) == [2, 2, 2]
inorder_values(from_list([0, -3, 9, -10, None, 5])) == [-10, -3, 0, 5, 9]
inorder_values(from_list([v for i in range(5000) for v in (i, None)])) == list(range(5000))
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


def inorder_values(root):
    out = []
    stack = []
    node = root
    while node or stack:
        while node:
            stack.append(node)
            node = node.left
        node = stack.pop()
        out.append(node.val)
        node = node.right
    return out
```

## Hints

1. The recursive version keeps its place on the call stack. Keep that place on a list instead.
2. From the current node, push nodes while walking left. When you can't go further, pop one, record it, then move to its right child.
3. `while node or stack:` push and go left until `node` is `None`, then `node = stack.pop()`, append `node.val`, set `node = node.right`.
