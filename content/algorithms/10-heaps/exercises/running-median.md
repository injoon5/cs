---
id: running-median
title: Running median
level: stretch
---

Return a list with the median of `nums[:i + 1]` for every `i`. For an even count the median is the mean of the two middle numbers. Use two heaps, so each step costs O(log n). For `[5, 2, 8, 1]` the answer is `[5, 3.5, 5, 3.5]`.

```python starter
import heapq


def running_medians(nums):
    pass
```

```tests
running_medians([5, 2, 8, 1]) == [5, 3.5, 5, 3.5]
running_medians([]) == []
running_medians([7]) == [7]
running_medians([1, 2]) == [1, 1.5]
running_medians([4, 4, 4]) == [4, 4, 4]
running_medians([3, 2, 1]) == [3, 2.5, 2]
running_medians([-1, -5, 10, 0]) == [-1, -3, -1, -0.5]
running_medians([1, 9, 2, 8, 3, 7]) == [1, 5, 2, 5, 3, 5]
running_medians(list(range(100000)))[-1] == 49999.5
```

```python tests
import random
import statistics

for _ in range(100):
    nums = [random.randint(-30, 30) for _ in range(random.randint(1, 25))]
    want = [statistics.median(nums[:i + 1]) for i in range(len(nums))]
    assert running_medians(nums) == want
```

```python solution
import heapq


def running_medians(nums):
    low, high = [], []
    out = []
    for x in nums:
        heapq.heappush(low, -x)
        heapq.heappush(high, -heapq.heappop(low))
        if len(high) > len(low):
            heapq.heappush(low, -heapq.heappop(high))
        if len(low) > len(high):
            out.append(-low[0])
        else:
            out.append((-low[0] + high[0]) / 2)
    return out
```

## Hints

1. Keep the smaller half and the larger half apart, with quick access to the largest of the small half and the smallest of the large half.
2. A max-heap `low` (store negated numbers) and a min-heap `high`. Keep `len(low)` equal to `len(high)` or one more.
3. Push each number into `low`, move `low`'s top to `high`, and if `high` is now bigger, move its top back. The median is `-low[0]`, or the mean of `-low[0]` and `high[0]`.
