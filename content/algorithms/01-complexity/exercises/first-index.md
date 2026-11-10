---
id: first-index
title: First index
level: warmup
---

Return the index of the first item in `xs` equal to `target`, or -1 if there is none. Don't use `xs.index`.

```python starter
def first_index(xs, target):
    pass
```

```tests
first_index([], 3) == -1
first_index([3], 3) == 0
first_index([7, 2, 9, 4, 5], 4) == 3
first_index([7, 2, 9, 4, 5], 8) == -1
first_index([1, 2, 1, 2], 2) == 1
first_index([0] * 1000 + [1], 1) == 1000
```

```python solution
def first_index(xs, target):
    for i in range(len(xs)):
        if xs[i] == target:
            return i
    return -1
```

## Hints

1. Check the items one at a time, from the front.
2. Loop over indexes and stop at the first match.
3. Return `i` as soon as `xs[i] == target`. After the loop, return -1.
