---
id: min-arrows-burst
title: Burst the balloons
level: core
---

Each balloon is a `(start, end)` pair on a line, with `start <= end`. An arrow shot at `x` bursts every balloon with `start <= x <= end`, so balloons that only touch, like `(1, 3)` and `(3, 5)`, can share an arrow. Return the fewest arrows that burst every balloon.

For `[(10, 16), (2, 8), (1, 6), (7, 12)]` the answer is 2: one arrow at 6 bursts `(2, 8)` and `(1, 6)`, and one at 12 bursts the other two.

```python starter
def min_arrows(balloons):
    pass
```

```tests
min_arrows([(10, 16), (2, 8), (1, 6), (7, 12)]) == 2
min_arrows([]) == 0
min_arrows([(4, 4)]) == 1
min_arrows([(1, 2), (3, 4), (5, 6), (7, 8)]) == 4
min_arrows([(1, 3), (3, 5)]) == 1
min_arrows([(1, 2), (2, 3), (3, 4), (4, 5)]) == 2
min_arrows([(0, 3), (1, 4), (4, 6), (5, 8)]) == 2
min_arrows([(1, 10), (2, 3), (4, 5)]) == 2
min_arrows([(-8, -2), (-5, 0), (-1, 3)]) == 2
min_arrows([(i, i + 1) for i in range(0, 200000, 2)]) == 100000
```

```python tests
import random
from itertools import combinations


def slow(balloons):
    spots = sorted({e for _, e in balloons})
    for k in range(len(balloons) + 1):
        for arrows in combinations(spots, k):
            if all(any(s <= x <= e for x in arrows) for s, e in balloons):
                return k


for _ in range(300):
    balloons = []
    for _ in range(random.randint(0, 7)):
        s = random.randint(-5, 10)
        balloons.append((s, s + random.randint(0, 5)))
    assert min_arrows(balloons) == slow(balloons), balloons
```

```python solution
def min_arrows(balloons):
    arrows, last = 0, float("-inf")
    for start, end in sorted(balloons, key=lambda b: b[1]):
        if start > last:
            arrows += 1
            last = end
    return arrows
```

## Hints

1. Look at the balloon that ends first. Some arrow has to hit it, at its end or before.
2. Shooting exactly at that end bursts everything the arrow could have hit further left, and maybe more.
3. Sort by end. Keep `last`, where the last arrow went. A balloon with `start <= last` is already burst; otherwise shoot a new arrow at its end.
