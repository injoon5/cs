---
id: longest-sum-run
title: Longest run with a sum
level: stretch
---

Return the length of the longest run of items in a row in `nums` that adds up to exactly `k`, or 0 if there is none. Numbers can be negative or zero. In `[1, -1, 5, -2, 3]` with `k = 3`, the longest is `[1, -1, 5, -2]`, so the answer is 4.

```python starter
def longest_run(nums, k):
    pass
```

```tests
longest_run([1, -1, 5, -2, 3], 3) == 4
longest_run([-2, -1, 2, 1], 1) == 2
longest_run([], 0) == 0
longest_run([5], 5) == 1
longest_run([5], 4) == 0
longest_run([0, 0, 0], 0) == 3
longest_run([1, 2, 3], 7) == 0
longest_run([3, -3, 3, -3], 0) == 4
longest_run([2, -1, 2, -1, 2], 2) == 4
longest_run([1] * 100000, 50000) == 50000
```

```python tests
import random

def slow(nums, k):
    best = 0
    for l in range(len(nums)):
        total = 0
        for r in range(l, len(nums)):
            total += nums[r]
            if total == k:
                best = max(best, r - l + 1)
    return best

rng = random.Random(7)
for _ in range(300):
    nums = [rng.randint(-3, 3) for _ in range(rng.randint(0, 12))]
    k = rng.randint(-4, 4)
    assert longest_run(nums, k) == slow(nums, k), (nums, k)
```

```python solution
def longest_run(nums, k):
    first = {0: -1}
    running = 0
    best = 0
    for i, x in enumerate(nums):
        running += x
        if running - k in first:
            best = max(best, i - first[running - k])
        if running not in first:
            first[running] = i
    return best
```

## Hints

1. A run ending at `i` adds up to `k` when an earlier running total equals `running - k`. To make the run long, that earlier total should be as early as possible.
2. Keep a dict from each running total to the first index where it appeared, starting with `{0: -1}` for the empty start.
3. At each `i`, if `running - k` is in the dict, the run has length `i - first[running - k]`. Only store `running` the first time you see it.
