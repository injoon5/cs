---
id: pair-sum
title: Pair with a sum
level: core
---

`nums` is sorted from smallest to largest. Return the indices `(i, j)`, with `i < j`, of two numbers that add up to `target`, or `None` if no two do. Each test has at most one answer. Use O(1) extra space.

```python starter
def pair_sum(nums, target):
    pass
```

```tests
pair_sum([1, 3, 4, 6, 8, 11], 10) == (2, 3)
pair_sum([1, 3, 4, 6, 8, 11], 12) == (0, 5)
pair_sum([1, 3, 4, 6, 8, 11], 100) == None
pair_sum([2, 7], 9) == (0, 1)
pair_sum([5], 10) == None
pair_sum([], 0) == None
pair_sum([-8, -3, 0, 2, 9], -1) == (1, 3)
pair_sum([-4, -2, 1, 5], -6) == (0, 1)
pair_sum([3, 3, 3], 7) == None
```

```python solution
def pair_sum(nums, target):
    lo, hi = 0, len(nums) - 1
    while lo < hi:
        s = nums[lo] + nums[hi]
        if s == target:
            return (lo, hi)
        if s < target:
            lo += 1
        else:
            hi -= 1
    return None
```

## Hints

1. Start with the smallest and the largest number. If their sum is too big, which of the two can never be in the answer?
2. Keep `lo` at the left end and `hi` at the right end. Too big: move `hi` left. Too small: move `lo` right.
3. Loop `while lo < hi`. Return `(lo, hi)` when the sum matches, and `None` after the loop.
