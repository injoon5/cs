---
id: order-by-priority
title: Order by priority
level: warmup
---

`tasks` is a list of `(name, priority)` pairs. Return the names in the order a priority queue would hand them out: smallest priority first, and tasks with equal priority in the order they appear in `tasks`. Use `heapq`. For `[("write", 2), ("plan", 1), ("test", 2)]` the answer is `["plan", "write", "test"]`.

```python starter
import heapq


def by_priority(tasks):
    pass
```

```tests
by_priority([("write", 2), ("plan", 1), ("test", 2)]) == ["plan", "write", "test"]
by_priority([]) == []
by_priority([("only", 5)]) == ["only"]
by_priority([("b", 1), ("a", 1)]) == ["b", "a"]
by_priority([("z", 3), ("y", 2), ("x", 1)]) == ["x", "y", "z"]
by_priority([("late", 0), ("early", -4)]) == ["early", "late"]
by_priority([("a", 1), ("a", 0)]) == ["a", "a"]
by_priority([(str(i), i % 3) for i in range(6)]) == ["0", "3", "1", "4", "2", "5"]
```

```python solution
import heapq


def by_priority(tasks):
    heap = []
    for i, (name, prio) in enumerate(tasks):
        heapq.heappush(heap, (prio, i, name))
    out = []
    while heap:
        out.append(heapq.heappop(heap)[2])
    return out
```

## Hints

1. A tuple `(priority, name)` breaks ties by name, which isn't what the task asks for.
2. Put something between the priority and the name that is unique and grows in input order.
3. Push `(priority, i, name)` where `i` is the position from `enumerate`, then pop until the heap is empty and keep the names.
