---
id: course-order
title: Course order
level: core
---

There are `n` courses, numbered `0` to `n - 1`. Each pair `(a, b)` in `prereqs` means course `a` must be taken before course `b`. Return a list of all the courses in an order that respects every pair, or `[]` if no order can. If several orders work, any of them is right.

For `n = 4` and `prereqs = [(0, 1), (0, 2), (1, 3), (2, 3)]`, both `[0, 1, 2, 3]` and `[0, 2, 1, 3]` are right.

```python starter
from collections import deque


def course_order(n, prereqs):
    pass
```

```tests
course_order(3, [(0, 1), (1, 2)]) == [0, 1, 2]
course_order(3, [(2, 1), (1, 0)]) == [2, 1, 0]
course_order(0, []) == []
course_order(1, []) == [0]
course_order(2, [(0, 1), (0, 1)]) == [0, 1]
course_order(2, [(0, 1), (1, 0)]) == []
course_order(3, [(0, 1), (1, 2), (2, 1)]) == []
course_order(4, [(0, 1), (1, 2), (2, 3), (3, 1)]) == []
course_order(4, [(0, 1), (0, 2), (1, 3), (2, 3)]) in ([0, 1, 2, 3], [0, 2, 1, 3])
```

```python tests
import random


def has_order(n, prereqs):
    left = set(range(n))
    while left:
        free = [v for v in left if not any(a in left and b == v for a, b in prereqs)]
        if not free:
            return False
        left -= set(free)
    return True


def check(n, prereqs):
    order = course_order(n, prereqs)
    if not has_order(n, prereqs):
        assert order == [], (n, prereqs, order)
        return
    assert sorted(order) == list(range(n)), (n, prereqs, order)
    place = {v: i for i, v in enumerate(order)}
    for a, b in prereqs:
        assert place[a] < place[b], (n, prereqs, order)


for _ in range(300):
    n = random.randint(1, 8)
    prereqs = [tuple(random.sample(range(n), 2)) for _ in range(random.randint(0, 8))] if n > 1 else []
    check(n, prereqs)

# 0 comes first, n - 1 comes last, everything else in between.
n = 100000
order = course_order(n, [(0, i) for i in range(1, n - 1)] + [(i, n - 1) for i in range(1, n - 1)])
assert order[0] == 0 and order[-1] == n - 1 and sorted(order) == list(range(n))
```

```python solution
from collections import deque


def course_order(n, prereqs):
    graph = {v: [] for v in range(n)}
    indegree = [0] * n
    for a, b in prereqs:
        graph[a].append(b)
        indegree[b] += 1
    queue = deque(v for v in range(n) if indegree[v] == 0)
    order = []
    while queue:
        v = queue.popleft()
        order.append(v)
        for w in graph[v]:
            indegree[w] -= 1
            if indegree[w] == 0:
                queue.append(w)
    return order if len(order) == n else []
```

## Hints

1. This asks for a topological order of the graph with an edge from `a` to `b` for each pair, and for `[]` when that graph has a cycle.
2. Use Kahn's algorithm: count each course's prerequisites, start with the courses that have none, and each time you place a course, lower the count of the courses that come after it.
3. Queue every course with in-degree 0. Pop, append to `order`, and queue any neighbor whose in-degree drops to 0. At the end, return `order` if it holds all `n` courses, else `[]`.
