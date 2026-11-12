---
id: binary-trees
title: Binary trees
---

Folders on a disk, a family tree and the calls of a recursive function all branch the same way. In a binary tree, each node has at most two children: a left one and a right one.

```diagram
tree
8 -> 3 10
3 -> 1 6
10 -> _ 14
6 -> 4 7
highlight 8
```

The top node, 8, is the root. Every other node hangs from exactly one parent: 3 is the parent of 1 and 6, and they are its children. Nodes with no children are leaves. Here those are 1, 4, 7 and 14.

---

The depth of a node is how many edges you walk down from the root to reach it. The root has depth 0, 3 and 10 have depth 1, and 4 has depth 3.

```diagram
tree
8 -> 3 10
3 -> 1 6
10 -> _ 14
6 -> 4 7
highlight 8 3 6 4
dim 1 10 14 7
```

The height of a tree is the depth of its deepest node, the number of edges on the longest path down from the root. This tree has height 3. One node alone has height 0, and the empty tree has height -1 so that the code below works out.

---

In Python a node is a small class: a value and two links. `None` means there is no child on that side. What does this print?

```python predict
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

root = TreeNode(8,
    TreeNode(3, TreeNode(1), TreeNode(6)),
    TreeNode(10, None, TreeNode(14)))
print(root.left.right.val)
print(root.right.left)
```

---

Every node is the root of a smaller tree, its subtree. A node's left and right subtrees share no nodes. So a question about a tree splits into the same question about two smaller trees, which is what recursion is good at.

To count the nodes: an empty tree has 0. Otherwise count the left subtree, count the right one, and add 1 for the node itself.

```python
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def size(node):
    if node is None:
        return 0
    return 1 + size(node.left) + size(node.right)

root = TreeNode(8, TreeNode(3, TreeNode(1)), TreeNode(10))
print(size(root))
```

---

Height has the same shape: one more than the taller subtree. With -1 for an empty tree, a leaf comes out as `1 + max(-1, -1)`, which is 0.

```python trace stop=49
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def height(node):
    if node is None:
        return -1
    left = height(node.left)
    right = height(node.right)
    return 1 + max(left, right)

root = TreeNode(5, TreeNode(2, TreeNode(1)))
print(height(root))
```

The call for node 2 is about to return. What are its `left` and `right`?

- [x] `left` is 0, `right` is -1
- [ ] `left` is 1, `right` is 0
- [ ] `left` is -1, `right` is -1

---

Put the lines in order so `tree_sum` adds up every value in the tree.

```python arrange
def tree_sum(node):
    if node is None:
        return 0
    left = tree_sum(node.left)
    right = tree_sum(node.right)
    return node.val + left + right
```

```python tests
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

assert tree_sum(None) == 0
assert tree_sum(TreeNode(7)) == 7
root = TreeNode(1, TreeNode(-2), TreeNode(3, TreeNode(4)))
assert tree_sum(root) == 6
```

---

`height` calls itself once for every node and once for every empty child. On a tree with n nodes and height h, it takes

- [ ] O(h) time, O(1) extra space
- [x] O(n) time, O(h) extra space for the call stack
- [ ] O(n log n) time, O(n) extra space

---

A binary tree has 7 nodes. Its height is

- [ ] always 2
- [ ] always 6
- [x] anywhere from 2 to 6, depending on its shape

---

The exercises build trees from a list read level by level, left to right, with `None` for a missing child. `from_list([1, 2, 3, None, 4])` is this tree:

```diagram
tree
1 -> 2 3
2 -> _ 4
```

Node 2 gets `None` on the left and 4 on the right. Node 3 has nothing left in the list, so it is a leaf.

---

[Tree height](exercises/tree-height.md)

[Count the leaves](exercises/count-leaves.md)
