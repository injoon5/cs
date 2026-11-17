---
id: gray-code-sequence
title: Gray code
level: stretch
---

A Gray code lists every n-bit number once, starting at 0, so that each number differs from the one before it in exactly one bit. As masks, it walks through every subset of n items by adding or removing one item per step.

Return the reflected Gray code for `n` as a list of ints. For n bits, take the list for n - 1 bits, then the same list reversed with bit n - 1 set on each number. For n = 0 the list is `[0]`.

`gray_code(2)` is `[0, 1, 3, 2]`, which is `00`, `01`, `11`, `10`.

```python starter
def gray_code(n):
    pass
```

```tests
gray_code(2) == [0, 1, 3, 2]
gray_code(0) == [0]
gray_code(1) == [0, 1]
gray_code(3) == [0, 1, 3, 2, 6, 7, 5, 4]
gray_code(4)[8:] == [12, 13, 15, 14, 10, 11, 9, 8]
len(gray_code(16)) == 65536
```

```python tests
for n in range(13):
    code = gray_code(n)
    assert len(code) == 2**n
    assert sorted(code) == list(range(2**n))
    assert code[0] == 0
    for a, b in zip(code, code[1:]):
        assert (a ^ b).bit_count() == 1
    if n > 0:
        half = gray_code(n - 1)
        assert code == half + [x | 1 << (n - 1) for x in reversed(half)]
```

```python solution
def gray_code(n):
    code = [0]
    for k in range(n):
        code += [x | 1 << k for x in reversed(code)]
    return code
```

## Hints

1. The second half is the first half backwards, so where the halves meet, the two numbers are the same apart from the new top bit.
2. Start from `[0]` and grow the list n times. Each round appends the list reversed, with the next bit set on each number.
3. For `k` in `range(n)`: `code += [x | 1 << k for x in reversed(code)]`. There is also a one-line formula worth checking against it: number `i` is `i ^ (i >> 1)`.
