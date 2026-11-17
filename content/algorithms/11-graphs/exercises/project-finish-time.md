---
id: project-finish-time
title: Project time
level: stretch
---

Task `i` takes `durations[i]` hours. Each pair `(a, b)` in `deps` means task `b` can only start once task `a` has finished. Any number of tasks can run at the same time, and there are no cycles. Return the earliest time at which every task is done.

For `durations = [3, 2, 5]` and `deps = [(0, 2), (1, 2)]`, tasks 0 and 1 start right away. Task 2 waits for the slower of them, so it starts at 3 and finishes at 8.

```python starter
from collections import deque


def finish_time(durations, deps):
    pass
```

```tests
finish_time([3, 2, 5], [(0, 2), (1, 2)]) == 8
finish_time([], []) == 0
finish_time([4], []) == 4
finish_time([1, 2, 3], []) == 3
finish_time([1, 2, 3], [(0, 1), (1, 2)]) == 6
finish_time([5, 1, 1, 1], [(1, 2), (2, 3)]) == 5
finish_time([1, 1, 10, 1], [(0, 1), (1, 3), (0, 2), (2, 3)]) == 12
finish_time([2, 2], [(1, 0), (1, 0)]) == 4
finish_time([1] * 600, [(v, w) for v in range(598) for w in (v // 2 * 2 + 2, v // 2 * 2 + 3)]) == 300
finish_time([1] * 100000, []) == 1
```

```python tests
import random


def slow(durations, deps):
    end = list(durations)
    for _ in range(len(durations)):
        for a, b in deps:
            end[b] = max(end[b], end[a] + durations[b])
    return max(end, default=0)


for _ in range(300):
    n = random.randint(1, 8)
    durations = [random.randint(1, 9) for _ in range(n)]
    deps = []
    for _ in range(random.randint(0, 10)):
        a, b = sorted(random.sample(range(n), 2)) if n > 1 else (0, 0)
        if a != b:
            deps.append((a, b))
    perm = random.sample(range(n), n)
    deps = [(perm[a], perm[b]) for a, b in deps]
    durations = [durations[perm.index(i)] for i in range(n)]
    assert finish_time(durations, deps) == slow(durations, deps), (durations, deps)
```

```python solution
from collections import deque


def finish_time(durations, deps):
    n = len(durations)
    graph = {v: [] for v in range(n)}
    indegree = [0] * n
    for a, b in deps:
        graph[a].append(b)
        indegree[b] += 1
    start = [0] * n
    queue = deque(v for v in range(n) if indegree[v] == 0)
    end = 0
    while queue:
        v = queue.popleft()
        done = start[v] + durations[v]
        end = max(end, done)
        for w in graph[v]:
            start[w] = max(start[w], done)
            indegree[w] -= 1
            if indegree[w] == 0:
                queue.append(w)
    return end
```

## Hints

1. A task starts when the last of its prerequisites finishes. If you handle tasks in topological order, all of a task's prerequisites are done before you reach it.
2. Run Kahn's algorithm and keep `start[v]`, the earliest time task `v` can begin. When you take `v` from the queue, it finishes at `start[v] + durations[v]`.
3. For each `w` after `v`, set `start[w] = max(start[w], finish of v)` before lowering its in-degree. The answer is the largest finish time of any task.
