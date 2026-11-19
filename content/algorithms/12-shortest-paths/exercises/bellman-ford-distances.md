---
id: bellman-ford-distances
title: Distances with negative edges
level: warmup
---

A directed graph has `n` nodes, numbered 0 to `n - 1`, and each `(a, b, w)` in `edges` is an edge from `a` to `b` of weight `w`. Weights can be negative, but there is no negative cycle. Return a list with the distance from `start` to every node, and `float("inf")` for nodes that can't be reached.

For `n = 4` and `edges = [(0, 1, 2), (0, 2, 5), (2, 1, -4), (1, 3, 1)]` from 0, the answer is `[0, 1, 5, 2]`.

```python starter
def bellman_ford(n, edges, start):
    pass
```

```tests
bellman_ford(4, [(0, 1, 2), (0, 2, 5), (2, 1, -4), (1, 3, 1)], 0) == [0, 1, 5, 2]
bellman_ford(1, [], 0) == [0]
bellman_ford(3, [(1, 2, -1)], 0) == [0, float("inf"), float("inf")]
bellman_ford(3, [(1, 0, -1)], 0) == [0, float("inf"), float("inf")]
bellman_ford(3, [(0, 1, -2), (1, 2, -3)], 0) == [0, -2, -5]
bellman_ford(3, [(1, 2, 1), (0, 1, 1)], 0) == [0, 1, 2]
bellman_ford(3, [(0, 1, 4), (0, 1, 1), (1, 2, 1)], 0) == [0, 1, 2]
bellman_ford(2, [(0, 1, 3), (1, 0, -3)], 1) == [-3, 0]
bellman_ford(4, [(2, 3, 1), (1, 2, 1), (0, 1, 1), (0, 3, 10)], 0) == [0, 1, 2, 3]
```

```python tests
import random


def slow(n, edges, start):
    inf = float("inf")
    d = [[0 if i == j else inf for j in range(n)] for i in range(n)]
    for a, b, w in edges:
        d[a][b] = min(d[a][b], w)
    for k in range(n):
        for i in range(n):
            for j in range(n):
                d[i][j] = min(d[i][j], d[i][k] + d[k][j])
    return d[start]


for _ in range(300):
    n = random.randint(1, 7)
    # Weights w + h[a] - h[b] can be negative, but every cycle keeps its non-negative total.
    h = [random.randint(0, 8) for _ in range(n)]
    edges = []
    for _ in range(random.randint(0, 12)):
        a, b = random.randrange(n), random.randrange(n)
        edges.append((a, b, random.randint(0, 6) + h[a] - h[b]))
    start = random.randrange(n)
    assert bellman_ford(n, edges, start) == slow(n, edges, start), (n, edges, start)
```

```python solution
def bellman_ford(n, edges, start):
    dist = [float("inf")] * n
    dist[start] = 0
    for _ in range(n - 1):
        changed = False
        for a, b, w in edges:
            if dist[a] + w < dist[b]:
                dist[b] = dist[a] + w
                changed = True
        if not changed:
            break
    return dist
```

## Hints

1. With negative weights no node can be settled early. Relax every edge, over and over.
2. Start with `dist[start] = 0` and every other entry `float("inf")`, then run rounds that each relax every edge.
3. A shortest path has at most `n - 1` edges, so `n - 1` rounds are enough. You can stop early when a round changes nothing.
