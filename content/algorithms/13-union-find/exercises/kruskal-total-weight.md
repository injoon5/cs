---
id: kruskal-total-weight
title: Minimum spanning tree weight
level: core
---

A graph has `n` nodes, numbered `0` to `n - 1`. `edges` is a list of undirected edges `(a, b, w)`, where `w` is the weight. Weights can be negative or equal, and two nodes can be joined by more than one edge. Return the total weight of a minimum spanning tree, or `None` if the graph isn't connected.

For `n = 4` and `edges = [(0, 1, 1), (1, 2, 2), (0, 2, 3), (2, 3, 4)]`, the tree takes the edges of weight 1, 2 and 4, so the answer is 7.

```python starter
def mst_weight(n, edges):
    pass
```

```tests
mst_weight(4, [(0, 1, 1), (1, 2, 2), (0, 2, 3), (2, 3, 4)]) == 7
mst_weight(1, []) == 0
mst_weight(2, []) is None
mst_weight(2, [(0, 1, 5), (1, 0, 2), (0, 0, -9)]) == 2
mst_weight(3, [(0, 1, -2), (1, 2, -3), (0, 2, -1)]) == -5
mst_weight(4, [(0, 1, 1), (2, 3, 1)]) is None
mst_weight(4, [(0, 1, 7), (1, 2, 7), (2, 3, 7), (3, 0, 7)]) == 21
mst_weight(6, [(0, 1, 4), (1, 2, 7), (2, 3, 5), (3, 4, 8), (4, 5, 6), (5, 0, 3), (1, 5, 1), (2, 4, 2)]) == 17
mst_weight(100000, [(i + 1, i, i) for i in range(99999)] + [(0, j, 10 ** 6) for j in range(100000)]) == 99999 * 99998 // 2
mst_weight(100000, [(i, i + 1, i) for i in range(99999)] + [(0, j, 10 ** 6) for j in range(100000)]) == 99999 * 99998 // 2
```

```python tests
import random
from itertools import combinations


def slow(n, edges):
    best = None
    for subset in combinations(edges, n - 1):
        group = list(range(n))
        for a, b, _ in subset:
            old, new = group[a], group[b]
            group = [new if g == old else g for g in group]
        if len(set(group)) == 1:
            total = sum(w for _, _, w in subset)
            best = total if best is None else min(best, total)
    return best


for _ in range(300):
    n = random.randint(1, 5)
    edges = [(random.randrange(n), random.randrange(n), random.randint(-5, 9))
             for _ in range(random.randint(0, 8))]
    assert mst_weight(n, edges) == slow(n, edges), (n, edges)
```

```python solution
def mst_weight(n, edges):
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    total = 0
    used = 0
    for a, b, w in sorted(edges, key=lambda e: e[2]):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra
            total += w
            used += 1
    return total if used == n - 1 else None
```

## Hints

1. Kruskal's algorithm: take edges from lightest to heaviest, and skip any edge whose ends are already connected.
2. Sort with `key=lambda e: e[2]`, and use a union-find to tell whether two ends are already connected. Count the edges you take.
3. Add `w` to the total each time the two roots differ, and merge them. At the end, the graph was connected exactly when you took `n - 1` edges; otherwise return `None`.
