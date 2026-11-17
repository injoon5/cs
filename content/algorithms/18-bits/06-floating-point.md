---
id: floating-point-numbers
title: Floating point
---

What does this print?

```python predict
print(0.1 + 0.2)
print(0.1 + 0.2 == 0.3)
```

---

A float is a binary fraction, and 1/10 has no exact binary form. In decimal, 1/3 is 0.333... forever. In binary, 1/10 is 0.000110011001100... forever. A float keeps 53 significant bits and rounds the rest away, so `0.1` is stored as a number very slightly above 0.1.

`Decimal` can print the exact value a float holds:

```python
from decimal import Decimal

print(Decimal(0.1))
print(Decimal(0.5))
```

0.5 is 1/2, a power of two, so it is exact.

---

Which of these is stored exactly as a float?

- [x] 0.375
- [ ] 0.1
- [ ] 0.3

---

A float has three parts in 64 bits: 1 sign bit, 11 exponent bits and 52 fraction bits. The value is 1.fraction × 2ᵉ, where e comes from the exponent bits. It is scientific notation in base 2, like 6.02 × 10²³ in base 10. The leading 1 isn't stored, which is where the 53rd bit comes from.

`float.hex` shows the parts without the rounding to decimal. After `0x1.` come 52 fraction bits as 13 hex digits, and after `p` the power of two.

```python
print((0.5).hex())
print((0.375).hex())
print((0.1).hex())
```

0.1 is 1.6 × 2⁻⁴. The repeating `9`s are `1001`, the pattern from 1/10, and the last digit rounds up to `a`.

---

Because results round, compare floats with a tolerance. `math.isclose` checks that two numbers agree to about 9 significant digits. Near zero there are no significant digits to agree on, so give it an absolute tolerance too. What does this print?

```python predict
import math

print(math.isclose(0.1 + 0.2, 0.3))
print(math.isclose(1e-20, 0.0))
print(math.isclose(1e-20, 0.0, abs_tol=1e-12))
```

---

53 bits also limit whole numbers. Every integer up to 2⁵³ fits in a float exactly. Past that, the gap between neighboring floats is 2 or more, so some integers get rounded. Python ints don't have this limit, and only lose digits when they turn into floats. What does this print?

```python predict
n = 2**53 + 1
print(n)
print(float(n))
print(int(float(n)) == n)
```

---

`/` always returns a float, even for two ints. Use `//` when you want an exact integer result from large numbers.

You need the exact average of two huge ints, rounded down. Which is right?

- [x] `(a + b) // 2`
- [ ] `int((a + b) / 2)`
- [ ] `round((a + b) / 2)`

---

When you need exact answers, don't use floats. `fractions.Fraction` stores a fraction as two ints, and `decimal.Decimal` does arithmetic in base 10, which is why it suits money.

```python
from decimal import Decimal
from fractions import Fraction

print(Fraction(1, 10) + Fraction(2, 10) == Fraction(3, 10))
print(Decimal("0.1") + Decimal("0.2"))
print(Decimal(0.1) + Decimal(0.2))
```

Build a `Decimal` from a string. `Decimal(0.1)` copies the float, error included. `Decimal` still rounds what has no short decimal form, like 1/3.

---

A shop app adds up prices. Which ways give exact totals?

- [x] Store prices as whole cents in ints
- [x] Use `Decimal("19.99")` for each price
- [ ] Use `Decimal(19.99)` for each price
- [ ] Add floats and compare with `math.isclose`

---

[Exact price total](exercises/exact-money-sum.md)
