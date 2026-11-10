---
id: count-in-ranges
title: Letters in ranges
level: warmup
---

For each `(l, r)` in `queries`, count how many times `ch` appears in `s[l]` through `s[r]`, both ends included. Return the counts as a list. Do the counting pass over `s` only once.

```python starter
def count_in_ranges(s, ch, queries):
    pass
```

```tests
count_in_ranges("banana", "a", [(0, 5), (1, 3), (0, 0)]) == [3, 2, 0]
count_in_ranges("banana", "n", [(2, 4)]) == [2]
count_in_ranges("banana", "z", [(0, 5)]) == [0]
count_in_ranges("aaaa", "a", [(0, 3), (1, 2), (3, 3)]) == [4, 2, 1]
count_in_ranges("x", "x", [(0, 0)]) == [1]
count_in_ranges("abc", "a", []) == []
```

```python solution
def count_in_ranges(s, ch, queries):
    prefix = [0]
    for c in s:
        prefix.append(prefix[-1] + (1 if c == ch else 0))
    return [prefix[r + 1] - prefix[l] for l, r in queries]
```

## Hints

1. Counting a letter is adding up 1s and 0s.
2. Build a prefix list where `prefix[i]` counts `ch` in the first `i` characters.
3. Append `prefix[-1] + 1` when `c == ch`, else `prefix[-1]`. Each answer is `prefix[r + 1] - prefix[l]`.
