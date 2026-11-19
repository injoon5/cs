---
id: largest-group-after-each
title: Largest group
level: core
---

There are `n` people, numbered `0` to `n - 1`, and `pairs` lists introductions in the order they happen. After an introduction, the two people and everyone they already knew, directly or through others, are in one group. Return a list with the size of the largest group after each introduction.

For `n = 5` and `pairs = [(0, 1), (2, 3), (1, 3), (0, 2)]`, the groups grow to {0, 1}, then {2, 3} as well, then {0, 1, 2, 3}, and the last pair changes nothing. The answer is `[2, 2, 4, 4]`.

```python starter
def largest_after_each(n, pairs):
    pass
```

```tests
largest_after_each(5, [(0, 1), (2, 3), (1, 3), (0, 2)]) == [2, 2, 4, 4]
largest_after_each(3, []) == []
largest_after_each(1, [(0, 0)]) == [1]
largest_after_each(4, [(0, 1), (0, 1), (1, 0)]) == [2, 2, 2]
largest_after_each(6, [(0, 1), (2, 3), (4, 5), (3, 4), (5, 1)]) == [2, 2, 2, 4, 6]
largest_after_each(7, [(0, 1), (1, 2), (3, 4), (4, 5), (5, 6), (2, 6)]) == [2, 3, 3, 3, 4, 7]
largest_after_each(100000, [(i + 1, i) for i in range(99999)] + [(0, i) for i in range(100000)])[-1] == 100000
largest_after_each(100000, [(i, i + 1) for i in range(99999)] + [(0, i) for i in range(100000)])[-1] == 100000
largest_after_each(200000, [(i, i + 100000) for i in range(100000)])[-1] == 2
```

```python tests
import random


def slow(n, pairs):
    groups = [{x} for x in range(n)]
    out = []
    for a, b in pairs:
        ga = next(g for g in groups if a in g)
        gb = next(g for g in groups if b in g)
        if ga is not gb:
            groups.remove(gb)
            ga |= gb
        out.append(max(len(g) for g in groups))
    return out


for _ in range(300):
    n = random.randint(1, 10)
    pairs = [(random.randrange(n), random.randrange(n)) for _ in range(random.randint(0, 12))]
    assert largest_after_each(n, pairs) == slow(n, pairs), (n, pairs)
```

```python solution
def largest_after_each(n, pairs):
    parent = list(range(n))
    size = [1] * n

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    largest = 1
    out = []
    for a, b in pairs:
        ra, rb = find(a), find(b)
        if ra != rb:
            if size[ra] < size[rb]:
                ra, rb = rb, ra
            parent[rb] = ra
            size[ra] += size[rb]
            largest = max(largest, size[ra])
        out.append(largest)
    return out
```

## Hints

1. Groups only ever merge, so the largest size can only grow. Each merge creates exactly one new size worth checking.
2. Union by size already stores the size of every group at its root. After a merge, compare the new root's size with the largest so far.
3. Keep `largest = 1`. When `ra != rb`, link the smaller root under the larger, add the sizes, and set `largest = max(largest, size[ra])`. Append `largest` after every pair, merged or not.
