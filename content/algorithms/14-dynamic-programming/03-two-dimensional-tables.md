---
id: two-dimensional-tables
title: Tables in two dimensions
---

A robot starts at the top left of a grid and moves only right or down. How many paths take it to the bottom right?

Every path into a cell arrives from the cell above or the cell to the left. So `paths[r][c] = paths[r - 1][c] + paths[r][c - 1]`. The top row and the left column have one path each: straight along the edge.

```diagram
grid paths
row [1, 1, 1, 1]
row [1, 2, 3, 4]
row [1, 3, 6, 10]
highlight 2,3
arrow 2,3 -> 1,3
arrow 2,3 -> 2,2
```

---

The state now has two parts, a row and a column, so the table is a grid. Fill it row by row, left to right: the cell above and the cell to the left are always done.

A rock at row 1, column 1 blocks its cell, which keeps 0 paths. What does this print?

```python predict
rows, cols = 3, 4
paths = [[0] * cols for _ in range(rows)]
for r in range(rows):
    for c in range(cols):
        if (r, c) == (1, 1):
            continue
        if r == 0 and c == 0:
            paths[r][c] = 1
            continue
        up = paths[r - 1][c] if r > 0 else 0
        left = paths[r][c - 1] if c > 0 else 0
        paths[r][c] = up + left
for row in paths:
    print(row)
```

---

Tables over two strings work the same way. A subsequence keeps some characters in order and drops the rest: "ace" is a subsequence of "abcde". The longest common subsequence, or LCS, of two strings is the longest string that is a subsequence of both.

The state is `dp[i][j]`, the LCS length of `a[:i]` and `b[:j]`. Compare their last characters:

- If `a[i - 1] == b[j - 1]`, keep that character: `dp[i - 1][j - 1] + 1`.
- Otherwise one of the two isn't in the LCS. Drop either: `max(dp[i - 1][j], dp[i][j - 1])`.

Row 0 and column 0 stand for an empty prefix, whose LCS is 0.

---

The table for "ace" and "abcde". Highlighted cells are where the characters match and a diagonal step adds 1.

```diagram
grid dp
col-labels [, a, b, c, d, e]
row-labels [, a, c, e]
row [0, 0, 0, 0, 0, 0]
row [0, 1, 1, 1, 1, 1]
row [0, 1, 1, 2, 2, 2]
row [0, 1, 1, 2, 2, 3]
highlight 1,1 2,3 3,5
arrow 3,5 -> 2,4
```

The bottom right holds the answer, 3.

---

Run this to watch the table for "dance" and "ancient" fill in. Each arrow points to the cell the value came from.

```python
import viz

a, b = "dance", "ancient"
m, n = len(a), len(b)
dp = [[0] * (n + 1)]
dp += [[0] + [None] * n for _ in range(m)]

for i in range(1, m + 1):
    for j in range(1, n + 1):
        if a[i - 1] == b[j - 1]:
            dp[i][j] = dp[i - 1][j - 1] + 1
            src = (i - 1, j - 1)
            note = f"{a[i - 1]} matches"
        elif dp[i - 1][j] >= dp[i][j - 1]:
            dp[i][j] = dp[i - 1][j]
            src, note = (i - 1, j), "copy from above"
        else:
            dp[i][j] = dp[i][j - 1]
            src, note = (i, j - 1), "copy from the left"
        viz.grid(dp, highlight=(i, j),
                 arrows=[((i, j), src)],
                 row_labels=[""] + list(a),
                 col_labels=[""] + list(b), note=note)
```

---

The table gives the length. To get the string itself, walk back from the bottom right along the arrows:

- If the characters match, that character is in the LCS. Take it and step diagonally.
- Otherwise step toward the neighbor with the bigger value, up or left: the number came from there.

Stop at row 0 or column 0. The characters come out last first. What does this print?

```python predict
a, b = "dance", "ancient"
m, n = len(a), len(b)
dp = [[0] * (n + 1) for _ in range(m + 1)]
for i in range(1, m + 1):
    for j in range(1, n + 1):
        if a[i - 1] == b[j - 1]:
            dp[i][j] = dp[i - 1][j - 1] + 1
        else:
            dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])

out = []
i, j = m, n
while i > 0 and j > 0:
    if a[i - 1] == b[j - 1]:
        out.append(a[i - 1])
        i, j = i - 1, j - 1
    elif dp[i - 1][j] >= dp[i][j - 1]:
        i -= 1
    else:
        j -= 1
print(dp[m][n], "".join(reversed(out)))
```

---

How many single-character edits turn "horse" into "ros"? An edit inserts, deletes or replaces one character. Here it takes 3: replace the h with r, then delete the second r and the e. This number is the edit distance.

`dp[i][j]` is the fewest edits that turn `a[:i]` into `b[:j]`. If the last characters match, they cost nothing: `dp[i - 1][j - 1]`. Otherwise one edit fixes the end, plus the best for the rest:

- replace `a[i - 1]` with `b[j - 1]`: `dp[i - 1][j - 1] + 1`
- delete `a[i - 1]`: `dp[i - 1][j] + 1`
- insert `b[j - 1]`: `dp[i][j - 1] + 1`

---

What is `dp[i][0]`, the fewest edits that turn `a[:i]` into the empty string?

- [ ] 0, as in the LCS table
- [x] `i`, one delete per character
- [ ] `len(a)`, deleting the whole string

---

Filling an LCS or edit distance table for strings of lengths m and n takes

- [ ] O(m + n) time
- [x] O(m · n) time
- [ ] O(2ᵐ⁺ⁿ) time

Each row reads only the row above it, so for the number alone two rows are enough: O(n) space. Rebuilding the string needs the whole table.

---

Put the lines in order so `min_path_sum` returns the smallest total along a path from the top left to the bottom right of `grid`, moving only right or down.

```python arrange
def min_path_sum(grid):
    rows, cols = len(grid), len(grid[0])
    best = [[0] * cols for _ in range(rows)]
    for r in range(rows):
        for c in range(cols):
            before = []
            if r > 0:
                before.append(best[r - 1][c])
            if c > 0:
                before.append(best[r][c - 1])
            best[r][c] = grid[r][c] + min(before, default=0)
    return best[-1][-1]
```

```tests
min_path_sum([[1, 3, 1], [1, 5, 1], [4, 2, 1]]) == 7
min_path_sum([[5]]) == 5
min_path_sum([[1, 2, 3]]) == 6
min_path_sum([[1], [2], [3]]) == 6
min_path_sum([[1, 2], [1, 1]]) == 3
min_path_sum([[0, 0], [0, 0]]) == 0
```

---

[Paths around rocks](exercises/grid-paths-blocked.md)

[Longest common subsequence](exercises/common-subsequence.md)

[Edit distance](exercises/min-edits.md)
