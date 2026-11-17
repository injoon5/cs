---
id: interval-dp
title: Dynamic programming on intervals
---

A palindrome reads the same both ways. What is the longest palindrome you can get from "bbbab" by deleting characters? Deleting the a leaves "bbbb", length 4.

Look at the two ends of the string. If they match, they can wrap the best palindrome from the inside. If they don't, at least one of them is left out, so drop one end and solve the rest.

So the state is a piece of the string, `s[i..j]`, both ends included. `dp[i][j]` is the longest palindromic subsequence in it:

- `dp[i][i]` is 1: one character is a palindrome.
- If `s[i] == s[j]`: `dp[i + 1][j - 1] + 2`.
- Otherwise: `max(dp[i + 1][j], dp[i][j - 1])`.

---

Every cell reads cells for shorter pieces: one row down, one column left, or both. Here is the table for "bbbab". Only `i <= j` makes sense, so the lower half is empty.

```diagram
grid dp
col-labels [b, b, b, a, b]
row-labels [b, b, b, a, b]
row [1, 2, 3, 3, 4]
row [, 1, 2, 2, 3]
row [, , 1, 1, 3]
row [, , , 1, 1]
row [, , , , 1]
highlight 0,4
arrow 0,4 -> 1,3
```

The ends of "bbbab" match, so the answer is 2 plus the best inside "bba", which is 2.

---

Fill the table by length: the diagonal first, then every piece of length 2, then 3, and so on. Every piece a cell reads is shorter, so it is already done. This loop lists the pieces of "abcd" in that order. What does it print?

```python predict
s = "abcd"
n = len(s)
for length in range(2, n + 1):
    pieces = []
    for i in range(n - length + 1):
        j = i + length - 1
        pieces.append(s[i:j + 1])
    print(length, pieces)
```

---

In the table, each length is one diagonal, moving up and to the right. Run this to watch them fill for "agbdba".

```python
import viz

s = "agbdba"
n = len(s)
dp = [[None] * n for _ in range(n)]
for i in range(n):
    dp[i][i] = 1
viz.grid(dp, row_labels=list(s), col_labels=list(s),
         note="length 1")

for length in range(2, n + 1):
    for i in range(n - length + 1):
        j = i + length - 1
        inner = dp[i + 1][j - 1] if length > 2 else 0
        if s[i] == s[j]:
            dp[i][j] = inner + 2
            arrows = [((i, j), (i + 1, j - 1))]
        else:
            dp[i][j] = max(dp[i + 1][j], dp[i][j - 1])
            arrows = [((i, j), (i + 1, j)),
                      ((i, j), (i, j - 1))]
        viz.grid(dp, highlight=(i, j), arrows=arrows,
                 row_labels=list(s), col_labels=list(s),
                 note=f"{s[i:j + 1]}: {dp[i][j]}")
```

---

Filling by length isn't the only order that works. Which other one does?

- [ ] Row 0 first, then row 1, and so on, each left to right
- [x] The last row first, then up to row 0, each row left to right from the diagonal
- [ ] The last column first, then leftward, each column top to bottom

---

For a string of length n, filling the table takes

- [ ] O(n) time
- [x] O(n²) time
- [ ] O(n³) time

---

Some interval problems choose where to split. A stick of length 7 needs cuts at 1, 3, 4 and 5. Each cut costs the length of the piece being cut, so the order matters.

```diagram
array marks [0, 1, 3, 4, 5, 7]
highlight 2
```

Cutting from left to right costs 7 + 6 + 4 + 3 = 20. Cutting at 3 first costs 7. Then the pieces 0 to 3 and 3 to 7 are separate problems: cut the right one at 5 for 4, the left one at 1 for 3, and the piece from 3 to 5 at 4 for 2. That is 16 in all.

---

Add the two ends to the cuts and sort them into `marks`. The state is `cost(i, j)`, the cheapest way to make every cut strictly between `marks[i]` and `marks[j]`.

Try each mark `k` in between as the first cut. It costs the whole piece, `marks[j] - marks[i]`, and leaves two smaller intervals that don't affect each other:

`cost(i, j) = marks[j] - marks[i] + min(cost(i, k) + cost(k, j))`

With no mark in between, the cost is 0.

```python
from functools import cache

marks = [0, 1, 3, 4, 5, 7]


@cache
def cost(i, j):
    if j - i < 2:
        return 0
    piece = marks[j] - marks[i]
    return piece + min(cost(i, k) + cost(k, j)
                       for k in range(i + 1, j))


print(cost(0, len(marks) - 1))
```

A memo handles the order for you: each call asks for shorter intervals, and the recursion is only as deep as the number of marks.

---

With m marks there are O(m²) intervals, and each one tries O(m) split points. Cutting the stick this way takes

- [ ] O(m²) time
- [x] O(m³) time
- [ ] O(2ᵐ) time

---

[Longest palindromic subsequence](exercises/longest-pal-subseq.md)

[Cut a stick](exercises/cut-stick-cost.md)
