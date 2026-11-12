---
id: euclid-gcd
title: Greatest common divisor
level: warmup
---

Return the greatest common divisor of `a` and `b`, the largest number that divides both. Both are 0 or more, and `gcd(0, 0)` is 0. Use Euclid's rule: `gcd(a, b)` equals `gcd(b, a % b)`, and `gcd(a, 0)` is `a`. For `gcd(12, 18)`: `gcd(18, 12)`, then `gcd(12, 6)`, then `gcd(6, 0)`, which is 6.

Write it with recursion, without `math.gcd`.

```python starter
def gcd(a, b):
    pass
```

```tests
gcd(12, 18) == 6
gcd(18, 12) == 6
gcd(7, 13) == 1
gcd(10, 10) == 10
gcd(0, 5) == 5
gcd(5, 0) == 5
gcd(0, 0) == 0
gcd(1, 999) == 1
gcd(2 ** 40, 6 ** 20) == 2 ** 20
gcd(832040, 514229) == 1
```

```python tests
import math
import random

for _ in range(200):
    a = random.randint(0, 10 ** 12)
    b = random.randint(0, 10 ** 12)
    assert gcd(a, b) == math.gcd(a, b), (a, b)
```

```python solution
def gcd(a, b):
    if b == 0:
        return a
    return gcd(b, a % b)
```

## Hints

1. The rule already says what the smaller problem is. What is the base case?
2. When `b` is 0, the answer is `a`. Otherwise call `gcd` again with `b` and the remainder.
3. `if b == 0: return a`, then `return gcd(b, a % b)`.
