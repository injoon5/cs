---
id: islands-as-land-appears
title: Islands as land appears
level: stretch
---

A map of `rows` × `cols` cells starts as all water. `cells` lists the cells `(r, c)` that turn into land, in order. An island is a group of land cells joined up, down, left or right. Return a list with the number of islands after each cell turns. A cell can show up again after it is already land, and then nothing changes.

On a 3 × 3 map with `cells = [(0, 0), (0, 1), (1, 2), (2, 1), (1, 1)]`, the counts are 1, 1, 2, 3, and then 1, since `(1, 1)` touches all three islands. The answer is `[1, 1, 2, 3, 1]`.

```python starter
def islands_after_each(rows, cols, cells):
    pass
```

```tests
islands_after_each(3, 3, [(0, 0), (0, 1), (1, 2), (2, 1), (1, 1)]) == [1, 1, 2, 3, 1]
islands_after_each(2, 2, []) == []
islands_after_each(1, 1, [(0, 0)]) == [1]
islands_after_each(1, 1, [(0, 0), (0, 0)]) == [1, 1]
islands_after_each(2, 2, [(0, 0), (1, 1), (0, 1)]) == [1, 2, 1]
islands_after_each(1, 5, [(0, 0), (0, 4), (0, 2), (0, 3), (0, 1)]) == [1, 2, 3, 2, 1]
islands_after_each(3, 1, [(2, 0), (0, 0), (1, 0), (1, 0)]) == [1, 2, 1, 1]
islands_after_each(2, 3, [(0, 2), (1, 0)]) == [1, 2]
islands_after_each(300, 300, [(i, i) for i in range(300)]) == list(range(1, 301))
islands_after_each(300, 300, [(r, c) for r in range(300) for c in range(300)])[-1] == 1
islands_after_each(300, 300, [(r, c) for c in range(300) for r in range(0, 300, 2)])[-1] == 150
```

```python tests
import random


def slow(rows, cols, cells):
    land = set()
    out = []
    for cell in cells:
        land.add(cell)
        seen = set()
        count = 0
        for start in land:
            if start in seen:
                continue
            count += 1
            seen.add(start)
            stack = [start]
            while stack:
                r, c = stack.pop()
                for nxt in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                    if nxt in land and nxt not in seen:
                        seen.add(nxt)
                        stack.append(nxt)
        out.append(count)
    return out


for _ in range(300):
    rows, cols = random.randint(1, 5), random.randint(1, 5)
    cells = [(random.randrange(rows), random.randrange(cols)) for _ in range(random.randint(0, 15))]
    assert islands_after_each(rows, cols, cells) == slow(rows, cols, cells), (rows, cols, cells)
```

```python solution
def islands_after_each(rows, cols, cells):
    parent = list(range(rows * cols))
    size = [1] * (rows * cols)
    land = [False] * (rows * cols)

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    count = 0
    out = []
    for r, c in cells:
        cell = r * cols + c
        if not land[cell]:
            land[cell] = True
            count += 1
            for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                if 0 <= nr < rows and 0 <= nc < cols and land[nr * cols + nc]:
                    ra, rb = find(cell), find(nr * cols + nc)
                    if ra != rb:
                        if size[ra] < size[rb]:
                            ra, rb = rb, ra
                        parent[rb] = ra
                        size[ra] += size[rb]
                        count -= 1
        out.append(count)
    return out
```

## Hints

1. A new land cell starts as an island of its own. Then each neighbor that is already land, and on a different island, merges two islands into one.
2. Number cell `(r, c)` as `r * cols + c` so it can live in a union-find. Keep a list of which cells are land. A repeated cell changes nothing.
3. For a new cell, add 1 to the count. For each of its four neighbors inside the map that is land, find both roots, and if they differ, merge them and subtract 1. Append the count after every cell.
