---
id: connect-points-cost
title: Connect the points
level: stretch
---

`points` is a list of distinct `(x, y)` points with integer coordinates. A wire between two points costs their Manhattan distance, `|x1 - x2| + |y1 - y2|`. Return the least total cost of wires that connect every point to every other, directly or through other points.

Any two points can be wired, so this is a minimum spanning tree on a complete graph. Aim for O(n²) time for n points.

For `[(0, 0), (2, 2), (3, 10), (5, 2), (7, 0)]`, the cheapest wires cost 4, 3, 4 and 9, so the answer is 20.

```python starter
def connect_cost(points):
    pass
```

```tests
connect_cost([(0, 0), (2, 2), (3, 10), (5, 2), (7, 0)]) == 20
connect_cost([]) == 0
connect_cost([(4, -1)]) == 0
connect_cost([(0, 0), (1, 1)]) == 2
connect_cost([(3, 12), (-2, 5), (-4, 1)]) == 18
connect_cost([(0, 0), (0, 5), (0, 2), (0, -3)]) == 8
connect_cost([(0, 0), (1, 0), (1, 1), (0, 1)]) == 3
connect_cost([(i * 7919 % 10007, i * 104729 % 10009) for i in range(1500)]) == 259197
```

```python tests
import random
from itertools import combinations


def slow(points):
    n = len(points)
    edges = sorted((abs(a[0] - b[0]) + abs(a[1] - b[1]), i, j)
                   for (i, a), (j, b) in combinations(enumerate(points), 2))
    group = list(range(n))
    total = 0
    for w, i, j in edges:
        if group[i] != group[j]:
            old = group[j]
            group = [group[i] if g == old else g for g in group]
            total += w
    return total


for _ in range(300):
    cells = [(x, y) for x in range(-6, 7) for y in range(-6, 7)]
    points = random.sample(cells, random.randint(0, 9))
    assert connect_cost(points) == slow(points), points
```

```python solution
def connect_cost(points):
    if not points:
        return 0
    best = {i: float("inf") for i in range(1, len(points))}
    total = 0
    x, y = points[0]
    while best:
        for i in best:
            px, py = points[i]
            best[i] = min(best[i], abs(px - x) + abs(py - y))
        v = min(best, key=best.get)
        total += best.pop(v)
        x, y = points[v]
    return total
```

## Hints

1. With n points there are about n² / 2 possible wires. Pushing them all into a heap, or sorting them all, costs O(n² log n). Prim without a heap does it in O(n²).
2. Grow a tree from point 0. For every point outside the tree, keep the cost of its cheapest wire to any point in the tree. Each step, the outside point with the smallest such cost joins.
3. Keep `best`, a dict from each outside point to that cost, starting at infinity. After a point joins, lower `best[i]` with its distance to every outside point `i`, then pop the point with the smallest `best` value and add that value to the total.
