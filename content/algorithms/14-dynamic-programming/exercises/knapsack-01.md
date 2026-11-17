---
id: knapsack-01
title: Pack the knapsack
level: core
---

`items` is a list of `(weight, value)` pairs with positive weights, and the bag holds a total weight of at most `capacity`. Each item can be packed once or not at all. Return the most total value that fits. For items `[(1, 1), (3, 4), (4, 5), (5, 7)]` and capacity 7 the answer is 9, from the items weighing 3 and 4.

```python starter
def best_value(items, capacity):
    pass
```

```tests
best_value([(1, 1), (3, 4), (4, 5), (5, 7)], 7) == 9
best_value([], 10) == 0
best_value([(2, 3)], 0) == 0
best_value([(5, 10)], 4) == 0
best_value([(5, 10)], 5) == 10
best_value([(2, 3)], 4) == 3
best_value([(2, 3), (2, 3)], 4) == 6
best_value([(1, 0), (1, 0)], 2) == 0
best_value([(3, 5), (4, 6), (2, 3)], 5) == 8
best_value([(10, 60), (20, 100), (30, 120)], 50) == 220
best_value([(i % 17 + 1, i * 7 % 23 + 1) for i in range(100)], 500) == 1009
```

```python tests
import random
from itertools import combinations


def brute(items, capacity):
    best = 0
    for k in range(len(items) + 1):
        for picked in combinations(items, k):
            if sum(w for w, _ in picked) <= capacity:
                best = max(best, sum(v for _, v in picked))
    return best


for _ in range(150):
    items = [(random.randint(1, 8), random.randint(0, 20)) for _ in range(random.randint(0, 8))]
    capacity = random.randint(0, 20)
    assert best_value(items, capacity) == brute(items, capacity)
```

```python solution
def best_value(items, capacity):
    best = [0] * (capacity + 1)
    for wt, val in items:
        for w in range(capacity, wt - 1, -1):
            best[w] = max(best[w], best[w - wt] + val)
    return best[capacity]
```

## Hints

1. For each item there are two choices, skip it or pack it. Packing it leaves `capacity - weight` for the items before it.
2. `best[i][w] = max(best[i - 1][w], best[i - 1][w - wt] + val)`, where the second option needs `wt <= w`. Row 0 is all 0.
3. One list is enough if the inner loop runs `w` from `capacity` down to `wt`, so `best[w - wt]` still holds the value from before this item.
