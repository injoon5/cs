---
id: edges-to-adjacency
title: Adjacency list from edges
level: warmup
---

The nodes are `0` to `n - 1`, and `edges` is a list of `(a, b)` pairs. Return the adjacency list: a dict with every node as a key and the list of its neighbors as the value, in the order the edges appear. If `directed` is `True`, each pair is an edge from `a` to `b` only. Otherwise it goes both ways. No edge joins a node to itself.

For `n = 4`, `edges = [(0, 1), (1, 2), (0, 3)]` and `directed = False`, the answer is `{0: [1, 3], 1: [0, 2], 2: [1], 3: [0]}`.

```python starter
def adjacency(n, edges, directed):
    pass
```

```tests
adjacency(4, [(0, 1), (1, 2), (0, 3)], False) == {0: [1, 3], 1: [0, 2], 2: [1], 3: [0]}
adjacency(4, [(0, 1), (1, 2), (0, 3)], True) == {0: [1, 3], 1: [2], 2: [], 3: []}
adjacency(0, [], False) == {}
adjacency(1, [], True) == {0: []}
adjacency(3, [(2, 0)], False) == {0: [2], 1: [], 2: [0]}
adjacency(3, [(2, 0)], True) == {0: [], 1: [], 2: [0]}
adjacency(2, [(0, 1), (1, 0)], True) == {0: [1], 1: [0]}
adjacency(100000, [(i, i + 1) for i in range(99999)], False)[500] == [499, 501]
len(adjacency(100000, [], True)) == 100000
```

```python tests
import random


def slow(n, edges, directed):
    out = {}
    for v in range(n):
        out[v] = []
        for a, b in edges:
            if a == v:
                out[v].append(b)
            elif b == v and not directed:
                out[v].append(a)
    return out


for _ in range(200):
    n = random.randint(1, 8)
    edges = [tuple(random.sample(range(n), 2)) for _ in range(random.randint(0, 10))] if n > 1 else []
    directed = random.choice([True, False])
    assert adjacency(n, edges, directed) == slow(n, edges, directed)
```

```python solution
def adjacency(n, edges, directed):
    graph = {v: [] for v in range(n)}
    for a, b in edges:
        graph[a].append(b)
        if not directed:
            graph[b].append(a)
    return graph
```

## Hints

1. Start with every node mapped to an empty list, so nodes with no edges are still keys.
2. For each pair, append `b` to the list of `a`. An undirected edge also needs the reverse.
3. Build `{v: [] for v in range(n)}`, then loop over the pairs: `graph[a].append(b)`, and if not `directed`, `graph[b].append(a)`.
