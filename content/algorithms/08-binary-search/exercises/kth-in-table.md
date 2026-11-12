---
id: kth-in-table
title: Kth in a multiplication table
level: stretch
---

The `m` by `n` multiplication table holds `i * j` for every `i` from 1 to `m` and `j` from 1 to `n`. Return the `k`th smallest number in it, counting from 1 and counting repeats. The 3 by 3 table holds 1, 2, 2, 3, 3, 4, 6, 6, 9, so for `k = 5` the answer is 3. Don't build the table: `m` and `n` can be 30,000.

```python starter
def kth_in_table(m, n, k):
    pass
```

```tests
kth_in_table(3, 3, 5) == 3
kth_in_table(3, 3, 1) == 1
kth_in_table(3, 3, 9) == 9
kth_in_table(3, 3, 7) == 6
kth_in_table(2, 3, 6) == 6
kth_in_table(1, 1, 1) == 1
kth_in_table(1, 5, 4) == 4
kth_in_table(5, 1, 2) == 2
kth_in_table(30_000, 30_000, 450_000_000) == 168_028_638
```

```python tests
for m in range(1, 7):
    for n in range(1, 7):
        table = sorted(i * j for i in range(1, m + 1) for j in range(1, n + 1))
        for k in range(1, m * n + 1):
            assert kth_in_table(m, n, k) == table[k - 1], (m, n, k)
```

```python solution
def kth_in_table(m, n, k):
    def count_at_most(x):
        return sum(min(x // i, n) for i in range(1, m + 1))

    lo, hi = 1, m * n
    while lo < hi:
        mid = (lo + hi) // 2
        if count_at_most(mid) >= k:
            hi = mid
        else:
            lo = mid + 1
    return lo
```

## Hints

1. Search over values, not positions. The answer is the smallest `x` with at least `k` numbers in the table that are `<= x`.
2. Row `i` holds `i, 2i, ..., n·i`, so it has `min(x // i, n)` numbers that are at most `x`. Adding that over the rows takes O(m).
3. Search `lo, hi = 1, m * n`. If `count_at_most(mid) >= k`, set `hi = mid`, else `lo = mid + 1`. The `lo` you end on is always in the table.
