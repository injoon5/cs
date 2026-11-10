---
id: is-palindrome
title: Palindrome check
level: warmup
---

Return `True` if `s` reads the same forwards and backwards. Compare characters exactly: `"Aa"` is not a palindrome. Don't build a reversed copy.

```python starter
def is_palindrome(s):
    pass
```

```tests
is_palindrome("level") == True
is_palindrome("abba") == True
is_palindrome("abca") == False
is_palindrome("ab") == False
is_palindrome("a") == True
is_palindrome("") == True
is_palindrome("aaaa") == True
is_palindrome("Aa") == False
```

```python solution
def is_palindrome(s):
    i, j = 0, len(s) - 1
    while i < j:
        if s[i] != s[j]:
            return False
        i += 1
        j -= 1
    return True
```

## Hints

1. The first character has to match the last one. What has to match next?
2. Put `i` at the start and `j` at the end. Compare, then move both inward.
3. Loop `while i < j`. Return `False` on the first mismatch, `True` after the loop.
