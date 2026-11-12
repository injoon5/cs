---
id: longest-steady-run
title: Longest steady run
level: stretch
---

Return the length of the longest run of numbers in a row in `nums` whose biggest and smallest differ by at most `limit`. For `[8, 2, 4, 7]` with a limit of 4, the answer is 2: `[2, 4]` and `[4, 7]` both fit, and no run of 3 does.

```python starter
def longest_steady_run(nums, limit):
    pass
```

```tests
longest_steady_run([8, 2, 4, 7], 4) == 2
longest_steady_run([10, 1, 2, 4, 7, 2], 5) == 4
longest_steady_run([4, 2, 2, 2, 4, 4, 2, 2], 0) == 3
longest_steady_run([], 3) == 0
longest_steady_run([5], 0) == 1
longest_steady_run([1, 100], 0) == 1
longest_steady_run([3, 3, 3], 0) == 3
longest_steady_run([-1, -4, 2, -2], 3) == 2
longest_steady_run([1, 2, 3, 4, 5], 10) == 5
```

```python tests
import random
random.seed(7)
for _ in range(200):
    a = [random.randint(-6, 6)
         for _ in range(random.randint(0, 12))]
    limit = random.randint(0, 6)
    want = 0
    for i in range(len(a)):
        for j in range(i, len(a)):
            part = a[i:j + 1]
            if max(part) - min(part) <= limit:
                want = max(want, j - i + 1)
    assert longest_steady_run(a, limit) == want, (a, limit)
big = list(range(100000))
assert longest_steady_run(big, 99) == 100
```

```python solution
from collections import deque

def longest_steady_run(nums, limit):
    hi = deque()
    lo = deque()
    left = 0
    best = 0
    for right, x in enumerate(nums):
        while hi and nums[hi[-1]] <= x:
            hi.pop()
        hi.append(right)
        while lo and nums[lo[-1]] >= x:
            lo.pop()
        lo.append(right)
        while nums[hi[0]] - nums[lo[0]] > limit:
            left += 1
            if hi[0] < left:
                hi.popleft()
            if lo[0] < left:
                lo.popleft()
        best = max(best, right - left + 1)
    return best
```

## Hints

1. This is a sliding window that changes size. The hard part is knowing the window's maximum and minimum as it moves.
2. Grow the window on the right. Keep a falling deque for the maximum and a rising one for the minimum. While the spread is over `limit`, move `left` forward.
3. After `left += 1`, pop the front of either deque if its index is now below `left`. The window `left..right` then fits, so update `best` with `right - left + 1`.
