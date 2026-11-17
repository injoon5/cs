---
id: distinct-k-substrings
title: Distinct substrings of length k
level: core
---

Return how many different substrings of length `k` the string `s` has, where `k >= 1`. Roll a hash across `s` and count the different hashes, so the time is O(n) however big `k` is. Use a large prime such as `2**61 - 1`. In `"banana"` with `k = 2` the substrings are `ba`, `an`, `na`, `an`, `na`, so the answer is 3.

```python starter
def count_distinct(s, k):
    pass
```

```tests
count_distinct("banana", 2) == 3
count_distinct("banana", 3) == 3
count_distinct("banana", 6) == 1
count_distinct("banana", 7) == 0
count_distinct("", 1) == 0
count_distinct("a", 1) == 1
count_distinct("aaaa", 2) == 1
count_distinct("abcd", 1) == 4
count_distinct("ab" * 100000, 100000) == 2
```

```python tests
import random

for _ in range(300):
    s = "".join(random.choice("abc") for _ in range(random.randint(0, 25)))
    k = random.randint(1, 8)
    expected = len({s[i:i + k] for i in range(len(s) - k + 1)})
    assert count_distinct(s, k) == expected, (s, k)
```

```python solution
B, P = 256, 2**61 - 1


def count_distinct(s, k):
    n = len(s)
    if k > n:
        return 0
    power = pow(B, k - 1, P)
    h = 0
    for ch in s[:k]:
        h = (h * B + ord(ch)) % P
    seen = {h}
    for i in range(k, n):
        h = ((h - ord(s[i - k]) * power) * B + ord(s[i])) % P
        seen.add(h)
    return len(seen)
```

## Hints

1. A set of the slices `s[i:i + k]` gives the right answer, but each slice costs O(k) to build and to hash.
2. Put each window's rolling hash in the set instead. Different substrings almost surely get different hashes when `P` is about 2⁶¹.
3. Hash the first `k` characters, add it to a set, then for each `i` from `k` on roll with `h = ((h - ord(s[i - k]) * power) * B + ord(s[i])) % P` and add `h`. Return the size of the set.
