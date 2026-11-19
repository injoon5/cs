---
id: disjoint-sets
title: Disjoint sets
---

Six computers, numbered 0 to 5, get cables plugged in one at a time. Between cables, someone asks whether two computers can reach each other.

```diagram
graph
node 0 at 0,0
node 1 at 0.4,0
node 2 at 0.4,0.4
node 3 at 0.85,0
node 4 at 0.85,0.4
node 5 at 0,0.4
0 -- 1
1 -- 2
3 -- 4
```

So far 0 reaches 2 through 1, 3 reaches 4, and 5 reaches nothing. A BFS answers one question in O(V + E). But the questions keep coming, and the graph changes between them.

---

The questions only depend on the groups, the connected components: {0, 1, 2}, {3, 4} and {5}. No computer is in two groups, so the groups are disjoint sets. A new cable either merges two groups or lands inside one and changes nothing. Groups never split.

So two operations are enough. `find(x)` names the group of `x` by one of its members, the group's representative. `union(a, b)` merges the groups of `a` and `b`. Then `a` and `b` are connected exactly when `find(a) == find(b)`. A structure with these two operations is called union-find.

---

The obvious way is a label per item: `group[x]` is the representative of the group `x` is in, as in `[0, 0, 0, 3, 3, 5]`. `find` is one lookup. `union` has to relabel every member of one group, and finding them means scanning the whole list.

n items start in groups of their own, and n - 1 unions join them into one. With labels, the unions cost

- [ ] O(n) in total, one step per union
- [ ] O(n log n) in total
- [x] O(n²) in total, since every union scans all n labels

---

Union-find keeps each group as a tree instead. Every item stores its parent, and the root of the tree is the representative. A root is its own parent. Here are the same groups, with arrows from each item to its parent:

```diagram
digraph
node 0 at 0,0
node 1 at 0,0.35
node 2 at 0,0.7
node 3 at 0.45,0
node 4 at 0.45,0.35
node 5 at 0.9,0
1 -> 0
2 -> 1
4 -> 3
highlight 0 3 5

array parent [0, 0, 1, 3, 3, 5]
```

`parent[2]` is 1 and `parent[1]` is 0, so 2 sits two levels below its root.

---

To find the group of `x`, follow parents until you reach an item that is its own parent.

To merge two groups, find both roots and point one at the other. One entry of `parent` changes, however big the groups are. If the roots are the same, the two items are already in one group, and there is nothing to do. What does this print?

```python predict
parent = [0, 0, 1, 3, 3, 5]


def find(x):
    while parent[x] != x:
        x = parent[x]
    return x


def union(a, b):
    ra, rb = find(a), find(b)
    if ra != rb:
        parent[rb] = ra


print(find(2), find(4), find(5))
union(2, 4)
print(find(4), parent)
```

---

A cable from 2 to 4 ran `union(2, 4)`. It found the roots 0 and 3, so 3 now points at 0.

```diagram
digraph
node 0 at 0.3,0
node 1 at 0,0.35
node 2 at 0,0.7
node 3 at 0.6,0.35
node 4 at 0.6,0.7
node 5 at 0.95,0
1 -> 0
2 -> 1
3 -> 0
4 -> 3
highlight 0 5

array parent [0, 0, 1, 0, 3, 5]
```

There is no cable between 3 and 0. The tree records who is in the group, not which cables joined it.

---

Why does `union(2, 4)` link the two roots, rather than point 4 straight at 2?

- [ ] Changing a root is cheaper than changing any other item
- [x] 4 would join the group of 2, but 3 would stay behind, though it is connected to 4
- [ ] `find` only works when every item points straight at its root

Linking the roots moves whole trees.

---

Now a run from the start, with every item in a group of its own.

```python trace stop=53
parent = list(range(5))


def find(x):
    while parent[x] != x:
        x = parent[x]
    return x


def union(a, b):
    ra, rb = find(a), find(b)
    if ra != rb:
        parent[rb] = ra


for a, b in [(0, 1), (2, 3), (1, 3), (4, 3)]:
    union(a, b)
print(parent)
```

The loop has just handled `(1, 3)`. What is `parent`?

- [ ] `[0, 0, 2, 1, 4]`
- [x] `[0, 0, 0, 2, 4]`
- [ ] `[0, 0, 2, 0, 4]`

---

`find` walks from `x` up to its root, so it costs the depth of `x`. `union` costs two finds. Nothing so far keeps the trees short. What does this print?

```python predict
parent = list(range(6))


def find(x):
    while parent[x] != x:
        x = parent[x]
    return x


def union(a, b):
    ra, rb = find(a), find(b)
    if ra != rb:
        parent[rb] = ra


for i in range(1, 6):
    union(i, i - 1)
print(parent)
```

---

Each union hung the whole tree under one new item, and the tree grew into a chain.

```diagram
digraph
node 5 at 0,0
node 4 at 0,0.2
node 3 at 0,0.4
node 2 at 0,0.6
node 1 at 0,0.8
node 0 at 0,1
4 -> 5
3 -> 4
2 -> 3
1 -> 2
0 -> 1
highlight 5
```

`find(0)` now walks past every item. Building a chain of n items like this, then calling `find(0)` n times, costs

- [ ] O(n) in total, since each union changes one entry
- [ ] O(n log n) in total
- [x] O(n²) in total, since every `find(0)` walks the whole chain

The next lesson keeps the trees short.

---

[Root of every item](exercises/find-every-root.md)

[Connection queries](exercises/connection-queries.md)
