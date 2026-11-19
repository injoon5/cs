---
id: fenwick-inversions
title: Inversions with a Fenwick tree
level: core
---

An inversion is a pair of indexes `i < j` with `nums[i] > nums[j]`. Return how many inversions `nums` has, in O(n log n) time, using the Fenwick tree functions in the starter. `[3, 1, 2]` has 2: `(3, 1)` and `(3, 2)`. Equal numbers are not an inversion.

The numbers can be any integers, so first give each one its rank: its place among the distinct values in sorted order, counting from 1.

```python starter
def add(bit, i, delta):
    while i < len(bit):
        bit[i] += delta
        i += i & -i


def prefix(bit, i):
    total = 0
    while i > 0:
        total += bit[i]
        i -= i & -i
    return total


def inversions(nums):
    pass
```

```tests
inversions([3, 1, 2]) == 2
inversions([3, 1, 4, 2]) == 3
inversions([]) == 0
inversions([5]) == 0
inversions([1, 2, 3, 4]) == 0
inversions([4, 3, 2, 1]) == 6
inversions([2, 2, 2]) == 0
inversions([2, 1, 2, 1]) == 3
inversions([-5, 100, -5, 0]) == 2
inversions([10 ** 9, -(10 ** 9)]) == 1
inversions(list(range(20000, 0, -1))) == 20000 * 19999 // 2
```

```python tests
import random

rng = random.Random(12)
for _ in range(300):
    nums = [rng.randint(-5, 5) for _ in range(rng.randint(0, 12))]
    want = sum(nums[i] > nums[j] for i in range(len(nums)) for j in range(i + 1, len(nums)))
    assert inversions(nums) == want, nums
```

```python solution
def add(bit, i, delta):
    while i < len(bit):
        bit[i] += delta
        i += i & -i


def prefix(bit, i):
    total = 0
    while i > 0:
        total += bit[i]
        i -= i & -i
    return total


def inversions(nums):
    rank = {x: r for r, x in enumerate(sorted(set(nums)), start=1)}
    bit = [0] * (len(rank) + 1)
    count = 0
    for seen, x in enumerate(nums):
        count += seen - prefix(bit, rank[x])
        add(bit, rank[x], 1)
    return count
```

## Hints

1. Go through `nums` from left to right. Each number makes one inversion with every earlier number that is bigger.
2. Keep a Fenwick tree over ranks: add 1 at a number's rank once you have passed it. Then `prefix(bit, r)` counts the earlier numbers with rank at most `r`.
3. Build `rank = {x: r for r, x in enumerate(sorted(set(nums)), start=1)}`. At index `seen`, the earlier numbers bigger than `x` are `seen - prefix(bit, rank[x])`. Add that to the count, then `add(bit, rank[x], 1)`.
