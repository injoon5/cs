---
id: min-jumps-to-end
title: Fewest jumps
level: core
---

You start at index 0 of `nums`, a list of numbers that are 0 or more. From index `i` you can jump forward to any index from `i + 1` to `i + nums[i]`. The last index can always be reached. Return the fewest jumps that get there.

For `[2, 3, 1, 1, 4]` the answer is 2: jump from 0 to 1, then from 1 to 4.

```python starter
def min_jumps(nums):
    pass
```

```tests
min_jumps([2, 3, 1, 1, 4]) == 2
min_jumps([0]) == 0
min_jumps([1, 0]) == 1
min_jumps([1, 1, 1, 1]) == 3
min_jumps([4, 1, 1, 1, 1]) == 1
min_jumps([2, 3, 0, 1, 4]) == 2
min_jumps([1, 2, 1, 1, 1]) == 3
min_jumps([3, 1, 1, 5, 0, 0, 0, 0]) == 2
min_jumps([1] * 100000) == 99999
min_jumps([2] * 100000) == 50000
min_jumps(list(range(100000, 0, -1))) == 1
```

```python tests
import random


def slow(nums):
    inf = float("inf")
    best = [0] + [inf] * (len(nums) - 1)
    for i in range(len(nums)):
        for j in range(i + 1, min(len(nums), i + nums[i] + 1)):
            best[j] = min(best[j], best[i] + 1)
    return best[-1]


for _ in range(500):
    nums = [random.randint(0, 4) for _ in range(random.randint(1, 12))]
    if slow(nums) != float("inf"):
        assert min_jumps(nums) == slow(nums), nums
```

```python solution
def min_jumps(nums):
    jumps = reach = furthest = 0
    for i in range(len(nums) - 1):
        furthest = max(furthest, i + nums[i])
        if i == reach:
            jumps += 1
            reach = furthest
    return jumps
```

## Hints

1. Each jump covers a stretch of indexes, like a clip covering part of a video. Ask how far `k` jumps can get you.
2. Walk the indexes once. `reach` is the furthest index the jumps so far can land on, and `furthest` is the furthest the next jump could land, from any index up to `reach`.
3. Loop over `i` up to the second-to-last index. Update `furthest` with `i + nums[i]`. When `i` reaches `reach`, you must jump again: add one jump and set `reach = furthest`.
