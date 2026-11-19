---
id: min-removals-overlap
title: Fewest removals
level: core
---

Each interval is a `(start, end)` pair with `start < end`. Two intervals that only touch, like `(1, 3)` and `(3, 5)`, don't overlap. Return the fewest intervals to remove so that no two of the rest overlap.

For `[(1, 2), (2, 3), (3, 4), (1, 3)]` the answer is 1: remove `(1, 3)`.

```python starter
def min_removals(intervals):
    pass
```

```tests
min_removals([(1, 2), (2, 3), (3, 4), (1, 3)]) == 1
min_removals([]) == 0
min_removals([(0, 5)]) == 0
min_removals([(1, 2), (1, 2), (1, 2)]) == 2
min_removals([(1, 2), (2, 3)]) == 0
min_removals([(0, 9), (1, 3), (4, 6), (7, 9)]) == 1
min_removals([(0, 4), (3, 5), (4, 8)]) == 1
min_removals([(-5, -1), (-3, 2), (0, 4)]) == 1
min_removals([(1, 10), (2, 3), (4, 5), (6, 7), (8, 9)]) == 1
min_removals([(i, i + 2) for i in range(100000)]) == 50000
```

```python tests
import random
from itertools import combinations


def slow(intervals):
    n = len(intervals)
    for keep in range(n, -1, -1):
        for chosen in combinations(intervals, keep):
            ordered = sorted(chosen)
            if all(a[1] <= b[0] for a, b in zip(ordered, ordered[1:])):
                return n - keep


for _ in range(300):
    intervals = []
    for _ in range(random.randint(0, 8)):
        s = random.randint(-5, 10)
        intervals.append((s, s + random.randint(1, 5)))
    assert min_removals(intervals) == slow(intervals), intervals
```

```python solution
def min_removals(intervals):
    kept, free = 0, float("-inf")
    for start, end in sorted(intervals, key=lambda iv: iv[1]):
        if start >= free:
            kept += 1
            free = end
    return len(intervals) - kept
```

## Hints

1. Removing the fewest is the same as keeping the most.
2. Keep intervals the way you'd fill one room with meetings: by earliest end.
3. Sort by end. Keep an interval when its start is at least the end of the last one kept. Return `len(intervals)` minus the number kept.
