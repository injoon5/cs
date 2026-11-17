---
id: signed-byte
title: Read a signed byte
level: core
---

`bits` is a string of exactly 8 characters, `"0"` or `"1"`, highest bit first. Return the number it holds in 8-bit two's complement, from -128 to 127. `signed_byte("11111011")` is -5.

```python starter
def signed_byte(bits):
    pass
```

```tests
signed_byte("11111011") == -5
signed_byte("00000101") == 5
signed_byte("00000000") == 0
signed_byte("11111111") == -1
signed_byte("01111111") == 127
signed_byte("10000000") == -128
signed_byte("10000001") == -127
```

```python tests
for x in range(-128, 128):
    assert signed_byte(format(x & 0xFF, "08b")) == x
```

```python solution
def signed_byte(bits):
    value = int(bits, 2)
    if bits[0] == "1":
        value -= 256
    return value
```

## Hints

1. Read the byte as an ordinary number from 0 to 255 first. Then fix up the top bit.
2. The top bit counts +128 in the plain reading but should count -128. That is off by 256.
3. `value = int(bits, 2)`, and subtract 256 when `bits[0] == "1"`.
