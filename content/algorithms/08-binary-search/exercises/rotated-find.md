---
id: rotated-find
title: Search a rotated list
level: stretch
---

`nums` is a sorted list of distinct numbers that may have been rotated. Return the index of `target`, or -1 if it isn't there. In `[4, 5, 6, 7, 0, 1, 2]`, 1 is at index 5. Use O(log n) time.

```python starter
def rotated_find(nums, target):
    pass
```

```tests
rotated_find([4, 5, 6, 7, 0, 1, 2], 1) == 5
rotated_find([4, 5, 6, 7, 0, 1, 2], 4) == 0
rotated_find([4, 5, 6, 7, 0, 1, 2], 7) == 3
rotated_find([4, 5, 6, 7, 0, 1, 2], 2) == 6
rotated_find([4, 5, 6, 7, 0, 1, 2], 3) == -1
rotated_find([4, 5, 6, 7, 0, 1, 2], 8) == -1
rotated_find([], 5) == -1
rotated_find([5], 5) == 0
rotated_find([5], 1) == -1
rotated_find([1, 3], 3) == 1
rotated_find([3, 1], 1) == 1
rotated_find([-2, 0, -9, -5], -5) == 3
rotated_find(list(range(600_000, 1_000_000)) + list(range(600_000)), 599_999) == 999_999
```

```python tests
base = [2, 5, 9, 14, 20, 33, 41]
for r in range(len(base)):
    nums = base[r:] + base[:r]
    for t in range(45):
        want = nums.index(t) if t in nums else -1
        assert rotated_find(nums, t) == want, (nums, t)
```

```python solution
from bisect import bisect_left


def rotated_find(nums, target):
    if not nums:
        return -1
    last = nums[-1]
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] <= last:
            hi = mid
        else:
            lo = mid + 1
    start = lo
    if target <= last:
        lo, hi = start, len(nums)
    else:
        lo, hi = 0, start
    i = bisect_left(nums, target, lo, hi)
    if i < hi and nums[i] == target:
        return i
    return -1
```

## Hints

1. Split the problem in two: where does the rotation start, and which sorted run could hold `target`?
2. Find the start as the first index with `nums[i] <= nums[-1]`. If `target <= nums[-1]` it can only be in `nums[start:]`, otherwise only in `nums[:start]`.
3. Search that run with `bisect_left(nums, target, lo, hi)` so you don't copy it. Check `i < hi and nums[i] == target` before returning `i`, and handle the empty list first.
