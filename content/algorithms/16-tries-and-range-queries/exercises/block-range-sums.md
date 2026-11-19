---
id: block-range-sums
title: Range sums in blocks
level: warmup
---

Finish `BlockSums`. The constructor already splits `nums` into blocks of `b` numbers, about √n, and keeps each block's sum in `blocks`.

- `update(i, x)` sets `nums[i]` to `x` and keeps `blocks` right.
- `query(l, r)` returns the sum of `nums[l..r]`, both ends included, using whole blocks where it can.

`play` runs a list of operations and collects what each `query` returned. For `nums = [3, -1, 4, 1, 5, 9, 2, 6, 5]`, `b` is 3, `query(1, 7)` is 26, and after `update(4, 0)` it is 21.

```python starter
from math import isqrt


class BlockSums:
    def __init__(self, nums):
        self.nums = list(nums)
        self.b = max(1, isqrt(len(nums)))
        self.blocks = [sum(self.nums[i:i + self.b]) for i in range(0, len(nums), self.b)]

    def update(self, i, x):
        pass

    def query(self, l, r):
        pass


def play(nums, ops):
    s = BlockSums(nums)
    out = []
    for name, *args in ops:
        result = getattr(s, name)(*args)
        if name == "query":
            out.append(result)
    return out
```

```tests
play([3, -1, 4, 1, 5, 9, 2, 6, 5], [("query", 1, 7), ("update", 4, 0), ("query", 1, 7)]) == [26, 21]
play([3, -1, 4, 1, 5, 9, 2, 6, 5], [("query", 0, 8), ("query", 4, 4), ("query", 3, 5)]) == [34, 5, 15]
play([7], [("query", 0, 0), ("update", 0, -2), ("query", 0, 0)]) == [7, -2]
play([1, 2, 3, 4, 5], [("update", 4, 10), ("query", 3, 4), ("query", 0, 4)]) == [14, 20]
play([5, 5, 5, 5], [("update", 1, 5), ("query", 0, 3)]) == [20]
play([0, 0, 0, 0, 0, 0], [("update", 2, -3), ("update", 3, 4), ("query", 2, 3), ("query", 0, 5)]) == [1, 1]
play([], []) == []
```

```python tests
import random

rng = random.Random(1)
for _ in range(100):
    nums = [rng.randint(-9, 9) for _ in range(rng.randint(1, 30))]
    s = BlockSums(nums)
    ref = list(nums)
    for _ in range(40):
        if rng.random() < 0.5:
            i, x = rng.randrange(len(ref)), rng.randint(-9, 9)
            s.update(i, x)
            ref[i] = x
        else:
            l = rng.randrange(len(ref))
            r = rng.randrange(l, len(ref))
            assert s.query(l, r) == sum(ref[l:r + 1]), (nums, l, r)
    want = [sum(ref[i:i + s.b]) for i in range(0, len(ref), s.b)]
    assert s.blocks == want, "update must keep each block's sum right"
```

```python solution
from math import isqrt


class BlockSums:
    def __init__(self, nums):
        self.nums = list(nums)
        self.b = max(1, isqrt(len(nums)))
        self.blocks = [sum(self.nums[i:i + self.b]) for i in range(0, len(nums), self.b)]

    def update(self, i, x):
        self.blocks[i // self.b] += x - self.nums[i]
        self.nums[i] = x

    def query(self, l, r):
        b = self.b
        total = 0
        while l <= r:
            if l % b == 0 and l + b - 1 <= r:
                total += self.blocks[l // b]
                l += b
            else:
                total += self.nums[l]
                l += 1
        return total


def play(nums, ops):
    s = BlockSums(nums)
    out = []
    for name, *args in ops:
        result = getattr(s, name)(*args)
        if name == "query":
            out.append(result)
    return out
```

## Hints

1. Position `i` belongs to block `i // b`, and block `k` covers positions `k * b` to `k * b + b - 1`.
2. An update changes one block's sum by the difference between the new and the old value. A query moves `l` towards `r`, adding one number at a time except where a whole block fits.
3. In `query`, while `l <= r`: if `l % b == 0` and `l + b - 1 <= r`, add `blocks[l // b]` and jump `l` by `b`; else add `nums[l]` and step by 1.
