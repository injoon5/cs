---
id: cheapest-flight-k-stops
title: Cheapest flight within k stops
level: core
---

There are `n` cities, numbered 0 to `n - 1`. Each `(a, b, price)` in `flights` is a one-way flight from `a` to `b`, with `price >= 0`. Return the cheapest way to get from `src` to `dst` with at most `k` stops in between, that is, at most `k + 1` flights. Return -1 if there is no such route. Getting from a city to itself costs 0.

For `flights = [(0, 1, 100), (1, 2, 100), (2, 3, 100), (1, 3, 350), (0, 3, 500)]` from 0 to 3, the answer is 500 with `k = 0`, 450 with `k = 1` and 300 with `k = 2`.

```python starter
def cheapest_flight(n, flights, src, dst, k):
    pass
```

```tests
cheapest_flight(4, [(0, 1, 100), (1, 2, 100), (2, 3, 100), (1, 3, 350), (0, 3, 500)], 0, 3, 0) == 500
cheapest_flight(4, [(0, 1, 100), (1, 2, 100), (2, 3, 100), (1, 3, 350), (0, 3, 500)], 0, 3, 1) == 450
cheapest_flight(4, [(0, 1, 100), (1, 2, 100), (2, 3, 100), (1, 3, 350), (0, 3, 500)], 0, 3, 2) == 300
cheapest_flight(4, [(0, 1, 100), (1, 2, 100), (2, 3, 100), (1, 3, 350), (0, 3, 500)], 0, 3, 10) == 300
cheapest_flight(3, [(0, 1, 5)], 0, 2, 5) == -1
cheapest_flight(3, [(0, 1, 1), (1, 2, 1)], 0, 2, 0) == -1
cheapest_flight(2, [(0, 1, 5)], 0, 0, 0) == 0
cheapest_flight(2, [(0, 1, 5), (0, 1, 3)], 0, 1, 0) == 3
cheapest_flight(4, [(0, 1, 1), (1, 2, 1), (2, 3, 1), (0, 3, 10)], 0, 3, 0) == 10
cheapest_flight(4, [(0, 1, 1), (1, 2, 1), (2, 3, 1), (0, 3, 10)], 0, 3, 1) == 10
cheapest_flight(5, [(0, 1, 1), (1, 2, 1), (0, 2, 5), (2, 3, 1), (3, 4, 1)], 0, 4, 2) == 7
cheapest_flight(62, [(v, w, 1 + (v + w) % 3) for v in range(60) for w in (v // 2 * 2 + 2, v // 2 * 2 + 3)], 0, 61, 29) == 41
cheapest_flight(62, [(v, w, 1 + (v + w) % 3) for v in range(60) for w in (v // 2 * 2 + 2, v // 2 * 2 + 3)], 0, 61, 28) == -1
```

```python tests
import random


def slow(n, flights, src, dst, k):
    best = float("inf")

    def go(city, cost, used):
        nonlocal best
        if city == dst:
            best = min(best, cost)
        if used == k + 1:
            return
        for a, b, price in flights:
            if a == city:
                go(b, cost + price, used + 1)

    go(src, 0, 0)
    return -1 if best == float("inf") else best


for _ in range(300):
    n = random.randint(1, 5)
    flights = [(random.randrange(n), random.randrange(n), random.randint(0, 9)) for _ in range(random.randint(0, 7))]
    src, dst, k = random.randrange(n), random.randrange(n), random.randint(0, 3)
    assert cheapest_flight(n, flights, src, dst, k) == slow(n, flights, src, dst, k), (n, flights, src, dst, k)
```

```python solution
def cheapest_flight(n, flights, src, dst, k):
    inf = float("inf")
    cost = [inf] * n
    cost[src] = 0
    for _ in range(k + 1):
        prev = cost[:]
        for a, b, price in flights:
            if prev[a] + price < cost[b]:
                cost[b] = prev[a] + price
    return -1 if cost[dst] == inf else cost[dst]
```

## Hints

1. At most `k` stops means at most `k + 1` flights. A round of Bellman-Ford adds one more edge to the paths it has tried.
2. Run `k + 1` rounds. In each round, relax every flight, but read the starting costs from a copy of `cost` made when the round began.
3. Without the copy, one round can chain several flights and go over the limit. At the end, return `cost[dst]`, or -1 if it is still `float("inf")`.
