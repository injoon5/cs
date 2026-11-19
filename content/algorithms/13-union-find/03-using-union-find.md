---
id: using-union-find
title: Using union-find
---

The number of groups is a count you can keep as edges arrive. It starts at n, since every item is alone. A union that merges two groups lowers it by one, and a union inside one group changes nothing. The code below is the last lesson's union-find, with union by size and path halving, and `union` now returns whether it merged. What does this print?

```python predict
n = 5
parent = list(range(n))
size = [1] * n


def find(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


def union(a, b):
    ra, rb = find(a), find(b)
    if ra == rb:
        return False
    if size[ra] < size[rb]:
        ra, rb = rb, ra
    parent[rb] = ra
    size[ra] += size[rb]
    return True


groups = n
for a, b in [(0, 1), (3, 4), (1, 0), (1, 4)]:
    if union(a, b):
        groups -= 1
    print(groups)
```

---

A union that merges nothing tells you more. Its two ends were already connected, so the new edge closes a cycle.

```diagram
graph
node 0 at 0,0
node 1 at 0.4,0
node 2 at 0.2,0.35
node 3 at 0.8,0
node 4 at 0.8,0.35
0 -- 1
1 -- 2
3 -- 4
2 -- 0
highlight 2 0
```

When the edge (2, 0) arrives, 2 already reaches 0 through 1. In an undirected graph, union-find spots each cycle the moment its last edge arrives.

---

Here the loop stops at the first edge whose union merges nothing.

```python trace stop=63
parent = list(range(5))
size = [1] * 5


def find(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


def union(a, b):
    ra, rb = find(a), find(b)
    if ra == rb:
        return False
    if size[ra] < size[rb]:
        ra, rb = rb, ra
    parent[rb] = ra
    size[ra] += size[rb]
    return True


for a, b in [(0, 1), (1, 2), (3, 4), (2, 0), (2, 3)]:
    if not union(a, b):
        print("cycle at", a, b)
        break
```

`union(2, 0)` is about to run. What is `parent`, and what will `union` return?

- [x] `[0, 0, 0, 3, 3]`, and `False`, since 2 and 0 share the root 0
- [ ] `[0, 0, 1, 3, 3]`, and `False`, since 2 and 0 share the root 0
- [ ] `[0, 0, 0, 3, 3]`, and `True`, since there is no edge between 2 and 0 yet

---

Can the same trick find a cycle in a directed graph?

- [ ] Yes, an edge between two items of one group always closes a cycle
- [ ] Only if the edges arrive in topological order
- [x] No. Union-find ignores direction, so 0 → 1, 0 → 2, 1 → 2 looks like a cycle, though no path leads back to 0

For directed graphs, use the DFS states or Kahn's algorithm from the graphs unit.

---

Union-find wants items numbered 0 to n - 1. A grid cell `(r, c)` becomes `r * cols + c`. For strings, `parent` can be a dict that adds each item the first time it shows up.

```python
parent = {}


def find(x):
    parent.setdefault(x, x)
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


def union(a, b):
    ra, rb = find(a), find(b)
    if ra != rb:
        parent[rb] = ra


union("a", "b")
union("c", "d")
union("b", "d")
print(find("d"), find("e"))
print(parent)
```

A `size` dict works the same way.

---

Union-find also groups things that share a key. Photos tagged with the same place belong in one album, and so do photos linked through a chain of shared tags.

Keep a dict from each tag to the first photo that had it. A later photo with that tag joins that photo's group: one union per tag, however many photos share it. What does this print?

```python predict
photos = [["beach", "sunset"], ["city"], ["sunset", "dog"],
          ["park", "city"], ["cave"], ["dog"]]
parent = list(range(len(photos)))


def find(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


first = {}
for i, tags in enumerate(photos):
    for tag in tags:
        if tag in first:
            parent[find(i)] = find(first[tag])
        else:
            first[tag] = i

albums = {}
for i in range(len(photos)):
    albums.setdefault(find(i), []).append(i)
print(list(albums.values()))
```

---

Union-find can't say how two items are connected, only whether they are. It can't give a path or a distance, and it can't remove an edge. For a graph you get all at once, one DFS counts the components in O(V + E) just as well.

Which is a job for union-find rather than BFS or DFS?

- [ ] Finding the fewest roads between two cities
- [x] Opening roads one at a time, and after each one, saying whether every city can reach the capital
- [ ] Listing the cities along a route between two cities

Searching again after each of E roads costs O(E × (V + E)). Union-find handles all of them in nearly O(V + E).

---

[Components as cables arrive](exercises/components-as-edges-arrive.md)

[Redundant cable](exercises/redundant-cable.md)

[Equations that can all hold](exercises/equations-hold.md)

[Merge accounts](exercises/merge-accounts.md)

[Islands as land appears](exercises/islands-as-land-appears.md)
