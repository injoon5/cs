---
id: weighted-wait
title: Weighted waiting time
level: stretch
---

One machine runs jobs one after another, from time 0 with no gaps. Each job is a `(length, weight)` pair, both positive whole numbers. A job that finishes at time `t` costs `weight * t`. Return the smallest total cost over all orders.

For `[(3, 1), (1, 2)]` the answer is 6. Running `(1, 2)` first, it finishes at 1 and costs 2, then `(3, 1)` finishes at 4 and costs 4. The other order costs 3 + 8 = 11.

```python starter
def min_weighted_wait(jobs):
    pass
```

```tests
min_weighted_wait([(3, 1), (1, 2)]) == 6
min_weighted_wait([]) == 0
min_weighted_wait([(5, 3)]) == 15
min_weighted_wait([(6, 1), (1, 1), (3, 1)]) == 15
min_weighted_wait([(1, 1), (10, 20)]) == 211
min_weighted_wait([(2, 1), (4, 2)]) == 14
min_weighted_wait([(3, 3), (1, 1), (2, 2)]) == 25
min_weighted_wait([(4, 1), (1, 3), (2, 5)]) == 25
```

```python tests
import random
from itertools import permutations


def cost(order):
    t = total = 0
    for length, weight in order:
        t += length
        total += weight * t
    return total


for _ in range(300):
    jobs = [(random.randint(1, 9), random.randint(1, 9)) for _ in range(random.randint(0, 6))]
    want = min(cost(p) for p in permutations(jobs))
    assert min_weighted_wait(jobs) == want, jobs
```

```python solution
from fractions import Fraction


def min_weighted_wait(jobs):
    order = sorted(jobs, key=lambda job: Fraction(job[0], job[1]))
    t = total = 0
    for length, weight in order:
        t += length
        total += weight * t
    return total
```

## Hints

1. Shortest first is wrong here: in `[(1, 1), (10, 20)]` the long job matters 20 times as much. Look at what one swap of neighbors does.
2. Job `a` sits right before job `b`. Swapping them changes only their two costs: `a` first adds `length_a * weight_b` that `b` first doesn't, and `b` first adds `length_b * weight_a`.
3. So `a` should go first when `length_a * weight_b < length_b * weight_a`, that is when `length_a / weight_a` is smaller. Sort by `length / weight` (a `Fraction` keeps it exact) and add up the costs.
