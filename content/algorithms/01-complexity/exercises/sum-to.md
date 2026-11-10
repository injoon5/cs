---
id: sum-to
title: Sum to n
level: warmup
---

Return `1 + 2 + ... + n`. Return 0 when `n` is 0. It has to work for `n` up to 10¹², so a loop is too slow.

```python starter
def sum_to(n):
    total = 0
    for k in range(1, n + 1):
        total += k
    return total
```

```tests
sum_to(0) == 0
sum_to(1) == 1
sum_to(4) == 10
sum_to(100) == 5050
sum_to(10 ** 12) == 500000000000500000000000
```

```python solution
def sum_to(n):
    return n * (n + 1) // 2
```

## Hints

1. The loop is O(n). You need an answer in O(1).
2. Write the numbers forward, then backward underneath. Each column adds to the same value.
3. There are `n` columns, each adding to `n + 1`, and that counts every number twice.
