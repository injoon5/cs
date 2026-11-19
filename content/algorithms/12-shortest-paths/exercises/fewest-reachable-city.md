---
id: fewest-reachable-city
title: City with the fewest neighbors
level: core
---

There are `n` cities, numbered 0 to `n - 1`. Each `(a, b, w)` in `roads` is a two-way road of length `w > 0`. For each city, count the other cities it can reach with a route of length `limit` or less. Return the city with the smallest count. If several cities tie, return the smallest number.

For `n = 4`, `roads = [(0, 1, 3), (1, 2, 1), (1, 3, 4), (2, 3, 1)]` and `limit = 4`, cities 0 and 3 each have 2 cities within 4, and cities 1 and 2 have 3. The answer is 0.

```python starter
def best_city(n, roads, limit):
    pass
```

```tests
best_city(4, [(0, 1, 3), (1, 2, 1), (1, 3, 4), (2, 3, 1)], 4) == 0
best_city(1, [], 5) == 0
best_city(3, [], 1) == 0
best_city(3, [(0, 1, 1), (0, 2, 1)], 1) == 1
best_city(4, [(0, 1, 1), (1, 2, 5), (2, 3, 1), (0, 3, 1)], 1) == 1
best_city(4, [(0, 1, 1), (1, 2, 1), (2, 3, 1)], 2) == 0
best_city(4, [(0, 1, 1), (1, 2, 1), (2, 3, 9)], 2) == 3
best_city(3, [(0, 1, 2), (1, 2, 2), (0, 2, 9)], 4) == 0
best_city(3, [(1, 2, 1), (1, 2, 9), (0, 1, 1)], 1) == 0
best_city(5, [(0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 4, 5)], 2) == 4
best_city(5, [(0, 1, 2), (0, 2, 2), (0, 3, 2), (1, 4, 3), (2, 4, 3), (3, 4, 3)], 4) == 0
```

```python tests
import heapq
import random


def counts(n, roads, limit):
    graph = {v: [] for v in range(n)}
    for a, b, w in roads:
        graph[a].append((b, w))
        graph[b].append((a, w))
    out = []
    for s in range(n):
        dist = {s: 0}
        heap = [(0, s)]
        while heap:
            d, v = heapq.heappop(heap)
            if d > dist[v]:
                continue
            for u, w in graph[v]:
                if d + w < dist.get(u, float("inf")):
                    dist[u] = d + w
                    heapq.heappush(heap, (d + w, u))
        out.append(sum(1 for v, d in dist.items() if v != s and d <= limit))
    return out


for _ in range(300):
    n = random.randint(1, 7)
    roads = [(random.randrange(n), random.randrange(n), random.randint(1, 6)) for _ in range(random.randint(0, 10))]
    limit = random.randint(0, 10)
    c = counts(n, roads, limit)
    assert best_city(n, roads, limit) == c.index(min(c)), (n, roads, limit)
```

```python solution
def best_city(n, roads, limit):
    inf = float("inf")
    d = [[0 if i == j else inf for j in range(n)] for i in range(n)]
    for a, b, w in roads:
        d[a][b] = min(d[a][b], w)
        d[b][a] = min(d[b][a], w)
    for k in range(n):
        for i in range(n):
            for j in range(n):
                if d[i][k] + d[k][j] < d[i][j]:
                    d[i][j] = d[i][k] + d[k][j]
    best, fewest = 0, n
    for i in range(n):
        count = sum(1 for j in range(n) if j != i and d[i][j] <= limit)
        if count < fewest:
            best, fewest = i, count
    return best
```

## Hints

1. You need the distance from every city to every other city.
2. Run Floyd-Warshall, storing each road in both directions and keeping the shorter of two roads between the same cities.
3. For each city, count the others with `d[i][j] <= limit`. Replace the best city only on a strictly smaller count, so ties keep the smaller number.
