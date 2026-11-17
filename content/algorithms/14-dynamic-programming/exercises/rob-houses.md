---
id: rob-houses
title: House robber
level: warmup
---

`houses` holds the money in each house along a street, all zero or more. Robbing two neighbors sets off the alarm. Return the most money you can take. For `[2, 7, 9, 3, 1]` the answer is 12: houses 0, 2 and 4.

Streets can be 100,000 houses long, so fill a table with a loop rather than recursing.

```python starter
def rob(houses):
    pass
```

```tests
rob([2, 7, 9, 3, 1]) == 12
rob([2, 1, 1, 2]) == 4
rob([]) == 0
rob([5]) == 5
rob([1, 2]) == 2
rob([1, 3, 1]) == 3
rob([5, 1, 1, 5]) == 10
rob([0, 0, 0]) == 0
rob([4, 4, 4, 4]) == 8
rob([3, 1] * 50000) == 150000
rob(list(range(100000))) == 2500000000
```

```python tests
import random
from itertools import combinations


def brute(houses):
    best = 0
    n = len(houses)
    for k in range(n + 1):
        for picked in combinations(range(n), k):
            if all(b - a > 1 for a, b in zip(picked, picked[1:])):
                best = max(best, sum(houses[i] for i in picked))
    return best


for _ in range(200):
    houses = [random.randint(0, 20) for _ in range(random.randint(0, 10))]
    assert rob(houses) == brute(houses)
```

```python solution
def rob(houses):
    prev, cur = 0, 0
    for h in houses:
        prev, cur = cur, max(cur, prev + h)
    return cur
```

## Hints

1. For the last house there are two choices: skip it, or rob it and give up its neighbor.
2. `best[i] = max(best[i - 1], best[i - 2] + houses[i - 1])`, with `best[0] = 0` and `best[1] = houses[0]`.
3. Only the last two values are ever read. Keep them as `prev, cur = 0, 0` and for each `h` set `prev, cur = cur, max(cur, prev + h)`.
