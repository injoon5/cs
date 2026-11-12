---
id: first-negative
title: First negative in each window
level: warmup
---

For each window of `k` numbers in a row in `nums`, return the first negative number in it, or 0 if it has none. You can assume `1 <= k <= len(nums)`. For `[-8, 2, 3, -6, 10]` with `k = 2`, the windows are `[-8, 2]`, `[2, 3]`, `[3, -6]` and `[-6, 10]`, so the answer is `[-8, 0, -6, -6]`.

```python starter
def first_negative(nums, k):
    pass
```

```tests
first_negative([-8, 2, 3, -6, 10], 2) == [-8, 0, -6, -6]
first_negative([1, 2, 3], 2) == [0, 0]
first_negative([-1, -2, -3], 2) == [-1, -2]
first_negative([5], 1) == [0]
first_negative([-5], 1) == [-5]
first_negative([12, -1, -7, 8, -15, 30, 16, 28], 3) == [-1, -1, -7, -15, -15, 0]
first_negative([-2, -2, 4], 3) == [-2]
first_negative([0, -1, 0], 1) == [0, -1, 0]
first_negative([-1] + [1] * 999, 1000) == [-1]
```

```python solution
from collections import deque

def first_negative(nums, k):
    negs = deque()
    out = []
    for i, x in enumerate(nums):
        if x < 0:
            negs.append(i)
        if negs and negs[0] <= i - k:
            negs.popleft()
        if i >= k - 1:
            out.append(nums[negs[0]] if negs else 0)
    return out
```

## Hints

1. Only the negative numbers matter, and the oldest one in the window is the answer.
2. Keep a queue of the indexes of negative numbers. Add new ones at the back. Drop the front when it slides out of the window.
3. The window ending at `i` starts at `i - k + 1`, so pop the front while it is `<= i - k`. Then the answer is `nums[negs[0]]`, or 0 if the queue is empty.
