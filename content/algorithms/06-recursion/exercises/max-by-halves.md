---
id: max-by-halves
title: Largest by halves
level: warmup
---

Return the largest number in `nums[lo:hi]` by divide and conquer: split the range in half, find the largest on each side, and keep the bigger one. The range has at least one number. For `[3, 9, 2, 7]` with `lo = 0` and `hi = 4`, the halves give 9 and 7, so the answer is 9.

Don't use `max` on the whole range.

```python starter
def max_by_halves(nums, lo, hi):
    pass
```

```tests
max_by_halves([3, 9, 2, 7], 0, 4) == 9
max_by_halves([3, 9, 2, 7], 2, 4) == 7
max_by_halves([3, 9, 2, 7], 2, 3) == 2
max_by_halves([5], 0, 1) == 5
max_by_halves([-4, -2, -9], 0, 3) == -2
max_by_halves([1, 1, 1, 1, 1], 0, 5) == 1
max_by_halves([2, 8, 8, 3], 0, 4) == 8
max_by_halves([10, 3, 4, 5, 6], 1, 5) == 6
max_by_halves(list(range(100_000)), 0, 100_000) == 99_999
```

```python solution
def max_by_halves(nums, lo, hi):
    if hi - lo == 1:
        return nums[lo]
    mid = (lo + hi) // 2
    left = max_by_halves(nums, lo, mid)
    right = max_by_halves(nums, mid, hi)
    return left if left >= right else right
```

## Hints

1. A range with one number is its own largest number.
2. Split at `mid = (lo + hi) // 2`. Solve `lo..mid` and `mid..hi`, then compare the two answers.
3. `if hi - lo == 1: return nums[lo]`. Otherwise return the bigger of `max_by_halves(nums, lo, mid)` and `max_by_halves(nums, mid, hi)`.
