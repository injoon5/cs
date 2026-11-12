---
id: grid-word-search
title: Word search
level: stretch
---

`grid` is a list of equal-length strings. Return `True` if `word` can be spelled by a path of cells, each one next to the one before it: up, down, left or right. A path can't use the same cell twice. In this grid `"card"` is there, going `c`, `a`, `r`, `d`. `"tat"` is not, because it would need the one `t` twice.

```
cat
xrs
ode
```

`word` has at least one letter.

```python starter
def word_search(grid, word):
    pass
```

```tests
word_search(["cat", "xrs", "ode"], "card") == True
word_search(["cat", "xrs", "ode"], "cats") == True
word_search(["cat", "xrs", "ode"], "tat") == False
word_search(["cat", "xrs", "ode"], "cad") == False
word_search(["cat", "xrs", "ode"], "rode") == False
word_search(["cat", "xrs", "ode"], "xod") == True
word_search(["a"], "a") == True
word_search(["a"], "aa") == False
word_search([], "a") == False
word_search(["aa", "aa"], "aaaa") == True
word_search(["aa", "aa"], "aaaaa") == False
word_search(["ab", "cd"], "abdc") == True
word_search(["ab", "cd"], "ad") == False
word_search(["aaaa", "aaaa", "aaab"], "aaaaaaaaaaab") == True
```

```python solution
def word_search(grid, word):
    rows = len(grid)
    cols = len(grid[0]) if grid else 0
    used = set()

    def explore(r, c, k):
        if k == len(word):
            return True
        if not (0 <= r < rows and 0 <= c < cols):
            return False
        if (r, c) in used or grid[r][c] != word[k]:
            return False
        used.add((r, c))
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if explore(r + dr, c + dc, k + 1):
                used.discard((r, c))
                return True
        used.discard((r, c))
        return False

    return any(explore(r, c, 0) for r in range(rows) for c in range(cols))
```

## Hints

1. Try every cell as a starting point. From there, each step is a choice of up to four neighbors.
2. `explore(r, c, k)` asks whether `word[k:]` can be spelled starting at `(r, c)`. Fail on cells off the grid, cells already used, or the wrong letter.
3. Add `(r, c)` to a `used` set, try the four neighbors with `k + 1`, then remove it before returning. Return `True` as soon as `k == len(word)`.
