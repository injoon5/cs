---
id: tree-traversals
title: Traversals
---

A traversal visits every node once. Done recursively, each node has three jobs: visit itself, walk its left subtree, walk its right subtree. When the visit happens gives the order its name.

```diagram
tree
A -> B C
B -> D E
```

- Preorder, node first: A B D E C
- In-order, node between its subtrees: D B E A C
- Postorder, node last: D E B C A

All three go left before right. Only the moment the node itself is written down moves.

---

Preorder collects the node, then everything on its left, then everything on its right.

```python
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def preorder(node, out):
    if node is None:
        return
    out.append(node.val)
    preorder(node.left, out)
    preorder(node.right, out)

root = TreeNode("A", TreeNode("B", TreeNode("D"), TreeNode("E")), TreeNode("C"))
out = []
preorder(root, out)
print(out)
```

---

The same tree, now with the visit moved. What does this print?

```python predict
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def order(node, out, when):
    if node is None:
        return
    if when == "pre": out.append(node.val)
    order(node.left, out, when)
    if when == "in": out.append(node.val)
    order(node.right, out, when)
    if when == "post": out.append(node.val)

root = TreeNode(1, TreeNode(2, None, TreeNode(4)), TreeNode(3))
for when in ("pre", "in", "post"):
    out = []
    order(root, out, when)
    print(when, out)
```

---

Run this to watch a preorder walk. The highlighted node is being visited; faded nodes are done.

```python
import viz

class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

root = TreeNode("F",
    TreeNode("B", TreeNode("A"),
        TreeNode("D", TreeNode("C"), TreeNode("E"))),
    TreeNode("G", None, TreeNode("I", TreeNode("H"))))
done = []

def preorder(node):
    if node is None:
        return
    names = " ".join(n.val for n in done + [node])
    viz.tree(root, active=node, dimmed=done, note=names)
    done.append(node)
    preorder(node.left)
    preorder(node.right)

preorder(root)
```

---

Each order suits different jobs.

- Preorder sees a parent before its children. Use it to copy a tree, or to print folders with their contents indented below them.
- In-order sees everything on the left, then the node, then the right. On a binary search tree that is sorted order, as the BST lesson shows.
- Postorder sees a node after both subtrees are done. Use it when a node needs answers from below: height, size, or deleting a tree from the bottom up.

Each folder's total size is the sizes of its files plus the totals of its subfolders. To compute every total in one pass, visit the folders in

- [ ] preorder
- [ ] in-order
- [x] postorder

---

The three orders above all go deep first. Level order goes wide: the root, then every node at depth 1, then depth 2, left to right.

```diagram
tree
1 -> 2 3
2 -> 4 5
3 -> _ 6
```

Level order here is 1 2 3 4 5 6. Recursion can't do this, because the call stack always finishes one subtree before the next. A queue can. Take the node at the front, record it, and add its children at the back. Children join behind everything already waiting, so a whole level leaves before the next one starts. A `deque` makes both ends O(1).

---

```python trace stop=40
from collections import deque

class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

root = TreeNode(1, TreeNode(2, TreeNode(4)), TreeNode(3))
queue = deque([root])
order = []
while queue:
    node = queue.popleft()
    order.append(node.val)
    if node.left:
        queue.append(node.left)
    if node.right:
        queue.append(node.right)
print(order)
```

Node 2 has just been taken from the queue and recorded. Which node is waiting in the queue?

- [ ] 4
- [x] 3
- [ ] 3 and 4

---

Put the lines in order so `level_order` returns the values in level order.

```python arrange
def level_order(root):
    out = []
    queue = deque([root] if root else [])
    while queue:
        node = queue.popleft()
        out.append(node.val)
        if node.left:
            queue.append(node.left)
        if node.right:
            queue.append(node.right)
    return out
```

```python tests
from collections import deque

class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

assert level_order(None) == []
assert level_order(TreeNode(5)) == [5]
root = TreeNode(1, TreeNode(2, TreeNode(4), TreeNode(5)), TreeNode(3))
assert level_order(root) == [1, 2, 3, 4, 5]
```

---

A full tree with n nodes has about n/2 of them on its bottom level. In level order, the queue holds at most

- [ ] about log n nodes, one per level
- [x] about n/2 nodes, when it holds the bottom level
- [ ] 2 nodes, the children of the current node

---

[Mirror a tree](exercises/mirror-tree.md)

[Values by level](exercises/tree-levels.md)

[In-order with a stack](exercises/inorder-iterative.md)
