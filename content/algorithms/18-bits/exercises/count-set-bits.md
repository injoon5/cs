---
id: count-set-bits
title: Count the 1 bits
level: warmup
---

Return how many 1 bits the non-negative integer `x` has, using Kernighan's method: clear the lowest 1 bit until nothing is left. `count_ones(22)` is 3, since 22 is `10110`.

```python starter
def count_ones(x):
    pass
```

```tests
count_ones(22) == 3
count_ones(0) == 0
count_ones(1) == 1
count_ones(8) == 1
count_ones(255) == 8
count_ones(2**64) == 1
count_ones(2**64 - 1) == 64
```

```python tests
for x in range(5000):
    assert count_ones(x) == x.bit_count()
assert count_ones(3**500) == (3**500).bit_count()
```

```python solution
def count_ones(x):
    count = 0
    while x:
        x &= x - 1
        count += 1
    return count
```

## Hints

1. `x & (x - 1)` is `x` with its lowest 1 bit cleared.
2. Clear one bit per pass and count the passes. Stop when `x` is 0.
3. `while x:` do `x &= x - 1` and `count += 1`.
