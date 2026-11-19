---
id: merge-overlapping-intervals
title: Merge intervals
level: core
---

Each interval is a `(start, end)` pair with `start <= end`, in any order. Merge every group of intervals that overlap or touch, and return the merged intervals as tuples, sorted by start. `(1, 3)` and `(3, 5)` touch, so they merge into `(1, 5)`.

For `[(8, 10), (1, 3), (2, 6), (15, 18)]` the answer is `[(1, 6), (8, 10), (15, 18)]`.

```python starter
def merge_intervals(intervals):
    pass
```

```tests
merge_intervals([(8, 10), (1, 3), (2, 6), (15, 18)]) == [(1, 6), (8, 10), (15, 18)]
merge_intervals([]) == []
merge_intervals([(4, 7)]) == [(4, 7)]
merge_intervals([(1, 3), (3, 5)]) == [(1, 5)]
merge_intervals([(1, 2), (4, 5)]) == [(1, 2), (4, 5)]
merge_intervals([(1, 10), (2, 3), (4, 5)]) == [(1, 10)]
merge_intervals([(2, 3), (2, 3), (2, 3)]) == [(2, 3)]
merge_intervals([(5, 5), (1, 4)]) == [(1, 4), (5, 5)]
merge_intervals([(-3, -1), (-2, 4), (6, 7)]) == [(-3, 4), (6, 7)]
merge_intervals([(1, 4), (0, 0), (2, 3), (4, 9)]) == [(0, 0), (1, 9)]
merge_intervals([(i, i + 1) for i in range(100000, 0, -2)]) == [(i, i + 1) for i in range(2, 100001, 2)]
```

```python tests
import random


def slow(intervals):
    groups = [[s, e] for s, e in intervals]
    changed = True
    while changed:
        changed = False
        for i in range(len(groups)):
            for j in range(i + 1, len(groups)):
                a, b = groups[i], groups[j]
                if a[0] <= b[1] and b[0] <= a[1]:
                    groups[i] = [min(a[0], b[0]), max(a[1], b[1])]
                    del groups[j]
                    changed = True
                    break
            if changed:
                break
    return sorted((s, e) for s, e in groups)


for _ in range(300):
    intervals = []
    for _ in range(random.randint(0, 8)):
        s = random.randint(-5, 15)
        intervals.append((s, s + random.randint(0, 4)))
    assert merge_intervals(intervals) == slow(intervals), intervals
```

```python solution
def merge_intervals(intervals):
    merged = []
    for start, end in sorted(intervals):
        if merged and start <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    return [(start, end) for start, end in merged]
```

## Hints

1. Sorted by start, intervals that merge sit next to each other.
2. Walk the sorted intervals and keep the merged blocks so far. Only the last block can reach the next interval.
3. If `start <= merged[-1][1]`, stretch the last block's end to `max(merged[-1][1], end)`. Otherwise start a new block. Keep blocks as lists so the end can change, and turn them into tuples at the end.
