---
id: count-in-sorted
title: Count in a sorted list
level: warmup
---

`nums` is sorted. Return how many times `x` appears in it. In `[1, 2, 2, 2, 3, 5]`, 2 appears 3 times. Use O(log n) time: you may use the `bisect` module, but not `count` or a loop over the items.

```python starter
from bisect import bisect_left, bisect_right


def count_in_sorted(nums, x):
    pass
```

```tests
count_in_sorted([1, 2, 2, 2, 3, 5], 2) == 3
count_in_sorted([1, 2, 2, 2, 3, 5], 5) == 1
count_in_sorted([1, 2, 2, 2, 3, 5], 4) == 0
count_in_sorted([1, 2, 2, 2, 3, 5], 0) == 0
count_in_sorted([1, 2, 2, 2, 3, 5], 9) == 0
count_in_sorted([], 1) == 0
count_in_sorted([7], 7) == 1
count_in_sorted([4, 4, 4, 4], 4) == 4
count_in_sorted([-3, -3, -1, 0, 0], -3) == 2
count_in_sorted([0] * 500_000 + [1] * 250_000 + [2] * 250_000, 1) == 250_000
```

```python solution
from bisect import bisect_left, bisect_right


def count_in_sorted(nums, x):
    return bisect_right(nums, x) - bisect_left(nums, x)
```

## Hints

1. The copies of `x` sit next to each other. You only need where the run starts and where it ends.
2. `bisect_left` gives the first index of `x`, and `bisect_right` the index just after the last one.
3. Return `bisect_right(nums, x) - bisect_left(nums, x)`.
