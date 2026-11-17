---
id: binary-and-bases
title: Binary and other bases
---

In 413, the 4 is worth 400 because of where it sits. Each place is worth ten times the place to its right: 4 × 100 + 1 × 10 + 3 × 1.

Binary works the same way with two digits, 0 and 1, and places worth powers of 2. From the right they are worth 1, 2, 4, 8 and so on.

```diagram
bits 1101
group 4
```

This is 8 + 4 + 0 + 1 = 13. Each digit is a bit.

---

Python reads and writes binary directly. `0b` starts a binary literal, `bin` writes a number in binary, and `int` with a base reads a string back.

```python
print(0b1101)
print(bin(13))
print(int("1101", 2))
print(format(13, "08b"))
```

`format(x, "08b")` pads to 8 digits and leaves off the `0b`.

---

Base 16, hexadecimal, uses the digits 0 to 9 and then a to f for 10 to 15. One hex digit covers exactly four bits, so hex is a short way to write long binary numbers.

```diagram
bits 1111 0101
group 4
```

`1111` is f and `0101` is 5, so this byte is `0xf5`, which is 15 × 16 + 5 = 245.

---

What does this print?

```python predict
print(bin(10), int("111", 2), hex(31), 0b100 + 1)
```

---

To write a number in binary by hand, divide by 2 over and over. `n % 2` is the last bit, and `n // 2` drops it. The bits come out right to left, so reverse them at the end.

```python trace stop=9
n = 13
digits = []
while n > 0:
    digits.append(n % 2)
    n //= 2
digits.reverse()
print(digits)
```

Two passes are done. What are `n` and `digits`?

- [ ] `n` is 6, `digits` is `[1, 0]`
- [x] `n` is 3, `digits` is `[1, 0]`
- [ ] `n` is 3, `digits` is `[0, 1]`

---

Reading goes the other way. Start at 0, and for each bit from the left, double what you have and add the bit. Doubling shifts every bit read so far one place left. What does this print?

```python predict
value = 0
for ch in "1011":
    value = value * 2 + int(ch)
    print(value)
```

---

What is `0b10110` in decimal?

- [ ] 13
- [x] 22
- [ ] 44

---

Each extra bit doubles how many values fit: k bits hold 2ᵏ of them, 0 to 2ᵏ - 1. So a number n needs about log₂ n bits. `int.bit_length` gives the exact count.

```python
for n in [1, 7, 8, 255, 256, 1000, 10**6]:
    print(n, n.bit_length())
```

A million fits in 20 bits. 8 needs 4 bits, one more than 7, because it is the first number past 2³ - 1.

---

The conversion loop makes one pass per bit of `n`. It costs

- [ ] O(1)
- [x] O(log n)
- [ ] O(n)

---

[Binary by hand](exercises/to-binary-string.md)

[Read a binary string](exercises/from-binary-string.md)
