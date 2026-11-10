---
id: max-window-sum
title: Best window of k
level: warmup
---

Return the largest total of `k` items in a row in `nums`. You can assume `1 <= k <= len(nums)`. Numbers can be negative.

```python starter
def max_window_sum(nums, k):
    pass
```

```tests
max_window_sum([2, 1, 5, 1, 3, 2], 3) == 9
max_window_sum([2, 1, 5, 1, 3, 2], 1) == 5
max_window_sum([2, 1, 5, 1, 3, 2], 6) == 14
max_window_sum([7], 1) == 7
max_window_sum([4, 4, 4, 4], 2) == 8
max_window_sum([-3, -1, -2], 2) == -3
max_window_sum([-5, -2, -7], 1) == -2
max_window_sum([1, -10, 2, 3], 2) == 5
```

```python solution
def max_window_sum(nums, k):
    window = sum(nums[:k])
    best = window
    for right in range(k, len(nums)):
        window += nums[right] - nums[right - k]
        best = max(best, window)
    return best
```

## Hints

1. Neighboring windows share all but two items.
2. Add up the first `k` items once. Each slide adds the item entering on the right and subtracts the one leaving on the left.
3. Start `best` at the first window's total, not 0, so all-negative lists work. The item leaving is `nums[right - k]`.
