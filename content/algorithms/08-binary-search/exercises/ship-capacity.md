---
id: ship-capacity
title: Ship within days
level: core
---

Packages with weights `weights` must ship in order within `days` days. Each day the ship loads packages from the front of the line until the next one would go over its capacity. Return the smallest capacity that ships everything in time. For `[3, 2, 2, 4, 1, 4]` in 3 days the answer is 6: `[3, 2]`, `[2, 4]`, `[1, 4]`. `weights` is not empty and `days` is at least 1.

```python starter
def ship_capacity(weights, days):
    pass
```

```tests
ship_capacity([3, 2, 2, 4, 1, 4], 3) == 6
ship_capacity([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 5) == 15
ship_capacity([1, 2, 3, 1, 1], 4) == 3
ship_capacity([3, 2, 2, 4, 1, 4], 1) == 16
ship_capacity([3, 2, 2, 4, 1, 4], 6) == 4
ship_capacity([3, 2, 2, 4, 1, 4], 100) == 4
ship_capacity([7], 1) == 7
ship_capacity([5, 5, 5, 5], 2) == 10
ship_capacity([1] * 100_000, 10) == 10_000
ship_capacity([500] * 50_000, 7) == 3_571_500
```

```python solution
def ship_capacity(weights, days):
    def days_needed(cap):
        count, load = 1, 0
        for w in weights:
            if load + w > cap:
                count += 1
                load = 0
            load += w
        return count

    lo, hi = max(weights), sum(weights)
    while lo < hi:
        mid = (lo + hi) // 2
        if days_needed(mid) <= days:
            hi = mid
        else:
            lo = mid + 1
    return lo
```

## Hints

1. If a capacity works, every bigger one works too. Search over capacities, not packages.
2. The answer is between the heaviest package and the total weight. Write `days_needed(cap)` that loads packages greedily, then find the first capacity where it is at most `days`.
3. `lo, hi = max(weights), sum(weights)`. If `days_needed(mid) <= days`, set `hi = mid`, else `lo = mid + 1`. Return `lo`.
