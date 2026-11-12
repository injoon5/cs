---
id: closest-value
title: Closest value
level: core
---

`nums` is sorted and not empty. Return the item closest to `target`. On a tie, return the smaller one. In `[1, 4, 6, 10]` with a target of 8, both 6 and 10 are 2 away, so the answer is 6. Use O(log n) time.

```python starter
def closest_value(nums, target):
    pass
```

```tests
closest_value([1, 4, 6, 10], 8) == 6
closest_value([1, 4, 6, 10], 5) == 4
closest_value([1, 4, 6, 10], 9) == 10
closest_value([1, 4, 6, 10], 6) == 6
closest_value([1, 4, 6, 10], -5) == 1
closest_value([1, 4, 6, 10], 99) == 10
closest_value([7], 3) == 7
closest_value([2, 2, 2, 5], 3) == 2
closest_value([-10, -3, 0, 4], -6) == -3
closest_value([-10, -3, 0, 4], -7) == -10
closest_value(list(range(0, 3_000_000, 3)), 1_000_001) == 1_000_002
```

```python solution
def closest_value(nums, target):
    lo, hi = 0, len(nums) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if nums[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    best = None
    for i in (hi, lo):
        if 0 <= i < len(nums):
            if best is None or abs(nums[i] - target) < abs(best - target):
                best = nums[i]
    return best
```

## Hints

1. When a search for a missing target ends, `hi` and `lo` sit on either side of where it would go.
2. Run the search without stopping on a match. After the loop, `nums[hi]` is the last item below `target` and `nums[lo]` the first one at or above it.
3. Check `hi` first, then `lo`, skipping any index outside the list. Keep the closer one, and only replace it when the new one is strictly closer, so ties keep the smaller.
