---
id: binary-search-trees
title: Binary search trees
---

A binary search tree keeps one rule at every node: everything in its left subtree is smaller, and everything in its right subtree is bigger.

```diagram
tree
8 -> 3 10
3 -> 1 6
10 -> _ 14
6 -> 4 7
highlight 8 3 6 7
dim 1 4 10 14
```

To find 7, start at the root. 7 is less than 8, so it can only be on the left. It is more than 3, so go right. More than 6, go right again, and there it is. Each comparison throws away a whole subtree, like binary search throws away half a list.

```python
def search(node, target):
    while node:
        if target == node.val:
            return node
        if target < node.val:
            node = node.left
        else:
            node = node.right
    return None
```

---

To insert, search for the value. The search falls off the tree at a `None`, and that empty spot is exactly where the value belongs.

```python trace stop=61
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

root = None
for val in [5, 3, 8, 4]:
    root = insert(root, val)
```

4 is being inserted, and the call for node 3 is about to choose a side. Where will 4 end up?

- [ ] Left child of 3
- [x] Right child of 3
- [ ] Left child of 8

---

Insert a few values, then walk the tree in-order. What does this print?

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

def inorder(node, out):
    if node:
        inorder(node.left, out)
        out.append(node.val)
        inorder(node.right, out)

root = None
for val in [50, 20, 70, 10, 30, 60]:
    root = insert(root, val)
out = []
inorder(root, out)
print(out)
```

---

In-order lists the left subtree, then the node, then the right subtree. In a BST that is everything smaller, then the node, then everything bigger, and the same holds inside each subtree. So in-order visits a BST in sorted order.

Run this to watch it. The values come out sorted even though they went in shuffled.

```python
import viz

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

root = None
for val in [8, 3, 10, 1, 6, 14, 4, 7]:
    root = insert(root, val)

done = []
def inorder(node):
    if node:
        inorder(node.left)
        done.append(node)
        names = " ".join(str(n.val) for n in done)
        viz.tree(root, active=node, dimmed=done[:-1], note=names)
        inorder(node.right)

inorder(root)
```

---

Is this a valid binary search tree?

```diagram
tree
5 -> 3 8
3 -> 1 6
highlight 6
```

- [ ] Yes, every left child is smaller than its parent and every right child is bigger
- [x] No, 6 is in the left subtree of 5 but bigger than 5

---

The rule is about whole subtrees, not just children. So a check has to carry limits down. Every node starts with no limits. Going left, the parent's value becomes the upper limit; going right, it becomes the lower limit. 6 above inherits "below 5" from the root and "above 3" from its parent, and fails the first one.

Another check uses the in-order property: walk in-order and make sure each value is bigger than the one before.

---

Deleting a node has three cases.

- A leaf: remove it.
- One child: the child takes the node's place.
- Two children: copy in the next bigger value, the smallest one in the right subtree, then delete that one from the right subtree. It has no left child, so its own delete is one of the easy cases.

Deleting 3 copies in 4, then removes the old 4:

```diagram
tree
8 -> 3 10
3 -> 1 6
6 -> 4 7
highlight 3 4

tree
8 -> 4 10
4 -> 1 6
6 -> _ 7
highlight 4
```

---

Search, insert and delete each follow one path down from the root. On a BST with n nodes and height h, each takes

- [ ] O(log n) time, always
- [x] O(h) time
- [ ] O(n) time, always

---

[Range sum in a BST](exercises/bst-range-sum.md)

[Validate a BST](exercises/validate-bst.md)

[Kth smallest in a BST](exercises/kth-smallest-bst.md)
