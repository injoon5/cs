---
id: meeting-rooms-needed
title: Meeting rooms
level: core
---

Each meeting is a `(start, end)` pair, and a meeting that ends at 10 frees its room for one that starts at 10. Return the fewest rooms that fit every meeting. For `[(9, 10), (9, 12), (10, 11), (11, 13)]` the answer is 2.

```python starter
import heapq


def min_rooms(meetings):
    pass
```

```tests
min_rooms([(9, 10), (9, 12), (10, 11), (11, 13)]) == 2
min_rooms([]) == 0
min_rooms([(1, 5)]) == 1
min_rooms([(1, 2), (2, 3), (3, 4)]) == 1
min_rooms([(1, 4), (1, 4), (1, 4)]) == 3
min_rooms([(5, 8), (1, 3), (2, 6)]) == 2
min_rooms([(1, 10), (2, 3), (4, 5), (6, 7)]) == 2
min_rooms([(-3, 0), (-1, 2), (0, 1)]) == 2
min_rooms([(i, i + 3) for i in range(10000)]) == 3
```

```python tests
import random


def slow(meetings):
    times = sorted({t for m in meetings for t in m})
    return max((sum(s <= t < e for s, e in meetings) for t in times), default=0)


for _ in range(200):
    ms = []
    for _ in range(random.randint(0, 12)):
        s = random.randint(0, 20)
        ms.append((s, s + random.randint(1, 6)))
    assert min_rooms(ms) == slow(ms)
```

```python solution
import heapq


def min_rooms(meetings):
    ends = []
    for start, end in sorted(meetings):
        if ends and ends[0] <= start:
            heapq.heappop(ends)
        heapq.heappush(ends, end)
    return len(ends)
```

## Hints

1. Handle meetings in order of start time. For each one, ask whether some room is already free.
2. Keep a min-heap of the end times of rooms in use. The root is the room that frees up first.
3. Sort the meetings. If the heap isn't empty and `ends[0] <= start`, pop it to reuse that room. Push `end` either way. The heap's size at the end is the answer.
