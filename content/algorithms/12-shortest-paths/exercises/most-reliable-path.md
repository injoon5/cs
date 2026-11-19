---
id: most-reliable-path
title: Most reliable path
level: stretch
---

A network has `n` nodes, numbered 0 to `n - 1`. Each `(a, b, p)` in `links` is a two-way link that carries a message through with probability `p`, between 0 and 1. A message sent along a path gets through only if every link on it works, so its chance is the product of their probabilities. Return the highest chance of getting a message from `start` to `goal`, or 0.0 if there is no path. From a node to itself, the chance is 1.0.

For `n = 3` and `links = [(0, 1, 0.5), (1, 2, 0.5), (0, 2, 0.2)]`, going from 0 to 2 through 1 has chance 0.5 × 0.5 = 0.25, better than 0.2 for the direct link.

```python starter
import heapq


def best_chance(n, links, start, goal):
    pass
```

```tests
best_chance(3, [(0, 1, 0.5), (1, 2, 0.5), (0, 2, 0.2)], 0, 2) == 0.25
best_chance(3, [(0, 1, 0.5), (1, 2, 0.5), (0, 2, 0.3)], 0, 2) == 0.3
best_chance(3, [(0, 1, 0.5), (1, 2, 0.5), (0, 2, 0.2)], 2, 0) == 0.25
best_chance(3, [(0, 1, 0.5)], 0, 2) == 0.0
best_chance(1, [], 0, 0) == 1.0
best_chance(2, [(0, 1, 0.0)], 0, 1) == 0.0
best_chance(2, [(0, 1, 0.25), (0, 1, 0.5)], 0, 1) == 0.5
best_chance(4, [(0, 1, 1.0), (1, 2, 1.0), (2, 3, 0.5), (0, 3, 0.25)], 0, 3) == 0.5
round(best_chance(4, [(0, 1, 0.9), (1, 3, 0.9), (0, 2, 0.8), (2, 3, 0.95)], 0, 3), 9) == 0.81
best_chance(20000, [(i, i + 1, 1.0) for i in range(19999)] + [(i, i + 2, 0.5) for i in range(19998)], 0, 19999) == 1.0
```

```python tests
import random


def slow(n, links, start, goal):
    best = [0.0] * n
    best[start] = 1.0
    for _ in range(n):
        for a, b, p in links:
            best[b] = max(best[b], best[a] * p)
            best[a] = max(best[a], best[b] * p)
    return best[goal]


for _ in range(300):
    n = random.randint(1, 7)
    links = [(random.randrange(n), random.randrange(n), random.choice([0.0, 0.1, 0.25, 0.5, 0.6, 0.75, 0.9, 1.0]))
             for _ in range(random.randint(0, 10))]
    start, goal = random.randrange(n), random.randrange(n)
    got = best_chance(n, links, start, goal)
    want = slow(n, links, start, goal)
    assert abs(got - want) < 1e-9, (n, links, start, goal, got, want)
```

```python solution
import heapq


def best_chance(n, links, start, goal):
    graph = {v: [] for v in range(n)}
    for a, b, p in links:
        graph[a].append((b, p))
        graph[b].append((a, p))
    best = [0.0] * n
    best[start] = 1.0
    heap = [(-1.0, start)]
    done = set()
    while heap:
        neg, node = heapq.heappop(heap)
        if node in done:
            continue
        if node == goal:
            return -neg
        done.add(node)
        for nxt, p in graph[node]:
            chance = -neg * p
            if chance > best[nxt]:
                best[nxt] = chance
                heapq.heappush(heap, (-chance, nxt))
    return 0.0
```

## Hints

1. Chances multiply along a path, and multiplying by a probability never makes a number bigger. That is the property Dijkstra needs, with "largest first" in place of "smallest first".
2. Keep `best[v]`, the highest chance found so far, starting at 1.0 for `start`. `heapq` is a min-heap, so push `(-chance, node)`.
3. Crossing a link with probability `p` from a node popped with chance `c` gives `c * p`. Return the chance when `goal` comes off the heap, and 0.0 if the heap runs dry.
