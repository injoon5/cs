---
id: merge-sorted-lists
title: Merge two sorted lists
level: warmup
---

`a` and `b` are each sorted from smallest to largest. Return one new sorted list with every item from both, in O(len(a) + len(b)) time. Don't call `sort` or `sorted`. For example, `merge_sorted_lists([1, 4, 7], [2, 3, 9])` gives `[1, 2, 3, 4, 7, 9]`.

```python starter
def merge_sorted_lists(a, b):
    pass
```

```tests
merge_sorted_lists([1, 4, 7], [2, 3, 9]) == [1, 2, 3, 4, 7, 9]
merge_sorted_lists([1, 2, 3], [4, 5]) == [1, 2, 3, 4, 5]
merge_sorted_lists([4, 5], [1, 2, 3]) == [1, 2, 3, 4, 5]
merge_sorted_lists([], [1, 2]) == [1, 2]
merge_sorted_lists([3], []) == [3]
merge_sorted_lists([], []) == []
merge_sorted_lists([2, 2], [2]) == [2, 2, 2]
merge_sorted_lists([-5, 0, 5], [-6, -1]) == [-6, -5, -1, 0, 5]
merge_sorted_lists(list(range(0, 10000, 2)), list(range(1, 10000, 2))) == list(range(10000))
```

```python solution
def merge_sorted_lists(a, b):
    out = []
    i = j = 0
    while i < len(a) and j < len(b):
        if a[i] <= b[j]:
            out.append(a[i])
            i += 1
        else:
            out.append(b[j])
            j += 1
    out.extend(a[i:])
    out.extend(b[j:])
    return out
```

## Hints

1. The smallest item overall is at the front of `a` or the front of `b`.
2. Keep an index into each list. Each step, append the smaller of `a[i]` and `b[j]` and move that index on.
3. Loop while both indexes are in range. After the loop, one list may have items left; `extend` with `a[i:]` and `b[j:]`.
