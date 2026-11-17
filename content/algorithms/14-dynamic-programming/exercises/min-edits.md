---
id: min-edits
title: Edit distance
level: stretch
---

An edit inserts one character, deletes one, or replaces one with another. Return the fewest edits that turn the string `a` into `b`. `"horse"` becomes `"ros"` in 3: replace h with r, delete the second r, delete the e.

```python starter
def edit_distance(a, b):
    pass
```

```tests
edit_distance("horse", "ros") == 3
edit_distance("intention", "execution") == 5
edit_distance("kitten", "sitting") == 3
edit_distance("", "") == 0
edit_distance("", "abc") == 3
edit_distance("abc", "") == 3
edit_distance("same", "same") == 0
edit_distance("a", "b") == 1
edit_distance("ab", "ba") == 2
edit_distance("abc" * 100, "bca" * 100) == 2
edit_distance("kitten" * 40, "sitting" * 40) == 120
```

```python tests
import random


def text():
    return "".join(random.choice("abc") for _ in range(random.randint(0, 8)))


for _ in range(200):
    a, b, c = text(), text(), text()
    d = edit_distance(a, b)
    assert d == edit_distance(b, a)
    assert abs(len(a) - len(b)) <= d <= max(len(a), len(b))
    assert edit_distance(a, c) <= d + edit_distance(b, c)
    assert edit_distance(a, a + c) == len(c)
```

```python solution
def edit_distance(a, b):
    m, n = len(a), len(b)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if a[i - 1] == b[j - 1]:
                dp[i][j] = dp[i - 1][j - 1]
            else:
                dp[i][j] = 1 + min(dp[i - 1][j - 1],  # replace
                                   dp[i - 1][j],      # delete
                                   dp[i][j - 1])      # insert
    return dp[m][n]
```

## Hints

1. Look at the last characters of the two prefixes. If they match, they need no edit. If not, the last edit either replaces, deletes or inserts there.
2. `dp[i][j]` is the answer for `a[:i]` and `b[:j]`. `dp[i][0]` is `i` and `dp[0][j]` is `j`.
3. On a match, `dp[i][j] = dp[i - 1][j - 1]`. Otherwise it is `1 + min(dp[i - 1][j - 1], dp[i - 1][j], dp[i][j - 1])`.
