---
id: subsets-of-size
title: Subsets of size k
level: core
---

Return every subset of `nums` with exactly `k` items. Keep the items of each subset in the order they appear in `nums`, and list the subsets in the order a take-it-first search finds them. For `nums = [1, 2, 3, 4]` and `k = 2`:

`[[1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]]`

The items of `nums` are distinct.

```python starter
def subsets_of_size(nums, k):
    pass
```

```tests
subsets_of_size([1, 2, 3, 4], 2) == [[1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]]
subsets_of_size([1, 2, 3], 3) == [[1, 2, 3]]
subsets_of_size([1, 2, 3], 1) == [[1], [2], [3]]
subsets_of_size([1, 2, 3], 0) == [[]]
subsets_of_size([1, 2], 3) == []
subsets_of_size([], 0) == [[]]
subsets_of_size([5, -1, 0], 2) == [[5, -1], [5, 0], [-1, 0]]
len(subsets_of_size(list(range(20)), 10)) == 184756
```

```python solution
def subsets_of_size(nums, k):
    out = []
    picked = []

    def explore(start):
        if len(picked) == k:
            out.append(picked[:])
            return
        for i in range(start, len(nums)):
            picked.append(nums[i])
            explore(i + 1)
            picked.pop()

    explore(0)
    return out
```

## Hints

1. Choose, explore, unchoose. Stop as soon as `picked` has `k` items.
2. To keep the original order and avoid repeats, only pick items after the last one you picked. Pass a `start` index down.
3. In `explore(start)`, loop `i` from `start` to the end: append `nums[i]`, call `explore(i + 1)`, then pop. Save `picked[:]` when it has `k` items.
