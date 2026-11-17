---
id: longest-pal-subseq
title: Longest palindromic subsequence
level: core
---

Return the length of the longest palindrome you can get from the string `s` by deleting characters, without reordering the rest. For `"bbbab"` it is 4, `"bbbb"`. For `"character"` it is 5, `"carac"`.

```python starter
def lps_length(s):
    pass
```

```tests
lps_length("bbbab") == 4
lps_length("character") == 5
lps_length("cbbd") == 2
lps_length("") == 0
lps_length("a") == 1
lps_length("ab") == 1
lps_length("aa") == 2
lps_length("abc") == 1
lps_length("racecar") == 7
lps_length("agbdba") == 5
lps_length("ab" * 150) == 299
lps_length("abcab" * 60) == 239
```

```python tests
import random
from itertools import combinations


def brute(s):
    for k in range(len(s), 0, -1):
        for c in combinations(s, k):
            if c == c[::-1]:
                return k
    return 0


for _ in range(200):
    s = "".join(random.choice("abc") for _ in range(random.randint(0, 10)))
    assert lps_length(s) == brute(s)
```

```python solution
def lps_length(s):
    n = len(s)
    dp = [[0] * n for _ in range(n)]
    for i in range(n):
        dp[i][i] = 1
    for length in range(2, n + 1):
        for i in range(n - length + 1):
            j = i + length - 1
            if s[i] == s[j]:
                dp[i][j] = dp[i + 1][j - 1] + 2
            else:
                dp[i][j] = max(dp[i + 1][j], dp[i][j - 1])
    return dp[0][n - 1] if n else 0
```

## Hints

1. Look at both ends of a piece of the string. If they match, they can wrap a palindrome from inside. If not, one of them is left out.
2. `dp[i][j]` is the answer for `s[i..j]`, both ends included. `dp[i][i]` is 1. A matching pair adds 2 to `dp[i + 1][j - 1]`, and a mismatch takes `max(dp[i + 1][j], dp[i][j - 1])`.
3. Fill by length, 2 up to `n`, with `j = i + length - 1`. For length 2, `dp[i + 1][j - 1]` is a cell below the diagonal, which stays 0.
