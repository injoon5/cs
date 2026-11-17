---
id: kmp-find-all
title: KMP search
level: core
---

Return every index where `pat` starts in `text`, in increasing order, including matches that overlap. `pat` is never empty. Use KMP: compute the pattern's prefix function, then walk the text once without ever moving back. Don't use `find`, `index`, `count` or `in` on the pattern. For `"abababa"` and `"aba"` the answer is `[0, 2, 4]`.

```python starter
def kmp_search(text, pat):
    pass
```

```tests
kmp_search("abababa", "aba") == [0, 2, 4]
kmp_search("ababababc", "ababc") == [4]
kmp_search("aaab", "aab") == [1]
kmp_search("aaaa", "a") == [0, 1, 2, 3]
kmp_search("abc", "abc") == [0]
kmp_search("ab", "abc") == []
kmp_search("", "a") == []
kmp_search("abcabd", "abd") == [3]
kmp_search("a" * 600000, "a" * 300000) == list(range(300001))
kmp_search("a" * 600000, "a" * 299999 + "b") == []
```

```python tests
import random

for _ in range(300):
    text = "".join(random.choice("ab") for _ in range(random.randint(0, 25)))
    pat = "".join(random.choice("ab") for _ in range(random.randint(1, 5)))
    expected = [i for i in range(len(text)) if text.startswith(pat, i)]
    assert kmp_search(text, pat) == expected, (text, pat)
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


def kmp_search(text, pat):
    pi = prefix_function(pat)
    found = []
    k = 0
    for i, ch in enumerate(text):
        while k > 0 and ch != pat[k]:
            k = pi[k - 1]
        if ch == pat[k]:
            k += 1
        if k == len(pat):
            found.append(i - k + 1)
            k = pi[k - 1]
    return found
```

## Hints

1. Keep `k`, how many characters of the pattern match the text ending at the current character. On a mismatch, the prefix function says how many still match.
2. For each text character `ch`, fall back with `k = pi[k - 1]` while `k > 0` and `ch != pat[k]`. Then, if `ch == pat[k]`, add 1 to `k`.
3. When `k == len(pat)`, the match starts at `i - k + 1`. Record it and set `k = pi[k - 1]` so the next match can overlap this one.
