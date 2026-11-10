---
id: halvings
title: Halvings
level: warmup
---

Return how many times you can replace `n` with `n // 2` before it reaches 1. `n` is at least 1.

For example, 10 goes 10 → 5 → 2 → 1, so `halvings(10)` is 3.

```python starter
def halvings(n):
    pass
```

```tests
halvings(1) == 0
halvings(2) == 1
halvings(3) == 1
halvings(10) == 3
halvings(1024) == 10
halvings(1023) == 9
halvings(10 ** 6) == 19
```

```python solution
def halvings(n):
    count = 0
    while n > 1:
        n //= 2
        count += 1
    return count
```

## Hints

1. Count passes of a loop, not items.
2. Loop while `n > 1`. Each pass, halve `n` and add one to a counter.
3. `while n > 1: n //= 2; count += 1`, then return `count`.
