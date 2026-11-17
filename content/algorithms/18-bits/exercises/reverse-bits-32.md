---
id: reverse-bits-32
title: Reverse 32 bits
level: core
---

Treat `x` as a 32-bit number, with leading zeros up to 32 bits, and return the number you get by reversing the order of those 32 bits. `0 <= x < 2**32`.

`1` is 31 zeros and then a 1. Reversed, the 1 comes first, so `reverse_bits(1)` is `2**31`, which is 2147483648.

```python starter
def reverse_bits(x):
    pass
```

```tests
reverse_bits(1) == 2147483648
reverse_bits(0) == 0
reverse_bits(2**31) == 1
reverse_bits(2**32 - 1) == 2**32 - 1
reverse_bits(0b1011) == 0b1101 << 28
reverse_bits(43261596) == 964176192
reverse_bits(0xF0000000) == 0x0000000F
reverse_bits(0x80000001) == 0x80000001
```

```python tests
import random

for _ in range(500):
    x = random.randrange(2**32)
    want = int(format(x, "032b")[::-1], 2)
    assert reverse_bits(x) == want
    assert reverse_bits(reverse_bits(x)) == x
```

```python solution
def reverse_bits(x):
    out = 0
    for _ in range(32):
        out = out << 1 | x & 1
        x >>= 1
    return out
```

## Hints

1. Take bits off the low end of `x` one at a time, and push each one onto the low end of the answer. The first bit taken ends up highest.
2. Repeat exactly 32 times, even when `x` runs out of 1 bits early. The leading zeros of `x` become trailing zeros of the answer.
3. In the loop: `out = out << 1 | x & 1`, then `x >>= 1`.
