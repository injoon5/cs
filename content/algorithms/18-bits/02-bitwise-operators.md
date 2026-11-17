---
id: bitwise-operators
title: Bitwise operators
---

The bitwise operators work on each bit position on its own, with no carries between positions. Take 12 and 10:

```diagram
bits 1100
group 4
bits 1010
group 4
```

- `&` (and) keeps a 1 where both have a 1: `1000`.
- `|` (or) keeps a 1 where either has a 1: `1110`.
- `^` (xor) keeps a 1 where they differ: `0110`.

---

6 is `110` and 3 is `011`. What does this print?

```python predict
print(6 & 3, 6 | 3, 6 ^ 3)
```

---

`x << k` moves every bit k places left and fills the gap with zeros. Each place left doubles a bit's worth, so `x << k` is `x * 2**k`. Here is 22, then `22 << 2`:

```diagram
bits 0001 0110
bits 0101 1000
```

`x >> k` moves the bits right and drops the k lowest. That is `x // 2**k`.

---

What does this print?

```python predict
print(5 << 3, 100 >> 2, 7 >> 1, 1 << 10)
```

---

`1 << k` has a single 1, at bit k. Bits are numbered from the right, starting at 0. A number like this is called a mask, and with it you can read or change one bit and leave the rest alone.

```python
x = 0b0110_0101
k = 3
print(x >> k & 1)                       # read bit k: 0 or 1
print(format(x | (1 << k), "08b"))      # set it to 1
print(format(x & ~(1 << 2), "08b"))     # clear bit 2 to 0
print(format(x ^ (1 << 0), "08b"))      # toggle bit 0
```

`~` flips every bit, so `~(1 << 2)` has a 0 only at bit 2. The next lesson shows what `~` gives as a number. An `_` inside a literal is only for reading; Python ignores it.

---

Shifts bind tighter than `&`, and `&` tighter than `^` and `|`. All of them bind looser than `+` and `-`, and tighter than comparisons. So `x >> k & 1` means `(x >> k) & 1`, but `1 << k + 1` means `1 << (k + 1)`. Add brackets when in doubt.

---

13 is `1101`. What is `13 & (1 << 2)`?

- [ ] 1
- [x] 4
- [ ] `True`

---

Put the lines in order so `to_bits` writes the lowest `width` bits of `x`, highest bit first.

```python arrange
def to_bits(x, width):
    out = ""
    for k in range(width - 1, -1, -1):
        if x >> k & 1:
            out += "1"
        else:
            out += "0"
    return out
```

```tests
to_bits(5, 4) == "0101"
to_bits(6, 3) == "110"
to_bits(0, 3) == "000"
to_bits(255, 8) == "11111111"
to_bits(13, 2) == "01"
```

---

`x ^ y` has a 1 exactly where `x` and `y` differ. To count the positions where two numbers differ, you would

- [ ] count the 1 bits of `x & y`
- [x] count the 1 bits of `x ^ y`
- [ ] compute `abs(x - y)`

---

[Total Hamming distance](exercises/total-hamming-distance.md)

[Reverse 32 bits](exercises/reverse-bits-32.md)
