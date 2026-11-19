---
id: fewest-walls-removed
title: Fewest walls
level: stretch
---

`grid` is a list of equal-length strings: `.` is an open cell and `#` is a wall. You walk from the top-left cell to the bottom-right cell, moving up, down, left or right, and you may break through walls. Return the fewest walls you have to break. A corner that is a wall has to be broken too.

For this grid the answer is 1: break the wall in the middle.

```
..#
###
#..
```

```python starter
from collections import deque


def fewest_walls(grid):
    pass
```

```tests
fewest_walls(["..#", "###", "#.."]) == 1
fewest_walls(["."]) == 0
fewest_walls(["#"]) == 1
fewest_walls(["...", "...", "..."]) == 0
fewest_walls(["#.", ".#"]) == 2
fewest_walls([".#.#."]) == 2
fewest_walls([".", "#", "#", "."]) == 2
fewest_walls([".#...", ".#.#.", "...#."]) == 0
fewest_walls(["..#..", "####.", "....#", ".####", "....."]) == 1
fewest_walls(["." * 200 if r % 2 == 0 else "#" * 200 for r in range(199)]) == 99
fewest_walls(["." * 200] * 100 + ["#" * 199 + "."] + ["." * 200] * 99) == 0
```

```python tests
import random


def slow(grid):
    rows, cols = len(grid), len(grid[0])
    cost = [[1 if ch == "#" else 0 for ch in row] for row in grid]
    inf = float("inf")
    dist = [[inf] * cols for _ in range(rows)]
    dist[0][0] = cost[0][0]
    for _ in range(rows * cols):
        for r in range(rows):
            for c in range(cols):
                for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                    if 0 <= nr < rows and 0 <= nc < cols:
                        dist[r][c] = min(dist[r][c], dist[nr][nc] + cost[r][c])
    return dist[-1][-1]


for _ in range(100):
    rows, cols = random.randint(1, 5), random.randint(1, 5)
    grid = ["".join(random.choice(".#") for _ in range(cols)) for _ in range(rows)]
    assert fewest_walls(grid) == slow(grid), grid
```

```python solution
from collections import deque


def fewest_walls(grid):
    rows, cols = len(grid), len(grid[0])
    start = 1 if grid[0][0] == "#" else 0
    dist = {(0, 0): start}
    dq = deque([(start, 0, 0)])
    done = set()
    while dq:
        d, r, c = dq.popleft()
        if (r, c) in done:
            continue
        if (r, c) == (rows - 1, cols - 1):
            return d
        done.add((r, c))
        for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
            if 0 <= nr < rows and 0 <= nc < cols:
                w = 1 if grid[nr][nc] == "#" else 0
                if d + w < dist.get((nr, nc), float("inf")):
                    dist[(nr, nc)] = d + w
                    if w == 0:
                        dq.appendleft((d, nr, nc))
                    else:
                        dq.append((d + 1, nr, nc))
```

## Hints

1. Each cell is a node. Stepping into an open cell costs 0 and into a wall costs 1, so this is a shortest path where every weight is 0 or 1.
2. Use 0-1 BFS: a deque of `(walls, r, c)`, starting with the cost of the top-left cell itself.
3. When a move lowers a cell's count, `appendleft` it if the cell is open and `append` it if it's a wall. Return the count when the bottom-right cell comes off the deque.
