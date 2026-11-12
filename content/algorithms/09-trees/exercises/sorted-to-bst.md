---
id: sorted-to-bst
title: Balanced BST from a sorted list
level: stretch
---

Build a binary search tree from a sorted list of distinct values and return its root. Every node's two subtrees must differ in height by at most 1.

`[1, 2, 3, 4, 5, 6, 7]` gives 4 at the root, 2 and 6 below it, and 1, 3, 5, 7 as leaves, height 2. An empty list gives `None`.

`values_in_order` and `height` are there to check your tree.

```python starter
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right


def values_in_order(root):
    if root is None:
        return []
    return (values_in_order(root.left) + [root.val]
            + values_in_order(root.right))


def height(root):
    if root is None:
        return -1
    return 1 + max(height(root.left), height(root.right))


def sorted_to_bst(values):
    pass
```

```tests
values_in_order(sorted_to_bst([1, 2, 3, 4, 5, 6, 7])) == [1, 2, 3, 4, 5, 6, 7]
height(sorted_to_bst([1, 2, 3, 4, 5, 6, 7])) == 2
height(sorted_to_bst(list(range(8)))) == 3
values_in_order(sorted_to_bst([4])) == [4]
values_in_order(sorted_to_bst([-3, -1, 0, 5])) == [-3, -1, 0, 5]
height(sorted_to_bst([-3, -1, 0, 5])) == 2
sorted_to_bst([]) is None
height(sorted_to_bst(list(range(1000)))) == 9
values_in_order(sorted_to_bst(list(range(1000)))) == list(range(1000))
```

```python tests
def balanced(node):
    if node is None:
        return True
    gap = abs(height(node.left) - height(node.right))
    return gap <= 1 and balanced(node.left) and balanced(node.right)

for n in range(1, 40):
    root = sorted_to_bst(list(range(n)))
    assert values_in_order(root) == list(range(n))
    assert balanced(root), f"not balanced for {n} values"
```

```python solution
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right


def values_in_order(root):
    if root is None:
        return []
    return (values_in_order(root.left) + [root.val]
            + values_in_order(root.right))


def height(root):
    if root is None:
        return -1
    return 1 + max(height(root.left), height(root.right))


def sorted_to_bst(values):
    def build(lo, hi):
        if lo > hi:
            return None
        mid = (lo + hi) // 2
        node = TreeNode(values[mid])
        node.left = build(lo, mid - 1)
        node.right = build(mid + 1, hi)
        return node

    return build(0, len(values) - 1)
```

## Hints

1. The middle value splits the rest into two halves of nearly the same size.
2. Put the middle at the root, then build the left subtree from the left half and the right subtree from the right half, the same way.
3. Recurse on index ranges `build(lo, hi)`: return `None` if `lo > hi`, else make `values[mid]` with `mid = (lo + hi) // 2` and children `build(lo, mid - 1)` and `build(mid + 1, hi)`.
