---
id: n-queens-count
title: Count n-queens solutions
level: stretch
---

Return how many ways there are to place `n` queens on an `n × n` board so that no two share a row, a column or a diagonal. For `n = 4` there are 2. One of them:

```
. Q . .
. . . Q
Q . . .
. . Q .
```

An empty board, `n = 0`, counts as one way.

```python starter
def n_queens(n):
    pass
```

```tests
n_queens(4) == 2
n_queens(1) == 1
n_queens(2) == 0
n_queens(3) == 0
n_queens(5) == 10
n_queens(6) == 4
n_queens(8) == 92
n_queens(9) == 352
n_queens(0) == 1
```

```python solution
def n_queens(n):
    cols = set()
    downs = set()
    ups = set()

    def place(r):
        if r == n:
            return 1
        count = 0
        for c in range(n):
            if c in cols or r - c in downs or r + c in ups:
                continue
            cols.add(c)
            downs.add(r - c)
            ups.add(r + c)
            count += place(r + 1)
            cols.remove(c)
            downs.remove(r - c)
            ups.remove(r + c)
        return count

    return place(0)
```

## Hints

1. Every row gets exactly one queen. Place them one row at a time, so rows never clash.
2. A square `(r, c)` is attacked when its column, its `r - c` diagonal or its `r + c` diagonal is already taken. Keep a set for each.
3. `place(r)` returns 1 when `r == n`. Otherwise, for each free column, add to the three sets, add `place(r + 1)` to a count, then remove from the sets.
