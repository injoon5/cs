---
id: keeping-trees-short
title: Keeping trees short
---

`union(3, 4)` has to point one of these roots at the other.

```diagram
digraph
node 0 at 0.3,0
node 1 at 0,0.35
node 2 at 0.6,0.35
node 3 at 0,0.7
node 4 at 1,0
1 -> 0
2 -> 0
3 -> 1
highlight 0 4
```

If 0 goes under 4, all four items on the left get one step deeper, and 3 ends up three steps from its root. If 4 goes under 0, only 4 gets deeper, and no item is more than two steps from the root.

---

That is the rule. Keep `size[r]`, the number of items in the tree under root `r`, and always point the smaller tree's root at the larger one's. This is union by size. Here are the unions that built a chain in the last lesson. What does this print?

```python predict
parent = list(range(6))
size = [1] * 6


def find(x):
    while parent[x] != x:
        x = parent[x]
    return x


def union(a, b):
    ra, rb = find(a), find(b)
    if ra == rb:
        return
    if size[ra] < size[rb]:
        ra, rb = rb, ra
    parent[rb] = ra
    size[ra] += size[rb]


for i in range(1, 6):
    union(i, i - 1)
print(parent)
print(size)
```

The chain became a star. Only the sizes of roots are kept up to date. The other entries are left over from when those items were roots, and nothing reads them.

---

Union by size keeps every tree short. An item gets one step deeper only when the root of its tree is pointed at another root, and that only happens to a tree no bigger than the other. So each time the item gets deeper, the tree it is in at least doubles. A tree can't grow past n items, so that happens at most log₂ n times, and every `find` costs O(log n).

Trees of equal size merging over and over reach that bound. Join 8 items in pairs, then pairs of pairs, then the two halves, and one item ends up 3 steps from the root.

With union by size, a group of 1,000,000 items has no item deeper than about

- [ ] 1,000
- [x] 20
- [ ] 500,000

---

`find` walks the whole path to the root anyway. Once it knows the root, it can point every item it passed straight at it, so the next `find` from any of them takes one step. This is path compression. Left, before `find(3)`. Right, after:

```diagram
digraph
node a0 "0" at 0,0
node a1 "1" at 0,0.3
node a2 "2" at 0,0.6
node a3 "3" at 0,0.9
node a4 "4" at 0.22,0.9
node b0 "0" at 0.78,0
node b1 "1" at 0.56,0.3
node b2 "2" at 0.78,0.3
node b3 "3" at 1,0.3
node b4 "4" at 0.78,0.6
a1 -> a0
a2 -> a1
a3 -> a2
a4 -> a2
b1 -> b0
b2 -> b0
b3 -> b0
b4 -> b2
highlight a0 b0
```

4 was not on the path, but it moved up with 2.

---

Run this to watch `find(3)` work. The first loop walks up to the root. The second walks the path again and points each item at the root.

```python
import viz


class Node:
    def __init__(self, val):
        self.val = val
        self.children = []


parent = [0, 0, 1, 2, 2]
nodes = [Node(x) for x in range(len(parent))]


def show(active, note):
    for node in nodes:
        node.children = [nodes[c] for c in range(len(parent))
                         if parent[c] == node.val and c != node.val]
    viz.tree(nodes[0], active=[nodes[a] for a in active], note=note)


x = 3
show([x], "find(3)")
while parent[x] != x:
    x = parent[x]
    show([x], f"up to {x}")
root = x
x = 3
while parent[x] != root:
    nxt = parent[x]
    parent[x] = root
    show([x], f"point {x} at {root}")
    x = nxt
show([root], "every item on the path points at the root")
```

---

Put the lines in order so `compress` runs `find(x)` with path compression and returns `parent` afterwards.

```python arrange
def compress(parent, x):
    root = x
    while parent[root] != root:
        root = parent[root]
    while parent[x] != root:
        nxt = parent[x]
        parent[x] = root
        x = nxt
    return parent
```

```tests
compress([0, 0, 1, 2, 3], 4) == [0, 0, 0, 0, 0]
compress([0, 0, 1, 2, 3], 2) == [0, 0, 0, 2, 3]
compress([0, 0, 1, 2, 2], 3) == [0, 0, 0, 0, 2]
compress([1, 2, 2, 2], 0) == [2, 2, 2, 2]
compress([1, 1, 1], 0) == [1, 1, 1]
compress([0], 0) == [0]
```

---

A shorter loop does almost as well. While walking up, point each item at its grandparent, then step to it. Every item on the path ends up closer to the root, and it takes one pass. This is path halving, and the rest of this unit uses it.

```python trace stop=13
parent = [0, 0, 1, 2, 3, 4]
x = 5
while parent[x] != x:
    parent[x] = parent[parent[x]]
    x = parent[x]
print(x)
```

The loop has ended. What is `parent`?

- [ ] `[0, 0, 0, 0, 0, 0]`
- [x] `[0, 0, 1, 1, 3, 3]`
- [ ] `[0, 0, 1, 2, 3, 3]`

---

Path compression changes the shape of a tree. What happens to `size`?

- [ ] Each item that moved needs its size updated
- [ ] The root's size has to be counted again
- [x] Nothing: items only move within their own tree, so every root's size stays right

---

Each trick alone makes an operation cost O(log n): union by size in the worst case, path compression on average over a run. Together, any run of m operations on n items costs O(m α(n)). α is the inverse Ackermann function, which grows so slowly that it is at most 4 for any n that fits in a computer. In practice, each `find` and `union` costs O(1) amortized.

With both tricks, a million unions and a million finds on a million items take about

- [ ] a million squared steps
- [ ] a million × 20 steps
- [x] a few million steps

---

[Disjoint sets class](exercises/disjoint-sets-class.md)

[Largest group](exercises/largest-group-after-each.md)
