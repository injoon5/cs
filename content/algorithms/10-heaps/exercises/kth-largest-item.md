---
id: kth-largest-item
title: K-th largest
level: core
---

Return the k-th largest number in `nums`, counting duplicates, where `1 <= k <= len(nums)`. Use a min-heap of size k, in O(n log k) time. For `[5, 1, 9, 3, 7, 6]` and `k = 3` the answer is 6.

```python starter
import heapq


def kth_largest(nums, k):
    pass
```

```tests
kth_largest([5, 1, 9, 3, 7, 6], 3) == 6
kth_largest([5, 1, 9, 3, 7, 6], 1) == 9
kth_largest([5, 1, 9, 3, 7, 6], 6) == 1
kth_largest([4], 1) == 4
kth_largest([3, 3, 3, 1], 2) == 3
kth_largest([2, 2, 1, 1], 3) == 1
kth_largest([-4, -1, -7], 2) == -4
kth_largest(list(range(100000)), 10) == 99990
```

```python tests
import random

for _ in range(200):
    nums = [random.randint(-50, 50) for _ in range(random.randint(1, 30))]
    k = random.randint(1, len(nums))
    assert kth_largest(nums, k) == sorted(nums)[-k]
```

```python solution
import heapq


def kth_largest(nums, k):
    heap = []
    for x in nums:
        if len(heap) < k:
            heapq.heappush(heap, x)
        elif x > heap[0]:
            heapq.heapreplace(heap, x)
    return heap[0]
```

## Hints

1. Keep the k largest numbers seen so far. Which one of them is the answer at the end?
2. In a min-heap of the k largest, the root is the smallest of them, which is the k-th largest.
3. Push while the heap has fewer than k items. After that, if `x > heap[0]`, call `heapq.heapreplace(heap, x)`. Return `heap[0]`.
