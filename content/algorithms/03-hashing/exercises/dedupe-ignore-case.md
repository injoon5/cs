---
id: dedupe-ignore-case
title: Dedupe, ignoring case
level: core
---

Remove repeated words, treating upper and lower case as the same. Keep the first spelling of each word and the original order. For `["Apple", "apple", "Bee", "APPLE", "cat"]` the answer is `["Apple", "Bee", "cat"]`.

```python starter
def dedupe_words(words):
    pass
```

```tests
dedupe_words(["Apple", "apple", "Bee", "APPLE", "cat"]) == ["Apple", "Bee", "cat"]
dedupe_words([]) == []
dedupe_words(["one"]) == ["one"]
dedupe_words(["a", "b", "c"]) == ["a", "b", "c"]
dedupe_words(["x", "X", "x"]) == ["x"]
dedupe_words(["Bee", "bee", "Apple"]) == ["Bee", "Apple"]
dedupe_words(["", "", "A"]) == ["", "A"]
dedupe_words(["Go", "GO", "go", "gO", "Stop"]) == ["Go", "Stop"]
dedupe_words([f"w{i % 1000}" for i in range(100000)]) == [f"w{i}" for i in range(1000)]
```

```python solution
def dedupe_words(words):
    seen = set()
    out = []
    for w in words:
        key = w.lower()
        if key not in seen:
            seen.add(key)
            out.append(w)
    return out
```

## Hints

1. Two words are the same if their lowercase forms match. Use that form to decide, but keep the original word.
2. Keep a set of lowercase words seen so far, and a list for the answer.
3. For each word, compute `key = w.lower()`. If `key` isn't in `seen`, add it and append `w`.
