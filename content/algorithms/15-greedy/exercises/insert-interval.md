---
id: insert-interval
title: Insert an interval
level: core
---

`intervals` is a list of `(start, end)` pairs, sorted by start, where no two overlap or touch. Insert `new`, merging it with every interval it overlaps or touches, and return the new list, still sorted and with no overlaps. Do it in one pass, without sorting.

For `intervals = [(1, 2), (3, 5), (6, 7), (8, 10)]` and `new = (4, 7)` the answer is `[(1, 2), (3, 7), (8, 10)]`.

```python starter
def insert_interval(intervals, new):
    pass
```

```tests
insert_interval([(1, 2), (3, 5), (6, 7), (8, 10)], (4, 7)) == [(1, 2), (3, 7), (8, 10)]
insert_interval([], (2, 4)) == [(2, 4)]
insert_interval([(5, 6)], (1, 2)) == [(1, 2), (5, 6)]
insert_interval([(1, 2)], (5, 6)) == [(1, 2), (5, 6)]
insert_interval([(1, 3), (6, 9)], (2, 5)) == [(1, 5), (6, 9)]
insert_interval([(1, 3), (6, 9)], (4, 5)) == [(1, 3), (4, 5), (6, 9)]
insert_interval([(1, 3), (6, 9)], (3, 6)) == [(1, 9)]
insert_interval([(1, 2), (4, 5), (7, 8)], (0, 10)) == [(0, 10)]
insert_interval([(1, 10)], (3, 4)) == [(1, 10)]
insert_interval([(-6, -4), (0, 1)], (-4, -2)) == [(-6, -2), (0, 1)]
```

```python tests
import random


def slow(intervals, new):
    out = []
    for s, e in sorted(intervals + [new]):
        if out and s <= out[-1][1]:
            out[-1] = (out[-1][0], max(out[-1][1], e))
        else:
            out.append((s, e))
    return out


for _ in range(500):
    intervals, x = [], random.randint(-10, 0)
    for _ in range(random.randint(0, 6)):
        s = x + random.randint(1, 3)
        e = s + random.randint(0, 3)
        intervals.append((s, e))
        x = e
    s = random.randint(-10, 20)
    new = (s, s + random.randint(0, 6))
    assert insert_interval(intervals, new) == slow(intervals, new), (intervals, new)
```

```python solution
def insert_interval(intervals, new):
    start, end = new
    out = []
    i = 0
    while i < len(intervals) and intervals[i][1] < start:
        out.append(intervals[i])
        i += 1
    while i < len(intervals) and intervals[i][0] <= end:
        start = min(start, intervals[i][0])
        end = max(end, intervals[i][1])
        i += 1
    out.append((start, end))
    out.extend(intervals[i:])
    return out
```

## Hints

1. The list falls into three runs: intervals that end before `new` starts, intervals that overlap or touch `new`, and intervals that start after `new` ends.
2. Copy the first run as it is. Fold every interval of the second run into `new`. Copy the third run as it is.
3. While `intervals[i][1] < start`, copy and move on. Then while `intervals[i][0] <= end`, widen `start` and `end` with `min` and `max`. Append `(start, end)`, then the rest of the list.
