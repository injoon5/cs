---
id: from-binary-string
title: Read a binary string
level: warmup
---

Return the value of a string of `"0"` and `"1"` characters, read as a binary number. Leading zeros are allowed, and the empty string is 0. Work through the digits yourself instead of calling `int(s, 2)`. `from_binary("1011")` is 11.

```python starter
def from_binary(s):
    pass
```

```tests
from_binary("1011") == 11
from_binary("") == 0
from_binary("0") == 0
from_binary("1") == 1
from_binary("0001") == 1
from_binary("11111111") == 255
from_binary("100000000") == 256
from_binary("1" * 64) == 2**64 - 1
```

```python tests
for n in range(2000):
    assert from_binary(bin(n)[2:]) == n
    assert from_binary(format(n, "016b")) == n
```

```python solution
def from_binary(s):
    value = 0
    for ch in s:
        value = value * 2 + int(ch)
    return value
```

## Hints

1. Read from the left. Each new digit pushes everything read so far one place to the left, which doubles it.
2. Start with `value = 0`. For each character, double `value` and add the digit.
3. `value = value * 2 + int(ch)` inside a loop over `s`.
