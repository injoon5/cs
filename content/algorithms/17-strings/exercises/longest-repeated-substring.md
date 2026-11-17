---
id: longest-repeated-substring
title: Longest repeated substring
level: stretch
---

Return the length of the longest substring that occurs at least twice in `s`. The two occurrences may overlap. Return 0 if no character repeats. Aim for O(n log n) time: binary search on the length, and check each length with substring hashes. In `"banana"` the answer is 3, for `ana`.

```python starter
def longest_repeat(s):
    pass
```

```tests
longest_repeat("banana") == 3
longest_repeat("mississippi") == 4
longest_repeat("aaaa") == 3
longest_repeat("abab") == 2
longest_repeat("abcabc") == 3
longest_repeat("abcd") == 0
longest_repeat("a") == 0
longest_repeat("") == 0
longest_repeat("ab" * 10000) == 19998
```

```python tests
import random


def brute(s):
    best = 0
    for length in range(1, len(s)):
        parts = [s[i:i + length] for i in range(len(s) - length + 1)]
        if len(set(parts)) == len(parts):
            break
        best = length
    return best


for _ in range(300):
    s = "".join(random.choice("ab") for _ in range(random.randint(0, 14)))
    assert longest_repeat(s) == brute(s), s

rng = random.Random(5)
r = "".join(rng.choice("acgt") for _ in range(15000))
assert longest_repeat(r[:10000] + r[5000:]) == 5002
```

```python solution
B, P = 256, 2**61 - 1


def longest_repeat(s):
    n = len(s)
    h, pw = [0] * (n + 1), [1] * (n + 1)
    for i, ch in enumerate(s):
        h[i + 1] = (h[i] * B + ord(ch)) % P
        pw[i + 1] = pw[i] * B % P

    def has_repeat(length):
        first = {}
        for i in range(n - length + 1):
            x = (h[i + length] - h[i] * pw[length]) % P
            j = first.setdefault(x, i)
            if j != i and s[j:j + length] == s[i:i + length]:
                return True
        return False

    lo, hi = 0, max(n - 1, 0)
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if has_repeat(mid):
            lo = mid
        else:
            hi = mid - 1
    return lo
```

## Hints

1. If a substring of length L occurs twice, so does a substring of every shorter length. So "is there a repeat of length L?" is yes up to the answer and no after it.
2. Binary search L between 0 and `n - 1`. To check one length, compute the hash of every window of that length from prefix hashes and look for a hash you've already seen.
3. With `h` and `pw` built once, the window at `i` hashes to `(h[i + L] - h[i] * pw[L]) % P`. Keep `lo` on a length that repeats: `mid = (lo + hi + 1) // 2`, then `lo = mid` if it repeats, else `hi = mid - 1`.
