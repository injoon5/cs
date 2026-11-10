---
id: growth-rates
title: Big-O and growth rates
---

Two programs solve the same problem. One takes `10n + 50` steps, the other `n * n / 2`. Run this to compare them.

```python
for n in [10, 100, 1000, 10000]:
    print(n, 10 * n + 50, n * n // 2)
```

At `n = 10` the second one is cheaper. By `n = 100` it's about five times slower, and the gap keeps widening.

---

For large inputs, only the fastest-growing term matters. Constants and smaller terms fade.

Big-O names that term. `10n + 50` is O(n). `n * n / 2` is O(n²). Formally, `f(n)` is O(`g(n)`) if `f(n) ≤ c · g(n)` for some fixed `c` once `n` is big enough.

---

What is `4n² + 100n + 7` in Big-O?

- [ ] O(n)
- [x] O(n²)
- [ ] O(4n²)
- [ ] O(n² + n)

---

Some loops shrink the problem instead of stepping through it. What does this print?

```python predict
n = 1000
count = 0
while n > 1:
    n //= 2
    count += 1
print(count)
```

---

Each pass throws away half of what's left. Here, 8 items become 4 after one pass.

```diagram
array [3, 8, 12, 19, 25, 31, 40, 47]
pointer lo 4
pointer hi 7
shade 4..7
```

Halving from `n` down to 1 takes about log₂ n passes. A million items need only 20. That's O(log n).

---

The common growth rates, slowest first:

O(1), O(log n), O(n), O(n log n), O(n²), O(2ⁿ)

Here they are at `n = 20`:

```python
import math

n = 20
print(1, round(math.log2(n)), n, round(n * math.log2(n)), n ** 2, 2 ** n)
```

---

This checks a list for a repeated value.

```python
def has_duplicate(xs):
    for i in range(len(xs)):
        for j in range(i + 1, len(xs)):
            if xs[i] == xs[j]:
                return True
    return False
```

What is its worst-case running time?

- [ ] O(n)
- [ ] O(n log n)
- [x] O(n²)

---

[Halvings](exercises/halvings.md)

---

[Has duplicate](exercises/has-duplicate.md)
