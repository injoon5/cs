---
id: balanced-trees
title: Balanced trees
---

Insert 1, 2, 3, 4, 5 into an empty BST, in that order. Each value is bigger than everything before it, so it always goes right.

```diagram
tree
1 -> _ 2
2 -> _ 3
3 -> _ 4
4 -> _ 5
```

That is a linked list drawn sideways. Its height is n - 1, so search and insert walk every node: O(n), no better than scanning a list. Sorted input, which is common, is the worst case.

---

The same seven values, inserted in two orders. What does this print?

```python predict
class TreeNode:
    def __init__(self, val):
        self.val = val
        self.left = None
        self.right = None

def insert(node, val):
    if node is None:
        return TreeNode(val)
    if val < node.val:
        node.left = insert(node.left, val)
    else:
        node.right = insert(node.right, val)
    return node

def height(node):
    if node is None:
        return -1
    return 1 + max(height(node.left), height(node.right))

for order in ([1, 2, 3, 4, 5, 6, 7], [4, 2, 6, 1, 3, 5, 7]):
    root = None
    for val in order:
        root = insert(root, val)
    print(height(root))
```

---

A tree of height h has room for at most 2^(h+1) - 1 nodes, because each level holds twice as many as the one above. Turned around, n nodes fit in a height of about log₂ n. A million nodes fit in 20 levels.

A BST holds a million keys. The slowest search takes about

- [ ] 20 steps, whatever the shape
- [x] 20 steps if the tree is balanced, a million if it is a chain
- [ ] a million steps, whatever the shape

---

A balanced tree fixes its shape after every insert and delete, so its height stays O(log n) whatever order the keys arrive in.

- AVL trees keep a strict rule: at every node, the two subtree heights differ by at most 1. After an insert, walk back up and repair the first node that breaks it.
- Red-black trees color each node red or black. A red node never has a red child, and every path from a node down to an empty spot passes the same number of black nodes. So the longest path is at most twice the shortest. The rule is looser, so inserts need fewer repairs.

Both repair with the same move: a rotation.

---

A right rotation at `y` lifts its left child `x` into its place. `y` becomes the right child of `x`, and `x`'s old right subtree, `B`, moves over to become `y`'s left.

```diagram
tree
y -> x C
x -> A B
highlight y x

tree
x -> A y
y -> B C
highlight y x
```

In-order is A, x, B, y, C both before and after, so the tree is still a valid BST. The left side got one level shorter and the right side one level taller. Only three links change, so a rotation is O(1).

---

Put the lines in order so `rotate_right` rotates at `y` and returns the new top of the subtree.

```python arrange
def rotate_right(y):
    x = y.left
    y.left = x.right
    x.right = y
    return x
```

```python tests
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

a, b, c = TreeNode(1), TreeNode(3), TreeNode(5)
x = TreeNode(2, a, b)
y = TreeNode(4, x, c)
top = rotate_right(y)
assert top is x
assert x.left is a and x.right is y
assert y.left is b and y.right is c
```

---

The chain 1, 2, 3, inserted in that order, has height 2. One rotation fixes it. Which one?

```diagram
tree
1 -> _ 2
2 -> _ 3
highlight 1
```

- [ ] A right rotation at 1
- [x] A left rotation at 1, lifting 2 to the root
- [ ] A left rotation at 2, lifting 3

---

Python has no balanced tree built in. When you need sorted keys with fast inserts, the usual tools are a sorted list with `bisect` for small data, or a heap when you only need the smallest item. Java's `TreeMap` and C++'s `std::map` are red-black trees.

With a balanced tree of n keys, search, insert and delete each take

- [ ] O(1) time
- [x] O(log n) time
- [ ] O(n) time

---

[Height-balanced](exercises/is-height-balanced.md)

[Balanced BST from a sorted list](exercises/sorted-to-bst.md)
