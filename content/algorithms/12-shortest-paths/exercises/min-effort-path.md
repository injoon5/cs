---
id: min-effort-path
title: Least effort
level: stretch
---

`heights` is a list of equal-length rows of numbers, the height of each cell on a map. A hike starts at the top-left cell, ends at the bottom-right cell, and moves up, down, left or right. Its effort is the largest height difference between two cells next to each other on the hike, in either direction. Return the smallest effort of any hike.

For `[[1, 2, 9], [6, 3, 9], [9, 4, 5]]` the answer is 1: the hike 1, 2, 3, 4, 5 never changes height by more than 1.

```python starter
import heapq


def min_effort(heights):
    pass
```

```tests
min_effort([[1, 2, 9], [6, 3, 9], [9, 4, 5]]) == 1
min_effort([[7]]) == 0
min_effort([[1, 10]]) == 9
min_effort([[10], [1]]) == 9
min_effort([[3, 3, 3], [3, 3, 3]]) == 0
min_effort([[5, 1], [9, 4]]) == 4
min_effort([[-3, 2], [4, -1]]) == 5
min_effort([[1, 100, 1, 1, 1], [1, 100, 1, 100, 1], [1, 1, 1, 100, 1]]) == 0
min_effort([[1, 2, 3, 4, 5], [9, 9, 9, 9, 20], [11, 13, 15, 17, 19]]) == 5
min_effort([[r * 150 + c for c in range(150)] for r in range(150)]) == 150
```

```python tests
import random
from collections import deque


def reachable(heights, limit):
    rows, cols = len(heights), len(heights[0])
    seen = {(0, 0)}
    queue = deque([(0, 0)])
    while queue:
        r, c = queue.popleft()
        for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
            if 0 <= nr < rows and 0 <= nc < cols and (nr, nc) not in seen:
                if abs(heights[nr][nc] - heights[r][c]) <= limit:
                    seen.add((nr, nc))
                    queue.append((nr, nc))
    return (rows - 1, cols - 1) in seen


def slow(heights):
    limit = 0
    while not reachable(heights, limit):
        limit += 1
    return limit


for _ in range(200):
    rows, cols = random.randint(1, 5), random.randint(1, 5)
    heights = [[random.randint(-5, 12) for _ in range(cols)] for _ in range(rows)]
    assert min_effort(heights) == slow(heights), heights
```

```python solution
import heapq


def min_effort(heights):
    rows, cols = len(heights), len(heights[0])
    best = [[float("inf")] * cols for _ in range(rows)]
    best[0][0] = 0
    heap = [(0, 0, 0)]
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
                effort = max(d, abs(heights[nr][nc] - heights[r][c]))
                if effort < best[nr][nc]:
                    best[nr][nc] = effort
                    heapq.heappush(heap, (effort, nr, nc))
```

## Hints

1. The cost of a hike is its largest step, not the sum of its steps. Dijkstra still works if extending a path costs `max(d, step)` instead of `d + step`.
2. Keep `best[r][c]`, the smallest effort found so far to reach each cell, and a heap of `(effort, r, c)` starting with `(0, 0, 0)`.
3. Moving from `(r, c)` to a neighbor costs `max(d, abs(heights[nr][nc] - heights[r][c]))`. Return `d` when the bottom-right cell comes off the heap.
