---
id: network-delay-time
title: Network delay
level: core
---

A network has `n` machines, numbered 0 to `n - 1`. Each `(a, b, t)` in `links` means a message sent from `a` reaches `b` after `t` milliseconds, with `t >= 0`. Links are one way. Machine `start` sends a signal, and every machine passes it on as soon as it arrives. Return how long it takes until every machine has it, or -1 if some machine never gets it.

For `n = 4` and `links = [(0, 1, 4), (0, 2, 1), (2, 1, 2), (1, 3, 1), (2, 3, 5)]` from 0, the machines get the signal at 0, 3, 1 and 4 milliseconds, so the answer is 4.

```python starter
import heapq


def delay_time(n, links, start):
    pass
```

```tests
delay_time(4, [(0, 1, 4), (0, 2, 1), (2, 1, 2), (1, 3, 1), (2, 3, 5)], 0) == 4
delay_time(1, [], 0) == 0
delay_time(2, [(0, 1, 5)], 0) == 5
delay_time(2, [(0, 1, 5)], 1) == -1
delay_time(3, [(0, 1, 2), (1, 0, 1)], 0) == -1
delay_time(3, [(0, 1, 3), (0, 1, 1), (1, 2, 1)], 0) == 2
delay_time(3, [(0, 1, 0), (1, 2, 0)], 0) == 0
delay_time(3, [(0, 2, 9), (0, 1, 2), (1, 2, 2)], 0) == 4
delay_time(20000, [(i, i + 1, 1) for i in range(19998, -1, -1)] + [(i, i + 2, 3) for i in range(19997, -1, -1)], 0) == 19999
```

```python tests
import random


def slow(n, links, start):
    dist = [float("inf")] * n
    dist[start] = 0
    for _ in range(n):
        for a, b, t in links:
            dist[b] = min(dist[b], dist[a] + t)
    return -1 if max(dist) == float("inf") else max(dist)


for _ in range(300):
    n = random.randint(1, 7)
    links = [(random.randrange(n), random.randrange(n), random.randint(0, 9)) for _ in range(random.randint(0, 14))]
    start = random.randrange(n)
    assert delay_time(n, links, start) == slow(n, links, start), (n, links, start)
```

```python solution
import heapq


def delay_time(n, links, start):
    graph = {v: [] for v in range(n)}
    for a, b, t in links:
        graph[a].append((b, t))
    dist = [float("inf")] * n
    dist[start] = 0
    heap = [(0, start)]
    done = set()
    while heap:
        d, node = heapq.heappop(heap)
        if node in done:
            continue
        done.add(node)
        for nxt, t in graph[node]:
            if d + t < dist[nxt]:
                dist[nxt] = d + t
                heapq.heappush(heap, (dist[nxt], nxt))
    if len(done) < n:
        return -1
    return max(dist)
```

## Hints

1. Each machine gets the signal at its distance from `start`. The answer is the largest of those distances.
2. Build a weighted adjacency list from `links`, then run Dijkstra from `start`.
3. If Dijkstra settled fewer than `n` machines, some machine is unreachable: return -1. Otherwise return `max(dist)`.
