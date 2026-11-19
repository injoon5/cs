---
id: jump-game-reach
title: Can you reach the end
level: warmup
---

You start at index 0 of `nums`, a list of numbers that are 0 or more. From index `i` you can jump forward to any index from `i + 1` to `i + nums[i]`. Return `True` if you can reach the last index.

For `[2, 3, 1, 1, 4]` the answer is `True`: jump from 0 to 1, then from 1 to 4. For `[3, 2, 1, 0, 4]` it is `False`: every route lands on index 3, which can't move.

```python starter
def can_reach_end(nums):
    pass
```

```tests
can_reach_end([2, 3, 1, 1, 4]) == True
can_reach_end([3, 2, 1, 0, 4]) == False
can_reach_end([0]) == True
can_reach_end([5]) == True
can_reach_end([0, 1]) == False
can_reach_end([1, 0]) == True
can_reach_end([2, 0, 0]) == True
can_reach_end([1, 1, 0, 1]) == False
can_reach_end([4, 0, 0, 0, 0, 0]) == False
can_reach_end([100000] * 100000) == True
can_reach_end([3, 2, 1, 0] * 25000 + [0]) == False
```

```python tests
import random


def slow(nums):
    reach = {0}
    for i in range(len(nums)):
        if i in reach:
            reach.update(range(i + 1, i + nums[i] + 1))
    return len(nums) - 1 in reach


for _ in range(500):
    nums = [random.randint(0, 3) for _ in range(random.randint(1, 12))]
    assert can_reach_end(nums) == slow(nums), nums
```

```python solution
def can_reach_end(nums):
    furthest = 0
    for i, jump in enumerate(nums):
        if i > furthest:
            return False
        furthest = max(furthest, i + jump)
    return True
```

## Hints

1. You don't need the route, only how far right you could possibly get.
2. Walk the indexes from left to right, keeping `furthest`, the largest index reachable so far.
3. If `i > furthest`, index `i` is out of reach, and so is everything after it. Otherwise update `furthest` with `i + nums[i]`.
