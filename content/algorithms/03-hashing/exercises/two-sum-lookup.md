---
id: two-sum-lookup
title: Two sum, unsorted
level: core
---

`nums` is in no particular order. Return the indices `(i, j)`, with `i < j`, of two numbers that add up to `target`, or `None` if no two do. If several pairs work, return the one whose `j` is smallest. For `[3, 8, 2, 7]` and target 9 the answer is `(2, 3)`. Lists can hold 100,000 numbers.

```python starter
def two_sum(nums, target):
    pass
```

```tests
two_sum([3, 8, 2, 7], 9) == (2, 3)
two_sum([3, 2, 4], 6) == (1, 2)
two_sum([3, 3], 6) == (0, 1)
two_sum([3, 4], 6) == None
two_sum([], 0) == None
two_sum([5], 10) == None
two_sum([-3, 4, 3, 90], 0) == (0, 2)
two_sum([0, 4, 0], 0) == (0, 2)
two_sum(list(range(100000)), 199997) == (99998, 99999)
```

```python solution
def two_sum(nums, target):
    seen = {}
    for j, x in enumerate(nums):
        if target - x in seen:
            return (seen[target - x], j)
        seen[x] = j
    return None
```

## Hints

1. For each number, you know exactly which partner it needs: `target - x`.
2. Walk left to right with a dict from each value seen so far to its index. Look up the partner before storing the current number.
3. `if target - x in seen: return (seen[target - x], j)`, then `seen[x] = j`. Return `None` after the loop.
