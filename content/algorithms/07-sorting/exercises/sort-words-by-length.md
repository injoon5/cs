---
id: sort-words-by-length
title: Sort words by length
level: warmup
---

Return the words in `words` from shortest to longest. Words of the same length keep the order they had. For example, `["pear", "fig", "kiwi"]` gives `["fig", "pear", "kiwi"]`.

```python starter
def sort_by_length(words):
    pass
```

```tests
sort_by_length(["pear", "fig", "kiwi"]) == ["fig", "pear", "kiwi"]
sort_by_length(["kiwi", "pear", "fig"]) == ["fig", "kiwi", "pear"]
sort_by_length(["ccc", "a", "bb"]) == ["a", "bb", "ccc"]
sort_by_length(["b", "a", "c"]) == ["b", "a", "c"]
sort_by_length(["same", "same"]) == ["same", "same"]
sort_by_length(["", "x", ""]) == ["", "", "x"]
sort_by_length(["one"]) == ["one"]
sort_by_length([]) == []
```

```python solution
def sort_by_length(words):
    return sorted(words, key=len)
```

## Hints

1. You only want to compare lengths, not the words themselves.
2. Pass a `key` to `sorted`. Python's sort is stable, so ties already keep their order.
3. `sorted(words, key=len)`.
