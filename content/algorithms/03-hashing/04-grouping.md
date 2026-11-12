---
id: grouping-by-key
title: Grouping by a key
---

Sort these words into groups by their first letter: "ant", "bee", "asp", "cat", "bat".

Give each word a key, here its first letter. Words with the same key go in the same list. A dict from key to list does the filing in one pass.

```python
words = ["ant", "bee", "asp", "cat", "bat"]
groups = {}
for w in words:
    groups.setdefault(w[0], []).append(w)
print(groups)
```

`setdefault(key, [])` returns the list for `key`, putting in an empty one first if the key is new.

---

The whole trick is picking a key that is the same for words that belong together and different otherwise.

Anagrams have the same letters in a different order. Sort the letters and every anagram gives the same string: "eat", "tea" and "ate" all become "aet".

```diagram
grid groups
row-labels [aet, ant, abt]
row [eat, tea, ate]
row [tan, nat, ]
row [bat, , ]
```

---

```python predict
words = ["eat", "tea", "tan",
         "ate", "nat", "bat"]
groups = {}
for w in words:
    key = "".join(sorted(w))
    groups.setdefault(key, []).append(w)
print(len(groups))
print(groups["aet"])
```

---

```python trace stop=12
words = ["eat", "tea", "tan", "bat"]
groups = {}
for w in words:
    key = "".join(sorted(w))
    groups.setdefault(key, []).append(w)
print(groups)
```

The third word was just filed. What is `groups`?

- [ ] `{'aet': ['eat'], 'tea': ['tea'], 'ant': ['tan']}`
- [x] `{'aet': ['eat', 'tea'], 'ant': ['tan']}`
- [ ] `{'aet': ['eat', 'tea', 'tan']}`

---

Sorting a word of length L costs O(L log L). Counting its letters costs O(L), and the 26 counts make a key too.

The counts start as a list, and a list can't be a key. Turn it into a tuple first.

```python
def letter_key(word):
    counts = [0] * 26
    for ch in word:
        counts[ord(ch) - ord("a")] += 1
    return tuple(counts)

print(letter_key("tea") == letter_key("eat"))
print(letter_key("tea") == letter_key("tee"))
```

---

Why does `letter_key` return `tuple(counts)` and not `counts`?

- [ ] Tuples compare faster than lists
- [x] A dict key must be hashable, and a list isn't
- [ ] A tuple uses less memory than 26 numbers

---

Grouping n words of length up to L with the sorted-letters key takes

- [ ] O(n) time
- [x] O(n · L log L) time
- [ ] O(n log n · L) time

---

Put the lines in order so `group_by_length` groups words by how long they are, in the order each length first appears.

```python arrange
def group_by_length(words):
    groups = {}
    for w in words:
        groups.setdefault(len(w), []).append(w)
    return list(groups.values())
```

```tests
group_by_length(["hi", "cat", "to", "dog"]) == [["hi", "to"], ["cat", "dog"]]
group_by_length(["a"]) == [["a"]]
group_by_length([]) == []
group_by_length(["abc", "", "x"]) == [["abc"], [""], ["x"]]
```

---

[Group anagrams](exercises/group-anagrams.md)

[Same letter pattern](exercises/same-pattern-groups.md)
