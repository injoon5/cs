---
id: sorted-find
title: Find in a sorted list
level: warmup
---

`nums` is sorted from smallest to largest, with no repeats. Return the index of `target`, or -1 if it isn't there. In `[1, 3, 5, 7, 9]`, 7 is at index 3. Use O(log n) time, and don't use `index`, `in` or `bisect`.

```python starter
def sorted_find(nums, target):
    pass
```

```tests
sorted_find([1, 3, 5, 7, 9], 7) == 3
sorted_find([1, 3, 5, 7, 9], 1) == 0
sorted_find([1, 3, 5, 7, 9], 9) == 4
sorted_find([1, 3, 5, 7, 9], 4) == -1
sorted_find([1, 3, 5, 7, 9], 0) == -1
sorted_find([1, 3, 5, 7, 9], 10) == -1
sorted_find([], 3) == -1
sorted_find([5], 5) == 0
sorted_find([5], 2) == -1
sorted_find([-9, -4, 0, 2], -4) == 1
sorted_find(list(range(0, 2_000_000, 2)), 1_234_566) == 617_283
sorted_find(list(range(0, 2_000_000, 2)), 1_234_567) == -1
```

```python solution
def sorted_find(nums, target):
    lo, hi = 0, len(nums) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if nums[mid] == target:
            return mid
        if nums[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1
```

## Hints

1. Compare `target` with the middle item. Which half can you throw away?
2. Keep `lo` and `hi` on the ends of the range still in play, and loop while `lo <= hi`.
3. With `mid = (lo + hi) // 2`: return `mid` on a match, set `lo = mid + 1` if `nums[mid]` is too small, else `hi = mid - 1`. Return -1 after the loop.
