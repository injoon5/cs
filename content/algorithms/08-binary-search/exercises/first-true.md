---
id: first-true
title: First true
level: core
---

`xs` is a list of booleans: some `False`s, then some `True`s. Return the index of the first `True`, or `len(xs)` if there is none. For `[False, False, True, True]` the answer is 2. Use O(log n) time.

```python starter
def first_true(xs):
    pass
```

```tests
first_true([False, False, True, True]) == 2
first_true([False, False, True]) == 2
first_true([True]) == 0
first_true([False]) == 1
first_true([]) == 0
first_true([True] * 5) == 0
first_true([False] * 5) == 5
first_true([False] * 999 + [True]) == 999
first_true([False] * 300_000 + [True] * 700_000) == 300_000
```

```python solution
def first_true(xs):
    lo, hi = 0, len(xs)
    while lo < hi:
        mid = (lo + hi) // 2
        if xs[mid]:
            hi = mid
        else:
            lo = mid + 1
    return lo
```

## Hints

1. The answer is the boundary between two runs.
2. Keep everything left of `lo` known `False` and everything from `hi` on known `True`. Start with `lo = 0` and `hi = len(xs)`.
3. Loop `while lo < hi`. If `xs[mid]` is true, set `hi = mid`; otherwise `lo = mid + 1`. Return `lo`.
