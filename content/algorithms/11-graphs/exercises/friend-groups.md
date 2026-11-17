---
id: friend-groups
title: Friend groups
level: core
---

There are `n` people, numbered `0` to `n - 1`, and `pairs` lists who is friends with whom. Friendship goes both ways, and a friend of a friend is in the same group. Return the size of every group, largest first. Someone with no friends is a group of 1.

For `n = 6` and `pairs = [(0, 1), (1, 2), (3, 4)]`, the groups are 0, 1, 2 and 3, 4 and 5 alone, so the answer is `[3, 2, 1]`.

```python starter
def group_sizes(n, pairs):
    pass
```

```tests
group_sizes(6, [(0, 1), (1, 2), (3, 4)]) == [3, 2, 1]
group_sizes(0, []) == []
group_sizes(1, []) == [1]
group_sizes(3, []) == [1, 1, 1]
group_sizes(5, [(0, 4), (4, 2), (2, 0)]) == [3, 1, 1]
group_sizes(4, [(0, 1), (1, 0), (2, 3), (3, 2)]) == [2, 2]
group_sizes(5, [(4, 3), (1, 0), (2, 1)]) == [3, 2]
group_sizes(100000, [(i, i + 1) for i in range(99999)]) == [100000]
group_sizes(100000, [(i, i + 50000) for i in range(50000)]) == [2] * 50000
```

```python tests
import random


def slow(n, pairs):
    groups = [{v} for v in range(n)]
    for a, b in pairs:
        ga = next(g for g in groups if a in g)
        gb = next(g for g in groups if b in g)
        if ga is not gb:
            groups.remove(gb)
            ga |= gb
    return sorted((len(g) for g in groups), reverse=True)


for _ in range(300):
    n = random.randint(0, 9)
    pairs = [tuple(random.sample(range(n), 2)) for _ in range(random.randint(0, 8))] if n > 1 else []
    assert group_sizes(n, pairs) == slow(n, pairs), (n, pairs)
```

```python solution
def group_sizes(n, pairs):
    graph = {v: [] for v in range(n)}
    for a, b in pairs:
        graph[a].append(b)
        graph[b].append(a)
    seen = set()
    sizes = []
    for start in range(n):
        if start in seen:
            continue
        seen.add(start)
        stack = [start]
        size = 0
        while stack:
            v = stack.pop()
            size += 1
            for w in graph[v]:
                if w not in seen:
                    seen.add(w)
                    stack.append(w)
        sizes.append(size)
    return sorted(sizes, reverse=True)
```

## Hints

1. People are nodes and friendships are undirected edges. A group is a connected component.
2. Build the adjacency list, then go through everyone. A person not seen yet starts a new group: search from them and count the people the search reaches.
3. Use a stack rather than recursion, since one group can hold 100,000 people. Each pop adds 1 to the group's size. Sort the sizes with `reverse=True` at the end.
