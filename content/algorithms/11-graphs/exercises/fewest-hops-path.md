---
id: fewest-hops-path
title: Shortest route
level: core
---

`graph` is an adjacency dict with every node as a key. Return a path from `start` to `goal` with the fewest edges, as a list of nodes that begins with `start` and ends with `goal`. Return `[]` if `goal` can't be reached. If several paths tie, any of them is right.

In `{0: [1, 2], 1: [0, 3], 2: [0, 3], 3: [1, 2, 4], 4: [3]}`, a shortest path from 0 to 4 is `[0, 1, 3, 4]`. `[0, 2, 3, 4]` is just as good.

```python starter
from collections import deque


def shortest_path(graph, start, goal):
    pass
```

```tests
shortest_path({0: [1], 1: [2], 2: []}, 0, 2) == [0, 1, 2]
shortest_path({0: [1], 1: [2], 2: []}, 2, 0) == []
shortest_path({0: []}, 0, 0) == [0]
shortest_path({0: [1, 3], 1: [2], 2: [3], 3: []}, 0, 3) == [0, 3]
shortest_path({0: [1], 1: [0], 2: [1]}, 0, 2) == []
shortest_path({"a": ["b", "c"], "b": ["d"], "c": ["e"], "e": ["d"], "d": []}, "a", "d") == ["a", "b", "d"]
shortest_path({0: [1, 2], 1: [0, 3], 2: [0, 3], 3: [1, 2, 4], 4: [3]}, 0, 4) in ([0, 1, 3, 4], [0, 2, 3, 4])
len(shortest_path({i: [i + 1] for i in range(99999)} | {99999: []}, 0, 99999)) == 100000
```

```python tests
import random
from collections import deque


def hops(graph, start):
    dist = {start: 0}
    queue = deque([start])
    while queue:
        v = queue.popleft()
        for w in graph[v]:
            if w not in dist:
                dist[w] = dist[v] + 1
                queue.append(w)
    return dist


def check(graph, start, goal):
    path = shortest_path(graph, start, goal)
    dist = hops(graph, start)
    if goal not in dist:
        assert path == [], (graph, start, goal, path)
        return
    assert path[0] == start and path[-1] == goal, (graph, start, goal, path)
    assert len(path) == dist[goal] + 1, (graph, start, goal, path)
    for a, b in zip(path, path[1:]):
        assert b in graph[a], (graph, start, goal, path)


for _ in range(300):
    n = random.randint(1, 8)
    graph = {v: random.sample(range(n), random.randint(0, min(3, n))) for v in range(n)}
    check(graph, random.randrange(n), random.randrange(n))

# Two nodes per layer, each joined to both nodes of the next layer: 2^100 paths.
ladder = {v: [w for w in (v // 2 * 2 + 2, v // 2 * 2 + 3) if w < 202] for v in range(202)}
check(ladder, 0, 201)
check(ladder, 1, 200)
```

```python solution
from collections import deque


def shortest_path(graph, start, goal):
    parent = {start: None}
    queue = deque([start])
    while queue:
        node = queue.popleft()
        if node == goal:
            break
        for nxt in graph[node]:
            if nxt not in parent:
                parent[nxt] = node
                queue.append(nxt)
    if goal not in parent:
        return []
    path = []
    node = goal
    while node is not None:
        path.append(node)
        node = parent[node]
    return path[::-1]
```

## Hints

1. BFS reaches every node first along a path with the fewest edges. You only need to remember how it got there.
2. Keep `parent`, a dict from each discovered node to the node it was found from. It doubles as the seen set.
3. Start with `parent = {start: None}`. After the search, if `goal` isn't in `parent`, return `[]`. Otherwise follow `parent` from `goal` until `None`, collecting nodes, and reverse.
