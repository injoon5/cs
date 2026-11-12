---
id: bit-strings
title: Bit strings
level: warmup
---

Return every string of `n` characters made of `"0"` and `"1"`, in increasing order. For `n = 2` that is `["00", "01", "10", "11"]`. For `n = 0` it is `[""]`, one empty string.

```python starter
def bit_strings(n):
    pass
```

```tests
bit_strings(2) == ["00", "01", "10", "11"]
bit_strings(1) == ["0", "1"]
bit_strings(0) == [""]
bit_strings(3) == ["000", "001", "010", "011", "100", "101", "110", "111"]
len(bit_strings(10)) == 1024
bit_strings(10)[0] == "0" * 10
bit_strings(10)[-1] == "1" * 10
len(set(bit_strings(12))) == 4096
```

```python tests
result = bit_strings(8)
assert result == sorted(result)
assert all(len(s) == 8 for s in result)
```

```python solution
def bit_strings(n):
    out = []

    def explore(prefix):
        if len(prefix) == n:
            out.append(prefix)
            return
        explore(prefix + "0")
        explore(prefix + "1")

    explore("")
    return out
```

## Hints

1. Each position is a choice between `"0"` and `"1"`. That is a tree with two branches at every level.
2. Build a prefix one character at a time. When it has `n` characters, save it.
3. Inside a helper `explore(prefix)`: save and return when `len(prefix) == n`, otherwise call `explore(prefix + "0")` and then `explore(prefix + "1")`.
