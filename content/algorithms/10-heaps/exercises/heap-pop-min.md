---
id: heap-pop-min
title: Pop from a heap
level: core
---

`heap` is a non-empty min-heap stored in a list. Remove its smallest item and return it, leaving the rest a min-heap. Move the last item to the root, then sift it down: swap it with its smaller child while that child is smaller. Popping `[1, 3, 2, 7, 4, 5]` returns 1 and leaves `[2, 3, 5, 7, 4]`.

```python starter
def heap_pop(heap):
    return heap[0]
```

```tests
heap_pop([1, 3, 2, 7, 4, 5]) == 1
heap_pop([4]) == 4
heap_pop([2, 2, 2]) == 2
heap_pop([-3, 1, -2]) == -3
```

```python tests
import heapq
import random

h = [1, 3, 2, 7, 4, 5]
heap_pop(h)
assert h == [2, 3, 5, 7, 4]

h = [4]
heap_pop(h)
assert h == []

h = [1, 2]
heap_pop(h)
assert h == [2]


def valid(a):
    return all(a[(i - 1) // 2] <= a[i] for i in range(1, len(a)))


for n in range(1, 40):
    h = [random.randint(-20, 20) for _ in range(n)]
    heapq.heapify(h)
    out = []
    while h:
        out.append(heap_pop(h))
        assert valid(h)
    assert out == sorted(out)

h = list(range(100000))
assert [heap_pop(h) for _ in range(1000)] == list(range(1000))
```

```python solution
def heap_pop(heap):
    smallest = heap[0]
    last = heap.pop()
    if not heap:
        return smallest
    heap[0] = last
    i, n = 0, len(heap)
    while 2 * i + 1 < n:
        c = 2 * i + 1
        if c + 1 < n and heap[c + 1] < heap[c]:
            c += 1
        if heap[i] <= heap[c]:
            break
        heap[i], heap[c] = heap[c], heap[i]
        i = c
    return smallest
```

## Hints

1. The answer is `heap[0]`. The work is in repairing the heap after it leaves.
2. `heap.pop()` removes the last item. If the list is now empty, you are done. Otherwise put that item at index 0 and sift it down.
3. At index `i`, the children are `2i + 1` and `2i + 2`. Pick the smaller one that exists; if it is smaller than `heap[i]`, swap and move `i` to it, else stop.
