---
id: negative-cycle-check
title: Negative cycle check
level: core
---

A directed graph has `n` nodes, numbered 0 to `n - 1`, and each `(a, b, w)` in `edges` is an edge from `a` to `b` of weight `w`. Return `True` if the graph has a cycle whose weights add up to less than 0, anywhere in the graph, and `False` otherwise.

For `n = 4` and `edges = [(0, 1, 1), (1, 2, 1), (2, 3, -3), (3, 1, 1)]`, the cycle 1, 2, 3 adds up to −1, so the answer is `True`.

```python starter
def has_negative_cycle(n, edges):
    pass
```

```tests
has_negative_cycle(4, [(0, 1, 1), (1, 2, 1), (2, 3, -3), (3, 1, 1)]) == True
has_negative_cycle(4, [(0, 1, 1), (1, 2, 1), (2, 3, -2), (3, 1, 1)]) == False
has_negative_cycle(1, []) == False
has_negative_cycle(1, [(0, 0, -1)]) == True
has_negative_cycle(1, [(0, 0, 0)]) == False
has_negative_cycle(3, [(0, 1, -5), (1, 2, -5)]) == False
has_negative_cycle(4, [(0, 1, 1), (2, 3, -1), (3, 2, -1)]) == True
has_negative_cycle(2, [(0, 1, 3), (1, 0, -4)]) == True
has_negative_cycle(2, [(0, 1, 3), (1, 0, -3)]) == False
has_negative_cycle(60, [(a, b, 1) for a in range(60) for b in range(60) if a != b]) == False
has_negative_cycle(60, [(a, b, 1) for a in range(60) for b in range(60) if a != b] + [(59, 0, -2)]) == True
```

```python tests
import random


def slow(n, edges):
    inf = float("inf")
    d = [[0 if i == j else inf for j in range(n)] for i in range(n)]
    for a, b, w in edges:
        d[a][b] = min(d[a][b], w)
    for k in range(n):
        for i in range(n):
            for j in range(n):
                d[i][j] = min(d[i][j], d[i][k] + d[k][j])
    return any(d[i][i] < 0 for i in range(n))


for _ in range(400):
    n = random.randint(1, 6)
    edges = [(random.randrange(n), random.randrange(n), random.randint(-3, 6)) for _ in range(random.randint(0, 9))]
    assert has_negative_cycle(n, edges) == slow(n, edges), (n, edges)
```

```python solution
def has_negative_cycle(n, edges):
    dist = [0] * n
    for _ in range(n - 1):
        for a, b, w in edges:
            if dist[a] + w < dist[b]:
                dist[b] = dist[a] + w
    return any(dist[a] + w < dist[b] for a, b, w in edges)
```

## Hints

1. Bellman-Ford's extra round finds a negative cycle, but only one that its start can reach. Here the cycle can be anywhere.
2. Picture one extra node with a weight-0 edge to every node. Starting Bellman-Ford there is the same as starting with every `dist` at 0.
3. Set `dist = [0] * n`, run `n - 1` rounds that relax every edge, then return whether any edge can still be relaxed.
