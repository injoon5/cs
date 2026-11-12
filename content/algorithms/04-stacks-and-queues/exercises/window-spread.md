---
id: window-spread
title: Window spread
level: core
---

For each window of `k` numbers in a row in `nums`, return its biggest number minus its smallest. You can assume `1 <= k <= len(nums)`. For `[4, 2, 12, 3, 8]` with `k = 3`, the windows are `[4, 2, 12]`, `[2, 12, 3]` and `[12, 3, 8]`, so the answer is `[10, 10, 9]`. Aim for O(n).

```python starter
def window_spread(nums, k):
    pass
```

```tests
window_spread([4, 2, 12, 3, 8], 3) == [10, 10, 9]
window_spread([7], 1) == [0]
window_spread([1, 2, 3], 1) == [0, 0, 0]
window_spread([5, 5, 5, 5], 2) == [0, 0, 0]
window_spread([1, 9], 2) == [8]
window_spread([-3, 4, -1, 0], 2) == [7, 5, 1]
window_spread([1, 2, 3, 4, 5], 3) == [2, 2, 2]
window_spread([3, 1, 3, 1], 4) == [2]
window_spread(list(range(1000)), 10) == [9] * 991
```

```python tests
import random
random.seed(4)
for _ in range(200):
    n = random.randint(1, 12)
    a = [random.randint(-5, 5) for _ in range(n)]
    k = random.randint(1, n)
    want = [max(a[i:i + k]) - min(a[i:i + k])
            for i in range(n - k + 1)]
    assert window_spread(a, k) == want, (a, k)
```

```python solution
from collections import deque

def window_spread(nums, k):
    hi = deque()
    lo = deque()
    out = []
    for i, x in enumerate(nums):
        while hi and nums[hi[-1]] <= x:
            hi.pop()
        hi.append(i)
        while lo and nums[lo[-1]] >= x:
            lo.pop()
        lo.append(i)
        if hi[0] <= i - k:
            hi.popleft()
        if lo[0] <= i - k:
            lo.popleft()
        if i >= k - 1:
            out.append(nums[hi[0]] - nums[lo[0]])
    return out
```

## Hints

1. The spread needs the window's maximum and its minimum, and each one can be kept the same way.
2. Use two deques of indexes: one with values falling from front to back for the maximum, one with values rising for the minimum.
3. For the minimum deque, pop from the back while `nums[lo[-1]] >= x`. Drop each front once it is `<= i - k`, then answer `nums[hi[0]] - nums[lo[0]]`.
