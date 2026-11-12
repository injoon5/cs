---
id: digit-sum
title: Digit sum
level: warmup
---

Return the sum of the decimal digits of `n`, using recursion instead of a loop. `n` is 0 or more. For `472` the answer is `4 + 7 + 2 = 13`.

```python starter
def digit_sum(n):
    pass
```

```tests
digit_sum(472) == 13
digit_sum(0) == 0
digit_sum(7) == 7
digit_sum(10) == 1
digit_sum(99) == 18
digit_sum(1000) == 1
digit_sum(11111) == 5
digit_sum(987654321) == 45
digit_sum(10 ** 50) == 1
```

```python solution
def digit_sum(n):
    if n < 10:
        return n
    return n % 10 + digit_sum(n // 10)
```

## Hints

1. `n % 10` is the last digit, and `n // 10` is the number with that digit removed.
2. A number below 10 is its own digit sum. That is the base case.
3. Return `n % 10 + digit_sum(n // 10)` when `n` has more than one digit.
