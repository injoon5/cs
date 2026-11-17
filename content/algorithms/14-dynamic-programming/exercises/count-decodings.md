---
id: count-decodings
title: Count decodings
level: core
---

A message of letters was encoded as numbers, with A as 1, B as 2, and so on up to Z as 26, and the numbers were written together with no spaces. Return how many ways the digit string `s` can be decoded.

`"226"` has 3 decodings: 2 2 6 (BBF), 22 6 (VF) and 2 26 (BZ). No letter is 0, so a `"0"` can only be the second digit of 10 or 20, and `"06"` has no decoding. The empty string has one decoding, the empty message.

```python starter
def num_decodings(s):
    pass
```

```tests
num_decodings("226") == 3
num_decodings("12") == 2
num_decodings("") == 1
num_decodings("7") == 1
num_decodings("0") == 0
num_decodings("06") == 0
num_decodings("10") == 1
num_decodings("27") == 1
num_decodings("100") == 0
num_decodings("101") == 1
num_decodings("11106") == 2
num_decodings("2611055971756562") == 4
num_decodings("1" * 80) == 37889062373143906
```

```python tests
import random


def brute(s):
    if not s:
        return 1
    total = 0
    if s[0] != "0":
        total += brute(s[1:])
        if len(s) > 1 and int(s[:2]) <= 26:
            total += brute(s[2:])
    return total


for _ in range(300):
    s = "".join(random.choice("0012226789") for _ in range(random.randint(0, 14)))
    assert num_decodings(s) == brute(s)
```

```python solution
from functools import cache


def num_decodings(s):
    @cache
    def count(i):
        if i == len(s):
            return 1
        if s[i] == "0":
            return 0
        total = count(i + 1)
        if i + 1 < len(s) and int(s[i:i + 2]) <= 26:
            total += count(i + 2)
        return total

    return count(0)
```

## Hints

1. The first letter uses either the first digit alone or the first two digits. Either way, what is left is a shorter string of the same kind.
2. The state is the index `i` where the rest of the string starts. `count(len(s))` is 1, and a rest that starts with `"0"` has no decoding.
3. With `@cache` on `count(i)`: return 0 if `s[i] == "0"`, else `count(i + 1)`, plus `count(i + 2)` when `i + 1 < len(s)` and `int(s[i:i + 2]) <= 26`.
