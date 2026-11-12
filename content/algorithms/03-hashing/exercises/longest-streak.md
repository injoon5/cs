---
id: longest-streak
title: Longest streak
level: stretch
---

Return the length of the longest run of consecutive whole numbers that are all in `nums`. The list isn't sorted and can have repeats. For `[100, 4, 200, 1, 3, 2]` the answer is 4, from 1, 2, 3, 4. Aim for O(n) average time.

```python starter
def longest_streak(nums):
    pass
```

```tests
longest_streak([100, 4, 200, 1, 3, 2]) == 4
longest_streak([]) == 0
longest_streak([5]) == 1
longest_streak([1, 2, 2, 3]) == 3
longest_streak([-2, -1, 0, 1]) == 4
longest_streak([10, 5, 12, 3, 55, 30, 4, 11, 2]) == 4
longest_streak([1, 3, 5, 7]) == 1
longest_streak([7, 7, 7]) == 1
longest_streak(list(range(100000, 0, -1))) == 100000
```

```python solution
def longest_streak(nums):
    have = set(nums)
    best = 0
    for x in have:
        if x - 1 in have:
            continue
        end = x
        while end + 1 in have:
            end += 1
        best = max(best, end - x + 1)
    return best
```

## Hints

1. Put the numbers in a set so "is `x + 1` here?" is O(1).
2. Only count a streak from its first number: `x` starts a streak when `x - 1` isn't in the set.
3. For each start, walk `end` up while `end + 1` is in the set. Each number is walked over once, so the total is O(n).
