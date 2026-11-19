---
id: covered-length
title: Covered length
level: core
---

Each interval is a `(start, end)` pair on a line, with `start <= end`, and covers everything from `start` to `end`. Intervals may overlap. Return the total length of the line covered by at least one interval, counting overlapping parts once.

For `[(1, 4), (2, 6), (8, 9)]` the answer is 6: `(1, 4)` and `(2, 6)` together cover 1 to 6, which is 5, and `(8, 9)` adds 1.

```python starter
def covered_length(intervals):
    pass
```

```tests
covered_length([(1, 4), (2, 6), (8, 9)]) == 6
covered_length([]) == 0
covered_length([(3, 3)]) == 0
covered_length([(0, 10)]) == 10
covered_length([(0, 10), (2, 3), (4, 5)]) == 10
covered_length([(1, 3), (3, 5)]) == 4
covered_length([(5, 7), (5, 7), (5, 7)]) == 2
covered_length([(-5, -2), (-3, 1)]) == 6
covered_length([(0, 1), (2, 3), (4, 5)]) == 3
covered_length([(i * 10**4, i * 10**4 + 15000) for i in range(100000)]) == 1000005000
```

```python tests
import random


def slow(intervals):
    return sum(any(s <= x < e for s, e in intervals) for x in range(-20, 40))


for _ in range(500):
    intervals = []
    for _ in range(random.randint(0, 7)):
        s = random.randint(-15, 25)
        intervals.append((s, s + random.randint(0, 8)))
    assert covered_length(intervals) == slow(intervals), intervals
```

```python solution
def covered_length(intervals):
    events = []
    for start, end in intervals:
        events.append((start, 1))
        events.append((end, -1))
    events.sort()
    total = count = 0
    prev = None
    for x, delta in events:
        if count > 0:
            total += x - prev
        count += delta
        prev = x
    return total
```

## Hints

1. Between two events in a row, the number of intervals covering the line doesn't change.
2. Sweep the sorted `+1` and `-1` events and keep `count`, the number of intervals open right now, and `prev`, the coordinate of the last event.
3. At each event, if `count > 0`, add `x - prev` before applying the event's delta. Then update `count` and set `prev = x`.
