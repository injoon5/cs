---
id: longest-border
title: Longest border
level: core
---

Return the longest string that is both a prefix and a suffix of `s`, but not all of `s`. Return `""` if there is none. It must run in O(n) time, so don't try every length with slices. For `"abacaba"` the answer is `"aba"`.

```python starter
def longest_border(s):
    pass
```

```tests
longest_border("abacaba") == "aba"
longest_border("ababab") == "abab"
longest_border("aaaa") == "aaa"
longest_border("abcd") == ""
longest_border("abca") == "a"
longest_border("a") == ""
longest_border("") == ""
longest_border("a" * 399999 + "b") == ""
longest_border("ab" * 200000) == "ab" * 199999
```

```python tests
import random


def brute(s):
    for k in range(len(s) - 1, 0, -1):
        if s[:k] == s[len(s) - k:]:
            return s[:k]
    return ""


for _ in range(300):
    s = "".join(random.choice("ab") for _ in range(random.randint(0, 16)))
    assert longest_border(s) == brute(s), s
```

```python solution
def longest_border(s):
    pi = [0] * len(s)
    k = 0
    for i in range(1, len(s)):
        while k > 0 and s[i] != s[k]:
            k = pi[k - 1]
        if s[i] == s[k]:
            k += 1
        pi[i] = k
    return s[:k]
```

## Hints

1. This is exactly what the prefix function measures, for the whole string.
2. Compute `pi` for `s`. The last entry is the length of the longest border.
3. After the prefix function loop, `k` already holds `pi[-1]`. Return `s[:k]`, which is `""` when `s` is empty.
