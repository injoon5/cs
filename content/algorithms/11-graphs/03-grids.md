---
id: grid-bfs
title: Grids as graphs
---

What is the fewest number of moves from the top-left corner of this maze to the bottom-right? Each move goes up, down, left or right, and `#` is a wall.

```diagram
grid maze
row [S, , , #, ]
row [, #, , #, ]
row [, #, , , ]
row [, #, #, #, ]
row [, , , #, E]
highlight 0,0 4,4
```

A maze is a graph in disguise. Every open cell is a node, and an edge joins two open cells that share a side. In code a maze is usually a list of strings, one per row, with `.` for an open cell and `#` for a wall.

---

There's no need to build an adjacency list. A cell's neighbors are the four cells next to it, kept only if they are inside the grid and not a wall. Cell `(r, c)` is `grid[r][c]`. What does this print?

```python predict
grid = ["..#",
        ".#.",
        "..."]
rows, cols = len(grid), len(grid[0])


def neighbors(r, c):
    out = []
    for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        nr, nc = r + dr, c + dc
        if 0 <= nr < rows and 0 <= nc < cols and grid[nr][nc] != "#":
            out.append((nr, nc))
    return out


print(neighbors(0, 0))
print(neighbors(1, 2))
print(neighbors(2, 1))
```

---

Someone drops `0 <= nr` from the bounds check. What happens for a cell in the top row?

- [ ] Python raises `IndexError` for row -1
- [x] `grid[-1]` is the bottom row, so the cell quietly gets a neighbor from the far side of the grid
- [ ] Nothing changes, since the other checks catch it

---

BFS runs unchanged on a grid. Cells are `(row, col)` tuples. Here the distances live in a list of lists shaped like the grid: walls start as `"#"` and open cells as `None`, so `None` means open and not reached yet.

Popping `len(queue)` cells at a time handles one ring per pass, so `steps` is the distance of the ring. Run this to watch the rings spread through the maze.

```python
import viz
from collections import deque

grid = ["...#.",
        ".#.#.",
        ".#...",
        ".###.",
        "...#."]
rows, cols = len(grid), len(grid[0])
dist = [["#" if ch == "#" else None for ch in row] for row in grid]
dist[0][0] = 0
queue = deque([(0, 0)])
steps = 0
while queue:
    viz.grid(dist, highlight=list(queue), note=f"distance {steps}")
    for _ in range(len(queue)):
        r, c = queue.popleft()
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols and dist[nr][nc] is None:
                dist[nr][nc] = steps + 1
                queue.append((nr, nc))
    steps += 1
print(dist[rows - 1][cols - 1])
```

The ring that goes down the left side runs into a dead end at distance 6. The one on the right reaches the corner in 8.

---

BFS on a grid with R rows and C columns takes

- [ ] O(R + C) time
- [x] O(R × C) time, since each cell joins the queue once and has at most 4 neighbors
- [ ] O((R × C)²) time

---

Sometimes there are several starting points, and each cell needs its distance to the nearest one: the nearest exit, say, or the nearest water.

Put every source in the queue at distance 0 before the loop starts, then run BFS as usual. The rings grow from all the sources at once, and each cell is claimed by whichever ring reaches it first, which is the nearest source.

```diagram
grid
row [0, 1, 2, 1, 0]
row [1, 2, 3, 2, 1]
row [2, 3, 4, 3, 2]
highlight 0,0 0,4
```

---

Here each `S` is a source.

```python trace stop=71
from collections import deque

grid = ["S...",
        "...S"]
rows, cols = len(grid), len(grid[0])
dist = {}
queue = deque()
for r in range(rows):
    for c in range(cols):
        if grid[r][c] == "S":
            dist[(r, c)] = 0
            queue.append((r, c))
while queue:
    r, c = queue.popleft()
    for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        nr, nc = r + dr, c + dc
        if 0 <= nr < rows and 0 <= nc < cols and (nr, nc) not in dist:
            dist[(nr, nc)] = dist[(r, c)] + 1
            queue.append((nr, nc))
print(dist)
```

Both sources have been handled. What is in `queue`?

- [ ] `(1, 0), (0, 1)`
- [x] `(1, 0), (0, 1), (0, 3), (1, 2)`
- [ ] `(1, 0), (0, 1), (0, 2), (1, 1)`

---

Running a separate BFS from each of k sources and keeping the smallest distance would cost O(k × R × C). Starting them all together costs

- [x] O(R × C), the same as one BFS
- [ ] O(k × R × C), the same as k searches
- [ ] O(R × C × log k)

---

[Through the maze](exercises/maze-fewest-steps.md)

[Rotting fruit](exercises/rotting-fruit.md)
