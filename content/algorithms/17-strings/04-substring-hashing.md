---
id: substring-hashing
title: Comparing substrings
---

Rabin-Karp hashes windows of one length, left to right. Other problems compare substrings anywhere in the string, of any length. For those, store the hash of every prefix, the way prefix sums store the total of every prefix.

With digits it's easy to see. For `31415`, `h[i]` is the number made by the first `i` digits.

```diagram
array h [0, 3, 31, 314, 3141, 31415]
pointer i 2
pointer j 4
```

The substring `s[2:4]` is `41`. Take `h[4]`, which is 3141, and subtract `h[2]`, which is 31, shifted left two places: `3141 - 31·10² = 41`.

---

The same works mod `P`, for any `i` and `j`:

```
hash(s[i:j]) = (h[j] - h[i] * B^(j-i)) % P
```

Build `h` and the powers `pw[k] = B^k % P` once, in O(n). Every substring's hash is then O(1).

```python trace stop=14
s = "31415"
B, P = 10, 1_000_000_007
h = [0]
pw = [1]
for ch in s:
    h.append((h[-1] * B + int(ch)) % P)
    pw.append(pw[-1] * B % P)
i, j = 2, 4
print((h[j] - h[i] * pw[j - i]) % P)
```

Three digits have been read. What is `h`?

- [ ] `[3, 31, 314]`
- [ ] `[0, 3, 1, 4]`
- [x] `[0, 3, 31, 314]`

---

After the O(n) setup, checking whether two substrings of length L are equal costs

- [ ] O(L), one comparison per character
- [x] O(1), one comparison of two hashes, if you accept a tiny chance of a collision
- [ ] O(log L)

---

Rabin-Karp could afford to check each hash match by comparing characters. Here the point is to skip that check, so a collision is a wrong answer. How likely is one?

You put the hashes of 100,000 different substrings in a set, mod `P = 1_000_000_007`. About how many pairs of them collide?

- [ ] About 0.0001, one chance in a billion per substring
- [x] About 5, because there are about 5 billion pairs
- [ ] About 100,000, because every substring collides with something

---

That's the birthday paradox: collisions grow with the number of pairs, about n²/2P. So for substring hashes without a check, use a much bigger prime. `P = 2**61 - 1` is a common choice. The same 100,000 substrings then expect about 0.000000002 collisions, and Python's integers handle the big products without overflow.

One more risk: if someone can build an input knowing your `B` and `P`, they can make two strings collide on purpose. Picking `B` at random when the program starts takes that away.

---

What does this print?

```python predict
B, P = 256, 2**61 - 1
s = "abcabcx"
h, pw = [0], [1]
for ch in s:
    h.append((h[-1] * B + ord(ch)) % P)
    pw.append(pw[-1] * B % P)


def sub(i, j):
    return (h[j] - h[i] * pw[j - i]) % P


print(sub(0, 3) == sub(3, 6))
print(sub(0, 4) == sub(3, 7))
print(sub(1, 3) == sub(4, 6), sub(2, 2) == sub(6, 6))
```

---

Now find the longest substring that occurs at least twice. Occurrences may overlap. In `banana` it's `ana`, at 1 and at 3.

If some substring of length L repeats, so does its prefix of length L - 1. So the answer to "is there a repeat of length L?" is yes up to some length and no after it. For `banana`, indexed by length:

```diagram
array repeats [yes, yes, yes, yes, no, no]
pointer best 3
```

That shape is what binary search on the answer needs, as in the binary search unit. Each check puts the hash of every window of length L in a set and looks for one that's already there: O(n). With about log n checks, the search costs O(n log n).

---

Here each check uses slices, to keep it short. What does this print?

```python predict
def has_repeat(s, length):
    seen = set()
    for i in range(len(s) - length + 1):
        part = s[i:i + length]
        if part in seen:
            return True
        seen.add(part)
    return False


s = "banana"
lo, hi = 0, len(s) - 1
while lo < hi:
    mid = (lo + hi + 1) // 2
    ok = has_repeat(s, mid)
    print(mid, ok)
    if ok:
        lo = mid
    else:
        hi = mid - 1
print(lo)
```

Each slice costs O(L), so this version is O(n·L) per check. Swapping `part` for the substring's hash makes each check O(n).

---

Put the lines in order so `prefix_hashes` returns the prefix hashes `h` and the powers `pw` of a string.

```python arrange
def prefix_hashes(s, B, P):
    h = [0]
    pw = [1]
    for ch in s:
        h.append((h[-1] * B + ord(ch)) % P)
        pw.append(pw[-1] * B % P)
    return h, pw
```

```python tests
B, P = 256, 2**61 - 1
h, pw = prefix_hashes("abcabc", B, P)
assert len(h) == len(pw) == 7
assert h[0] == 0 and pw[0] == 1
assert h[1] == ord("a") and pw[3] == 256 ** 3
assert (h[3] - h[0] * pw[3]) % P == (h[6] - h[3] * pw[3]) % P
assert prefix_hashes("", B, P) == ([0], [1])
```

---

[Distinct substrings of length k](exercises/distinct-k-substrings.md)

[Longest repeated substring](exercises/longest-repeated-substring.md)
