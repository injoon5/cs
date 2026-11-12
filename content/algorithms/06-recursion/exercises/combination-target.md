---
id: combination-target
title: Combinations that hit a target
level: core
---

`nums` holds distinct positive numbers. Return every combination that adds up to `target`, where each number may be used any number of times. Write each combination in increasing order, and return the list of combinations sorted. For `nums = [2, 3, 6, 7]` and `target = 7`:

`[[2, 2, 3], [7]]`

```python starter
def combination_target(nums, target):
    pass
```

```tests
combination_target([2, 3, 6, 7], 7) == [[2, 2, 3], [7]]
combination_target([2, 3, 5], 8) == [[2, 2, 2, 2], [2, 3, 3], [3, 5]]
combination_target([2], 1) == []
combination_target([1], 3) == [[1, 1, 1]]
combination_target([5, 1], 2) == [[1, 1]]
combination_target([4, 2], 6) == [[2, 2, 2], [2, 4]]
combination_target([3], 0) == [[]]
combination_target([], 4) == []
len(combination_target([2, 3, 5, 7], 40)) == 90
```

```python solution
def combination_target(nums, target):
    nums = sorted(nums)
    out = []
    picked = []

    def explore(start, left):
        if left == 0:
            out.append(picked[:])
            return
        for i in range(start, len(nums)):
            if nums[i] > left:
                break
            picked.append(nums[i])
            explore(i, left - nums[i])
            picked.pop()

    explore(0, target)
    return out
```

## Hints

1. This is the pruned search from the lesson with one change: a number can be picked again.
2. Sort `nums`. After picking `nums[i]`, the next call starts at `i`, not `i + 1`, so it may pick the same number again but never an earlier one.
3. `explore(start, left)`: save `picked[:]` when `left == 0`. Loop `i` from `start`, `break` when `nums[i] > left`, otherwise append, call `explore(i, left - nums[i])`, pop.
