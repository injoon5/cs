---
id: dag-shortest-paths
title: Shortest paths in a DAG
level: core
---

A directed graph with no cycles has `n` nodes, numbered 0 to `n - 1`, and each `(a, b, w)` in `edges` is an edge from `a` to `b` of weight `w`. Weights can be negative. Return a list with the distance from `start` to every node, and `float("inf")` for nodes that can't be reached. Take O(V + E) time.

For `n = 5` and `edges = [(0, 1, 2), (0, 2, 6), (1, 2, 3), (1, 3, 1), (3, 2, -2), (3, 4, 5), (2, 4, 1)]` from 0, the answer is `[0, 2, 1, 3, 2]`.

```python starter
from collections import deque


def dag_distances(n, edges, start):
    pass
```

```tests
dag_distances(5, [(0, 1, 2), (0, 2, 6), (1, 2, 3), (1, 3, 1), (3, 2, -2), (3, 4, 5), (2, 4, 1)], 0) == [0, 2, 1, 3, 2]
dag_distances(1, [], 0) == [0]
dag_distances(3, [(0, 1, 1)], 2) == [float("inf"), float("inf"), 0]
dag_distances(3, [(1, 0, -5), (0, 2, 1)], 0) == [0, float("inf"), 1]
dag_distances(4, [(0, 1, 1), (0, 2, 4), (2, 1, -4), (1, 3, 1)], 0) == [0, 0, 4, 1]
dag_distances(3, [(0, 1, 2), (0, 1, -1), (1, 2, 0)], 0) == [0, -1, -1]
dag_distances(4, [(2, 3, 1), (1, 2, 1), (0, 1, 1), (0, 3, 10)], 0) == [0, 1, 2, 3]
dag_distances(4, [(3, 1, 1), (3, 2, 1), (1, 0, 1), (2, 0, 5)], 3) == [2, 1, 1, 0]
dag_distances(100000, [(i, i + 1, -1) for i in range(99998, -1, -1)] + [(i, i + 2, -1) for i in range(99997, -1, -1)], 0)[-1] == -99999
```

```python tests
import random


def slow(n, edges, start):
    dist = [float("inf")] * n
    dist[start] = 0
    for _ in range(n):
        for a, b, w in edges:
            dist[b] = min(dist[b], dist[a] + w)
    return dist


for _ in range(300):
    n = random.randint(1, 7)
    perm = random.sample(range(n), n)
    edges = []
    for _ in range(random.randint(0, 12)):
        a, b = random.randrange(n), random.randrange(n)
        if a < b:
            edges.append((perm[a], perm[b], random.randint(-5, 9)))
    start = random.randrange(n)
    assert dag_distances(n, edges, start) == slow(n, edges, start), (n, edges, start)
```

```python solution
from collections import deque


def dag_distances(n, edges, start):
    graph = {v: [] for v in range(n)}
    indegree = [0] * n
    for a, b, w in edges:
        graph[a].append((b, w))
        indegree[b] += 1
    queue = deque(v for v in range(n) if indegree[v] == 0)
    order = []
    while queue:
        v = queue.popleft()
        order.append(v)
        for nxt, _ in graph[v]:
            indegree[nxt] -= 1
            if indegree[nxt] == 0:
                queue.append(nxt)
    dist = [float("inf")] * n
    dist[start] = 0
    for u in order:
        for v, w in graph[u]:
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
    return dist
```

## Hints

1. In a DAG, relaxing each node's edges in topological order makes every distance final in one pass, even with negative weights.
2. Build the adjacency list and the in-degrees, and get a topological order with Kahn's algorithm.
3. Set `dist[start] = 0` and the rest to `float("inf")`, then for each `u` in order relax every edge leaving `u`. Unreachable nodes stay infinite, since `inf + w` is still `inf`.
