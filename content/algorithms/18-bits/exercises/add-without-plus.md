---
id: add-without-plus
title: Add without plus
level: stretch
---

Return `a + b` for two 32-bit signed integers, using only bitwise operators: no `+`, `-` or `sum` on the numbers themselves. Like a 32-bit machine, the result wraps around: `add(2**31 - 1, 1)` is `-2**31`. `add(5, 3)` is 8.

The masking constants `MASK` and `SIGN` are given, and the last line, which turns the low 32 bits back into a signed number, may use `-`.

```python starter
MASK = 0xFFFFFFFF
SIGN = 1 << 31


def add(a, b):
    a &= MASK
    b &= MASK
    pass
    return a - (1 << 32) if a & SIGN else a
```

```tests
add(5, 3) == 8
add(0, 0) == 0
add(1, -1) == 0
add(-5, 3) == -2
add(-7, -8) == -15
add(100, 0) == 100
add(0, -100) == -100
add(2**31 - 1, 1) == -2**31
add(-2**31, -1) == 2**31 - 1
add(123456789, 987654321) == 1111111110
```

```python tests
import random

low, high = -2**31, 2**31 - 1
for _ in range(1000):
    a = random.randint(low, high)
    b = random.randint(low, high)
    want = (a + b + 2**31) % 2**32 - 2**31
    assert add(a, b) == want
```

```python solution
MASK = 0xFFFFFFFF
SIGN = 1 << 31


def add(a, b):
    a &= MASK
    b &= MASK
    while b:
        carry = (a & b) << 1 & MASK
        a = a ^ b
        b = carry
    return a - (1 << 32) if a & SIGN else a
```

## Hints

1. Add bit by bit with no carries, then add the carries in a second round. `a ^ b` is the sum without carries. A carry happens where both bits are 1.
2. The carries are `(a & b) << 1`. Add them to `a ^ b` the same way, and repeat until there are no carries left. Mask with `MASK` each round so a carry off the top bit disappears, like on a real 32-bit machine.
3. `while b:` set `carry = (a & b) << 1 & MASK`, `a = a ^ b`, `b = carry`.
