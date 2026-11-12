---
id: keys-and-sets
title: Keys and sets
---

A table files each key under its hash. If a key could change after it was stored, its hash would change too, and the table would look in the wrong bucket.

So Python only takes keys that can't change: numbers, strings, tuples of those, and `frozenset`. A list can change, so it can't be a key. A tuple can.

```python
seats = {}
seats[(2, 5)] = "Ana"
print(seats[(2, 5)])
try:
    seats[[2, 5]] = "Ben"
except TypeError as e:
    print(e)
```

---

The other rule: keys that are equal must hash the same, so they find the same slot. `1`, `1.0` and `True` are all equal in Python. What does this print?

```python predict
d = {}
d[1] = "int"
d[1.0] = "float"
d[True] = "bool"
print(len(d), d[1])
```

---

Which of these can be a dict key?

- [x] `(3, 4)`
- [x] `"3,4"`
- [ ] `[3, 4]`
- [ ] `(3, [4])`

---

A `set` is a hash table with keys and no values. `x in s` is O(1) on average, where `x in some_list` is O(n).

A set also removes repeats, but it doesn't keep the order you added things in. When order matters, a dict does: it remembers insertion order, and `dict.fromkeys` makes one with every value as a key.

```python
nums = [3, 1, 3, 2, 1]
print(sorted(set(nums)))
print(list(dict.fromkeys(nums)))
```

---

This finds the first number that shows up a second time. `seen` holds everything before the current item.

```python trace stop=7
nums = [4, 2, 7, 2, 4]
seen = set()
for x in nums:
    if x in seen:
        break
    seen.add(x)
print(x)
```

The loop is about to check `x in seen` for the second item. What is in `seen`?

- [ ] Nothing yet
- [x] Only 4
- [ ] 4 and 2

---

Sets also answer questions about two groups at once. `&` keeps what is in both, `-` what is only in the first, and `|` everything.

```python predict
a = {1, 2, 3, 4}
b = {3, 4, 5}
print(sorted(a & b), sorted(a - b))
print(len(a | b))
```

---

Put the lines in order so `first_repeat` returns the first value seen twice, or `None`.

```python arrange
def first_repeat(nums):
    seen = set()
    for x in nums:
        if x in seen:
            return x
        seen.add(x)
    return None
```

```tests
first_repeat([4, 2, 7, 2, 4]) == 2
first_repeat([1, 2, 3]) == None
first_repeat([]) == None
first_repeat([5, 5]) == 5
```

---

`first_repeat` checks n items against a set. If `seen` were a list instead, the whole loop would take

- [ ] O(n), the same as with a set
- [ ] O(n log n)
- [x] O(n²), because each `x in seen` scans up to n items

---

[Shared items](exercises/shared-items.md)

[Dedupe, ignoring case](exercises/dedupe-ignore-case.md)

[Longest streak](exercises/longest-streak.md)
