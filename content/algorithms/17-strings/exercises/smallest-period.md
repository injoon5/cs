---
id: smallest-period
title: Smallest repeating unit
level: core
---

`s` is not empty. Return the shortest string `t` such that `s` is `t` repeated a whole number of times. If no shorter string works, return `s` itself. Use the prefix function, in O(n) time. `"abcabc"` gives `"abc"`, and `"abcab"` gives `"abcab"`.

```python starter
def repeating_unit(s):
    pass
```

```tests
repeating_unit("abcabc") == "abc"
repeating_unit("abcab") == "abcab"
repeating_unit("aaaa") == "a"
repeating_unit("a") == "a"
repeating_unit("ab") == "ab"
repeating_unit("abababab") == "ab"
repeating_unit("aabaab") == "aab"
repeating_unit("abaaba") == "aba"
repeating_unit("abcabcab") == "abcabcab"
repeating_unit("abc" * 100000) == "abc"
repeating_unit("ab" * 99999 + "a") == "ab" * 99999 + "a"
```

```python tests
import random


def brute(s):
    for p in range(1, len(s) + 1):
        if len(s) % p == 0 and s[:p] * (len(s) // p) == s:
            return s[:p]


for _ in range(300):
    unit = "".join(random.choice("ab") for _ in range(random.randint(1, 4)))
    s = unit * random.randint(1, 5) + "".join(random.choice("ab") for _ in range(random.randint(0, 2)))
    assert repeating_unit(s) == brute(s), s
```

```python solution
def repeating_unit(s):
    pi = [0] * len(s)
    k = 0
    for i in range(1, len(s)):
        while k > 0 and s[i] != s[k]:
            k = pi[k - 1]
        if s[i] == s[k]:
            k += 1
        pi[i] = k
    p = len(s) - pi[-1]
    return s[:p] if len(s) % p == 0 else s
```

## Hints

1. The smallest period of `s` comes straight from its longest border.
2. With `pi` the prefix function of `s`, the smallest period is `p = len(s) - pi[-1]`.
3. If `len(s) % p == 0`, the answer is `s[:p]`. Otherwise no shorter unit fits a whole number of times, so return `s`.
