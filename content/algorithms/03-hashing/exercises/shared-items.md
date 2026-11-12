---
id: shared-items
title: Shared items
level: warmup
---

Return the items of `a` that also appear in `b`, in the order they first appear in `a`, each once. For `a = [3, 1, 4, 1, 5]` and `b = [5, 1, 9]` the answer is `[1, 5]`. Lists can hold 100,000 items.

```python starter
def shared_items(a, b):
    pass
```

```tests
shared_items([3, 1, 4, 1, 5], [5, 1, 9]) == [1, 5]
shared_items([], [1, 2]) == []
shared_items([1, 2], []) == []
shared_items([7], [7]) == [7]
shared_items([2, 2, 2], [2]) == [2]
shared_items([-1, 0, 1], [1, -1]) == [-1, 1]
shared_items(["b", "a", "c"], ["c", "b"]) == ["b", "c"]
shared_items([1, 2, 3], [4, 5, 6]) == []
shared_items(list(range(100000)), list(range(50000, 150000))) == list(range(50000, 100000))
```

```python solution
def shared_items(a, b):
    in_b = set(b)
    seen = set()
    out = []
    for x in a:
        if x in in_b and x not in seen:
            out.append(x)
            seen.add(x)
    return out
```

## Hints

1. Checking `x in b` on a list is O(len(b)) each time. Make that check O(1).
2. Put `b` in a set. Keep a second set of items you've already added, so repeats in `a` show up once.
3. Loop over `a` and append `x` when `x in in_b and x not in seen`, then add it to `seen`.
