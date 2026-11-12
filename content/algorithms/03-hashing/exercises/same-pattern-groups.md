---
id: same-pattern-groups
title: Same letter pattern
level: stretch
---

Two words share a letter pattern when you can turn one into the other by swapping each letter for another letter, the same swap every time, with different letters staying different. "egg" and "add" share a pattern, and so do "paper" and "title". "egg" and "ego" don't.

Group the words that share a pattern. Groups come in the order their first word appears, and words in a group keep their input order. For `["egg", "add", "abc", "foo", "xyz"]` the answer is `[["egg", "add", "foo"], ["abc", "xyz"]]`.

```python starter
def group_by_pattern(words):
    pass
```

```tests
group_by_pattern(["egg", "add", "abc", "foo", "xyz"]) == [["egg", "add", "foo"], ["abc", "xyz"]]
group_by_pattern([]) == []
group_by_pattern(["a"]) == [["a"]]
group_by_pattern(["a", "b", "ab"]) == [["a", "b"], ["ab"]]
group_by_pattern(["paper", "title", "tiger"]) == [["paper", "title"], ["tiger"]]
group_by_pattern(["egg", "ego"]) == [["egg"], ["ego"]]
group_by_pattern(["aba", "aab", "xyx", "baa"]) == [["aba", "xyx"], ["aab"], ["baa"]]
group_by_pattern(["", "zz", "", "qq"]) == [["", ""], ["zz", "qq"]]
group_by_pattern(["abab", "cdcd", "abba"]) == [["abab", "cdcd"], ["abba"]]
```

```python solution
def pattern(word):
    first = {}
    return tuple(first.setdefault(ch, len(first)) for ch in word)


def group_by_pattern(words):
    groups = {}
    for w in words:
        groups.setdefault(pattern(w), []).append(w)
    return list(groups.values())
```

## Hints

1. This is grouping by a key again. You need a key that "egg", "add" and "foo" share.
2. Number the letters in the order they first appear: "egg" is 0, 1, 1 and "paper" is 0, 1, 0, 2, 3.
3. Build the numbers with a dict from letter to its number, `first.setdefault(ch, len(first))`, and make the key a tuple so it is hashable.
