---
id: rotation-min
title: Smallest in a rotated list
level: core
---

`nums` is a sorted list of distinct numbers that may have been rotated: some items moved from the front to the back, keeping their order. It has at least one item. Return its smallest item. For `[4, 5, 6, 7, 0, 1, 2]` the answer is 0. Use O(log n) time, not `min`.

```python starter
def rotation_min(nums):
    pass
```

```tests
rotation_min([4, 5, 6, 7, 0, 1, 2]) == 0
rotation_min([3, 4, 5, 1, 2]) == 1
rotation_min([2, 1]) == 1
rotation_min([1, 2]) == 1
rotation_min([0, 1, 2, 4, 5, 6, 7]) == 0
rotation_min([7, 0, 1, 2, 4, 5, 6]) == 0
rotation_min([1, 2, 4, 5, 6, 7, 0]) == 0
rotation_min([9]) == 9
rotation_min([-1, 3, -8, -5]) == -8
rotation_min(list(range(700_000, 1_000_000)) + list(range(700_000))) == 0
```

```python tests
base = [3, 8, 10, 15, 21, 40]
for r in range(len(base)):
    assert rotation_min(base[r:] + base[:r]) == 3, r
```

```python solution
def rotation_min(nums):
    last = nums[-1]
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] <= last:
            hi = mid
        else:
            lo = mid + 1
    return nums[lo]
```

## Hints

1. Every item in the left run is bigger than every item in the right run. Find a test that tells the two runs apart.
2. "Is `nums[i] <= nums[-1]`?" is no in the left run and yes in the right run. The smallest item is the first yes.
3. Half-open search: if `nums[mid] <= nums[-1]`, set `hi = mid`, else `lo = mid + 1`. Return `nums[lo]`.
