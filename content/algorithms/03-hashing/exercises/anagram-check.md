---
id: anagram-check
title: Anagram check
level: warmup
---

Return `True` if `b` uses exactly the same letters as `a`, each the same number of times. Case matters, so `"A"` and `"a"` are different letters. For `"listen"` and `"silent"` the answer is `True`.

```python starter
def is_anagram(a, b):
    pass
```

```tests
is_anagram("listen", "silent") == True
is_anagram("rat", "car") == False
is_anagram("", "") == True
is_anagram("a", "a") == True
is_anagram("aab", "abb") == False
is_anagram("ab", "abc") == False
is_anagram("aaa", "aa") == False
is_anagram("Dusty", "study") == False
is_anagram("ab" * 50000, "ba" * 50000) == True
```

```python solution
from collections import Counter


def is_anagram(a, b):
    return Counter(a) == Counter(b)
```

## Hints

1. Order doesn't matter, only how many of each letter there are.
2. Count the letters of each word and compare the two counts.
3. `Counter(a) == Counter(b)`, or build two dicts with `counts.get(ch, 0) + 1` and compare them.
