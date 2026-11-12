---
id: eating-speed
title: Eating speed
level: core
---

Each number in `piles` is a pile of bananas. Eating at speed `k`, you spend each hour on one pile and eat up to `k` bananas from it; a pile of 7 at speed 3 takes 3 hours. Return the smallest whole speed that finishes every pile within `hours` hours. For `[3, 6, 7, 11]` in 8 hours the answer is 4: the piles take 1, 2, 2 and 3 hours. `piles` is not empty and `hours` is at least `len(piles)`.

```python starter
def eating_speed(piles, hours):
    pass
```

```tests
eating_speed([3, 6, 7, 11], 8) == 4
eating_speed([30, 11, 23, 4, 20], 5) == 30
eating_speed([30, 11, 23, 4, 20], 6) == 23
eating_speed([5], 1) == 5
eating_speed([5], 5) == 1
eating_speed([5], 100) == 1
eating_speed([1, 1, 1, 1], 4) == 1
eating_speed([10, 10], 3) == 10
eating_speed([10, 10], 4) == 5
eating_speed([1_000_000_000], 2) == 500_000_000
eating_speed([999_999_999] * 1000, 10_000) == 100_000_000
```

```python solution
def eating_speed(piles, hours):
    def hours_needed(k):
        return sum((p + k - 1) // k for p in piles)

    lo, hi = 1, max(piles)
    while lo < hi:
        mid = (lo + hi) // 2
        if hours_needed(mid) <= hours:
            hi = mid
        else:
            lo = mid + 1
    return lo
```

## Hints

1. Eating faster never takes longer, so "finishes in time" is no for slow speeds and yes from some speed on.
2. The speed is between 1 and the biggest pile; faster than that saves nothing. A pile of `p` takes `p / k` hours, rounded up.
3. `hours_needed(k)` is `sum((p + k - 1) // k for p in piles)`. Search `lo, hi = 1, max(piles)`: if it is at most `hours`, set `hi = mid`, else `lo = mid + 1`.
