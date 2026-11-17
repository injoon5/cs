---
id: lis-length
title: Longest increasing subsequence
level: core
---

Return the length of the longest strictly increasing subsequence of `nums`: numbers kept in their order, each bigger than the one before. For `[10, 9, 2, 5, 3, 7, 101, 18]` it is 4, for example 2, 3, 7, 18. Lists can hold 100,000 numbers, so aim for O(n log n).

```python starter
def lis_length(nums):
    pass
```

```tests
lis_length([10, 9, 2, 5, 3, 7, 101, 18]) == 4
lis_length([]) == 0
lis_length([5]) == 1
lis_length([2, 2, 2]) == 1
lis_length([5, 4, 3, 2]) == 1
lis_length([1, 2, 3]) == 3
lis_length([0, 1, 0, 3, 2, 3]) == 4
lis_length([3, 4, 5, 1, 2]) == 3
lis_length([-3, -1, -2, 0]) == 3
lis_length(list(range(100000))) == 100000
lis_length(list(range(100000, 0, -1))) == 1
lis_length([(i * 7919) % 100003 for i in range(100000)]) == 306
```

```python tests
import random


def slow(nums):
    ends = [1] * len(nums)
    for i in range(len(nums)):
        for j in range(i):
            if nums[j] < nums[i]:
                ends[i] = max(ends[i], ends[j] + 1)
    return max(ends, default=0)


for _ in range(200):
    nums = [random.randint(-10, 10) for _ in range(random.randint(0, 30))]
    assert lis_length(nums) == slow(nums)
```

```python solution
from bisect import bisect_left


def lis_length(nums):
    tails = []
    for x in nums:
        k = bisect_left(tails, x)
        if k == len(tails):
            tails.append(x)
        else:
            tails[k] = x
    return len(tails)
```

## Hints

1. The O(n²) table compares every pair, which is 5 billion comparisons for 100,000 numbers. Keep less: one number per length.
2. `tails[k]` is the smallest number that ends an increasing subsequence of length `k + 1`. It stays sorted.
3. For each `x`, `k = bisect_left(tails, x)`. Append `x` if `k == len(tails)`, else set `tails[k] = x`. Return `len(tails)`.
