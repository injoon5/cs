---
id: everyone-connected-time
title: Everyone connected
level: core
---

There are `n` people, numbered `0` to `n - 1`, with `n` at least 2. Each entry of `logs` is `(time, a, b)`: at that time, `a` and `b` became friends. The logs are not in time order. Friendship goes both ways, and a friend of a friend counts as connected. Return the earliest time at which everyone is connected to everyone else, or `None` if that never happens.

For `n = 4` and `logs = [(5, 2, 3), (1, 0, 1), (9, 1, 3), (7, 1, 2)]`, the friendships in time order are 0–1 at 1, 2–3 at 5, and 1–2 at 7, which connects everyone. The answer is 7.

```python starter
def earliest_all_connected(n, logs):
    pass
```

```tests
earliest_all_connected(4, [(5, 2, 3), (1, 0, 1), (9, 1, 3), (7, 1, 2)]) == 7
earliest_all_connected(2, []) is None
earliest_all_connected(2, [(3, 1, 0)]) == 3
earliest_all_connected(3, [(1, 0, 1), (2, 1, 0), (3, 0, 0)]) is None
earliest_all_connected(3, [(4, 0, 1), (4, 1, 2)]) == 4
earliest_all_connected(3, [(9, 0, 2), (2, 0, 1), (5, 1, 2)]) == 5
earliest_all_connected(5, [(10, 3, 4), (0, 0, 1), (20, 1, 4), (30, 2, 3), (40, 0, 2)]) == 30
earliest_all_connected(100000, [(10 ** 6 + j, 0, j) for j in range(50000, 100000)] + [(i, i + 1, i) for i in range(49999)]) == 10 ** 6 + 99999
earliest_all_connected(100000, [(10 ** 6 + j, 0, j) for j in range(50000, 100000)] + [(i, i, i + 1) for i in range(49999)]) == 10 ** 6 + 99999
earliest_all_connected(100000, [(10 ** 6 + j, 0, j) for j in range(1, 50000)] + [(j, j, j + 1) for j in range(50000, 99999)]) is None
```

```python tests
import random


def slow(n, logs):
    for t in sorted({t for t, _, _ in logs}):
        reach = {0}
        for _ in range(n):
            for time, a, b in logs:
                if time <= t and (a in reach or b in reach):
                    reach |= {a, b}
        if len(reach) == n:
            return t
    return None


for _ in range(300):
    n = random.randint(2, 6)
    logs = [(random.randint(0, 12), random.randrange(n), random.randrange(n))
            for _ in range(random.randint(0, 9))]
    assert earliest_all_connected(n, logs) == slow(n, logs), (n, logs)
```

```python solution
def earliest_all_connected(n, logs):
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    groups = n
    for time, a, b in sorted(logs):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra
            groups -= 1
            if groups == 1:
                return time
    return None
```

## Hints

1. Go through the friendships in time order and keep track of how many groups there are.
2. Sort the logs; tuples sort by their first item, the time. Start with `n` groups and use a union-find. Each friendship that joins two different groups lowers the count by one.
3. Return the time of the friendship that brings the count down to 1. If the logs run out first, return `None`.
