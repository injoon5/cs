---
id: balance-point
title: Balance point
level: core
---

Return the first index `i` where the numbers left of `i` add up to the same as the numbers right of `i`. `nums[i]` itself is on neither side, and an empty side adds up to 0. Return -1 if there is no such index.

In `[1, 7, 3, 6, 5, 6]` the answer is 3: `1 + 7 + 3` and `5 + 6` are both 11.

```python starter
def balance_point(nums):
    pass
```

```tests
balance_point([1, 7, 3, 6, 5, 6]) == 3
balance_point([1, 2, 3]) == -1
balance_point([2, 1, -1]) == 0
balance_point([-1, -1, 0, 1, 1, 0]) == 5
balance_point([0, 0, 0]) == 0
balance_point([4, 4, 4]) == 1
balance_point([9]) == 0
balance_point([]) == -1
```

```python solution
def balance_point(nums):
    total = sum(nums)
    left = 0
    for i, x in enumerate(nums):
        if left == total - left - x:
            return i
        left += x
    return -1
```

## Hints

1. If you know the total and the sum to the left of `i`, you know the sum to the right.
2. Compute `total` once. Walk left to right, keeping the running sum of everything before `i`.
3. The right side is `total - left - nums[i]`. Compare before adding `nums[i]` to `left`.
