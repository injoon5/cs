---
id: sort-colors
title: Sort colors
level: core
---

`colors` holds only 0, 1 and 2. Sort it in place in one pass with O(1) extra space, and return it. Don't count them and rewrite the list, and don't call `sort`. For example, `[2, 0, 1, 2, 0]` becomes `[0, 0, 1, 2, 2]`.

This is the three-way partition from quicksort, with 1 as the pivot.

```python starter
def sort_colors(colors):
    pass
```

```tests
sort_colors([2, 0, 1, 2, 0]) == [0, 0, 1, 2, 2]
sort_colors([2, 0, 1]) == [0, 1, 2]
sort_colors([0, 1, 2]) == [0, 1, 2]
sort_colors([2, 2, 2]) == [2, 2, 2]
sort_colors([1, 0]) == [0, 1]
sort_colors([1]) == [1]
sort_colors([]) == []
sort_colors([1, 1, 0, 0, 2, 1]) == [0, 0, 1, 1, 1, 2]
sort_colors([2, 1, 0] * 1000) == [0] * 1000 + [1] * 1000 + [2] * 1000
```

```python tests
a = [2, 0, 1]
assert sort_colors(a) is a, "sort colors in place and return it"
```

```python solution
def sort_colors(colors):
    low, mid, high = 0, 0, len(colors) - 1
    while mid <= high:
        if colors[mid] == 0:
            colors[low], colors[mid] = colors[mid], colors[low]
            low += 1
            mid += 1
        elif colors[mid] == 1:
            mid += 1
        else:
            colors[mid], colors[high] = colors[high], colors[mid]
            high -= 1
    return colors
```

## Hints

1. Keep three regions: 0s at the front, 2s at the back, 1s in between, and an unknown part in the middle still to look at.
2. Use `low`, `mid` and `high`. Everything before `low` is 0, everything between `low` and `mid` is 1, everything after `high` is 2.
3. Look at `colors[mid]`. A 0 swaps with `low` and both move on. A 1 just moves `mid`. A 2 swaps with `high` and only `high` moves, because the item swapped in hasn't been looked at.
