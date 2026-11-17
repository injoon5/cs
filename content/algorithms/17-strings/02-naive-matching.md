---
id: naive-string-matching
title: Searching for a pattern
---

Where does the pattern `ababc` occur in the text `ababababc`? Line the pattern up under the text at shift 0 and compare one character at a time.

```diagram
array text [a, b, a, b, a, b, a, b, c]
pointer i 0
shade 0..4
highlight 4

array pattern [a, b, a, b, c]
pointer j 4
highlight 4
```

The first four characters match. The fifth doesn't: the text has `a` where the pattern has `c`. So the pattern isn't at shift 0. Slide it one place right and start comparing again from `j = 0`.

---

That is naive matching. Try every shift `i` from 0 to `n - m`, compare left to right, and stop at the first mismatch. If all `m` characters match, record `i`.

```python
def find_all(text, pat):
    n, m = len(text), len(pat)
    found = []
    for i in range(n - m + 1):
        j = 0
        while j < m and text[i + j] == pat[j]:
            j += 1
        if j == m:
            found.append(i)
    return found


print(find_all("ababababc", "ababc"))
print(find_all("abababa", "aba"))
```

Matches can overlap: `aba` occurs at 0, 2 and 4.

---

Run this to watch every comparison. The shaded cells are the current shift, and the highlighted cell is the one being compared.

```python
import viz

text = "ababababc"
pat = "ababc"
n, m = len(text), len(pat)
count = 0
for i in range(n - m + 1):
    j = 0
    while j < m:
        count += 1
        same = text[i + j] == pat[j]
        sign = "=" if same else "≠"
        with viz.frame():
            viz.array(list(text), name="text", pointers={"i": i}, range=(i, i + m - 1), highlight=i + j)
            viz.array(list(pat), name="pattern", pointers={"j": j}, highlight=j,
                      note=f"compare {count}: {text[i + j]} {sign} {pat[j]}")
        if not same:
            break
        j += 1
    if j == m:
        viz.note(f"found at {i}")
```

Each new shift goes back and reads text it has already read. After shift 0 the matcher knew `text[1:4]` was `bab`, and shifts 1 and 2 compare those characters again anyway.

---

```python trace stop=9
text = "aabab"
pat = "ab"
found = []
for i in range(len(text) - len(pat) + 1):
    j = 0
    while j < len(pat) and text[i + j] == pat[j]:
        j += 1
    if j == len(pat):
        found.append(i)
print(found)
```

The inner loop for shift 0 has just stopped. What is `j`?

- [ ] 0, because the shift failed
- [x] 1, because `a` matched and then `a` didn't match `b`
- [ ] 2, the length of the pattern

---

Which input makes naive matching do the most work?

- [ ] A text of random letters, with the pattern `xyz`
- [ ] The text `abcabcabc…`, with the pattern `abd`
- [x] The text `aaaa…a`, with the pattern `aaab`

---

On an all-`a` text, the pattern `aab` matches twice at every shift before failing on `b`. How many comparisons does this make?

```python predict
text = "aaaaaaaa"
pat = "aab"
comparisons = 0
for i in range(len(text) - len(pat) + 1):
    for j in range(len(pat)):
        comparisons += 1
        if text[i + j] != pat[j]:
            break
print(comparisons)
```

---

With a text of length n and a pattern of length m, there are n - m + 1 shifts and each can cost up to m comparisons. Naive matching takes

- [ ] O(n + m) time
- [ ] O(n log m) time
- [x] O(n·m) time in the worst case

On ordinary text most shifts fail on the first or second character, so it's usually close to O(n). The worst case needs a text and pattern that almost match everywhere.

---

Python already does this. `pat in text`, `text.find(pat)` and `text.index(pat)` search for one match, and `text.count(pat)` counts them. What does this print?

```python predict
text = "abababa"
print("bab" in text)
print(text.find("aba"), text.find("aba", 1), text.find("xyz"))
print(text.count("aba"))
```

`find` takes a start index and returns -1 when there is no match. `count` skips past each match, so it counts only matches that don't overlap.

---

These are written in C and fast, and since Python 3.10 long patterns switch to a method that is linear even in the worst case. In real code, use them.

The rest of this unit matches by hand anyway, because the two ideas behind fast matching solve problems `find` can't: hashing a window in O(1) as it slides, and reusing what a mismatch already told you.

---

Put the lines in order so `first_match` returns the first shift where `pat` occurs in `text`, or -1.

```python arrange
def first_match(text, pat):
    m = len(pat)
    for i in range(len(text) - m + 1):
        j = 0
        while j < m and text[i + j] == pat[j]:
            j += 1
        if j == m:
            return i
    return -1
```

```tests
first_match("abacaba", "cab") == 3
first_match("abababa", "aba") == 0
first_match("aab", "ab") == 1
first_match("aaa", "b") == -1
first_match("ab", "abc") == -1
first_match("abc", "") == 0
```

---

[Is it a rotation](exercises/is-rotation.md)

[Find every match](exercises/naive-find-all.md)
