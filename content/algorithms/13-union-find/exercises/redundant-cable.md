---
id: redundant-cable
title: Redundant cable
level: core
---

There are `n` computers, numbered `0` to `n - 1`, and `cables` lists the cables in the order they are plugged in. A cable is redundant if its two ends could already reach each other without it. Return the first redundant cable, exactly as it appears in the list, or `None` if there is none.

For `n = 4` and `cables = [(0, 1), (1, 2), (2, 3), (3, 1)]`, the cable `(3, 1)` closes the loop 1, 2, 3, so the answer is `(3, 1)`.

```python starter
def first_redundant(n, cables):
    pass
```

```tests
first_redundant(4, [(0, 1), (1, 2), (2, 3), (3, 1)]) == (3, 1)
first_redundant(4, [(0, 1), (1, 2), (2, 3)]) is None
first_redundant(3, []) is None
first_redundant(2, [(0, 1), (1, 0)]) == (1, 0)
first_redundant(3, [(2, 2), (0, 1)]) == (2, 2)
first_redundant(6, [(0, 1), (2, 3), (4, 5), (1, 2), (3, 4), (5, 0), (0, 3)]) == (5, 0)
first_redundant(5, [(0, 1), (2, 3), (1, 3), (4, 2), (0, 2), (0, 4)]) == (0, 2)
first_redundant(100000, [(i + 1, i) for i in range(49999)] + [(0, j) for j in range(50000, 100000)] + [(50000, 99999)]) == (50000, 99999)
first_redundant(100000, [(i, i + 1) for i in range(49999)] + [(0, j) for j in range(50000, 100000)] + [(50000, 99999)]) == (50000, 99999)
```

```python tests
import random


def slow(n, cables):
    graph = {v: set() for v in range(n)}
    for a, b in cables:
        seen = {a}
        stack = [a]
        while stack:
            for w in graph[stack.pop()]:
                if w not in seen:
                    seen.add(w)
                    stack.append(w)
        if b in seen:
            return (a, b)
        graph[a].add(b)
        graph[b].add(a)
    return None


for _ in range(300):
    n = random.randint(1, 9)
    cables = [(random.randrange(n), random.randrange(n)) for _ in range(random.randint(0, 10))]
    assert first_redundant(n, cables) == slow(n, cables), (n, cables)
```

```python solution
def first_redundant(n, cables):
    parent = list(range(n))
    size = [1] * n

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for a, b in cables:
        ra, rb = find(a), find(b)
        if ra == rb:
            return (a, b)
        if size[ra] < size[rb]:
            ra, rb = rb, ra
        parent[rb] = ra
        size[ra] += size[rb]
    return None
```

## Hints

1. A cable is redundant exactly when its two ends are already in the same group.
2. Add the cables to a union-find in order. Before merging, compare the two roots.
3. When `find(a) == find(b)`, return `(a, b)`. Otherwise merge with union by size. A cable from a computer to itself is redundant right away, since its roots match.
