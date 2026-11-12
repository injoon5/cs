---
id: power-mod
title: Power with a modulus
level: core
---

Return `x ** n % m` without computing `x ** n` itself, which would be enormous. `n` can be as large as `10 ** 18`, so multiplying `n` times is far too slow. Use the halving idea: `x ** n` is `(x ** (n // 2)) ** 2`, times one more `x` when `n` is odd. Take `% m` after every multiplication to keep numbers small.

For `x = 3`, `n = 5`, `m = 7`: `3 ** 5` is 243, and `243 % 7` is 5.

Write it with recursion, without the built-in three-argument `pow`. `x` and `n` are 0 or more, and `m` is at least 1.

```python starter
def power_mod(x, n, m):
    pass
```

```tests
power_mod(3, 5, 7) == 5
power_mod(2, 10, 1000) == 24
power_mod(5, 0, 7) == 1
power_mod(5, 0, 1) == 0
power_mod(0, 0, 5) == 1
power_mod(0, 3, 5) == 0
power_mod(7, 1, 10) == 7
power_mod(10, 3, 9) == 1
power_mod(2, 10 ** 18, 1_000_000_007) == 719476260
power_mod(123456789, 987654321, 998244353) == pow(123456789, 987654321, 998244353)
```

```python solution
def power_mod(x, n, m):
    if n == 0:
        return 1 % m
    half = power_mod(x, n // 2, m)
    result = half * half % m
    if n % 2 == 1:
        result = result * x % m
    return result
```

## Hints

1. `power_mod(x, n, m)` only needs `power_mod(x, n // 2, m)`. Call it once and reuse the result.
2. Square the half result, then multiply by `x` once more if `n` is odd. Apply `% m` after each multiplication.
3. Base case: `n == 0` returns `1 % m`, which handles `m == 1`. Then `half = power_mod(x, n // 2, m)`, `result = half * half % m`, and if `n % 2 == 1`, `result = result * x % m`.
