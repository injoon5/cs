---
id: bit-tricks
title: Bit tricks
---

Subtracting 1 borrows from the lowest 1 bit. That bit turns to 0, and every 0 below it turns to 1. Everything above stays the same. Here is 88, then 87:

```diagram
bits 0101 1000
highlight 4 5 6 7
bits 0101 0111
highlight 4 5 6 7
```

So `x & (x - 1)` keeps the high part and zeros the rest: it is `x` with its lowest 1 bit cleared. For 88 that is `0101 0000`, 80.

---

What does this print?

```python predict
for x in [12, 7, 16, 0b10110]:
    print(bin(x), bin(x & (x - 1)))
```

---

Clear the lowest 1 bit over and over, and the number reaches 0 after one pass per 1 bit. Counting the passes counts the bits. This is Kernighan's method. Run it to watch the bits go, lowest first.

```python
import viz

x = 0b1011_0100
count = 0
viz.bits(x, note="x = 180")
while x:
    lowest = (x ^ (x & (x - 1))).bit_length() - 1
    x &= x - 1
    count += 1
    viz.bits(x, highlight=lowest, note=f"cleared bit {lowest}, count = {count}")
```

---

```python trace stop=9
x = 22
count = 0
while x:
    x &= x - 1
    count += 1
print(count)
```

22 is `10110`. Two bits have been cleared. What is `x`?

- [ ] 20
- [x] 16
- [ ] 4

---

Kernighan's loop makes one pass per 1 bit, not one per bit. For a 64-bit number with three bits set, it makes

- [x] 3 passes
- [ ] 6 passes
- [ ] 64 passes

---

In practice, use the built-in. `x.bit_count()` counts the 1 bits of `x`. Before Python 3.10, people wrote `bin(x).count("1")`.

```python
x = 0b1011_0100
print(x.bit_count(), bin(x).count("1"))
```

---

A related trick: `x & -x` keeps only the lowest 1 bit. Since `-x` is `~x + 1`, the flip turns the zeros below that bit into ones, and the +1 carries through them back to the bit itself. Above it, `x` and `-x` disagree everywhere, so `&` clears them. What does this print?

```python predict
for x in [12, 7, 40]:
    print(x & -x)
```

---

A power of two has exactly one 1 bit. Clearing it leaves 0. Which test returns `True` exactly for the powers of two 1, 2, 4, 8, ...?

- [x] `x > 0 and x & (x - 1) == 0`
- [ ] `x & (x - 1) == 0`
- [ ] `x % 2 == 0`

---

`^` has three facts worth knowing by heart: `x ^ x == 0`, `x ^ 0 == x`, and the order of the operands doesn't matter. So xor-ing a list cancels every value that appears twice. What does this print?

```python predict
acc = 0
for x in [4, 1, 2, 1, 2]:
    acc ^= x
    print(acc)
```

---

The pairs cancelled and left 4, using one variable instead of a set or a count per value.

In a list, every value appears an even number of times except one, which appears three times. Xor-ing the whole list gives

- [ ] 0
- [x] that value
- [ ] that value times 3

---

[Count the 1 bits](exercises/count-set-bits.md)

[Power of two](exercises/power-of-two-check.md)

[The odd one out](exercises/xor-single-number.md)

[Missing number](exercises/xor-missing-number.md)
