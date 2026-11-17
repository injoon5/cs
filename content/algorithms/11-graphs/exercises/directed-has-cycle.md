---
id: directed-has-cycle
title: Cycle in a directed graph
level: core
---

`graph` is a directed graph as an adjacency dict, with every node as a key. Return `True` if it has a cycle: a path that follows edges from some node back to itself.

`{0: [1], 1: [2], 2: [0]}` has a cycle. The diamond `{0: [1, 2], 1: [3], 2: [3], 3: []}` doesn't, even though two paths lead to 3.

```python starter
def has_cycle(graph):
    pass
```

```tests
has_cycle({0: [1], 1: [2], 2: [0]}) == True
has_cycle({0: [1, 2], 1: [3], 2: [3], 3: []}) == False
has_cycle({}) == False
has_cycle({0: []}) == False
has_cycle({0: [0]}) == True
has_cycle({0: [1], 1: [0]}) == True
has_cycle({0: [1], 1: [], 2: [3], 3: [4], 4: [2]}) == True
has_cycle({"a": ["b"], "b": ["c"], "c": [], "d": ["b"]}) == False
has_cycle({v: [w for w in (v // 2 * 2 + 2, v // 2 * 2 + 3) if w < 600] for v in range(600)}) == False
```

```python tests
import random


def slow(graph):
    for start in graph:
        reach = set(graph[start])
        for _ in range(len(graph)):
            reach |= {w for v in reach for w in graph[v]}
        if start in reach:
            return True
    return False


for _ in range(300):
    n = random.randint(1, 7)
    graph = {v: random.sample(range(n), random.randint(0, min(2, n))) for v in range(n)}
    assert has_cycle(graph) == slow(graph), graph

# Two nodes per layer, each pointing to both nodes of the next layer: 2^300 paths, no cycle.
ladder = {v: [w for w in (v // 2 * 2 + 2, v // 2 * 2 + 3) if w < 600] for v in range(600)}
ladder[599].append(1)
assert has_cycle(ladder) == True
```

```python solution
def has_cycle(graph):
    state = {v: "new" for v in graph}

    def visit(v):
        state[v] = "open"
        for w in graph[v]:
            if state[w] == "open":
                return True
            if state[w] == "new" and visit(w):
                return True
        state[v] = "done"
        return False

    return any(state[v] == "new" and visit(v) for v in graph)
```

## Hints

1. A seen set isn't enough: in the diamond, DFS reaches 3 twice with no cycle. What matters is whether a node is still on the current path.
2. Give each node a state: new, open while its DFS call is running, done once it returns. An edge to an open node closes a cycle. A done node has already been fully explored, so skip it.
3. Write `visit(v)` that sets `v` to open, returns `True` on an open neighbor, recurses into new ones, then sets `v` to done. Call it from every node that is still new.
