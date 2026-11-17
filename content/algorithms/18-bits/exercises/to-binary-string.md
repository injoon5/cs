---
id: to-binary-string
title: Binary by hand
level: warmup
---

Return the binary digits of a non-negative integer `n` as a string, with no `0b` and no leading zeros. Zero is `"0"`. Divide by 2 yourself instead of calling `bin` or `format`. `to_binary(13)` is `"1101"`.

```python starter
def to_binary(n):
    pass
```

```tests
to_binary(13) == "1101"
to_binary(0) == "0"
to_binary(1) == "1"
to_binary(2) == "10"
to_binary(8) == "1000"
to_binary(255) == "11111111"
to_binary(256) == "100000000"
to_binary(2**64) == "1" + "0" * 64
```

```python tests
for n in range(2000):
    assert to_binary(n) == bin(n)[2:]
n = 3**200
assert to_binary(n) == bin(n)[2:]
```

```python solution
def to_binary(n):
    if n == 0:
        return "0"
    digits = []
    while n > 0:
        digits.append(str(n % 2))
        n //= 2
    return "".join(reversed(digits))
```

## Hints

1. `n % 2` is the last bit of `n`, and `n // 2` is `n` with that bit removed.
2. Collect the bits in a list while `n > 0`. They come out from the right, so reverse them before joining. Zero never enters the loop, so handle it first.
3. In the loop: `digits.append(str(n % 2))`, then `n //= 2`. Return `"".join(reversed(digits))`.
