---
id: prim-total-weight
title: Prim's algorithm
level: core
---

`graph` is an undirected weighted graph with at least one node, as an adjacency dict: each node maps to a list of `(neighbor, weight)` pairs, and every edge is listed under both of its ends. Use Prim's algorithm to return the total weight of a minimum spanning tree, or `None` if the graph isn't connected.

For `{"a": [("b", 2), ("c", 5)], "b": [("a", 2), ("c", 1)], "c": [("a", 5), ("b", 1)]}`, the tree takes a – b and b – c, so the answer is 3.

```python starter
import heapq


def prim_weight(graph):
    pass
```

```tests
prim_weight({"a": [("b", 2), ("c", 5)], "b": [("a", 2), ("c", 1)], "c": [("a", 5), ("b", 1)]}) == 3
prim_weight({0: []}) == 0
prim_weight({0: [], 1: []}) is None
prim_weight({0: [(1, 4), (1, 2)], 1: [(0, 4), (0, 2)]}) == 2
prim_weight({0: [(1, -3)], 1: [(0, -3), (2, 0)], 2: [(1, 0)]}) == -3
prim_weight({0: [(1, 1)], 1: [(0, 1)], 2: [(3, 1)], 3: [(2, 1)]}) is None
prim_weight({0: [(1, 4), (5, 3)], 1: [(0, 4), (2, 7), (5, 1)], 2: [(1, 7), (3, 5), (4, 2)], 3: [(2, 5), (4, 8)], 4: [(3, 8), (5, 6), (2, 2)], 5: [(4, 6), (0, 3), (1, 1)]}) == 17
prim_weight({i: [(j, 1) for j in (i - 1, i + 1) if 0 <= j < 50000] + [(j, 5) for j in (i - 2, i + 2) if 0 <= j < 50000] for i in range(50000)}) == 49999
prim_weight({i: [(j, 50000 - min(i, j)) for j in (i - 1, i + 1) if 0 <= j < 50000] + [(j, 10 ** 6) for j in (i - 2, i + 2) if 0 <= j < 50000] for i in range(50000)}) == 50000 * 50001 // 2 - 1
```

```python tests
import random
from itertools import combinations


def slow(graph):
    nodes = list(graph)
    edges = {(a, b, w) for a in graph for b, w in graph[a] if a < b}
    best = None
    for subset in combinations(edges, len(nodes) - 1):
        group = {v: v for v in nodes}
        for a, b, _ in subset:
            old, new = group[a], group[b]
            group = {v: new if g == old else g for v, g in group.items()}
        if len(set(group.values())) == 1:
            total = sum(w for _, _, w in subset)
            best = total if best is None else min(best, total)
    return best


for _ in range(300):
    n = random.randint(1, 5)
    graph = {v: [] for v in range(n)}
    for _ in range(random.randint(0, 7)):
        a, b = random.sample(range(n), 2) if n > 1 else (0, 0)
        if a != b:
            w = random.randint(-3, 9)
            graph[a].append((b, w))
            graph[b].append((a, w))
    assert prim_weight(graph) == slow(graph), graph
```

```python solution
import heapq


def prim_weight(graph):
    start = next(iter(graph))
    in_tree = set()
    heap = [(0, start)]
    total = 0
    while heap:
        w, v = heapq.heappop(heap)
        if v in in_tree:
            continue
        in_tree.add(v)
        total += w
        for nxt, cost in graph[v]:
            if nxt not in in_tree:
                heapq.heappush(heap, (cost, nxt))
    return total if len(in_tree) == len(graph) else None
```

## Hints

1. Grow one tree from any node. At each step, the cheapest edge leaving the tree is safe to take.
2. Keep a min-heap of `(weight, node)` entries for edges leaving the tree, and a set of the nodes in the tree. Popped entries whose node is already in the tree are stale: skip them.
3. Start with `heap = [(0, start)]` for `start = next(iter(graph))`. When a node joins, add its weight to the total and push `(cost, nxt)` for its neighbors outside the tree. If the tree ends with fewer nodes than the graph, return `None`.
