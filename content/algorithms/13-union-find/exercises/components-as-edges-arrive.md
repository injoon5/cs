---
id: components-as-edges-arrive
title: Components as cables arrive
level: core
---

There are `n` computers, numbered `0` to `n - 1`, and `cables` lists the cables in the order they are plugged in. Each cable joins two computers both ways. Return a list with the number of connected groups after each cable.

For `n = 4` and `cables = [(0, 1), (2, 3), (1, 0), (1, 2)]`, the counts are 3, then 2, then still 2, since 0 and 1 were already connected, then 1. The answer is `[3, 2, 2, 1]`.

```python starter
def groups_after_each(n, cables):
    pass
```

```tests
groups_after_each(4, [(0, 1), (2, 3), (1, 0), (1, 2)]) == [3, 2, 2, 1]
groups_after_each(3, []) == []
groups_after_each(1, [(0, 0)]) == [1]
groups_after_each(2, [(1, 1), (0, 1), (1, 0)]) == [2, 1, 1]
groups_after_each(5, [(0, 4), (1, 3), (2, 2), (4, 1), (3, 0)]) == [4, 3, 3, 2, 2]
groups_after_each(6, [(5, 4), (4, 3), (3, 2), (2, 1), (1, 0)]) == [5, 4, 3, 2, 1]
groups_after_each(100000, [(i + 1, i) for i in range(99999)] + [(0, i) for i in range(100000)])[-1] == 1
groups_after_each(100000, [(i, i + 1) for i in range(99999)] + [(0, i) for i in range(100000)])[-1] == 1
groups_after_each(100000, [(i, i + 50000) for i in range(50000)])[-1] == 50000
```

```python tests
import random


def slow(n, cables):
    graph = {v: set() for v in range(n)}
    out = []
    for a, b in cables:
        graph[a].add(b)
        graph[b].add(a)
        seen = set()
        count = 0
        for start in range(n):
            if start not in seen:
                count += 1
                seen.add(start)
                stack = [start]
                while stack:
                    for w in graph[stack.pop()]:
                        if w not in seen:
                            seen.add(w)
                            stack.append(w)
        out.append(count)
    return out


for _ in range(300):
    n = random.randint(1, 10)
    cables = [(random.randrange(n), random.randrange(n)) for _ in range(random.randint(0, 12))]
    assert groups_after_each(n, cables) == slow(n, cables), (n, cables)
```

```python solution
def groups_after_each(n, cables):
    parent = list(range(n))
    size = [1] * n

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    groups = n
    out = []
    for a, b in cables:
        ra, rb = find(a), find(b)
        if ra != rb:
            if size[ra] < size[rb]:
                ra, rb = rb, ra
            parent[rb] = ra
            size[ra] += size[rb]
            groups -= 1
        out.append(groups)
    return out
```

## Hints

1. A cable can only lower the count, and only by one: when its two ends were in different groups.
2. Start the count at `n`. For each cable, find both roots. If they differ, merge the groups and lower the count. Record the count either way.
3. Use union by size and path halving, since the big tests build a chain of 100,000 computers. When `ra != rb`, link the smaller root under the larger and do `groups -= 1`, then append `groups`.
