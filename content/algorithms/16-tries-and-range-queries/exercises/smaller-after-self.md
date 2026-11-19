---
id: smaller-after-self
title: Smaller numbers after
level: stretch
---

Return a list where entry `i` counts the numbers after `nums[i]` that are smaller than it. Use the Fenwick tree functions in the starter, so the whole thing costs O(n log n). For `[5, 2, 6, 1]` the answer is `[2, 1, 1, 0]`: after 5 come 2 and 1, after 2 comes 1, after 6 comes 1, and nothing comes after 1.

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


def smaller_after(nums):
    pass
```

```tests
smaller_after([5, 2, 6, 1]) == [2, 1, 1, 0]
smaller_after([]) == []
smaller_after([7]) == [0]
smaller_after([1, 2, 3]) == [0, 0, 0]
smaller_after([3, 2, 1]) == [2, 1, 0]
smaller_after([2, 2, 2]) == [0, 0, 0]
smaller_after([2, 0, 1, 2, 1]) == [3, 0, 0, 1, 0]
smaller_after([-1, -1, -2]) == [1, 1, 0]
smaller_after([10 ** 9, 0, -(10 ** 9)]) == [2, 1, 0]
smaller_after(list(range(20000, 0, -1))) == list(range(19999, -1, -1))
```

```python tests
import random

rng = random.Random(13)
for _ in range(300):
    nums = [rng.randint(-5, 5) for _ in range(rng.randint(0, 12))]
    want = [sum(y < x for y in nums[i + 1:]) for i, x in enumerate(nums)]
    assert smaller_after(nums) == want, nums

nums = [i * 7919 % 20011 for i in range(20000)]
got = smaller_after(nums)
assert len(got) == len(nums)
for i in rng.sample(range(len(nums)), 20):
    assert got[i] == sum(y < nums[i] for y in nums[i + 1:]), i
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


def smaller_after(nums):
    rank = {x: r for r, x in enumerate(sorted(set(nums)), start=1)}
    bit = [0] * (len(rank) + 1)
    counts = [0] * len(nums)
    for i in range(len(nums) - 1, -1, -1):
        r = rank[nums[i]]
        counts[i] = prefix(bit, r - 1)
        add(bit, r, 1)
    return counts
```

## Hints

1. Walk from the right end to the left. Then the numbers after `nums[i]` are exactly the ones you have already passed.
2. Keep a Fenwick tree over ranks of the numbers passed so far. The count of those smaller than `nums[i]` is a prefix sum up to the rank just below it.
3. Rank the distinct values from 1 in sorted order. For `i` from `len(nums) - 1` down to 0: `counts[i] = prefix(bit, r - 1)`, then `add(bit, r, 1)`, where `r` is the rank of `nums[i]`.
