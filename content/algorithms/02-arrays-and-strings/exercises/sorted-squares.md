---
id: sorted-squares
title: Sorted squares
level: core
---

`nums` is sorted and may hold negative numbers. Return a new list of the squares, also sorted. `[-3, 1, 2]` gives `[1, 4, 9]`. Do it in O(n), without calling `sort`.

```python starter
def sorted_squares(nums):
    pass
```

```tests
sorted_squares([-3, 1, 2]) == [1, 4, 9]
sorted_squares([-4, -1, 0, 3, 10]) == [0, 1, 9, 16, 100]
sorted_squares([1, 2, 3]) == [1, 4, 9]
sorted_squares([-5, -3, -1]) == [1, 9, 25]
sorted_squares([-2, -2, 2, 2]) == [4, 4, 4, 4]
sorted_squares([-7]) == [49]
sorted_squares([]) == []
```

```python solution
def sorted_squares(nums):
    result = [0] * len(nums)
    lo, hi = 0, len(nums) - 1
    for k in range(len(nums) - 1, -1, -1):
        if abs(nums[lo]) > abs(nums[hi]):
            result[k] = nums[lo] * nums[lo]
            lo += 1
        else:
            result[k] = nums[hi] * nums[hi]
            hi -= 1
    return result
```

## Hints

1. The smallest square could be anywhere in the middle. Where is the largest square?
2. The largest square comes from one of the two ends. Compare the ends and fill the result from the back.
3. Make `result = [0] * len(nums)`. For `k` from the last index down to 0, put the bigger of the two end squares at `result[k]` and move that pointer inward.
