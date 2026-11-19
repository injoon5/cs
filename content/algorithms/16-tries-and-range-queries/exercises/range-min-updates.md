---
id: range-min-updates
title: Range minimum
level: core
---

Finish `MinTree`, a segment tree that answers minimums.

- `update(i, x)` sets `nums[i]` to `x`.
- `query(l, r)` returns the smallest of `nums[l..r]`, both ends included.

Both must cost O(log n). `play` runs a list of operations and collects what each `query` returned. For `nums = [5, 3, 7, 1, 4]`, `query(0, 2)` is 3, and after `update(1, 8)` it is 5.

```python starter
class MinTree:
    def __init__(self, nums):
        pass

    def update(self, i, x):
        pass

    def query(self, l, r):
        pass


def play(nums, ops):
    tree = MinTree(nums)
    out = []
    for name, *args in ops:
        result = getattr(tree, name)(*args)
        if name == "query":
            out.append(result)
    return out
```

```tests
play([5, 3, 7, 1, 4], [("query", 0, 2), ("update", 1, 8), ("query", 0, 2)]) == [3, 5]
play([5, 3, 7, 1, 4], [("query", 0, 4), ("query", 4, 4), ("query", 2, 4)]) == [1, 4, 1]
play([1, 5, 3, 4], [("query", 1, 3)]) == [3]
play([2], [("query", 0, 0), ("update", 0, 9), ("query", 0, 0)]) == [2, 9]
play([6, 6, 6], [("query", 0, 2), ("update", 1, 6), ("query", 1, 1)]) == [6, 6]
play([3, -2, 8], [("query", 0, 2), ("update", 1, 10), ("query", 0, 2), ("query", 1, 2)]) == [-2, 3, 8]
play([10, 20, 30, 40, 50, 60], [("update", 5, -1), ("query", 3, 5), ("query", 0, 4)]) == [-1, 10]
play(list(range(65536)), [op for k in range(10000) for op in (("update", 65535 - k, -k), ("query", k, 65535))]) == [-k for k in range(10000)]
```

```python tests
import random

rng = random.Random(8)
for _ in range(150):
    nums = [rng.randint(-20, 20) for _ in range(rng.randint(1, 20))]
    tree = MinTree(nums)
    ref = list(nums)
    for _ in range(40):
        if rng.random() < 0.4:
            i, x = rng.randrange(len(ref)), rng.randint(-20, 20)
            tree.update(i, x)
            ref[i] = x
        else:
            l = rng.randrange(len(ref))
            r = rng.randrange(l, len(ref))
            assert tree.query(l, r) == min(ref[l:r + 1]), (nums, l, r)
```

```python solution
class MinTree:
    def __init__(self, nums):
        self.n = 1
        while self.n < len(nums):
            self.n *= 2
        inf = float("inf")
        self.tree = [inf] * self.n + list(nums) + [inf] * (self.n - len(nums))
        for i in range(self.n - 1, 0, -1):
            self.tree[i] = min(self.tree[2 * i], self.tree[2 * i + 1])

    def update(self, i, x):
        i += self.n
        self.tree[i] = x
        while i > 1:
            i //= 2
            self.tree[i] = min(self.tree[2 * i], self.tree[2 * i + 1])

    def query(self, l, r):
        best = float("inf")
        l += self.n
        r += self.n
        while l <= r:
            if l % 2 == 1:
                best = min(best, self.tree[l])
                l += 1
            if r % 2 == 0:
                best = min(best, self.tree[r])
                r -= 1
            l //= 2
            r //= 2
        return best


def play(nums, ops):
    tree = MinTree(nums)
    out = []
    for name, *args in ops:
        result = getattr(tree, name)(*args)
        if name == "query":
            out.append(result)
    return out
```

## Hints

1. This is the sum tree with a different combine. A minimum can't be taken away, so prefix tricks don't help, but a segment tree only ever puts two neighbors together.
2. Replace every `a + b` with `min(a, b)`. The query's starting value and the padding must lose to every number: `float("inf")`.
3. Build the parents with `min` from the bottom up, recompute them with `min` on the way up in `update`, and in `query` start at `best = float("inf")` and take `min` with each node the climb picks.
