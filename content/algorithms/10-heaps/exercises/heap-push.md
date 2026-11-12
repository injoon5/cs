---
id: heap-push
title: Push onto a heap
level: core
---

`heap` is a min-heap stored in a list. Add `x` to it and return the same list, still a min-heap. Append `x`, then sift it up: swap it with its parent while the parent is bigger. Pushing 0 onto `[1, 3, 2, 7, 4, 5]` gives `[0, 3, 1, 7, 4, 5, 2]`.

```python starter
def heap_push(heap, x):
    heap.append(x)
    return heap
```

```tests
heap_push([1, 3, 2, 7, 4, 5], 0) == [0, 3, 1, 7, 4, 5, 2]
heap_push([], 5) == [5]
heap_push([1, 3, 2], 4) == [1, 3, 2, 4]
heap_push([1, 3, 2], 2) == [1, 2, 2, 3]
heap_push([2, 2], 2) == [2, 2, 2]
heap_push([-1, 0], -5) == [-5, 0, -1]
heap_push([1, 5, 2, 6, 7, 3], 4) == [1, 5, 2, 6, 7, 3, 4]
heap_push([3], 1) == [1, 3]
```

```python tests
import heapq
import random

mine, theirs = [], []
for _ in range(2000):
    x = random.randint(-1000, 1000)
    heap_push(mine, x)
    heapq.heappush(theirs, x)
assert mine == theirs
```

```python solution
def heap_push(heap, x):
    heap.append(x)
    i = len(heap) - 1
    while i > 0:
        p = (i - 1) // 2
        if heap[p] <= heap[i]:
            break
        heap[i], heap[p] = heap[p], heap[i]
        i = p
    return heap
```

## Hints

1. Appending keeps the shape. Only the path from the new item up to the root can be out of order.
2. Start at the last index. While it isn't the root and its parent at `(i - 1) // 2` is bigger, swap the two and move `i` to the parent.
3. Stop as soon as `heap[p] <= heap[i]`. Everything above that point was already in order.
