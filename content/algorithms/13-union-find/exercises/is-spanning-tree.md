---
id: is-spanning-tree
title: Is it a spanning tree
level: warmup
---

A graph has `n` nodes, numbered `0` to `n - 1`, with `n` at least 1. `edges` is a list of undirected edges `(a, b)`. Return `True` if the edges form a spanning tree: every node can reach every other, and there is no cycle.

For `n = 4`, `[(0, 1), (1, 2), (1, 3)]` is a spanning tree. `[(0, 1), (1, 2), (2, 0)]` is not: it has a cycle, and 3 can't be reached.

```python starter
def is_spanning_tree(n, edges):
    pass
```

```tests
is_spanning_tree(4, [(0, 1), (1, 2), (1, 3)]) == True
is_spanning_tree(4, [(0, 1), (1, 2), (2, 0)]) == False
is_spanning_tree(1, []) == True
is_spanning_tree(2, []) == False
is_spanning_tree(2, [(0, 1)]) == True
is_spanning_tree(2, [(0, 1), (1, 0)]) == False
is_spanning_tree(3, [(0, 1), (2, 2)]) == False
is_spanning_tree(4, [(0, 1), (2, 3)]) == False
is_spanning_tree(4, [(0, 1), (2, 3), (1, 2), (0, 3)]) == False
is_spanning_tree(5, [(3, 4), (2, 3), (0, 4), (4, 1)]) == True
is_spanning_tree(100000, [(i, i + 1) for i in range(99999)]) == True
is_spanning_tree(100000, [(i, i + 1) for i in range(99998)] + [(99998, 0)]) == False
```

```python tests
import random
from itertools import combinations


def slow(n, edges):
    if len(edges) != n - 1:
        return False
    reach = {0}
    for _ in range(n):
        reach |= {b for a, b in edges if a in reach} | {a for a, b in edges if b in reach}
    return len(reach) == n


for _ in range(300):
    n = random.randint(1, 6)
    edges = [(random.randrange(n), random.randrange(n)) for _ in range(random.randint(0, 7))]
    assert is_spanning_tree(n, edges) == slow(n, edges), (n, edges)
for n in range(1, 6):
    pairs = list(combinations(range(n), 2))
    for k in range(len(pairs) + 1):
        for edges in combinations(pairs, k):
            assert is_spanning_tree(n, list(edges)) == slow(n, list(edges)), (n, edges)
```

```python solution
def is_spanning_tree(n, edges):
    if len(edges) != n - 1:
        return False
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for a, b in edges:
        ra, rb = find(a), find(b)
        if ra == rb:
            return False
        parent[rb] = ra
    return True
```

## Hints

1. A spanning tree on `n` nodes has exactly `n - 1` edges. Count first.
2. With exactly `n - 1` edges, the graph is a spanning tree as long as no edge closes a cycle. Each of those edges then merges two groups, and `n - 1` merges leave one group.
3. Return `False` unless `len(edges) == n - 1`. Then add the edges to a union-find and return `False` the moment an edge's two ends already share a root.
