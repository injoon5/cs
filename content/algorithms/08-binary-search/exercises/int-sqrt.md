---
id: int-sqrt
title: Integer square root
level: warmup
---

`n` is at least 0. Return the largest whole number `k` with `k * k <= n`. For 30 that is 5, since 25 fits and 36 doesn't. Use a binary search, not `math.sqrt`, `math.isqrt` or `** 0.5`.

```python starter
def int_sqrt(n):
    pass
```

```tests
int_sqrt(30) == 5
int_sqrt(36) == 6
int_sqrt(35) == 5
int_sqrt(0) == 0
int_sqrt(1) == 1
int_sqrt(2) == 1
int_sqrt(3) == 1
int_sqrt(4) == 2
int_sqrt(10 ** 12) == 10 ** 6
int_sqrt(10 ** 12 - 1) == 10 ** 6 - 1
int_sqrt(10 ** 40) == 10 ** 20
```

```python tests
import math
for n in range(2000):
    assert int_sqrt(n) == math.isqrt(n), n
```

```python solution
def int_sqrt(n):
    lo, hi = 0, n + 1
    while lo < hi:
        mid = (lo + hi) // 2
        if mid * mid > n:
            hi = mid
        else:
            lo = mid + 1
    return lo - 1
```

## Hints

1. "Is `k * k` bigger than `n`?" is no for small `k` and yes from some point on.
2. Find the first `k` where it is yes, searching from 0 to `n + 1`. The answer is one less.
3. Half-open search: if `mid * mid > n`, set `hi = mid`, else `lo = mid + 1`. Return `lo - 1`.
