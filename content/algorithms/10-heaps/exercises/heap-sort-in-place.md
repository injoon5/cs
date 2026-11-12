---
id: heap-sort-in-place
title: Heap sort in place
level: stretch
---

Sort the list `a` in ascending order in place and return it, with heap sort and O(1) extra space: no `sorted`, `sort` or `heapq`. Build a max-heap, then repeatedly swap the root with the last item of the heap part and sift the new root down. `[4, 9, 2, 7, 5, 1]` becomes `[1, 2, 4, 5, 7, 9]`.

```python starter
def heap_sort(a):
    return a
```

```tests
heap_sort([4, 9, 2, 7, 5, 1]) == [1, 2, 4, 5, 7, 9]
heap_sort([]) == []
heap_sort([1]) == [1]
heap_sort([2, 1]) == [1, 2]
heap_sort([3, 3, 1, 3]) == [1, 3, 3, 3]
heap_sort([-2, 5, -9, 0]) == [-9, -2, 0, 5]
heap_sort([1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]
heap_sort([5, 4, 3, 2, 1]) == [1, 2, 3, 4, 5]
heap_sort(list(range(50000, 0, -1))) == list(range(1, 50001))
```

```python tests
import random

for n in range(50):
    items = [random.randint(-20, 20) for _ in range(n)]
    a = list(items)
    assert heap_sort(a) is a
    assert a == sorted(items)
```

```python solution
def sift_down(a, i, n):
    while 2 * i + 1 < n:
        c = 2 * i + 1
        if c + 1 < n and a[c + 1] > a[c]:
            c += 1
        if a[i] >= a[c]:
            return
        a[i], a[c] = a[c], a[i]
        i = c


def heap_sort(a):
    n = len(a)
    for i in range(n // 2 - 1, -1, -1):
        sift_down(a, i, n)
    for end in range(n - 1, 0, -1):
        a[0], a[end] = a[end], a[0]
        sift_down(a, 0, end)
    return a
```

## Hints

1. A max-heap has its largest item at index 0, and the largest item belongs at the end of the sorted list.
2. Write `sift_down(a, i, n)` that only looks at the first `n` items, so the sorted tail stays untouched. Build the max-heap by sifting down every parent.
3. For `end` from `n - 1` down to 1: swap `a[0]` with `a[end]`, then `sift_down(a, 0, end)`.
