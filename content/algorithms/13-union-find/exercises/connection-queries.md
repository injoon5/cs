---
id: connection-queries
title: Connection queries
level: warmup
---

There are `n` items, numbered `0` to `n - 1`, each in a group of its own. `ops` is a list of operations in order: `("union", a, b)` merges the groups of `a` and `b`, and `("connected", a, b)` asks whether `a` and `b` are in the same group. Return the answers to the questions, in order.

For `n = 4` and the operations union 0 and 1, connected 0 and 1, connected 1 and 2, union 1 and 2, connected 0 and 2, the answer is `[True, False, True]`.

```python starter
def answer_queries(n, ops):
    pass
```

```tests
answer_queries(4, [("union", 0, 1), ("connected", 0, 1), ("connected", 1, 2), ("union", 1, 2), ("connected", 0, 2)]) == [True, False, True]
answer_queries(3, []) == []
answer_queries(1, [("connected", 0, 0)]) == [True]
answer_queries(3, [("connected", 0, 2), ("connected", 2, 0)]) == [False, False]
answer_queries(3, [("union", 0, 1), ("union", 1, 0), ("union", 0, 1), ("connected", 1, 0)]) == [True]
answer_queries(5, [("union", 0, 1), ("union", 3, 4), ("connected", 1, 4), ("union", 1, 3), ("connected", 0, 4), ("connected", 2, 4)]) == [False, True, False]
answer_queries(6, [("union", 4, 5), ("union", 3, 4), ("union", 2, 3), ("union", 1, 2), ("union", 0, 1), ("connected", 0, 5)]) == [True]
answer_queries(2, [("union", 0, 1)]) == []
```

```python tests
import random


def slow(n, ops):
    groups = [{x} for x in range(n)]
    out = []
    for op, a, b in ops:
        ga = next(g for g in groups if a in g)
        gb = next(g for g in groups if b in g)
        if op == "connected":
            out.append(ga is gb)
        elif ga is not gb:
            groups.remove(gb)
            ga |= gb
    return out


for _ in range(300):
    n = random.randint(1, 8)
    ops = [(random.choice(["union", "connected"]), random.randrange(n), random.randrange(n))
           for _ in range(random.randint(0, 15))]
    assert answer_queries(n, ops) == slow(n, ops), (n, ops)
```

```python solution
def answer_queries(n, ops):
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            x = parent[x]
        return x

    out = []
    for op, a, b in ops:
        ra, rb = find(a), find(b)
        if op == "union":
            if ra != rb:
                parent[rb] = ra
        else:
            out.append(ra == rb)
    return out
```

## Hints

1. Keep a `parent` list where every item starts as its own root. Each operation needs the roots of `a` and `b`.
2. `find` follows parents up to the root. A union points one root at the other. A question compares the two roots.
3. Start with `parent = list(range(n))`. For each operation, get `ra, rb = find(a), find(b)`. On `"union"`, set `parent[rb] = ra` when they differ; on `"connected"`, append `ra == rb`.
