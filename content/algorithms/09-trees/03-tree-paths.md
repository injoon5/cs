---
id: tree-paths
title: Paths and ancestors
---

Which paths from the root down to a leaf add up to 12?

```diagram
tree
5 -> 4 8
4 -> 3 _
8 -> -1 6
```

There are three paths. 5, 4, 3 and 5, 8, -1 both add up to 12; 5, 8, 6 adds up to 19. Height passed answers up from the children. Here the information flows down: each call gets the total of the path above it as an argument.

```python
def leaf_sums(node, total, out):
    if node is None:
        return
    total += node.val
    if node.left is None and node.right is None:
        out.append(total)
    leaf_sums(node.left, total, out)
    leaf_sums(node.right, total, out)
```

---

What does this print?

```python predict
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def leaf_sums(node, total, out):
    if node is None:
        return
    total += node.val
    if node.left is None and node.right is None:
        out.append(total)
    leaf_sums(node.left, total, out)
    leaf_sums(node.right, total, out)

root = TreeNode(2, TreeNode(-3, TreeNode(4)),
    TreeNode(1, None, TreeNode(-2)))
out = []
leaf_sums(root, 0, out)
print(out)
```

---

The diameter of a tree is the longest path between any two nodes, counted in edges. It doesn't have to pass through the root.

```diagram
tree
1 -> 2 9
2 -> 3 4
3 -> 5 _
4 -> _ 6
5 -> 7 _
6 -> _ 8
highlight 7 5 3 2 4 6 8
dim 1 9
```

The longest path through the root, from 7 up to 1 and down to 9, has 5 edges. The highlighted one has 6 and never touches the root.

Every path has one highest node, where it bends. The longest path bending at a node goes as deep as it can on both sides: the heights of its two subtrees, plus one edge down to each of them. At node 2 that is `2 + 2 + 2`, which is 6.

---

So diameter is height with one extra line. Compute heights bottom up, in postorder, and at each node check the best path that bends there.

```python
def diameter(root):
    best = 0

    def height(node):
        nonlocal best
        if node is None:
            return -1
        left = height(node.left)
        right = height(node.right)
        best = max(best, left + right + 2)
        return 1 + max(left, right)

    height(root)
    return best
```

Run this to watch it. Each frame is one node finishing, after both its subtrees are done.

```python
import viz

class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

root = TreeNode(1,
    TreeNode(2,
        TreeNode(3, TreeNode(5, TreeNode(7))),
        TreeNode(4, None, TreeNode(6, None, TreeNode(8)))),
    TreeNode(9))
best = 0

def height(node):
    global best
    if node is None:
        return -1
    left = height(node.left)
    right = height(node.right)
    best = max(best, left + right + 2)
    viz.tree(root, active=node, note=f"bend at {node.val}: {left} + {right} + 2, best {best}")
    return 1 + max(left, right)

height(root)
```

---

Another way to find the diameter: at every node, call `height` on both children from scratch and take the best `left + right + 2`. On a tree that is a single chain of n nodes, this takes

- [ ] O(n) time, like the one-pass version
- [ ] O(n log n) time
- [x] O(n²) time, because each `height` call walks the rest of the chain

---

The lowest common ancestor of two nodes is the deepest node that has both of them in its subtree. A node counts as being in its own subtree.

```diagram
tree
3 -> 5 1
5 -> 6 2
2 -> 7 4
1 -> 0 8
highlight 6 4 5
dim 1 0 8
```

For 6 and 4 it is 5. For 5 and 4 it is 5 itself. For 6 and 8 it is the root, 3.

Ask each subtree whether it holds `p` or `q`. If one turns up on each side, this node is where their paths split, so it is the answer. If both are on one side, pass up what that side found.

---

```python trace stop=49
class TreeNode:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def lca(node, p, q):
    if node is None or node.val in (p, q):
        return node
    left = lca(node.left, p, q)
    right = lca(node.right, p, q)
    if left and right:
        return node
    return left or right

root = TreeNode(3, TreeNode(5, TreeNode(6), TreeNode(2)), TreeNode(1))
print(lca(root, 6, 2).val)
```

The call for node 5 has heard back from both children. Which node will it return?

- [x] Node 5, since 6 came back from the left and 2 from the right
- [ ] Node 6, the first one found
- [ ] `None`, since node 5 is neither 6 nor 2

---

`lca` stops at `p` or `q` without looking below it. Why is that safe?

- [ ] Below `p`, there are no other nodes
- [x] If the other node is below `p`, then `p` is the answer anyway
- [ ] `p` and `q` are always on different sides of the root

---

[Path with a sum](exercises/has-path-sum.md)

[Tree diameter](exercises/tree-diameter.md)

[Distance between nodes](exercises/node-distance.md)
