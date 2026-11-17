---
id: is-rotation
title: Is it a rotation
level: warmup
---

A rotation of `s` moves some characters from its front to its back: `"erbottlewat"` is a rotation of `"waterbottle"`. Return `True` if `t` is a rotation of `s`. A string is a rotation of itself. Do it in O(n) time, with no loop over all n rotations.

```python starter
def is_rotation(s, t):
    pass
```

```tests
is_rotation("waterbottle", "erbottlewat") == True
is_rotation("abcd", "cdab") == True
is_rotation("abcd", "acbd") == False
is_rotation("abc", "abc") == True
is_rotation("", "") == True
is_rotation("a", "") == False
is_rotation("ab", "aba") == False
is_rotation("aa", "a") == False
is_rotation("abab", "baba") == True
is_rotation("a" * 100000 + "b", "b" + "a" * 100000) == True
is_rotation("a" * 100000 + "b", "a" * 99999 + "ba") == True
is_rotation("a" * 100000 + "b", "a" * 99999 + "bb") == False
```

```python tests
import random

for _ in range(300):
    s = "".join(random.choice("ab") for _ in range(random.randint(0, 8)))
    t = "".join(random.choice("ab") for _ in range(random.randint(0, 8)))
    expected = len(s) == len(t) and any(s[k:] + s[:k] == t for k in range(max(1, len(s))))
    assert is_rotation(s, t) == expected, (s, t)
```

```python solution
def is_rotation(s, t):
    return len(s) == len(t) and t in s + s
```

## Hints

1. Write `s` twice in a row. What do you see inside `"waterbottlewaterbottle"`?
2. Every rotation of `s` is a substring of `s + s` of the same length, and `in` searches in linear time.
3. Check that the lengths are equal, otherwise `"a"` would count as a rotation of `"aa"`. Then return `t in s + s`.
