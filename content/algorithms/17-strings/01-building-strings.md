---
id: building-strings
title: Building strings
---

A Python string can't change after it's made. You can't assign to one of its characters, and every method that seems to edit it returns a new string.

```python
s = "jello"
try:
    s[0] = "h"
except TypeError as e:
    print(e)
t = "h" + s[1:]
print(s, t)
```

`s` is untouched. `t` is a new string, built by copying.

---

So `s = s + ch` doesn't add one character to `s`. It makes a new string and copies all of `s`, then `ch`, into it. Count the characters copied. What does this print?

```python predict
copied = 0
s = ""
for ch in "abcde":
    s = s + ch
    copied += len(s)
print(s, copied)
```

---

Building a string of n characters this way copies 1, then 2, then 3, and so on up to n characters. In total that is

- [ ] O(n), one copy per character
- [ ] O(n log n)
- [x] O(n²), about n²/2 characters copied

CPython can sometimes grow the string in place when nothing else refers to it, which hides the cost. Don't rely on it. It's an implementation detail, and a second name pointing at the string turns it off.

---

The fix is to collect the pieces in a list and join them once at the end. `join` adds up the lengths first, makes one string of the right size, and copies each piece into it once. That's O(total length).

```python
parts = []
for i in range(6):
    parts.append(str(i * i))
print(",".join(parts))
```

The string before `.join` goes between the pieces. Use `""` to put nothing between them.

---

`join` takes any iterable of strings, and a string is an iterable of one-character strings. What does this print?

```python predict
print("-".join("abc"))
print("".join(["ab", "", "c"]))
print(", ".join(str(n) for n in [3, 1, 2]))
```

---

When you need to change characters in place, turn the string into a list of characters, edit the list, and join it back. A list can change; two pointers can swap in it, as in the arrays unit.

```python
chars = list("hello")
chars[0] = "j"
chars.append("!")
print("".join(chars))
```

`list(s)` and `"".join(chars)` each cost O(n), once. Every edit in between is O(1).

---

Slicing copies too. `s[1:]` is a new string of n - 1 characters. This palindrome check looks harmless:

```python
def is_pal(s):
    if len(s) < 2:
        return True
    return s[0] == s[-1] and is_pal(s[1:-1])
```

On a palindrome of length n, it takes

- [ ] O(n) time, one comparison per pair of characters
- [x] O(n²) time, because each call copies the middle of the string
- [ ] O(log n) time, because each call drops two characters

Pass indexes instead of slices, and the same check is O(n).

---

Characters are numbers underneath. `ord(ch)` gives a character's code, and `chr(n)` turns a code back into a character. The lowercase letters have codes 97 to 122, in order, so `ord(ch) - ord("a")` maps `a` to 0 and `z` to 25.

That makes a list of 26 counts a cheap stand-in for a dict, when the strings hold only lowercase letters.

```python trace stop=8
counts = [0] * 26
for ch in "bead":
    counts[ord(ch) - ord("a")] += 1
print(counts[:5])
```

Three letters have been counted. What does `counts` start with?

- [ ] `[0, 1, 0, 0, 1]`
- [x] `[1, 1, 0, 0, 1]`
- [ ] `[1, 1, 0, 1, 1]`

---

Walking the 26 counts in order and turning each slot back into a letter with `chr` gives the letters sorted, in O(n) time. What does this print?

```python predict
counts = [0] * 26
for ch in "banana":
    counts[ord(ch) - ord("a")] += 1
out = []
for i, c in enumerate(counts):
    out.append(chr(ord("a") + i) * c)
print("".join(out))
```

---

Put the lines in order so `to_snake` turns `"camelCase"` into `"camel_case"`. It builds a list of pieces and joins once.

```python arrange
def to_snake(name):
    parts = []
    for ch in name:
        if ch.isupper():
            parts.append("_" + ch.lower())
        else:
            parts.append(ch)
    return "".join(parts)
```

```tests
to_snake("camelCase") == "camel_case"
to_snake("getX") == "get_x"
to_snake("aBC") == "a_b_c"
to_snake("name") == "name"
to_snake("") == ""
```

---

[Run-length encoding](exercises/run-length-encode.md)

[Reverse the words](exercises/reverse-word-order.md)
