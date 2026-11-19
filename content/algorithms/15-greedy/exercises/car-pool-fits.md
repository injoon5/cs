---
id: car-pool-fits
title: Car pool
level: core
---

A car drives along a road with `capacity` seats. Each trip is a `(passengers, start, end)` triple: that many people get in at kilometer `start` and get out at kilometer `end`, with `start < end`. At the same kilometer, people get out before others get in. Return `True` if the car never has more than `capacity` people in it.

For `[(2, 1, 5), (3, 3, 7)]` the car carries 5 people from kilometer 3 to 5, so the answer is `True` for a capacity of 5 and `False` for 4.

```python starter
def car_pool_fits(trips, capacity):
    pass
```

```tests
car_pool_fits([(2, 1, 5), (3, 3, 7)], 4) == False
car_pool_fits([(2, 1, 5), (3, 3, 7)], 5) == True
car_pool_fits([], 0) == True
car_pool_fits([(4, 0, 9)], 4) == True
car_pool_fits([(5, 0, 9)], 4) == False
car_pool_fits([(2, 1, 5), (3, 5, 7)], 3) == True
car_pool_fits([(3, 2, 7), (3, 7, 9), (8, 3, 9)], 11) == True
car_pool_fits([(1, 0, 4), (1, 1, 3), (1, 2, 5), (1, 6, 8)], 2) == False
car_pool_fits([(1, i, i + 1000) for i in range(100000)], 1000) == True
car_pool_fits([(1, i, i + 1000) for i in range(100000)], 999) == False
```

```python tests
import random


def slow(trips, capacity):
    for x in range(0, 30):
        if sum(p for p, s, e in trips if s <= x < e) > capacity:
            return False
    return True


for _ in range(500):
    trips = []
    for _ in range(random.randint(0, 6)):
        s = random.randint(0, 20)
        trips.append((random.randint(1, 4), s, s + random.randint(1, 6)))
    capacity = random.randint(0, 10)
    assert car_pool_fits(trips, capacity) == slow(trips, capacity), (trips, capacity)
```

```python solution
def car_pool_fits(trips, capacity):
    events = []
    for passengers, start, end in trips:
        events.append((start, passengers))
        events.append((end, -passengers))
    riding = 0
    for _, change in sorted(events):
        riding += change
        if riding > capacity:
            return False
    return True
```

## Hints

1. The number of people in the car only changes where a trip starts or ends.
2. Make two events per trip: `+passengers` at `start` and `-passengers` at `end`. Sort them and sweep, keeping a running total.
3. Tuples sort a negative change before a positive one at the same kilometer, so people get out before others get in. Return `False` as soon as the total passes `capacity`.
