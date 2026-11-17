---
id: shortest-palindrome-front
title: Shortest palindrome
level: stretch
---

Return the shortest palindrome you can make by adding characters only to the front of `s`. `s` holds only lowercase letters. It must run in O(n) time. For `"abcd"` the answer is `"dcbabcd"`. For `"aacecaaa"` it's `"aaacecaaa"`: one `a` in front is enough.

```python starter
def shortest_palindrome(s):
    pass
```

```tests
shortest_palindrome("abcd") == "dcbabcd"
shortest_palindrome("aacecaaa") == "aaacecaaa"
shortest_palindrome("") == ""
shortest_palindrome("a") == "a"
shortest_palindrome("aba") == "aba"
shortest_palindrome("ab") == "bab"
shortest_palindrome("aab") == "baab"
shortest_palindrome("abb") == "bbabb"
shortest_palindrome("b" + "a" * 150000) == "a" * 150000 + "b" + "a" * 150000
shortest_palindrome("a" * 150000 + "b") == "b" + "a" * 150000 + "b"
```

```python tests
import random


def brute(s):
    for k in range(len(s), -1, -1):
        if s[:k] == s[:k][::-1]:
            return s[k:][::-1] + s


for _ in range(300):
    s = "".join(random.choice("ab") for _ in range(random.randint(0, 12)))
    assert shortest_palindrome(s) == brute(s), s
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


def shortest_palindrome(s):
    r = s[::-1]
    keep = prefix_function(s + "#" + r)[-1]
    return r[:len(s) - keep] + s
```

## Hints

1. Whatever you add in front, the result ends with `s`. The less you add, the longer the palindrome that `s` already starts with.
2. A prefix of `s` is a palindrome exactly when it is also a suffix of `s[::-1]`. That's a job for the prefix function on `s + "#" + s[::-1]`.
3. Let `keep` be the last value of that prefix function. The rest of `s`, reversed, goes in front: return `s[::-1][:len(s) - keep] + s`.
