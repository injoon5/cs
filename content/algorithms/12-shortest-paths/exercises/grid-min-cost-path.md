---
id: grid-min-cost-path
title: Cheapest path through a grid
level: core
---

`grid` is a list of equal-length rows of numbers, each 0 or more. A path starts at the top-left cell, ends at the bottom-right cell, and moves up, down, left or right. Its cost is the sum of every cell on it, both corners included. Return the cost of the cheapest path.

For `[[1, 3, 1], [1, 5, 1], [4, 2, 1]]` the answer is 7: along the top row, then down the right column.

```python starter
import heapq


def min_path_cost(grid):
    pass
```

```tests
min_path_cost([[1, 3, 1], [1, 5, 1], [4, 2, 1]]) == 7
min_path_cost([[5]]) == 5
min_path_cost([[0, 0], [0, 0]]) == 0
min_path_cost([[1, 2, 3]]) == 6
min_path_cost([[1], [2], [3]]) == 6
min_path_cost([[1, 9, 1, 1, 1], [1, 9, 1, 9, 1], [1, 1, 1, 9, 1]]) == 11
min_path_cost([[1, 1, 1], [9, 9, 1], [1, 1, 1], [1, 9, 9], [1, 1, 1]]) == 11
min_path_cost([[1] * 150 for _ in range(150)]) == 299
min_path_cost([[1 if r % 4 == 0 or r % 4 == 2 or (r % 4 == 1 and c == 149) or (r % 4 == 3 and c == 0) else 1000 for c in range(150)] for r in range(149)]) == 75 * 150 + 74
```

```python tests
import random


def slow(grid):
    rows, cols = len(grid), len(grid[0])
    inf = float("inf")
    dist = [[inf] * cols for _ in range(rows)]
    dist[0][0] = grid[0][0]
    for _ in range(rows * cols):
        for r in range(rows):
            for c in range(cols):
                for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                    if 0 <= nr < rows and 0 <= nc < cols:
                        dist[r][c] = min(dist[r][c], dist[nr][nc] + grid[r][c])
    return dist[-1][-1]


for _ in range(100):
    rows, cols = random.randint(1, 5), random.randint(1, 5)
    grid = [[random.choice([0, 1, 1, 2, 5, 9]) for _ in range(cols)] for _ in range(rows)]
    assert min_path_cost(grid) == slow(grid), grid
```

```python solution
import heapq


def min_path_cost(grid):
    rows, cols = len(grid), len(grid[0])
    dist = [[float("inf")] * cols for _ in range(rows)]
    dist[0][0] = grid[0][0]
    heap = [(grid[0][0], 0, 0)]
    done = set()
    while heap:
        d, r, c = heapq.heappop(heap)
        if (r, c) in done:
            continue
        if (r, c) == (rows - 1, cols - 1):
            return d
        done.add((r, c))
        for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
            if 0 <= nr < rows and 0 <= nc < cols:
                nd = d + grid[nr][nc]
                if nd < dist[nr][nc]:
                    dist[nr][nc] = nd
                    heapq.heappush(heap, (nd, nr, nc))
```

## Hints

1. Each cell is a node, joined to the cells beside it. Stepping into a cell costs its number, so this is a shortest path with non-negative weights.
2. Run Dijkstra with `(cost, r, c)` in the heap, starting from `(grid[0][0], 0, 0)`. Moving into `(nr, nc)` adds `grid[nr][nc]`.
3. Return the cost when the bottom-right cell comes off the heap. Moving only right and down isn't enough: the cheapest path can turn back up or left.
