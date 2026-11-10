---
id: shortest-window
title: Shortest window with a sum
level: core
---

`nums` holds positive numbers. Return the length of the shortest run of items in a row whose total is at least `target`, or 0 if there is none. In `[2, 3, 1, 2, 4, 3]` with a target of 7, the answer is 2, for `4 + 3`.

```python starter
def shortest_window(nums, target):
    pass
```

```tests
shortest_window([2, 3, 1, 2, 4, 3], 7) == 2
shortest_window([1, 4, 4], 4) == 1
shortest_window([1, 1, 1, 1], 4) == 4
shortest_window([1, 1, 1, 1], 5) == 0
shortest_window([2, 2, 2, 2], 3) == 2
shortest_window([10], 7) == 1
shortest_window([3], 7) == 0
shortest_window([], 1) == 0
shortest_window([1, 2, 3, 4, 5], 11) == 3
```

```python solution
def shortest_window(nums, target):
    best = 0
    left = 0
    total = 0
    for right in range(len(nums)):
        total += nums[right]
        while total >= target:
            length = right - left + 1
            if best == 0 or length < best:
                best = length
            total -= nums[left]
            left += 1
    return best
```

## Hints

1. Once a window reaches the target, a longer window ending at the same place can't be the answer.
2. Grow the window on the right. While its total is at least `target`, record its length and shrink it from the left.
3. Inside `while total >= target`, update `best` with `right - left + 1`, then subtract `nums[left]` and move `left` forward. Use 0 to mean "nothing found yet".
