---
id: merge-k-sorted
title: Merge k sorted lists
level: core
---

`lists` holds sorted lists of numbers. Return one sorted list with every number, in O(N log k) time for N numbers in k lists. Don't call `sorted` or `heapq.merge`. For `[[1, 4, 7], [2, 5], [3, 6, 9]]` the answer is `[1, 2, 3, 4, 5, 6, 7, 9]`.

```python starter
import heapq


def merge_k(lists):
    pass
```

```tests
merge_k([[1, 4, 7], [2, 5], [3, 6, 9]]) == [1, 2, 3, 4, 5, 6, 7, 9]
merge_k([]) == []
merge_k([[], []]) == []
merge_k([[1, 2, 3]]) == [1, 2, 3]
merge_k([[], [4], []]) == [4]
merge_k([[1, 1], [1], [0, 1]]) == [0, 1, 1, 1, 1]
merge_k([[-5, 0], [-3, 10], [-4]]) == [-5, -4, -3, 0, 10]
merge_k([[i] for i in range(500, 0, -1)]) == list(range(1, 501))
merge_k([list(range(j, 30000, 3)) for j in range(3)]) == list(range(30000))
```

```python solution
import heapq


def merge_k(lists):
    heap = [(lst[0], i, 0) for i, lst in enumerate(lists) if lst]
    heapq.heapify(heap)
    out = []
    while heap:
        val, i, j = heapq.heappop(heap)
        out.append(val)
        if j + 1 < len(lists[i]):
            heapq.heappush(heap, (lists[i][j + 1], i, j + 1))
    return out
```

## Hints

1. The next number overall is the smallest of the k fronts. A heap gives the smallest front in O(log k).
2. Store `(value, list index, position)` in the heap, starting with the first item of every non-empty list.
3. Pop, append the value, and if that list has an item at `position + 1`, push it. Stop when the heap is empty.
