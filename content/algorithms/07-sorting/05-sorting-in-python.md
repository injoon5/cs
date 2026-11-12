---
id: sorting-in-python
title: Sorting in Python
---

Python has two ways to sort. `sorted(xs)` returns a new list and leaves `xs` alone. `xs.sort()` sorts `xs` in place and returns `None`. What does this print?

```python predict
a = [3, 1, 2]
b = sorted(a)
print(a, b)
c = a.sort()
print(a, c)
```

---

Both take `key`, a function that turns each item into the thing to compare. The items themselves are not changed.

```python
words = ["pear", "fig", "banana", "kiwi"]
print(sorted(words))
print(sorted(words, key=len))
print(sorted(words, key=len, reverse=True))
```

The key is called once per item, not once per comparison, so an expensive key costs n calls.

---

Python's sort is stable: items with equal keys keep the order they came in. `pear` and `kiwi` both have length 4. What does this print?

```python predict
words = ["pear", "fig", "kiwi", "plum", "date"]
print(sorted(words, key=len))
```

---

To sort by more than one thing, return a tuple. Tuples compare item by item, so `(points, name)` sorts by points and breaks ties by name.

For a number in the other direction, negate it. Here: most points first, then name from A to Z.

```python
players = [("ana", 30), ("bo", 45), ("cy", 30)]
ranked = sorted(players, key=lambda p: (-p[1], p[0]))
print(ranked)
```

---

Strings can't be negated. Stability gives another way: sort by the least important key first, then by the most important one. The second sort keeps ties in the order the first one left them.

```python predict
people = [("cy", 30), ("ana", 30), ("bo", 25)]
people.sort(key=lambda p: p[0], reverse=True)
people.sort(key=lambda p: p[1])
print(people)
```

---

Under the hood, Python uses Timsort. It looks for runs that are already in order, going up or down, and merges them the way merge sort does. Short runs are grown with insertion sort first. Real data often comes partly sorted, and Timsort takes advantage of it.

This counts the comparisons on 100 items that are already sorted, then on 100 that are backwards.

```python predict
count = 0

class Item:
    def __init__(self, v):
        self.v = v

    def __lt__(self, other):
        global count
        count += 1
        return self.v < other.v

sorted([Item(v) for v in range(100)])
print(count)
count = 0
sorted([Item(v) for v in range(100, 0, -1)])
print(count)
```

---

Python's `sorted` on n items takes

- [ ] O(n log n) time on every input
- [x] O(n log n) time in the worst case, and O(n) when the input is already in order
- [ ] O(n²) time in the worst case, like quicksort

---

Which key sorts words by length, longest first, and alphabetically within the same length?

- [ ] `key=lambda w: (len(w), w), reverse=True`
- [x] `key=lambda w: (-len(w), w)`
- [ ] `key=lambda w: (w, -len(w))`

---

Put the lines in order so `by_score` sorts `(name, score)` pairs by score, highest first, keeping the input order for ties.

```python arrange
def by_score(pairs):
    def score(pair):
        return pair[1]
    return sorted(pairs, key=score, reverse=True)
```

```tests
by_score([("a", 1), ("b", 3), ("c", 2)]) == [("b", 3), ("c", 2), ("a", 1)]
by_score([("a", 2), ("b", 2), ("c", 5)]) == [("c", 5), ("a", 2), ("b", 2)]
by_score([("x", 0)]) == [("x", 0)]
by_score([]) == []
```

---

[Sort words by length](exercises/sort-words-by-length.md)

[Rank players](exercises/rank-players.md)

[Sort by frequency](exercises/sort-by-frequency.md)
