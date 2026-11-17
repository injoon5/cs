---
id: rabin-karp-find-all
title: Rabin-Karp
level: core
---

Return every index where `pat` starts in `text`, in increasing order, including matches that overlap. `pat` is never empty. Use Rabin-Karp: roll a polynomial hash across the text, and compare characters only when a window's hash equals the pattern's. Don't use `find`, `index`, `count` or `in` on the pattern. For `"abracadabra"` and `"abra"` the answer is `[0, 7]`.

```python starter
def find_all(text, pat):
    pass
```

```tests
find_all("abracadabra", "abra") == [0, 7]
find_all("abababa", "aba") == [0, 2, 4]
find_all("aaaa", "a") == [0, 1, 2, 3]
find_all("abc", "abc") == [0]
find_all("ab", "abc") == []
find_all("", "a") == []
find_all("xyz", "q") == []
find_all("ünï cödé ünï", "ünï") == [0, 9]
find_all("a" * 600000, "a" * 299999 + "b") == []
find_all("ab" * 200000 + "c", "ab" * 100000 + "c") == [200000]
```

```python tests
import random

for _ in range(300):
    text = "".join(random.choice("ab") for _ in range(random.randint(0, 25)))
    pat = "".join(random.choice("ab") for _ in range(random.randint(1, 5)))
    expected = [i for i in range(len(text)) if text.startswith(pat, i)]
    assert find_all(text, pat) == expected, (text, pat)
```

```python solution
B, P = 256, 1_000_000_007


def find_all(text, pat):
    n, m = len(text), len(pat)
    if m > n:
        return []
    power = pow(B, m - 1, P)
    hp = hw = 0
    for k in range(m):
        hp = (hp * B + ord(pat[k])) % P
        hw = (hw * B + ord(text[k])) % P
    found = []
    for i in range(n - m + 1):
        if hw == hp and text[i:i + m] == pat:
            found.append(i)
        if i + m < n:
            hw = ((hw - ord(text[i]) * power) * B + ord(text[i + m])) % P
    return found
```

## Hints

1. Comparing two hashes is one step. Compute the pattern's hash once, and get each window's hash from the one before it instead of from scratch.
2. Hash the pattern and the first window with `h = (h * B + ord(ch)) % P`. To slide from `i` to `i + 1`, remove `text[i]` with `power = pow(B, m - 1, P)` and add `text[i + m]`.
3. In the loop over `i`, append `i` when `hw == hp and text[i:i + m] == pat`, then roll: `hw = ((hw - ord(text[i]) * power) * B + ord(text[i + m])) % P` while `i + m < n`.
