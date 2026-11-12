---
id: target-range
title: First and last index
level: core
---

`nums` is sorted. Return `(first, last)`, the indices of the first and last copy of `x`, or `(-1, -1)` if `x` isn't there. In `[5, 7, 7, 8, 8, 8, 10]`, 8 runs from index 3 to 5, so the answer is `(3, 5)`. Write the binary search yourself, without `bisect`, in O(log n) time.

```python starter
def target_range(nums, x):
    pass
```

```tests
target_range([5, 7, 7, 8, 8, 8, 10], 8) == (3, 5)
target_range([5, 7, 7, 8, 8, 8, 10], 7) == (1, 2)
target_range([5, 7, 7, 8, 8, 8, 10], 5) == (0, 0)
target_range([5, 7, 7, 8, 8, 8, 10], 10) == (6, 6)
target_range([5, 7, 7, 8, 8, 8, 10], 6) == (-1, -1)
target_range([5, 7, 7, 8, 8, 8, 10], 11) == (-1, -1)
target_range([5, 7, 7, 8, 8, 8, 10], 1) == (-1, -1)
target_range([], 3) == (-1, -1)
target_range([2], 2) == (0, 0)
target_range([3, 3, 3], 3) == (0, 2)
target_range([-4, -4, 0, 1], -4) == (0, 1)
target_range([1] * 400_000 + [2] * 600_000, 2) == (400_000, 999_999)
```

```python solution
def first_index_where(nums, test):
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if test(nums[mid]):
            hi = mid
        else:
            lo = mid + 1
    return lo


def target_range(nums, x):
    first = first_index_where(nums, lambda v: v >= x)
    if first == len(nums) or nums[first] != x:
        return (-1, -1)
    end = first_index_where(nums, lambda v: v > x)
    return (first, end - 1)
```

## Hints

1. This is two first-yes searches: one for where the run of `x` starts, one for where it stops.
2. The first copy is the first index with `nums[i] >= x`. The last copy is one before the first index with `nums[i] > x`.
3. Write a helper that takes the test as a function. If the lower bound is `len(nums)` or `nums[first] != x`, return `(-1, -1)`; else return `(first, upper - 1)`.
