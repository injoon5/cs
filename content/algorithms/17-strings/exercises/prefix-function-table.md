---
id: prefix-function-table
title: Prefix function
level: core
---

Return the prefix function of `s`: a list `pi` where `pi[i]` is the length of the longest proper prefix of `s[:i + 1]` that is also its suffix. It must run in O(n) time. For `"ababaca"` the answer is `[0, 0, 1, 2, 3, 0, 1]`.

```python starter
def prefix_function(s):
    pass
```

```tests
prefix_function("ababaca") == [0, 0, 1, 2, 3, 0, 1]
prefix_function("aabaaab") == [0, 1, 0, 1, 2, 2, 3]
prefix_function("") == []
prefix_function("a") == [0]
prefix_function("aaaa") == [0, 1, 2, 3]
prefix_function("abcd") == [0, 0, 0, 0]
prefix_function("abcabcab") == [0, 0, 0, 1, 2, 3, 4, 5]
prefix_function("a" * 399999 + "b") == list(range(399999)) + [0]
```

```python tests
import random


def brute(s):
    pi = []
    for i in range(len(s)):
        t = s[:i + 1]
        pi.append(max(k for k in range(i + 1) if t[:k] == t[i + 1 - k:]))
    return pi


for _ in range(300):
    s = "".join(random.choice("ab") for _ in range(random.randint(0, 16)))
    assert prefix_function(s) == brute(s), s
```

```python solution
def prefix_function(s):
    pi = [0] * len(s)
    k = 0
    for i in range(1, len(s)):
        while k > 0 and s[i] != s[k]:
            k = pi[k - 1]
        if s[i] == s[k]:
            k += 1
        pi[i] = k
    return pi
```

## Hints

1. Keep `k`, the longest border of the prefix you've handled so far. The next border is at most `k + 1` long.
2. If `s[i] == s[k]`, the border grows to `k + 1`. If not, the next shorter border to try has length `pi[k - 1]`.
3. For `i` from 1: `while k > 0 and s[i] != s[k]: k = pi[k - 1]`, then `if s[i] == s[k]: k += 1`, then `pi[i] = k`.
