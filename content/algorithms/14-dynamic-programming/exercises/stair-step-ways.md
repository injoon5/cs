---
id: stair-step-ways
title: Stairs with any step sizes
level: warmup
---

Return the number of ways to climb exactly `n` stairs, where each move climbs one of the sizes in `steps`. The order of moves matters. With `steps = [1, 3]` there are 3 ways to climb 4 stairs: 1+1+1+1, 1+3 and 3+1.

```python starter
def climb_ways(n, steps):
    pass
```

```tests
climb_ways(4, [1, 3]) == 3
climb_ways(4, [1, 2]) == 5
climb_ways(0, [1, 2]) == 1
climb_ways(0, []) == 1
climb_ways(3, []) == 0
climb_ways(1, [2]) == 0
climb_ways(5, [2]) == 0
climb_ways(6, [2]) == 1
climb_ways(7, [1, 3, 5]) == 12
climb_ways(10, [3, 1]) == 28
climb_ways(90, [1, 2]) == 4660046610375530309
climb_ways(60, [1, 2, 3]) == 4680045560037375
```

```python tests
import random


def brute(n, steps):
    if n == 0:
        return 1
    return sum(brute(n - s, steps) for s in steps if s <= n)


for _ in range(200):
    steps = random.sample(range(1, 7), random.randint(1, 4))
    n = random.randint(0, 15)
    assert climb_ways(n, steps) == brute(n, steps)
```

```python solution
from functools import cache


def climb_ways(n, steps):
    @cache
    def ways(left):
        if left == 0:
            return 1
        return sum(ways(left - s) for s in steps if s <= left)

    return ways(n)
```

## Hints

1. Look at the last move. It is one of the sizes in `steps`, and before it you had climbed `n - s` stairs.
2. The state is the number of stairs left to climb. `ways(0)` is 1, and `ways(left)` adds up `ways(left - s)` for every step `s <= left`.
3. Write `ways(left)` inside `climb_ways` and put `@cache` on it, so each `left` is worked out once: `sum(ways(left - s) for s in steps if s <= left)`.
