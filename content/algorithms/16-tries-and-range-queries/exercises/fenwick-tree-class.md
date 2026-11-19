---
id: fenwick-tree-class
title: A Fenwick tree
level: core
---

Finish `Fenwick`, a Fenwick tree over positions 1 to `n`, all starting at 0.

- `add(i, delta)` adds `delta` to position `i`.
- `prefix(i)` returns the sum of positions 1 to `i`, and 0 when `i` is 0.
- `range_sum(l, r)` returns the sum of positions `l` to `r`, both ends included.

Each must cost O(log n). `play` runs a list of operations and collects what each `prefix` and `range_sum` returned. After `add(2, 5)` and `add(4, 1)` on `n = 4`, `prefix(3)` is 5 and `range_sum(3, 4)` is 1.

```python starter
class Fenwick:
    def __init__(self, n):
        self.bit = [0] * (n + 1)

    def add(self, i, delta):
        pass

    def prefix(self, i):
        pass

    def range_sum(self, l, r):
        pass


def play(n, ops):
    f = Fenwick(n)
    out = []
    for name, *args in ops:
        result = getattr(f, name)(*args)
        if name != "add":
            out.append(result)
    return out
```

```tests
play(4, [("add", 2, 5), ("add", 4, 1), ("prefix", 3), ("range_sum", 3, 4)]) == [5, 1]
play(8, [("add", i, x) for i, x in enumerate([5, 3, 7, 1, 4, 2, 6, 8], start=1)] + [("prefix", 7), ("range_sum", 2, 6), ("prefix", 8)]) == [28, 17, 36]
play(1, [("prefix", 1), ("add", 1, -3), ("prefix", 1), ("range_sum", 1, 1)]) == [0, -3, -3]
play(5, [("add", 3, 2), ("add", 3, 2), ("prefix", 0), ("prefix", 2), ("prefix", 3)]) == [0, 0, 4]
play(6, [("add", 6, 10), ("add", 1, 1), ("range_sum", 2, 5), ("range_sum", 1, 6)]) == [0, 11]
play(3, [("add", 2, 4), ("add", 2, -4), ("prefix", 3)]) == [0]
play(65536, [op for k in range(20000) for op in (("add", k + 1, 5), ("range_sum", 1, 65536 - k))]) == [5 * (k + 1) for k in range(20000)]
```

```python tests
import random

rng = random.Random(2)
for _ in range(150):
    n = rng.randint(1, 20)
    f = Fenwick(n)
    ref = [0] * (n + 1)
    for _ in range(40):
        roll = rng.random()
        if roll < 0.4:
            i, d = rng.randint(1, n), rng.randint(-9, 9)
            f.add(i, d)
            ref[i] += d
        elif roll < 0.7:
            i = rng.randint(0, n)
            assert f.prefix(i) == sum(ref[1:i + 1]), (n, i)
        else:
            l = rng.randint(1, n)
            r = rng.randint(l, n)
            assert f.range_sum(l, r) == sum(ref[l:r + 1]), (n, l, r)
```

```python solution
class Fenwick:
    def __init__(self, n):
        self.bit = [0] * (n + 1)

    def add(self, i, delta):
        while i < len(self.bit):
            self.bit[i] += delta
            i += i & -i

    def prefix(self, i):
        total = 0
        while i > 0:
            total += self.bit[i]
            i -= i & -i
        return total

    def range_sum(self, l, r):
        return self.prefix(r) - self.prefix(l - 1)


def play(n, ops):
    f = Fenwick(n)
    out = []
    for name, *args in ops:
        result = getattr(f, name)(*args)
        if name != "add":
            out.append(result)
    return out
```

## Hints

1. Cell `i` of `self.bit` holds the sum of the `i & -i` positions that end at `i`.
2. `add` fixes every cell whose stretch holds position `i`, going up with `i += i & -i`. `prefix` adds up cells going down with `i -= i & -i` until `i` is 0.
3. `range_sum(l, r)` is `self.prefix(r) - self.prefix(l - 1)`.
