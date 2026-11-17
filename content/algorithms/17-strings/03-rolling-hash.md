---
id: rolling-hash
title: Rolling hash
---

Naive matching compares up to m characters at every shift. Comparing two numbers is one step. So give each window of the text a number, and compare it with the pattern's number.

Start with digits. The windows of length 3 in `31415` are the numbers 314, 141 and 415.

```diagram
array text [3, 1, 4, 1, 5]
pointer i 1
shade 1..3
```

To go from 314 to 141, drop the leading 3 by subtracting 300, shift left by multiplying by 10, and add the new digit 1: `(314 - 3·100)·10 + 1 = 141`. That's the same few steps however long the window is, like the window sums in the arrays unit.

---

What does this print?

```python predict
digits = "31415"
m = 3
h = int(digits[:m])
print(h)
for i in range(m, len(digits)):
    h = (h - int(digits[i - m]) * 10 ** (m - 1)) * 10 + int(digits[i])
    print(h)
```

---

Letters work the same way. Treat each character's code `ord(ch)` as one digit in base `B`, with a base like 256. A window of 1,000 characters is then a number with over 2,000 decimal digits, so keep only its remainder mod a large prime `P`. Adding, subtracting and multiplying all work on remainders, so rolling still does.

The result is the window's polynomial hash: `ord(s[0])·B^(m-1) + … + ord(s[m-1])`, mod `P`. `poly_hash` below builds it one character at a time. With `power = B^(m-1) mod P`, sliding one place right is

```
h = ((h - ord(out) * power) * B + ord(new)) % P
```

```python
B, P = 256, 1_000_000_007


def poly_hash(s):
    h = 0
    for ch in s:
        h = (h * B + ord(ch)) % P
    return h


text, m = "rolling", 3
power = pow(B, m - 1, P)
h = poly_hash(text[:m])
for i in range(m, len(text)):
    h = ((h - ord(text[i - m]) * power) * B + ord(text[i])) % P
    window = text[i - m + 1:i + 1]
    print(window, h, h == poly_hash(window))
```

In Python, `%` of a negative number is never negative, so the subtraction is safe. `pow(B, m - 1, P)` computes the power mod `P` without building the huge number.

---

Remainders throw information away, so two different windows can get the same hash. That's a collision. With a tiny `P` they're easy to find: mod 13, the windows `31`, `14`, `41`, `15` hash to 5, 1, 2, 2.

```diagram
array text [3, 1, 4, 1, 5]
pointer i 2
shade 2..3
```

Searching for `15`, whose hash is 2, the window `41` looks like a match too. So the search that uses rolling hashes, called Rabin-Karp, treats equal hashes only as a hint. When the hashes match, it compares the characters to make sure.

---

Here is Rabin-Karp on digits, with `B = 10` and `P = 13`, so `int(s) % 13` is the hash.

```python trace stop=17
text, pat = "31415", "15"
B, P = 10, 13
m = len(pat)
power = pow(B, m - 1, P)
hp = int(pat) % P
hw = int(text[:m]) % P
found = []
for i in range(len(text) - m + 1):
    if hw == hp and text[i:i + m] == pat:
        found.append(i)
    if i + m < len(text):
        hw = ((hw - int(text[i]) * power) * B + int(text[i + m])) % P
print(found)
```

At `i = 2`, `hw` equals `hp`. What happens next?

- [ ] 2 is appended to `found`, because the hashes match
- [x] Nothing is appended, because `text[2:4]` is `41`, not `15`
- [ ] The loop stops, because a collision means the pattern isn't there

---

Why does Rabin-Karp compare the characters after the hashes match?

- [ ] To find where the match starts
- [x] Different strings can have the same hash, so a matching hash doesn't prove a match
- [ ] Rolling the hash can make an arithmetic mistake, so the hash may be wrong

---

If the hashes behave like random numbers mod `P`, a window that doesn't match the pattern has about a 1 in `P` chance of colliding with it. With `P = 1_000_000_007` and a million windows, you expect about 0.001 false alarms. So the character check runs almost only on real matches.

When does Rabin-Karp take O(n·m) time?

- [x] When the pattern really occurs at almost every shift, since each match is checked in O(m)
- [ ] When the text uses many different characters
- [ ] When the pattern is long, since each roll handles m characters

---

Each shift costs O(1) to roll and compare the hashes, plus O(m) for each real match it checks. With few matches, Rabin-Karp takes

- [ ] O(n·m) time
- [x] O(n + m) time
- [ ] O(n log m) time

---

Put the lines in order so `window_hashes` returns the hash of every window of length `m`, rolling each one from the one before.

```python arrange
def window_hashes(s, m, B, P):
    power = pow(B, m - 1, P)
    h = 0
    for ch in s[:m]:
        h = (h * B + ord(ch)) % P
    out = [h]
    for i in range(m, len(s)):
        h = ((h - ord(s[i - m]) * power) * B + ord(s[i])) % P
        out.append(h)
    return out
```

```python tests
def direct(s, B, P):
    h = 0
    for ch in s:
        h = (h * B + ord(ch)) % P
    return h


for s, m in [("rolling", 3), ("abcab", 2), ("aaaa", 4), ("xyz", 1)]:
    expected = [direct(s[i:i + m], 256, 101) for i in range(len(s) - m + 1)]
    assert window_hashes(s, m, 256, 101) == expected
```

---

[Rabin-Karp](exercises/rabin-karp-find-all.md)
