---
id: kmp-search
title: KMP search and periods
---

The prefix function already searches. Glue the pattern, a separator that appears in neither string, and the text: `pat + "#" + text`. No border can reach across the `#`, so no `pi` value is bigger than m. Wherever `pi[i]` equals m, the m characters ending at `i` are the pattern. What does this print?

```python predict
def prefix_function(s):
    pi = [0] * len(s)
    k = 0
    for i in range(1, len(s)):
        while k > 0 and s[i] != s[k]:
            k = pi[k - 1]
        if s[i] == s[k]:
            k += 1
        pi[i] = k
    return pi


pat, text = "aba", "abababa"
s = pat + "#" + text
pi = prefix_function(s)
print(pi)
m = len(pat)
print([i - 2 * m for i in range(len(s)) if pi[i] == m])
```

A match ending at `i` in the glued string starts at `i - m + 1` there, which is `i - 2m` in the text.

---

That builds a `pi` list as long as the text and the pattern together. The Knuth-Morris-Pratt algorithm, KMP, gets the same answer with only the pattern's `pi`. It walks the text once and keeps `k`, how many pattern characters match so far. On a mismatch it falls back with `k = pi[k - 1]`, just as when building `pi`. After a full match it falls back too, so overlapping matches are found.

```python
def kmp(text, pat):
    pi = prefix_function(pat)
    found = []
    k = 0
    for i, ch in enumerate(text):
        while k > 0 and ch != pat[k]:
            k = pi[k - 1]
        if ch == pat[k]:
            k += 1
        if k == len(pat):
            found.append(i - k + 1)
            k = pi[k - 1]
    return found


def prefix_function(s):
    pi = [0] * len(s)
    k = 0
    for i in range(1, len(s)):
        while k > 0 and s[i] != s[k]:
            k = pi[k - 1]
        if s[i] == s[k]:
            k += 1
        pi[i] = k
    return pi


print(kmp("ababababc", "ababc"))
print(kmp("abababa", "aba"))
```

---

Run this to watch KMP on the same text and pattern as the naive animation. The shaded cells are the part of the text that matches the pattern's first `k` characters. `i` only ever moves right.

```python
import viz

text, pat = "ababababc", "ababc"
pi = [0, 0, 1, 2, 0]
count = 0
k = 0
for i, ch in enumerate(text):
    while True:
        count += 1
        same = ch == pat[k]
        sign = "=" if same else "≠"
        with viz.frame():
            viz.array(list(text), name="text", pointers={"i": i}, range=(i - k, i - 1), highlight=i)
            viz.array(list(pat), name="pattern", pointers={"k": k}, highlight=k,
                      note=f"compare {count}: {ch} {sign} {pat[k]}")
        if same or k == 0:
            break
        k = pi[k - 1]
        viz.note(f"fall back to k = {k}")
    if ch == pat[k]:
        k += 1
    if k == len(pat):
        viz.note(f"found at {i - k + 1}")
        k = pi[k - 1]
```

Naive matching made 17 comparisons here. KMP makes 11, and never reads a text character to the left of `i`.

---

```python trace stop=18
pat, text = "aab", "aaab"
pi = [0, 1, 0]
found = []
k = 0
for i, ch in enumerate(text):
    while k > 0 and ch != pat[k]:
        k = pi[k - 1]
    if ch == pat[k]:
        k += 1
    if k == len(pat):
        found.append(i - k + 1)
        k = pi[k - 1]
print(found)
```

At `i = 2` the text has `a` where the pattern needs `b`, and `k` has just fallen back. What is `k`?

- [ ] 0, so matching starts over from the pattern's beginning
- [x] 1, because the last `a` read still matches the pattern's first `a`
- [ ] 2, because two characters had matched

---

Each text character moves `i` forward once. Fallbacks lower `k`, which only rises by one per character, so there are at most n of them. With `pi` built in O(m), KMP takes

- [ ] O(n·m) time, O(1) extra space
- [x] O(n + m) time, O(m) extra space
- [ ] O(n log m) time, O(m) extra space

---

KMP never moves back in the text. What does that let it do that naive matching can't?

- [x] Read the text as a stream, one character at a time, without keeping it in memory
- [ ] Report the matches in increasing order
- [ ] Search for several patterns in one pass

---

The prefix function also finds repeats. A string has period p if every character equals the one p places later. `abcabcab` has period 3.

```diagram
array s [a, b, c, a, b, c, a, b]
shade 0..4
highlight 3 4 5 6 7
```

Its longest border, `abcab`, sits at 0, shaded, and at 3, highlighted. A border of length b says that every character equals the one n - b places later, so n - b is a period. The longest border gives the smallest period, `n - pi[-1]`, here `8 - 5 = 3`.

---

When the period divides n, the string is its first p characters repeated. What does this print?

```python predict
def prefix_function(s):
    pi = [0] * len(s)
    k = 0
    for i in range(1, len(s)):
        while k > 0 and s[i] != s[k]:
            k = pi[k - 1]
        if s[i] == s[k]:
            k += 1
        pi[i] = k
    return pi


for s in ["abcabcab", "abababab", "aabaab", "abcd"]:
    p = len(s) - prefix_function(s)[-1]
    unit = s[:p] if len(s) % p == 0 else None
    print(s, p, unit)
```

---

With n the length of `s` and p its smallest period, `s` is some shorter string repeated two or more times exactly when

- [ ] p < n
- [ ] n % p == 0
- [x] p < n and n % p == 0

`abcabcab` has p = 3 but isn't a whole number of `abc`s. `abcd` has p = 4, which divides 4, but the only repeat is `abcd` itself.

---

The glue trick works for any two strings `a` and `b`, not only a pattern and a text. On `a + "#" + b`, the last value of `pi` is

- [ ] the length of the longest substring that `a` and `b` share
- [ ] the number of times `a` occurs in `b`
- [x] the length of the longest prefix of `a` that is also a suffix of `b`

---

[KMP search](exercises/kmp-find-all.md)

[Smallest repeating unit](exercises/smallest-period.md)

[Shortest palindrome](exercises/shortest-palindrome-front.md)
