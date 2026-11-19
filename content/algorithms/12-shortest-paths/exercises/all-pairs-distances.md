---
id: all-pairs-distances
title: All-pairs distances
level: warmup
---

A directed graph has `n` nodes, numbered 0 to `n - 1`, and each `(a, b, w)` in `edges` is an edge from `a` to `b` of weight `w`. Weights can be negative, but there is no negative cycle. Return an `n` × `n` list of lists `d` where `d[i][j]` is the distance from `i` to `j`, `float("inf")` if `j` can't be reached from `i`, and 0 when `i == j`.

For `n = 3` and `edges = [(0, 1, 4), (1, 2, -1), (0, 2, 5)]` the answer is `[[0, 4, 3], [inf, 0, -1], [inf, inf, 0]]`, where `inf` is `float("inf")`.

```python starter
def all_pairs(n, edges):
    pass
```

```tests
all_pairs(3, [(0, 1, 4), (1, 2, -1), (0, 2, 5)]) == [[0, 4, 3], [float("inf"), 0, -1], [float("inf"), float("inf"), 0]]
all_pairs(4, [(0, 1, 3), (0, 3, 7), (1, 0, 8), (1, 2, 2), (2, 0, 5), (2, 3, 1), (3, 0, 2)]) == [[0, 3, 5, 6], [5, 0, 2, 3], [3, 6, 0, 1], [2, 5, 7, 0]]
all_pairs(1, []) == [[0]]
all_pairs(0, []) == []
all_pairs(2, []) == [[0, float("inf")], [float("inf"), 0]]
all_pairs(2, [(0, 1, 5), (0, 1, 2)]) == [[0, 2], [float("inf"), 0]]
all_pairs(2, [(0, 0, 3), (0, 1, 1)]) == [[0, 1], [float("inf"), 0]]
all_pairs(2, [(0, 1, -3), (1, 0, 3)]) == [[0, -3], [3, 0]]
all_pairs(80, [(i, i + 1, 1) for i in range(79)])[0][79] == 79
```

```python tests
import random


def from_one(n, edges, start):
    dist = [float("inf")] * n
    dist[start] = 0
    for _ in range(n):
        for a, b, w in edges:
            dist[b] = min(dist[b], dist[a] + w)
    return dist


for _ in range(300):
    n = random.randint(1, 6)
    # Weights w + h[a] - h[b] can be negative, but every cycle keeps its non-negative total.
    h = [random.randint(0, 8) for _ in range(n)]
    edges = []
    for _ in range(random.randint(0, 12)):
        a, b = random.randrange(n), random.randrange(n)
        edges.append((a, b, random.randint(0, 6) + h[a] - h[b]))
    assert all_pairs(n, edges) == [from_one(n, edges, s) for s in range(n)], (n, edges)
```

```python solution
def all_pairs(n, edges):
    inf = float("inf")
    d = [[0 if i == j else inf for j in range(n)] for i in range(n)]
    for a, b, w in edges:
        d[a][b] = min(d[a][b], w)
    for k in range(n):
        for i in range(n):
            for j in range(n):
                if d[i][k] + d[k][j] < d[i][j]:
                    d[i][j] = d[i][k] + d[k][j]
    return d
```

## Hints

1. Start from what the edges alone say, then let each node in turn serve as a stopover.
2. Fill `d` with 0 on the diagonal and `float("inf")` elsewhere, then lower `d[a][b]` to the lightest edge from `a` to `b`.
3. Loop `k` outermost, then `i`, then `j`. Whenever `d[i][k] + d[k][j]` is smaller than `d[i][j]`, use it.
