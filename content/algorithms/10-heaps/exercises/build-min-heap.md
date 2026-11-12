---
id: build-min-heap
title: Build a heap
level: stretch
---

Rearrange the list `a` into a min-heap in place, in O(n) time, and return it. Don't push items one at a time. Sift down every parent instead, from the last parent back to the root. `[9, 7, 5, 3, 1, 8, 2]` becomes `[1, 3, 2, 9, 7, 8, 5]`. Any valid min-heap of the same items passes.

```python starter
def build_heap(a):
    return a
```

```tests
build_heap([9, 7, 5, 3, 1, 8, 2])[0] == 1
sorted(build_heap([9, 7, 5, 3, 1, 8, 2])) == [1, 2, 3, 5, 7, 8, 9]
build_heap([]) == []
build_heap([7]) == [7]
build_heap([2, 1]) == [1, 2]
build_heap([3, 2, 1]) == [1, 2, 3]
build_heap([5, 5, 5]) == [5, 5, 5]
build_heap([0, -1, -2])[0] == -2
build_heap(list(range(100000, 0, -1)))[0] == 1
```

```python tests
import random


def valid(a):
    return all(a[(i - 1) // 2] <= a[i] for i in range(1, len(a)))


for n in range(60):
    items = [random.randint(-30, 30) for _ in range(n)]
    a = list(items)
    assert build_heap(a) is a
    assert valid(a)
    assert sorted(a) == sorted(items)

big = list(range(200000, 0, -1))
assert valid(build_heap(big))
```

```python solution
def sift_down(a, i):
    n = len(a)
    while 2 * i + 1 < n:
        c = 2 * i + 1
        if c + 1 < n and a[c + 1] < a[c]:
            c += 1
        if a[i] <= a[c]:
            return
        a[i], a[c] = a[c], a[i]
        i = c


def build_heap(a):
    for i in range(len(a) // 2 - 1, -1, -1):
        sift_down(a, i)
    return a
```

## Hints

1. Leaves are already heaps of one item. Only parents need fixing, and a parent can only be fixed once both of its subtrees are heaps.
2. Walk the parents from the last one, `len(a) // 2 - 1`, down to 0, and sift each one down.
3. Write `sift_down(a, i)` as in the lesson: swap with the smaller child while that child is smaller. Then `for i in range(len(a) // 2 - 1, -1, -1): sift_down(a, i)`.
