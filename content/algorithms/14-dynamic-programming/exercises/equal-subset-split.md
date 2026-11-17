---
id: equal-subset-split
title: Split into equal sums
level: stretch
---

`nums` holds positive integers. Return `True` if they can be split into two groups with equal sums, every number in exactly one group. `[1, 5, 11, 5]` splits into `[1, 5, 5]` and `[11]`. `[1, 2, 3, 5]` can't be split. An empty list splits into two empty groups.

```python starter
def can_partition(nums):
    pass
```

```tests
can_partition([1, 5, 11, 5]) == True
can_partition([1, 2, 3, 5]) == False
can_partition([]) == True
can_partition([2]) == False
can_partition([1, 1]) == True
can_partition([1, 2]) == False
can_partition([1, 2, 5]) == False
can_partition([3, 3, 3, 4, 5]) == True
can_partition([2, 2, 3, 5]) == False
can_partition([2] * 59 + [4]) == False
can_partition(list(range(1, 61))) == True
```

```python tests
import random
from itertools import combinations


def brute(nums):
    total = sum(nums)
    return any(2 * sum(c) == total for k in range(len(nums) + 1) for c in combinations(nums, k))


for _ in range(200):
    nums = [random.randint(1, 12) for _ in range(random.randint(0, 9))]
    assert can_partition(nums) == brute(nums)
```

```python solution
def can_partition(nums):
    total = sum(nums)
    if total % 2:
        return False
    target = total // 2
    reach = [True] + [False] * target
    for x in nums:
        for s in range(target, x - 1, -1):
            if reach[s - x]:
                reach[s] = True
    return reach[target]
```

## Hints

1. If the total is odd, there is no split. If it is even, you only need one group that adds up to half the total; the rest is the other group.
2. That is the subset-sum question from the lesson, with `target = sum(nums) // 2`.
3. Keep `reach = [True] + [False] * target`, and for each `x` run `s` from `target` down to `x`, setting `reach[s]` when `reach[s - x]` is `True`.
