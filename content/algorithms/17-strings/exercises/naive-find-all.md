---
id: naive-find-all
title: Find every match
level: core
---

Return the list of every index where `pat` starts in `text`, in increasing order, including matches that overlap. `pat` is never empty. Try every shift and compare characters one at a time; don't use `find`, `index`, `count` or `in` on the pattern. For `"abababa"` and `"aba"` the answer is `[0, 2, 4]`.

```python starter
def find_all(text, pat):
    pass
```

```tests
find_all("abababa", "aba") == [0, 2, 4]
find_all("ababababc", "ababc") == [4]
find_all("hello", "l") == [2, 3]
find_all("aaaa", "aa") == [0, 1, 2]
find_all("abc", "abc") == [0]
find_all("abc", "abcd") == []
find_all("", "a") == []
find_all("abc", "x") == []
find_all("ab" * 50000, "aba") == list(range(0, 99998, 2))
```

```python tests
import random

for _ in range(300):
    text = "".join(random.choice("ab") for _ in range(random.randint(0, 20)))
    pat = "".join(random.choice("ab") for _ in range(random.randint(1, 4)))
    expected = [i for i in range(len(text)) if text.startswith(pat, i)]
    assert find_all(text, pat) == expected, (text, pat)
```

```python solution
def find_all(text, pat):
    n, m = len(text), len(pat)
    found = []
    for i in range(n - m + 1):
        j = 0
        while j < m and text[i + j] == pat[j]:
            j += 1
        if j == m:
            found.append(i)
    return found
```

## Hints

1. The pattern can start at any index from 0 to `len(text) - len(pat)`.
2. For each shift `i`, move `j` forward while `text[i + j] == pat[j]`. Stop at the first mismatch or when `j` reaches `len(pat)`.
3. If `j == len(pat)` after the inner loop, append `i`. Don't skip ahead after a match, or you'll miss overlapping ones.
