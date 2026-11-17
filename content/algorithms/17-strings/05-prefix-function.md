---
id: prefix-function
title: The prefix function
---

Back to `ababc` in `ababababc`. At shift 0, the matcher read `abab` and then failed. Naive matching throws that away and starts over at shift 1. But it already knows what those four text characters are.

```diagram
array matched [a, b, a, b]
shade 0..1
highlight 2 3
```

The shaded `ab` at the start and the highlighted `ab` at the end are the same two letters. Shift 1 would put the pattern's `a` under a `b`, so it can't work. Shift 2 lines the pattern's first two characters, `ab`, up with the last two characters read, also `ab`. Those two are already known to match, so comparing can go on from the pattern's third character, with no step back in the text.

So the next shift to try comes from the longest start of `abab` that is also an end of it. `abab` is the start of the pattern, so that depends only on the pattern, and it can be worked out once, in advance.

---

A border of a string is a prefix that is also a suffix, other than the whole string. `abab` has the borders `ab` and the empty string. `aabaa` has `aa`, `a` and the empty string.

The prefix function of `s` is a list `pi` where `pi[i]` is the length of the longest border of `s[:i + 1]`.

```diagram
array s [a, b, a, b, a, c, a]
pointer i 4

array pi [0, 0, 1, 2, 3, 0, 1]
pointer i 4
```

`pi[4]` is 3, because `ababa` starts and ends with `aba`. A border can overlap itself. `pi[0]` is always 0, since a single character's only border is empty.

---

This computes `pi` straight from the definition: for each prefix, try every length from the longest down. What does it print?

```python predict
def prefix_brute(s):
    pi = []
    for i in range(len(s)):
        t = s[:i + 1]
        k = i
        while k > 0 and t[:k] != t[-k:]:
            k -= 1
        pi.append(k)
    return pi


print(prefix_brute("aabaaab"))
print(prefix_brute("abcab"))
```

That's slow: for each `i` it can try i lengths, each with a slice compare.

---

The first fast idea: a border can grow by at most one character per step. If `s[:i + 1]` has a border of length k, dropping the last character of both copies leaves a border of `s[:i]` of length k - 1. So `pi[i]` is at most `pi[i - 1] + 1`.

It is exactly that when the next character extends the old border. The old border has length `k = pi[i - 1]`, so the character after it is `s[k]`. If `s[i] == s[k]`, then `pi[i] = k + 1`.

In `ababa`, `pi[3]` is 2, for `ab`. `s[4]` is `a`, which equals `s[2]`, so `pi[4]` is 3.

---

When it doesn't extend, try the next shorter border. A border of a border is also a border, and every border of `s[:i]` shorter than `k` is a border of its border `s[:k]`. So the next candidate is `k = pi[k - 1]`, then `pi` of that, down to 0.

```diagram
array s [a, a, b, a, a, a, b]
pointer k 2
pointer i 5

array pi [0, 1, 0, 1, 2, , ]
```

At `i = 5`, the border so far is `aa`, so `k` is 2. `s[5]` is `a` but `s[2]` is `b`: no. Fall back to `k = pi[1]`, which is 1. Now `s[5]` equals `s[1]`, so `pi[5]` is 2.

---

That gives the whole algorithm. `k` carries the longest border from one `i` to the next.

```python
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


print(prefix_function("ababaca"))
print(prefix_function("aabaaab"))
```

---

```python trace stop=28
s = "aabaaab"
pi = [0] * len(s)
k = 0
for i in range(1, len(s)):
    while k > 0 and s[i] != s[k]:
        k = pi[k - 1]
    if s[i] == s[k]:
        k += 1
    pi[i] = k
print(pi)
```

At `i = 5`, `k` has just fallen back once. What is `k`?

- [ ] 0
- [x] 1
- [ ] 2

---

The `while` loop can fall back several times for one `i`. Across the whole string, how many times can `k = pi[k - 1]` run?

- [ ] Up to i times for each i, so about n²/2 in total
- [x] At most n - 1 in total, because each fallback lowers `k`, and `k` rises by at most 1 per character
- [ ] At most log n times for each i, because each fallback halves `k`

So the prefix function takes O(n) time, the same counting argument as the sliding window: `k` can't fall more than it rose.

---

The borders of a string are its longest border, that border's longest border, and so on. Put the lines in order so `all_borders` returns their lengths, longest first, given the string's `pi`.

```python arrange
def all_borders(pi):
    out = []
    k = pi[-1]
    while k > 0:
        out.append(k)
        k = pi[k - 1]
    return out
```

```tests
all_borders([0, 1, 0, 1, 2, 2, 3]) == [3]
all_borders([0, 0, 1, 2, 3, 4, 5]) == [5, 3, 1]
all_borders([0, 1, 2, 3]) == [3, 2, 1]
all_borders([0, 0, 0]) == []
all_borders([0]) == []
```

---

[Prefix function](exercises/prefix-function-table.md)

[Longest border](exercises/longest-border.md)
