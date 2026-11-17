---
id: split-into-words
title: Split into words
level: stretch
---

Return `True` if the string `s` can be split into a sequence of words from the list `words`, where each word may be used any number of times. `"applepenapple"` splits into apple, pen, apple with `words = ["apple", "pen"]`. `"catsandog"` can't be split with `["cats", "dog", "sand", "and", "cat"]`. The empty string always splits, into no words.

`s` can be thousands of characters long, so fill a table with a loop rather than recursing.

```python starter
def can_split(s, words):
    pass
```

```tests
can_split("applepenapple", ["apple", "pen"]) == True
can_split("catsandog", ["cats", "dog", "sand", "and", "cat"]) == False
can_split("leetcode", ["leet", "code"]) == True
can_split("", ["a"]) == True
can_split("", []) == True
can_split("a", []) == False
can_split("ab", ["a"]) == False
can_split("aaaaaaa", ["aaaa", "aaa"]) == True
can_split("cars", ["car", "ca", "rs"]) == True
can_split("a" * 200 + "b", ["a", "aa", "aaa", "aaaa", "aaaaa"]) == False
can_split("ab" * 2000, ["a", "b", "ab", "ba"]) == True
```

```python tests
import random


def brute(s, words):
    if not s:
        return True
    return any(s.startswith(w) and brute(s[len(w):], words) for w in words)


def text(lo, hi):
    return "".join(random.choice("ab") for _ in range(random.randint(lo, hi)))


for _ in range(300):
    words = [text(1, 3) for _ in range(random.randint(0, 3))]
    s = text(0, 12)
    assert can_split(s, words) == brute(s, words)
```

```python solution
def can_split(s, words):
    ok = [True] + [False] * len(s)
    for i in range(1, len(s) + 1):
        for w in words:
            if len(w) <= i and ok[i - len(w)] and s[i - len(w):i] == w:
                ok[i] = True
                break
    return ok[-1]
```

## Hints

1. Trying every way to split from the front repeats work: `"a" * 30 + "b"` can be cut up in millions of ways before the `b` rules them all out.
2. Let `ok[i]` be `True` when the prefix `s[:i]` splits into words. `ok[0]` is `True`, and the answer is `ok[len(s)]`.
3. `ok[i]` is `True` when some word `w` ends the prefix, `s[i - len(w):i] == w`, and `ok[i - len(w)]` is `True`.
