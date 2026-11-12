---
id: max-in-min-heap
title: Largest in a min-heap
level: warmup
---

`heap` is a non-empty min-heap. Return its largest item, looking only at the items that can hold it. For `[1, 3, 2, 7, 4, 5]` the answer is 7.

A parent is never bigger than its children, so the largest item is always a leaf. The leaves are the items with no child, from index `len(heap) // 2` on.

```python starter
def heap_max(heap):
    pass
```

```tests
heap_max([1, 3, 2, 7, 4, 5]) == 7
heap_max([4]) == 4
heap_max([1, 9]) == 9
heap_max([1, 2, 3]) == 3
heap_max([0, 0, 0, 0]) == 0
heap_max([-9, -4, -7, -1, -2]) == -1
heap_max([1, 2, 8, 3, 4, 9, 10, 5]) == 10
heap_max(list(range(100000))) == 99999
```

```python tests
import heapq
import random

for n in range(1, 60):
    h = [random.randint(-50, 50) for _ in range(n)]
    heapq.heapify(h)
    assert heap_max(h) == max(h)
```

```python solution
def heap_max(heap):
    return max(heap[len(heap) // 2:])
```

## Hints

1. Can a parent ever hold the largest item?
2. Only leaves can. Index `i` is a leaf when `2i + 1` is past the end of the list.
3. The first leaf is at `len(heap) // 2`. Return `max(heap[len(heap) // 2:])`.
