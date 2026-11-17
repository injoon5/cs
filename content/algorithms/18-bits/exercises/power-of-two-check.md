---
id: power-of-two-check
title: Power of two
level: warmup
---

Return `True` if the integer `n` is a power of two (1, 2, 4, 8, ...) and `False` otherwise, in O(1) with bit operations and no loop. `n` can be zero or negative. `is_power_of_two(16)` is `True` and `is_power_of_two(12)` is `False`.

```python starter
def is_power_of_two(n):
    pass
```

```tests
is_power_of_two(16) == True
is_power_of_two(12) == False
is_power_of_two(1) == True
is_power_of_two(2) == True
is_power_of_two(3) == False
is_power_of_two(0) == False
is_power_of_two(-8) == False
is_power_of_two(-1) == False
is_power_of_two(2**100) == True
is_power_of_two(2**100 + 2**50) == False
```

```python tests
powers = {1 << k for k in range(80)}
for n in range(-100, 5000):
    assert is_power_of_two(n) == (n in powers)
```

```python solution
def is_power_of_two(n):
    return n > 0 and n & (n - 1) == 0
```

## Hints

1. A power of two has exactly one 1 bit.
2. Clearing the lowest 1 bit of a power of two leaves 0. Zero and negative numbers need their own check.
3. `n > 0 and n & (n - 1) == 0`.
