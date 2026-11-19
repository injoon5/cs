---
id: segment-tree-sums
title: Range sums with updates
level: core
---

Finish `SumTree`, a segment tree over `nums`.

- `update(i, x)` sets `nums[i]` to `x`.
- `query(l, r)` returns the sum of `nums[l..r]`, both ends included.

Both must cost O(log n). `play` runs a list of operations and collects what each `query` returned. For `nums = [5, 3, 7, 1, 4, 2, 6, 8]`, `query(1, 6)` is 23, and after `update(2, 9)` it is 25.

```python starter
class SumTree:
    def __init__(self, nums):
        pass

    def update(self, i, x):
        pass

    def query(self, l, r):
        pass


def play(nums, ops):
    tree = SumTree(nums)
    out = []
    for name, *args in ops:
        result = getattr(tree, name)(*args)
        if name == "query":
            out.append(result)
    return out
```

```tests
play([5, 3, 7, 1, 4, 2, 6, 8], [("query", 1, 6), ("update", 2, 9), ("query", 1, 6)]) == [23, 25]
play([5, 3, 7, 1, 4, 2, 6, 8], [("query", 0, 7), ("query", 3, 3), ("query", 0, 4), ("query", 7, 7)]) == [36, 1, 20, 8]
play([4], [("query", 0, 0), ("update", 0, -4), ("query", 0, 0)]) == [4, -4]
play([1, 2, 3], [("query", 0, 2), ("update", 2, 10), ("query", 1, 2)]) == [6, 12]
play([1, 2, 3, 4, 5], [("query", 2, 4), ("update", 4, 0), ("query", 0, 4)]) == [12, 10]
play([-1, -2, -3, -4], [("query", 1, 2), ("update", 1, 2), ("query", 0, 3)]) == [-5, -6]
play([7, 7], [("update", 0, 7), ("query", 0, 1)]) == [14]
play([], []) == []
play([1] * 65536, [op for k in range(20000) for op in (("update", k, 2), ("query", k, 65535 - k))]) == [65536 - 2 * k + 1 for k in range(20000)]
```

```python tests
import random

rng = random.Random(4)
for _ in range(150):
    nums = [rng.randint(-20, 20) for _ in range(rng.randint(1, 20))]
    tree = SumTree(nums)
    ref = list(nums)
    for _ in range(40):
        if rng.random() < 0.4:
            i, x = rng.randrange(len(ref)), rng.randint(-20, 20)
            tree.update(i, x)
            ref[i] = x
        else:
            l = rng.randrange(len(ref))
            r = rng.randrange(l, len(ref))
            assert tree.query(l, r) == sum(ref[l:r + 1]), (nums, l, r)
```

```python solution
class SumTree:
    def __init__(self, nums):
        self.n = 1
        while self.n < len(nums):
            self.n *= 2
        self.tree = [0] * self.n + list(nums) + [0] * (self.n - len(nums))
        for i in range(self.n - 1, 0, -1):
            self.tree[i] = self.tree[2 * i] + self.tree[2 * i + 1]

    def update(self, i, x):
        i += self.n
        self.tree[i] = x
        while i > 1:
            i //= 2
            self.tree[i] = self.tree[2 * i] + self.tree[2 * i + 1]

    def query(self, l, r):
        total = 0
        l += self.n
        r += self.n
        while l <= r:
            if l % 2 == 1:
                total += self.tree[l]
                l += 1
            if r % 2 == 0:
                total += self.tree[r]
                r -= 1
            l //= 2
            r //= 2
        return total


def play(nums, ops):
    tree = SumTree(nums)
    out = []
    for name, *args in ops:
        result = getattr(tree, name)(*args)
        if name == "query":
            out.append(result)
    return out
```

## Hints

1. Adding up the range or keeping prefix sums costs O(n) for one of the two operations, which is too slow for the last test. A segment tree makes both O(log n).
2. Round n up to a power of two, `self.n`, and pad with zeros. Keep a list of `2 * self.n` where `nums[i]` sits at `self.n + i` and node `i` holds the sum of nodes `2i` and `2i + 1`.
3. `update` sets the leaf, then halves `i` up to the root, recomputing each parent. `query` climbs from both ends: an odd `l` is taken and moves right, an even `r` is taken and moves left, then both halve while `l <= r`.
