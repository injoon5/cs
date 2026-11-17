---
id: island-count
title: Count the islands
level: core
---

`grid` is a list of equal-length strings with at least one cell: `#` is land and `.` is water. An island is a group of land cells joined up, down, left or right. Cells that only touch at a corner are on different islands. Return the number of islands.

```
##..
#...
..#.
...#
```

This map has 3 islands: the three cells in the top-left corner, and two single cells that only meet at a corner.

```python starter
def islands(grid):
    pass
```

```tests
islands(["##..", "#...", "..#.", "...#"]) == 3
islands(["#"]) == 1
islands(["."]) == 0
islands(["...."]) == 0
islands(["#.#.#"]) == 3
islands(["#.#", ".#.", "#.#"]) == 5
islands(["###", "#.#", "###"]) == 1
islands(["#", "#", ".", "#"]) == 2
islands(["#" * 200] * 200) == 1
islands(["#." * 100, ".#" * 100] * 100) == 20000
```

```python tests
import random


def slow(grid):
    rows, cols = len(grid), len(grid[0])
    label = {(r, c): r * cols + c for r in range(rows) for c in range(cols) if grid[r][c] == "#"}
    changed = True
    while changed:
        changed = False
        for (r, c), lab in list(label.items()):
            for cell in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                if cell in label and label[cell] < lab:
                    label[(r, c)] = lab = label[cell]
                    changed = True
    return len(set(label.values()))


for _ in range(300):
    rows, cols = random.randint(1, 6), random.randint(1, 6)
    grid = ["".join(random.choice("#.") for _ in range(cols)) for _ in range(rows)]
    assert islands(grid) == slow(grid), grid
```

```python solution
def islands(grid):
    rows, cols = len(grid), len(grid[0])
    seen = set()
    count = 0
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] != "#" or (r, c) in seen:
                continue
            count += 1
            seen.add((r, c))
            stack = [(r, c)]
            while stack:
                cr, cc = stack.pop()
                for nr, nc in ((cr - 1, cc), (cr + 1, cc), (cr, cc - 1), (cr, cc + 1)):
                    if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] == "#" and (nr, nc) not in seen:
                        seen.add((nr, nc))
                        stack.append((nr, nc))
    return count
```

## Hints

1. Each island is a connected component of land cells. Count the components.
2. Scan every cell. A land cell you haven't seen yet starts a new island: count it, then mark its whole island so you never count it again.
3. Mark with your own stack, not recursion: a 200 × 200 island would go far past Python's recursion limit. Push the starting cell, then pop cells and push their unseen land neighbors.
