---
id: counting-with-dicts
title: Counting
---

How many times does each letter appear in "banana"? Keep a dict from letter to count. For each letter, read the old count, with 0 if it's new, and store one more.

```python
counts = {}
for ch in "banana":
    counts[ch] = counts.get(ch, 0) + 1
print(counts)
```

Each step is one lookup and one store, so counting n items takes O(n) time on average. The dict holds one entry per different item.

---

```python trace stop=10
counts = {}
for ch in "banana":
    counts[ch] = counts.get(ch, 0) + 1
print(counts)
```

Four letters have been counted. What is `counts`?

- [ ] `{'b': 1, 'a': 3, 'n': 2}`
- [x] `{'b': 1, 'a': 2, 'n': 1}`
- [ ] `{'b': 1, 'a': 1, 'n': 1, 'a': 2}`

---

Run this to watch the counts build up, one letter at a time.

```python
import viz

word = "banana"
counts = {}
for i, ch in enumerate(word):
    counts[ch] = counts.get(ch, 0) + 1
    with viz.frame():
        viz.array(list(word), name="word",
                  pointers={"i": i})
        viz.grid([list(counts.values())],
                 name="counts",
                 col_labels=list(counts),
                 highlight=(0, list(counts).index(ch)),
                 note=f"{ch!r} is now {counts[ch]}")
```

---

Counting is common enough that Python has a dict for it. `collections.Counter` counts an iterable in one call, gives 0 for missing items instead of an error, and sorts by count with `most_common`.

```python predict
from collections import Counter

c = Counter(["red", "blue", "red",
             "green", "red", "blue"])
print(c["red"], c["pink"])
print(c.most_common(2))
```

---

Two words are anagrams when they use the same letters the same number of times, like "listen" and "silent". Compare their counts.

```python
from collections import Counter

print(Counter("listen") == Counter("silent"))
print(Counter("listen") == Counter("tinsel"))
print(Counter("aab") == Counter("abb"))
```

`sorted(a) == sorted(b)` also works, but sorting costs O(n log n). Counting is O(n).

---

Put the lines in order so `most_frequent` returns the item with the highest count. On a tie, the item that reached that count first wins.

```python arrange
def most_frequent(items):
    counts = {}
    best = None
    for x in items:
        counts[x] = counts.get(x, 0) + 1
        if best is None or counts[x] > counts[best]:
            best = x
    return best
```

```tests
most_frequent([3, 1, 3, 2, 1, 3]) == 3
most_frequent(["a", "b", "b"]) == "b"
most_frequent([1, 2, 2, 1]) == 2
most_frequent([7]) == 7
most_frequent([]) == None
```

---

You count the words in a text of n words, with k different words. The dict ends up using

- [ ] O(n) space, one entry per word in the text
- [x] O(k) space, one entry per different word
- [ ] O(1) space, because only counts are stored

---

[Anagram check](exercises/anagram-check.md)

[Most frequent items](exercises/top-k-frequent.md)
