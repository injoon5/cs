---
id: cheapest-route
title: Cheapest route
level: core
---

`graph` is a weighted adjacency dict with every node as a key, and all weights are 0 or more. Return `(cost, path)`: the cost of the cheapest path from `start` to `goal`, and the path itself as a list of nodes that begins with `start` and ends with `goal`. If `goal` can't be reached, return `(float("inf"), [])`. If several paths tie, any of them is right.

With `graph = {0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}`, the answer from 0 to 3 is `(4, [0, 2, 1, 3])`.

```python starter
import heapq


def cheapest_route(graph, start, goal):
    pass
```

```tests
cheapest_route({0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}, 0, 3) == (4, [0, 2, 1, 3])
cheapest_route({0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}, 3, 0) == (float("inf"), [])
cheapest_route({0: [(1, 7), (2, 2)], 1: [(3, 1)], 2: [(1, 3), (3, 8), (4, 5)], 3: [(5, 2)], 4: [(3, 1), (5, 6)], 5: []}, 0, 5) == (8, [0, 2, 1, 3, 5])
cheapest_route({0: []}, 0, 0) == (0, [0])
cheapest_route({"a": [("b", 1)], "b": [("a", 1)]}, "b", "a") == (1, ["b", "a"])
cheapest_route({0: [(1, 0)], 1: [(2, 0)], 2: []}, 0, 2) == (0, [0, 1, 2])
cheapest_route({0: [(1, 5), (1, 3)], 1: []}, 0, 1) == (3, [0, 1])
cheapest_route({0: [(1, 1)], 1: [], 2: [(1, 1)]}, 0, 2) == (float("inf"), [])
cheapest_route({0: [(1, 1), (2, 1)], 1: [(3, 1)], 2: [(3, 1)], 3: []}, 0, 3) in ((2, [0, 1, 3]), (2, [0, 2, 3]))
```

```python tests
import random


def distances(graph, start):
    dist = {v: float("inf") for v in graph}
    dist[start] = 0
    for _ in range(len(graph)):
        for a in graph:
            for b, w in graph[a]:
                dist[b] = min(dist[b], dist[a] + w)
    return dist


def check(graph, start, goal):
    cost, path = cheapest_route(graph, start, goal)
    best = distances(graph, start)[goal]
    assert cost == best, (graph, start, goal, cost)
    if best == float("inf"):
        assert path == [], (graph, start, goal, path)
        return
    assert path[0] == start and path[-1] == goal, (graph, start, goal, path)
    total = 0
    for a, b in zip(path, path[1:]):
        weights = [w for nxt, w in graph[a] if nxt == b]
        assert weights, (graph, start, goal, path)
        total += min(weights)
    assert total == best, (graph, start, goal, path)


for _ in range(300):
    n = random.randint(1, 7)
    graph = {v: [(random.randrange(n), random.randint(0, 9)) for _ in range(random.randint(0, 3))] for v in range(n)}
    check(graph, random.randrange(n), random.randrange(n))

# Two nodes per layer, each joined to both nodes of the next layer: 2^100 paths.
ladder = {v: [(w, 1 + (v + w) % 3) for w in (v // 2 * 2 + 2, v // 2 * 2 + 3) if w < 202] for v in range(202)}
check(ladder, 0, 201)
check(ladder, 1, 200)
```

```python solution
import heapq


def cheapest_route(graph, start, goal):
    dist = {v: float("inf") for v in graph}
    dist[start] = 0
    parent = {start: None}
    heap = [(0, start)]
    done = set()
    while heap:
        d, node = heapq.heappop(heap)
        if node in done:
            continue
        if node == goal:
            break
        done.add(node)
        for nxt, w in graph[node]:
            if d + w < dist[nxt]:
                dist[nxt] = d + w
                parent[nxt] = node
                heapq.heappush(heap, (dist[nxt], nxt))
    if dist[goal] == float("inf"):
        return float("inf"), []
    path = []
    node = goal
    while node is not None:
        path.append(node)
        node = parent[node]
    return dist[goal], path[::-1]
```

## Hints

1. Run Dijkstra from `start`, and remember where each node's best distance came from.
2. Keep `parent`, starting with `{start: None}`. Whenever relaxing an edge lowers `dist[nxt]`, set `parent[nxt] = node`. You can stop once `goal` comes off the heap.
3. If `dist[goal]` is still `float("inf")`, return `(float("inf"), [])`. Otherwise follow `parent` from `goal` until `None`, collecting nodes, and reverse.
