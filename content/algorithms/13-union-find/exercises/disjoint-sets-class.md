---
id: disjoint-sets-class
title: Disjoint sets class
level: core
---

Finish `DisjointSets` for items `0` to `n - 1`, each starting in a group of its own.

- `find(x)` returns the root of the group `x` is in.
- `union(a, b)` merges the groups of `a` and `b`. It returns `True` if they were in different groups, and `False` if they were already together.
- `connected(a, b)` returns whether `a` and `b` are in the same group.

Use union by size and path compression, so a long run of operations stays fast. `play` runs a list of operations and collects what each `union` and `connected` returned. After `union(0, 1)`, `connected(1, 0)` is `True` and `union(1, 0)` returns `False`.

```python starter
class DisjointSets:
    def __init__(self, n):
        self.parent = list(range(n))
        self.size = [1] * n

    def find(self, x):
        pass

    def union(self, a, b):
        pass

    def connected(self, a, b):
        pass


def play(n, ops):
    ds = DisjointSets(n)
    return [getattr(ds, name)(a, b) for name, a, b in ops]
```

```tests
play(2, [("union", 0, 1), ("connected", 1, 0), ("union", 1, 0)]) == [True, True, False]
play(1, [("connected", 0, 0), ("union", 0, 0)]) == [True, False]
play(3, [("connected", 0, 2)]) == [False]
play(4, [("union", 0, 1), ("union", 2, 3), ("connected", 1, 2), ("union", 1, 3), ("connected", 0, 2)]) == [True, True, False, True, True]
play(5, [("union", 0, 1), ("union", 1, 2), ("union", 0, 2), ("connected", 2, 0), ("connected", 3, 4)]) == [True, True, False, True, False]
play(6, [("union", i + 1, i) for i in range(5)] + [("connected", 0, 5), ("union", 5, 0)]) == [True] * 6 + [False]
sum(play(100000, [("union", i + 1, i) for i in range(99999)] + [("connected", 0, i) for i in range(100000)])) == 199999
sum(play(100000, [("union", i, i + 1) for i in range(99999)] + [("connected", 0, i) for i in range(100000)])) == 199999
```

```python tests
import random

ds = DisjointSets(4)
ds.union(0, 1)
ds.union(2, 3)
ds.union(0, 3)
assert len({ds.find(x) for x in range(4)}) == 1
assert ds.find(ds.find(2)) == ds.find(2), "find returns a root"

for _ in range(300):
    n = random.randint(1, 10)
    ds = DisjointSets(n)
    groups = [{x} for x in range(n)]
    for _ in range(random.randint(0, 20)):
        a, b = random.randrange(n), random.randrange(n)
        ga = next(g for g in groups if a in g)
        gb = next(g for g in groups if b in g)
        if random.random() < 0.5:
            assert ds.connected(a, b) == (ga is gb)
        else:
            assert ds.union(a, b) == (ga is not gb)
            if ga is not gb:
                groups.remove(gb)
                ga |= gb
    for x in range(n):
        for y in range(n):
            same = any(x in g and y in g for g in groups)
            assert (ds.find(x) == ds.find(y)) == same
```

```python solution
class DisjointSets:
    def __init__(self, n):
        self.parent = list(range(n))
        self.size = [1] * n

    def find(self, x):
        parent = self.parent
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra == rb:
            return False
        if self.size[ra] < self.size[rb]:
            ra, rb = rb, ra
        self.parent[rb] = ra
        self.size[ra] += self.size[rb]
        return True

    def connected(self, a, b):
        return self.find(a) == self.find(b)


def play(n, ops):
    ds = DisjointSets(n)
    return [getattr(ds, name)(a, b) for name, a, b in ops]
```

## Hints

1. `connected` and `union` both start from the two roots. Write `find` first.
2. In `find`, walk up to the root and shorten the path as you go. In `union`, point the root of the smaller group at the root of the larger, and add the sizes.
3. Path halving is one extra line in the loop: `parent[x] = parent[parent[x]]` before `x = parent[x]`. In `union`, swap `ra` and `rb` when `size[ra] < size[rb]`, then set `parent[rb] = ra` and `size[ra] += size[rb]`.
