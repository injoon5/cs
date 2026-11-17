---
id: exact-money-sum
title: Exact price total
level: core
---

`prices` is a list of prices written as strings, like `"19.99"`. Return their exact total as a string, with exactly two digits after the point. Floats would round, so use `Decimal` or whole cents. Prices have at most two digits after the point, and refunds are negative. An empty list totals `"0.00"`.

`price_total(["0.10", "0.20"])` is `"0.30"`, where adding the floats would give 0.30000000000000004.

```python starter
def price_total(prices):
    pass
```

```tests
price_total(["0.10", "0.20"]) == "0.30"
price_total([]) == "0.00"
price_total(["5"]) == "5.00"
price_total(["19.99", "0.01"]) == "20.00"
price_total(["10.00", "-2.50"]) == "7.50"
price_total(["-0.10", "-0.20"]) == "-0.30"
price_total(["0.10"] * 3) == "0.30"
price_total(["0.10"] * 10) == "1.00"
price_total(["1.5", "2.25"]) == "3.75"
price_total(["90071992547409.93", "0.01"]) == "90071992547409.94"
```

```python tests
import random


def fmt(cents):
    sign = "-" if cents < 0 else ""
    return f"{sign}{abs(cents) // 100}.{abs(cents) % 100:02d}"


for _ in range(300):
    cents = [random.randint(-100000, 100000) for _ in range(random.randint(0, 20))]
    assert price_total([fmt(c) for c in cents]) == fmt(sum(cents))
```

```python solution
from decimal import Decimal


def price_total(prices):
    total = sum((Decimal(p) for p in prices), Decimal("0"))
    return str(total.quantize(Decimal("0.01")))
```

## Hints

1. Each string can be read exactly. The rounding only creeps in when it becomes a float.
2. Turn each string into a `Decimal` and add them, starting from `Decimal("0")`. Then fix the result to two places.
3. `total.quantize(Decimal("0.01"))` rounds to two places, and `str` of that is the answer.
