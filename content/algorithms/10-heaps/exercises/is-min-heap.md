---
id: is-min-heap
title: Is it a min-heap
level: warmup
---

Return `True` if the list `a` is a min-heap: every item is greater than or equal to its parent at `(i - 1) // 2`. `[1, 3, 2, 7, 4]` is a min-heap. `[1, 3, 2, 0]` is not, because 0 is smaller than its parent 3.

```python starter
def is_min_heap(a):
    pass
```

```tests
is_min_heap([1, 3, 2, 7, 4]) == True
is_min_heap([1, 3, 2, 0]) == False
is_min_heap([]) == True
is_min_heap([5]) == True
is_min_heap([2, 2, 2, 2]) == True
is_min_heap([2, 1]) == False
is_min_heap([-5, -3, -4, 0, -2]) == True
is_min_heap([1, 4, 2, 3, 5]) == False
is_min_heap(list(range(100000))) == True
is_min_heap(list(range(100000))[::-1]) == False
```

```python solution
def is_min_heap(a):
    for i in range(1, len(a)):
        if a[(i - 1) // 2] > a[i]:
            return False
    return True
```

## Hints

1. Every item except the root has exactly one parent. Checking each item against its parent covers every edge of the tree.
2. Loop `i` from 1 to the end and compare `a[i]` with `a[(i - 1) // 2]`.
3. Return `False` as soon as a parent is bigger than its child. If the loop finishes, return `True`. Equal values are allowed.
