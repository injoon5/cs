---
id: partition-by-pivot
title: Partition by pivot
level: core
---

Partition `a[lo..hi]`, both ends included, around the pivot `a[hi]`. Afterwards, items smaller than the pivot come first, then the pivot, then the rest. Leave items outside `lo..hi` alone, work in place, and return the pivot's new index.

For example, with `a = [3, 7, 1, 8, 2, 5]`, `lo = 0` and `hi = 5`, the pivot is 5. Three items are smaller, so return 3. `a` could end as `[3, 1, 2, 5, 7, 8]`; the order within each side doesn't matter.

```python starter
def partition(a, lo, hi):
    pass
```

```tests
partition([3, 7, 1, 8, 2, 5], 0, 5) == 3
partition([1, 2, 3, 4, 5], 0, 4) == 4
partition([5, 4, 3, 2, 1], 0, 4) == 0
partition([4, 4, 4], 0, 2) == 0
partition([2, 4, 1, 4], 0, 3) == 2
partition([9], 0, 0) == 0
partition([9, 1, 6, 0, 3, 7], 1, 4) == 3
partition([-2, 5, -8, 0], 0, 3) == 2
```

```python tests
import random

def check(a, lo, hi):
    pivot = a[hi]
    before = list(a)
    p = partition(a, lo, hi)
    assert sorted(a) == sorted(before), "a must keep the same items"
    assert a[:lo] == before[:lo] and a[hi + 1:] == before[hi + 1:], "items outside lo..hi moved"
    assert a[p] == pivot, f"a[{p}] should be the pivot {pivot}"
    assert all(x < pivot for x in a[lo:p]), "left side has an item not smaller than the pivot"
    assert all(x >= pivot for x in a[p + 1:hi + 1]), "right side has an item smaller than the pivot"

check([3, 7, 1, 8, 2, 5], 0, 5)
check([9, 1, 6, 0, 3, 7], 1, 4)
rng = random.Random(3)
for _ in range(100):
    a = [rng.randint(-9, 9) for _ in range(rng.randint(1, 20))]
    lo = rng.randrange(len(a))
    hi = rng.randrange(lo, len(a))
    check(a, lo, hi)
```

```python solution
def partition(a, lo, hi):
    pivot = a[hi]
    i = lo
    for j in range(lo, hi):
        if a[j] < pivot:
            a[i], a[j] = a[j], a[i]
            i += 1
    a[i], a[hi] = a[hi], a[i]
    return i
```

## Hints

1. Keep a boundary `i`: everything in `a[lo:i]` is smaller than the pivot. It starts empty, at `lo`.
2. Walk `j` from `lo` to `hi - 1`. When `a[j]` is smaller than the pivot, swap it to `i` and move `i` on.
3. After the loop, swap `a[i]` with `a[hi]` to put the pivot between the two sides, and return `i`.
