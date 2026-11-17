---
id: path-exists
title: Is there a path
level: warmup
---

`graph` is a directed graph as an adjacency dict: every node is a key, and its list holds the nodes one edge away. Return `True` if you can get from `start` to `goal` by following edges. A node can always reach itself.

In `{0: [1], 1: [2], 2: []}`, 0 can reach 2, but 2 can't reach 0.

```python starter
from collections import deque


def has_path(graph, start, goal):
    pass
```

```tests
has_path({0: [1], 1: [2], 2: []}, 0, 2) == True
has_path({0: [1], 1: [2], 2: []}, 2, 0) == False
has_path({0: []}, 0, 0) == True
has_path({0: [1], 1: [0], 2: []}, 0, 2) == False
has_path({0: [1, 2], 1: [0], 2: [3], 3: [2]}, 1, 3) == True
has_path({0: [1], 1: [0], 2: [0]}, 0, 2) == False
has_path({"a": ["b"], "b": ["c"], "c": ["a"], "d": []}, "c", "b") == True
has_path({i: [i + 1] for i in range(99999)} | {99999: []}, 0, 99999) == True
has_path({i: [i + 1] for i in range(99999)} | {99999: []}, 99999, 0) == False
```

```python tests
import random


def slow(graph, start, goal):
    reach = {start}
    for _ in range(len(graph)):
        reach |= {w for v in reach for w in graph[v]}
    return goal in reach


for _ in range(300):
    n = random.randint(1, 7)
    graph = {v: random.sample(range(n), random.randint(0, min(2, n))) for v in range(n)}
    a, b = random.randrange(n), random.randrange(n)
    assert has_path(graph, a, b) == slow(graph, a, b)
```

```python solution
from collections import deque


def has_path(graph, start, goal):
    seen = {start}
    queue = deque([start])
    while queue:
        node = queue.popleft()
        if node == goal:
            return True
        for nxt in graph[node]:
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return False
```

## Hints

1. Search outward from `start`. If the search ever reaches `goal`, the answer is `True`.
2. Run BFS with a seen set, so a cycle can't keep you going round forever.
3. Start with `seen = {start}` and a queue holding `start`. Return `True` when you take `goal` from the queue, and `False` once the queue is empty.
