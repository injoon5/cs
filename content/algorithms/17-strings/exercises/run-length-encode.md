---
id: run-length-encode
title: Run-length encoding
level: warmup
---

Compress `s` by writing each run of the same character as the character followed by the run's length. `"aaabcc"` becomes `"a3b1c2"`. Build a list of pieces and join it once at the end.

```python starter
def encode(s):
    pass
```

```tests
encode("aaabcc") == "a3b1c2"
encode("") == ""
encode("a") == "a1"
encode("abc") == "a1b1c1"
encode("aabbaa") == "a2b2a2"
encode("zzzzzzzzzzzz") == "z12"
encode("  x") == " 2x1"
encode("ab" * 100000) == "a1b1" * 100000
```

```python tests
import random
from itertools import groupby

for _ in range(300):
    s = "".join(random.choice("ab ") for _ in range(random.randint(0, 30)))
    expected = "".join(f"{ch}{len(list(run))}" for ch, run in groupby(s))
    assert encode(s) == expected, s
```

```python solution
def encode(s):
    parts = []
    i = 0
    while i < len(s):
        j = i
        while j < len(s) and s[j] == s[i]:
            j += 1
        parts.append(s[i] + str(j - i))
        i = j
    return "".join(parts)
```

## Hints

1. A run ends where the next character differs, or at the end of the string.
2. From the start `i` of a run, move `j` forward while `s[j] == s[i]`. The run's length is `j - i`, and the next run starts at `j`.
3. Append `s[i] + str(j - i)` to a list for each run, and return `"".join(parts)`.
