---
id: mirror-tree
title: Mirror a tree
level: warmup
---

Flip the tree left to right in place, so every node's left and right children swap, and return the root.

`from_list([4, 2, 7, 1, 3, 6, 9])` becomes the tree that `to_list` shows as `[4, 7, 2, 9, 6, 3, 1]`.

Tests build trees with `from_list`, which reads values level by level, left to right, with `None` for a missing child. `to_list` goes the other way.

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


def to_list(root):
    out = []
    queue = deque([root])
    while queue:
        node = queue.popleft()
        if node is None:
            out.append(None)
            continue
        out.append(node.val)
        queue.append(node.left)
        queue.append(node.right)
    while out and out[-1] is None:
        out.pop()
    return out


def mirror(root):
    pass
```

```tests
to_list(mirror(from_list([4, 2, 7, 1, 3, 6, 9]))) == [4, 7, 2, 9, 6, 3, 1]
mirror(None) is None
to_list(mirror(from_list([1]))) == [1]
to_list(mirror(from_list([1, 2]))) == [1, None, 2]
to_list(mirror(from_list([1, None, 2, None, 3]))) == [1, 2, None, 3]
to_list(mirror(from_list([1, 1, 2]))) == [1, 2, 1]
to_list(mirror(from_list([-1, -2, -3, -4]))) == [-1, -3, -2, None, None, None, -4]
to_list(mirror(mirror(from_list(list(range(1000)))))) == list(range(1000))
```

```python tests
root = from_list([1, 2, 3])
left = root.left
assert mirror(root) is root, "return the same root"
assert root.right is left, "move the nodes, don't copy them"
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


def to_list(root):
    out = []
    queue = deque([root])
    while queue:
        node = queue.popleft()
        if node is None:
            out.append(None)
            continue
        out.append(node.val)
        queue.append(node.left)
        queue.append(node.right)
    while out and out[-1] is None:
        out.pop()
    return out


def mirror(root):
    if root is None:
        return None
    root.left, root.right = root.right, root.left
    mirror(root.left)
    mirror(root.right)
    return root
```

## Hints

1. Mirroring a tree means mirroring both subtrees and then swapping them.
2. Swap `root.left` and `root.right`, then mirror each child. The order of the two steps doesn't matter.
3. `root.left, root.right = root.right, root.left`, recurse on both, return `root`. Return `None` for an empty tree.
