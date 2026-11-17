---
id: find-the-judge
title: Find the judge
level: warmup
---

A town has `n` people, numbered `0` to `n - 1`. Each pair `(a, b)` in `trusts` means `a` trusts `b`. The judge trusts nobody, and everybody else trusts the judge. Return the judge's number, or `-1` if there is no judge. No pair appears twice, and nobody trusts themselves.

For `n = 3` and `trusts = [(0, 2), (1, 2)]`, the judge is 2.

```python starter
def judge(n, trusts):
    pass
```

```tests
judge(3, [(0, 2), (1, 2)]) == 2
judge(2, [(0, 1)]) == 1
judge(1, []) == 0
judge(2, []) == -1
judge(3, [(0, 2), (1, 2), (2, 0)]) == -1
judge(3, [(0, 1), (1, 2)]) == -1
judge(3, [(0, 2)]) == -1
judge(4, [(0, 3), (1, 3), (2, 3), (0, 1), (2, 1)]) == 3
judge(100000, [(i, 0) for i in range(1, 100000)]) == 0
judge(100000, [(i, 99999) for i in range(1, 99999)]) == -1
```

```python tests
import random


def slow(n, trusts):
    for j in range(n):
        if all((j, b) not in trusts for b in range(n)) and all((a, j) in trusts for a in range(n) if a != j):
            return j
    return -1


for _ in range(300):
    n = random.randint(1, 6)
    pairs = [(a, b) for a in range(n) for b in range(n) if a != b]
    trusts = random.sample(pairs, random.randint(0, len(pairs)))
    if n > 1 and random.random() < 0.5:
        j = random.randrange(n)
        trusts = [(a, b) for a, b in trusts if a != j]
        trusts += [(a, j) for a in range(n) if a != j and (a, j) not in trusts]
    assert judge(n, trusts) == slow(n, trusts)
```

```python solution
def judge(n, trusts):
    trusted_by = [0] * n
    trusts_someone = [False] * n
    for a, b in trusts:
        trusts_someone[a] = True
        trusted_by[b] += 1
    for v in range(n):
        if trusted_by[v] == n - 1 and not trusts_someone[v]:
            return v
    return -1
```

## Hints

1. Treat each pair as a directed edge from `a` to `b`. The judge has no edges leaving and an edge arriving from everyone else.
2. One pass over the pairs gives every person's in-degree and out-degree. Then look for the person whose in-degree is `n - 1` and out-degree is 0.
3. Keep `trusted_by[b] += 1` and mark `a` as trusting someone. Return the first `v` with `trusted_by[v] == n - 1` that trusts nobody, else `-1`.
