---
id: rotting-fruit
title: Rotting fruit
level: core
---

`grid` is a list of equal-length strings: `f` is a fresh fruit, `r` a rotten one, and `.` an empty spot. Every minute, each fresh fruit directly above, below, left or right of a rotten one turns rotten. Return the number of minutes until no fresh fruit is left, or -1 if some fruit never rots.

```
rf.
ff.
.ff
```

After minute 1 the two fruits next to the rotten corner have turned. Then the center goes, then the one below it, and the last fruit rots at minute 4.

```python starter
from collections import deque


def rot_time(grid):
    pass
```

```tests
rot_time(["rf.", "ff.", ".ff"]) == 4
rot_time(["rf.", ".f.", "f.."]) == -1
rot_time(["..."]) == 0
rot_time(["r"]) == 0
rot_time(["f"]) == -1
rot_time(["rr", "rr"]) == 0
rot_time(["rfffr"]) == 2
rot_time(["fff", "frf", "fff"]) == 2
rot_time(["r.f"]) == -1
rot_time(["r" + "f" * 299] + ["f" * 300] * 299) == 598
```

```python tests
import random


def slow(grid):
    cells = [list(row) for row in grid]
    rows, cols = len(cells), len(cells[0])
    minutes = 0
    while True:
        turn = [(r, c) for r in range(rows) for c in range(cols) if cells[r][c] == "f" and any(
            0 <= nr < rows and 0 <= nc < cols and cells[nr][nc] == "r"
            for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)))]
        if not turn:
            break
        for r, c in turn:
            cells[r][c] = "r"
        minutes += 1
    if any("f" in row for row in cells):
        return -1
    return minutes


for _ in range(300):
    rows, cols = random.randint(1, 5), random.randint(1, 5)
    grid = ["".join(random.choice("ff.r") for _ in range(cols)) for _ in range(rows)]
    assert rot_time(grid) == slow(grid), grid
```

```python solution
from collections import deque


def rot_time(grid):
    rows, cols = len(grid), len(grid[0])
    minute = {}
    fresh = 0
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == "r":
                minute[(r, c)] = 0
            elif grid[r][c] == "f":
                fresh += 1
    queue = deque(minute)
    last = 0
    while queue:
        r, c = queue.popleft()
        last = minute[(r, c)]
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] == "f" and (nr, nc) not in minute:
                minute[(nr, nc)] = last + 1
                fresh -= 1
                queue.append((nr, nc))
    return last if fresh == 0 else -1
```

## Hints

1. Rot spreads from every rotten fruit at once, one ring per minute. That is BFS with many sources.
2. Put every rotten fruit in the queue at minute 0 and count the fresh ones. A fresh neighbor rots one minute after the fruit that reached it.
3. Keep `minute` as a dict from cell to the minute it rotted, and lower `fresh` each time a fruit turns. When the queue is empty, return the last minute you took out if `fresh` is 0, else -1.
