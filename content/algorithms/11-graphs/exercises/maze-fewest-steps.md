---
id: maze-fewest-steps
title: Through the maze
level: core
---

`grid` is a list of equal-length strings: `.` is an open cell and `#` is a wall. Return the fewest moves from the top-left cell to the bottom-right cell, moving up, down, left or right through open cells. Return -1 if there's no way through or either corner is a wall.

For the maze from the lesson, the answer is 8:

```
...#.
.#.#.
.#...
.###.
...#.
```

```python starter
from collections import deque


def maze_steps(grid):
    pass
```

```tests
maze_steps(["...#.", ".#.#.", ".#...", ".###.", "...#."]) == 8
maze_steps(["."]) == 0
maze_steps(["#"]) == -1
maze_steps(["..", ".."]) == 2
maze_steps([".#", "#."]) == -1
maze_steps(["...", "...", "..#"]) == -1
maze_steps([".", ".", "."]) == 2
maze_steps([".....", "####.", ".....", ".####", "....."]) == 16
maze_steps(["." * 300] * 300) == 598
```

```python tests
import random


def slow(grid):
    rows, cols = len(grid), len(grid[0])
    if grid[0][0] == "#" or grid[-1][-1] == "#":
        return -1
    inf = float("inf")
    dist = [[inf] * cols for _ in range(rows)]
    dist[0][0] = 0
    for _ in range(rows * cols):
        for r in range(rows):
            for c in range(cols):
                if grid[r][c] == "#":
                    continue
                for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                    if 0 <= nr < rows and 0 <= nc < cols:
                        dist[r][c] = min(dist[r][c], dist[nr][nc] + 1)
    return -1 if dist[-1][-1] == inf else dist[-1][-1]


for _ in range(100):
    rows, cols = random.randint(1, 5), random.randint(1, 5)
    grid = ["".join(random.choice("..#") for _ in range(cols)) for _ in range(rows)]
    assert maze_steps(grid) == slow(grid), grid

snake = ["." * 99 if r % 2 == 0 else ("#" * 98 + "." if r % 4 == 1 else "." + "#" * 98) for r in range(99)]
assert maze_steps(snake) == 49 * 98 + 98
```

```python solution
from collections import deque


def maze_steps(grid):
    rows, cols = len(grid), len(grid[0])
    if grid[0][0] == "#" or grid[-1][-1] == "#":
        return -1
    dist = {(0, 0): 0}
    queue = deque([(0, 0)])
    while queue:
        r, c = queue.popleft()
        if (r, c) == (rows - 1, cols - 1):
            return dist[(r, c)]
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] == "." and (nr, nc) not in dist:
                dist[(nr, nc)] = dist[(r, c)] + 1
                queue.append((nr, nc))
    return -1
```

## Hints

1. Each open cell is a node, joined to the open cells beside it. The fewest moves is a shortest path, so use BFS.
2. Start from `(0, 0)` at distance 0. For each cell you take from the queue, try its four neighbors and keep those inside the grid, open, and not seen yet.
3. Keep `dist` as a dict from `(r, c)` to moves. Return `dist[(r, c)]` when you take the bottom-right cell from the queue, and -1 if the queue runs dry. Check the two corners for walls first.
