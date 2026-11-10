---
id: longest-unique
title: Longest run without repeats
level: stretch
---

Return the length of the longest substring of `s` with no repeated character. In `"abcabcbb"` it is 3, for `"abc"`.

```python starter
def longest_unique(s):
    pass
```

```tests
longest_unique("abcabcbb") == 3
longest_unique("bbbbb") == 1
longest_unique("pwwkew") == 3
longest_unique("abba") == 2
longest_unique("dvdf") == 3
longest_unique("abcdef") == 6
longest_unique("a") == 1
longest_unique("") == 0
```

```python solution
def longest_unique(s):
    last_seen = {}
    left = 0
    best = 0
    for right, ch in enumerate(s):
        if ch in last_seen and last_seen[ch] >= left:
            left = last_seen[ch] + 1
        last_seen[ch] = right
        best = max(best, right - left + 1)
    return best
```

## Hints

1. A window with no repeats stays valid until the new character on the right is already inside it.
2. Remember where you last saw each character. When the new character is already in the window, move `left` past its earlier copy.
3. Keep a dict `last_seen`. If `last_seen[ch] >= left`, set `left = last_seen[ch] + 1`. Then store `right` for `ch` and update `best` with `right - left + 1`.
