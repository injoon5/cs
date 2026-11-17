---
id: twos-complement
title: Negative numbers
---

Hardware stores a number in a fixed number of bits. A byte has 8 bits and so 256 patterns, enough for 0 to 255.

To fit negative numbers in the same 256 patterns, almost every machine uses two's complement: the top bit is worth -128 instead of +128. Every other bit keeps its usual worth.

```diagram
bits 1111 1011
highlight 0
```

That is -128 + 64 + 32 + 16 + 8 + 2 + 1 = -5. A byte now holds -128 to 127, and the top bit tells you the sign.

---

To negate a number, flip every bit and add 1. Here is 5, then its bits flipped, then plus 1, which is -5:

```diagram
bits 0000 0101
bits 1111 1010
bits 1111 1011
```

---

Why flip and add 1? A number and its flipped bits add up to all ones, `1111 1111`, which is -1. So flipped `x` is `-x - 1`, and adding 1 gives `-x`.

The payoff is that adding needs no special case for signs. 5 + (-5) is `0000 0101` + `1111 1011` = `1 0000 0000`. The ninth bit doesn't fit in the byte and falls off, leaving 0. The same adder circuit works for signed and unsigned numbers.

---

In 8-bit two's complement, which byte holds -1?

- [x] `1111 1111`
- [ ] `1000 0001`
- [ ] `1111 1110`

---

Fixed width means a sum can fall off the end. Run this to count up past 127 in one byte. The bits carry the way they always do, but the top bit turns on and the value jumps to -128. This is overflow.

```python
import viz

for x in [125, 126, 127, -128, -127]:
    viz.bits(x, width=8, highlight=7, note=str(x))
```

---

`wrap8` keeps the low 8 bits of a result and reads them as two's complement, like a byte would. What does this print?

```python predict
def wrap8(x):
    x &= 0xFF
    if x >= 128:
        x -= 256
    return x

print(wrap8(127 + 1), wrap8(100 + 100), wrap8(-128 - 1))
```

---

Python's ints never overflow. They grow as needed, so `2**100` is exact. For bit operations, a Python int acts as if its sign bit went on forever to the left: 5 is `...0000 0101` and -5 is `...1111 1011`.

That gives three rules: `~x` is `-x - 1`, `x & 0xFF` shows the low byte, and `bin` writes a minus sign instead of the bits. What does this print?

```python predict
print(~5, ~-1, -5 & 0xFF, bin(-5))
```

---

`>>` copies the sign bit in from the left, so a negative number stays negative. That makes `x >> 1` equal to `x // 2`, which rounds down. What is `-7 >> 1` in Python?

- [x] -4
- [ ] -3
- [ ] 124

---

To act like a 32-bit machine in Python, keep the low 32 bits with `x & 0xFFFFFFFF` after each step. At the end, read bit 31 as the sign.

```python
MASK = 0xFFFFFFFF

def to_signed32(x):
    x &= MASK
    return x - (1 << 32) if x >> 31 else x

print(hex(-1 & MASK))
print(to_signed32(0xFFFFFFFF))
print(to_signed32(2**31 - 1 + 1))
```

---

[Read a signed byte](exercises/signed-byte.md)

[Add without plus](exercises/add-without-plus.md)
