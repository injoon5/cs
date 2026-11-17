---
id: two-teams
title: Split into two teams
level: stretch
---

There are `n` people, numbered `0` to `n - 1`, and each pair in `rivals` must end up on different teams. Return `True` if everyone can be split into two teams so that no rivals share a team. A team can be empty, and nobody is their own rival.

With rivals `[(0, 1), (1, 2), (2, 3), (3, 0)]`, teams 0, 2 and 1, 3 work. With `[(0, 1), (1, 2), (2, 0)]` they can't: whichever teams 0 and 1 take, 2 is the rival of both.

```python starter
from collections import deque


def can_split(n, rivals):
    pass
```

```tests
can_split(4, [(0, 1), (1, 2), (2, 3), (3, 0)]) == True
can_split(3, [(0, 1), (1, 2), (2, 0)]) == False
can_split(0, []) == True
can_split(1, []) == True
can_split(2, [(0, 1), (1, 0)]) == True
can_split(5, [(0, 1), (2, 3)]) == True
can_split(5, [(0, 1), (2, 3), (3, 4), (4, 2)]) == False
can_split(6, [(0, 1), (1, 2), (3, 4), (4, 5), (5, 3)]) == False
can_split(100000, [(i, (i + 1) % 100000) for i in range(100000)]) == True
can_split(99999, [(i, (i + 1) % 99999) for i in range(99999)]) == False
```

```python tests
import random
from itertools import product


def slow(n, rivals):
    return any(all(t[a] != t[b] for a, b in rivals) for t in product((0, 1), repeat=n))


for _ in range(300):
    n = random.randint(0, 8)
    rivals = [tuple(random.sample(range(n), 2)) for _ in range(random.randint(0, 9))] if n > 1 else []
    assert can_split(n, rivals) == slow(n, rivals), (n, rivals)
```

```python solution
from collections import deque


def can_split(n, rivals):
    graph = {v: [] for v in range(n)}
    for a, b in rivals:
        graph[a].append(b)
        graph[b].append(a)
    team = {}
    for start in range(n):
        if start in team:
            continue
        team[start] = 0
        queue = deque([start])
        while queue:
            v = queue.popleft()
            for w in graph[v]:
                if w not in team:
                    team[w] = 1 - team[v]
                    queue.append(w)
                elif team[w] == team[v]:
                    return False
    return True
```

## Hints

1. Once you pick a team for one person, every rival of theirs is forced onto the other team, then every rival of those, and so on through their component.
2. Search each component with BFS. Give the first person team 0 and each newly found person the team opposite to whoever found them. If an edge ever joins two people on the same team, the split is impossible.
3. Keep `team` as a dict that doubles as the seen set. For each neighbor `w` of `v`: if `w` has no team, set `team[w] = 1 - team[v]` and queue it; if `team[w] == team[v]`, return `False`. Start a new search from every person without a team.
