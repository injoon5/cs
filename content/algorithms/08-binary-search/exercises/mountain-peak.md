---
id: mountain-peak
title: Peak of a mountain
level: core
---

`heights` goes strictly up, then strictly down, and has at least one item. Return the index of the highest item. In `[1, 4, 8, 6, 2]` the peak is 8, at index 2. Use O(log n) time.

```python starter
def mountain_peak(heights):
    pass
```

```tests
mountain_peak([1, 4, 8, 6, 2]) == 2
mountain_peak([0, 2, 1]) == 1
mountain_peak([5]) == 0
mountain_peak([1, 2, 3, 4]) == 3
mountain_peak([9, 7, 3]) == 0
mountain_peak([3, 9]) == 1
mountain_peak([9, 3]) == 0
mountain_peak([-5, -2, -1, -3, -10]) == 2
mountain_peak(list(range(600_000)) + list(range(400_000, 0, -1))) == 599_999
```

```python solution
def mountain_peak(heights):
    lo, hi = 0, len(heights) - 1
    while lo < hi:
        mid = (lo + hi) // 2
        if heights[mid] > heights[mid + 1]:
            hi = mid
        else:
            lo = mid + 1
    return lo
```

## Hints

1. The list isn't sorted, but "is the next item lower?" is no on the way up and yes on the way down.
2. The peak is the first index where `heights[i] > heights[i + 1]`. The last index has no next item, so search only up to it.
3. Start with `lo, hi = 0, len(heights) - 1`. If `heights[mid] > heights[mid + 1]`, set `hi = mid`, else `lo = mid + 1`. Return `lo`.
