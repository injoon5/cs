---
id: common-subsequence
title: Longest common subsequence
level: core
---

Return the length of the longest common subsequence of the strings `a` and `b`: the longest string you can get from both by deleting characters, without reordering the rest. For `"abcde"` and `"ace"` it is 3, the string `"ace"`.

```python starter
def lcs_length(a, b):
    pass
```

```tests
lcs_length("abcde", "ace") == 3
lcs_length("ace", "abcde") == 3
lcs_length("abc", "def") == 0
lcs_length("", "abc") == 0
lcs_length("", "") == 0
lcs_length("abc", "abc") == 3
lcs_length("aaaa", "aa") == 2
lcs_length("abcbdab", "bdcaba") == 4
lcs_length("dance", "ancient") == 4
lcs_length("ab" * 150, "ba" * 150) == 299
lcs_length("abcde" * 60, "edcba" * 60) == 119
```

```python tests
import random
from itertools import combinations


def brute(a, b):
    for k in range(min(len(a), len(b)), 0, -1):
        subs = {"".join(c) for c in combinations(a, k)}
        if any("".join(c) in subs for c in combinations(b, k)):
            return k
    return 0


for _ in range(200):
    a = "".join(random.choice("abc") for _ in range(random.randint(0, 7)))
    b = "".join(random.choice("abc") for _ in range(random.randint(0, 7)))
    assert lcs_length(a, b) == brute(a, b)
```

```python solution
def lcs_length(a, b):
    m, n = len(a), len(b)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if a[i - 1] == b[j - 1]:
                dp[i][j] = dp[i - 1][j - 1] + 1
            else:
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
    return dp[m][n]
```

## Hints

1. Compare the last characters of the two prefixes. If they match, they can end the common subsequence. If not, one of them is left out.
2. `dp[i][j]` is the answer for `a[:i]` and `b[:j]`. Row 0 and column 0 are 0.
3. If `a[i - 1] == b[j - 1]`, `dp[i][j] = dp[i - 1][j - 1] + 1`. Otherwise it is `max(dp[i - 1][j], dp[i][j - 1])`. Return `dp[len(a)][len(b)]`.
