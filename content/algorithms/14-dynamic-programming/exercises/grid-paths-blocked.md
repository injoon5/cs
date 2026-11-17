---
id: grid-paths-blocked
title: Paths around rocks
level: warmup
---

`grid` is a list of rows, with 0 for an open cell and 1 for a rock. A robot starts at the top left and moves only right or down, never onto a rock. Return the number of paths to the bottom right. If either corner is a rock, or the grid is empty, there are none.

```diagram
grid
row [0, 0, 0]
row [0, 1, 0]
row [0, 0, 0]
highlight 1,1
```

This grid has 2 paths: around the rock along the top, or along the left.

```python starter
def count_paths(grid):
    pass
```

```tests
count_paths([[0, 0, 0], [0, 1, 0], [0, 0, 0]]) == 2
count_paths([[0, 0, 0], [0, 0, 0]]) == 3
count_paths([[0]]) == 1
count_paths([[1]]) == 0
count_paths([]) == 0
count_paths([[1, 0], [0, 0]]) == 0
count_paths([[0, 0], [0, 1]]) == 0
count_paths([[0, 1], [0, 0]]) == 1
count_paths([[0, 0, 0, 0]]) == 1
count_paths([[0, 1, 0]]) == 0
count_paths([[0, 0], [1, 1], [0, 0]]) == 0
count_paths([[0] * 18 for _ in range(18)]) == 2333606220
```

```python tests
import random


def brute(grid, r=0, c=0):
    rows, cols = len(grid), len(grid[0])
    if r >= rows or c >= cols or grid[r][c] == 1:
        return 0
    if (r, c) == (rows - 1, cols - 1):
        return 1
    return brute(grid, r + 1, c) + brute(grid, r, c + 1)


for _ in range(200):
    rows, cols = random.randint(1, 5), random.randint(1, 5)
    grid = [[int(random.random() < 0.25) for _ in range(cols)] for _ in range(rows)]
    assert count_paths(grid) == brute(grid)
```

```python solution
def count_paths(grid):
    if not grid:
        return 0
    rows, cols = len(grid), len(grid[0])
    paths = [[0] * cols for _ in range(rows)]
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == 1:
                continue
            if r == 0 and c == 0:
                paths[r][c] = 1
                continue
            up = paths[r - 1][c] if r > 0 else 0
            left = paths[r][c - 1] if c > 0 else 0
            paths[r][c] = up + left
    return paths[-1][-1]
```

## Hints

1. Every path into a cell comes from the cell above it or the cell to its left.
2. `paths[r][c]` is `paths[r - 1][c] + paths[r][c - 1]`, using 0 for a neighbor off the grid. A rock keeps 0, and the start is 1 unless it is a rock.
3. Fill the table row by row, left to right, so both neighbors are done before each cell. Return `paths[-1][-1]`.
