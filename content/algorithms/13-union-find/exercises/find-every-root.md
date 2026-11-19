---
id: find-every-root
title: Root of every item
level: warmup
---

`parent` stores disjoint sets as trees: `parent[x]` is the parent of item `x`, and a root is its own parent. Return a list with the root of every item, in item order.

For `parent = [0, 0, 1, 3, 3, 5]`, item 2 walks to 1 and then to 0, so the answer is `[0, 0, 0, 3, 3, 5]`.

```python starter
def roots(parent):
    pass
```

```tests
roots([0, 0, 1, 3, 3, 5]) == [0, 0, 0, 3, 3, 5]
roots([]) == []
roots([0]) == [0]
roots([0, 1, 2]) == [0, 1, 2]
roots([1, 2, 3, 4, 4]) == [4, 4, 4, 4, 4]
roots([2, 2, 2, 2, 3]) == [2, 2, 2, 2, 2]
roots([3, 0, 1, 3, 1]) == [3, 3, 3, 3, 3]
roots([1, 1, 3, 3, 5, 5]) == [1, 1, 3, 3, 5, 5]
roots(list(range(1, 1000)) + [999]) == [999] * 1000
```

```python tests
import random


def slow(parent):
    out = []
    for x in range(len(parent)):
        for _ in range(len(parent)):
            x = parent[x]
        out.append(x)
    return out


for _ in range(300):
    n = random.randint(1, 10)
    order = random.sample(range(n), n)
    parent = [0] * n
    for i, x in enumerate(order):
        parent[x] = x if i == 0 or random.random() < 0.3 else random.choice(order[:i])
    assert roots(parent) == slow(parent), parent
```

```python solution
def roots(parent):
    out = []
    for x in range(len(parent)):
        while parent[x] != x:
            x = parent[x]
        out.append(x)
    return out
```

## Hints

1. The root of `x` is the item you reach by following parents until an item is its own parent.
2. For each item, walk up with `x = parent[x]` while `parent[x] != x`, then record where you stopped.
3. Loop over `range(len(parent))`. For each item, step with `x = parent[x]` until `parent[x] == x`, then append `x` to the result.
