---
id: cut-stick-cost
title: Cut a stick
level: stretch
---

A stick of length `n` must be cut at every position in `cuts`, each between 1 and `n - 1` with no repeats. A cut costs the length of the piece it cuts, and you choose the order. Return the cheapest total. For `n = 7` and `cuts = [1, 3, 4, 5]` it is 16: cut at 3, then 5, then 1, then 4, paying 7 + 4 + 3 + 2.

```python starter
def min_cut_cost(n, cuts):
    pass
```

```tests
min_cut_cost(7, [1, 3, 4, 5]) == 16
min_cut_cost(7, [5, 4, 3, 1]) == 16
min_cut_cost(9, [5, 6, 1, 4, 2]) == 22
min_cut_cost(5, []) == 0
min_cut_cost(5, [2]) == 5
min_cut_cost(4, [1, 2, 3]) == 8
min_cut_cost(1000, list(range(10, 1000, 10))) == 6720
```

```python tests
import random
from itertools import permutations


def brute(n, cuts):
    best = float("inf")
    for order in permutations(cuts):
        made = [0, n]
        total = 0
        for c in order:
            left = max(m for m in made if m < c)
            right = min(m for m in made if m > c)
            total += right - left
            made.append(c)
        best = min(best, total)
    return best


for _ in range(100):
    n = random.randint(2, 15)
    cuts = random.sample(range(1, n), random.randint(0, min(5, n - 1)))
    assert min_cut_cost(n, cuts) == brute(n, cuts)
```

```python solution
from functools import cache


def min_cut_cost(n, cuts):
    marks = [0] + sorted(cuts) + [n]

    @cache
    def cost(i, j):
        if j - i < 2:
            return 0
        piece = marks[j] - marks[i]
        return piece + min(cost(i, k) + cost(k, j)
                           for k in range(i + 1, j))

    return cost(0, len(marks) - 1)
```

## Hints

1. Whichever cut you make first, it splits the stick into two pieces that never affect each other again.
2. Add 0 and `n` to the sorted cuts to get `marks`. `cost(i, j)` is the cheapest way to make every cut strictly between `marks[i]` and `marks[j]`, and it is 0 when no mark lies between them.
3. `cost(i, j) = marks[j] - marks[i] + min(cost(i, k) + cost(k, j))` over `i < k < j`. Memoize it with `@cache` and return `cost(0, len(marks) - 1)`.
