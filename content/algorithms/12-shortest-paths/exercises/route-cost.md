---
id: route-cost
title: Route cost
level: warmup
---

`graph` is a weighted adjacency dict: each node maps to a list of `(neighbor, weight)` pairs, and every node is a key. Return the total weight of following `path`, a non-empty list of nodes, edge by edge. If some step in the path isn't an edge, return `float("inf")`. If there are several edges from `a` to `b`, use the lightest.

With `graph = {0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}`, the path `[0, 2, 1, 3]` costs 1 + 2 + 1 = 4, and `[0, 3]` costs `float("inf")`.

```python starter
def route_cost(graph, path):
    pass
```

```tests
route_cost({0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}, [0, 2, 1, 3]) == 4
route_cost({0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}, [0, 1, 3]) == 5
route_cost({0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}, [0, 3]) == float("inf")
route_cost({0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}, [3, 1]) == float("inf")
route_cost({0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}, [2]) == 0
route_cost({0: [(1, 5), (1, 2)], 1: [(0, 1)]}, [0, 1, 0, 1]) == 5
route_cost({0: [(0, 3)]}, [0, 0, 0]) == 6
route_cost({"a": [("b", -2)], "b": [("c", 0)], "c": []}, ["a", "b", "c"]) == -2
route_cost({i: [(i + 1, 1)] for i in range(50000)} | {50000: []}, list(range(50001))) == 50000
```

```python tests
import random


def slow(graph, path):
    total = 0
    for i in range(len(path) - 1):
        best = float("inf")
        for nxt, w in graph[path[i]]:
            if nxt == path[i + 1]:
                best = min(best, w)
        total += best
    return total


for _ in range(300):
    n = random.randint(1, 6)
    graph = {v: [(random.randrange(n), random.randint(-5, 9)) for _ in range(random.randint(0, 4))] for v in range(n)}
    path = [random.randrange(n) for _ in range(random.randint(1, 6))]
    assert route_cost(graph, path) == slow(graph, path), (graph, path)
```

```python solution
def route_cost(graph, path):
    total = 0
    for a, b in zip(path, path[1:]):
        weights = [w for nxt, w in graph[a] if nxt == b]
        if not weights:
            return float("inf")
        total += min(weights)
    return total
```

## Hints

1. Each pair of neighbors in the path is one edge to look up.
2. `zip(path, path[1:])` gives the pairs. For a pair `(a, b)`, look through `graph[a]` for the entries that go to `b`.
3. Collect the weights of those entries. If there are none, return `float("inf")`; otherwise add the smallest to the total.
