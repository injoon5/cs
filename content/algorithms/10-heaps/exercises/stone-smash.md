---
id: stone-smash
title: Smash the stones
level: core
---

Each number in `stones` is a stone's weight. While two or more stones are left, take the two heaviest and smash them together. Equal stones both break. Otherwise the lighter one breaks and the heavier one loses that much weight. Return the weight of the stone left at the end, or 0 if none is left.

For `[2, 7, 4, 1, 8, 1]`: 8 and 7 leave 1, then 4 and 2 leave 2, then 2 and 1 leave 1, then 1 and 1 break, and the last stone weighs 1.

```python starter
import heapq


def last_stone(stones):
    pass
```

```tests
last_stone([2, 7, 4, 1, 8, 1]) == 1
last_stone([]) == 0
last_stone([5]) == 5
last_stone([3, 3]) == 0
last_stone([10, 4]) == 6
last_stone([1, 1, 1]) == 1
last_stone([9, 3, 2, 10]) == 0
last_stone([1, 2, 4, 8, 16]) == 1
last_stone([1000] * 10001) == 1000
```

```python solution
import heapq


def last_stone(stones):
    heap = [-s for s in stones]
    heapq.heapify(heap)
    while len(heap) > 1:
        a = -heapq.heappop(heap)
        b = -heapq.heappop(heap)
        if a != b:
            heapq.heappush(heap, -(a - b))
    return -heap[0] if heap else 0
```

## Hints

1. Each round needs the two largest of a set that keeps changing. Sorting again each round costs O(n log n) per round.
2. `heapq` only gives the smallest, so store every weight negated.
3. Heapify the negated list. While two or more are left, pop two, and if they differ push back the negated difference. Return the last weight, or 0.
