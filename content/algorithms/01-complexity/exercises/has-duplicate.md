---
id: has-duplicate
title: Has duplicate
level: core
---

Return `True` if any value appears more than once in `xs`, otherwise `False`. Lists can hold 200,000 items, so comparing every pair is too slow.

```python starter
def has_duplicate(xs):
    for i in range(len(xs)):
        for j in range(i + 1, len(xs)):
            if xs[i] == xs[j]:
                return True
    return False
```

```tests
has_duplicate([]) == False
has_duplicate([5]) == False
has_duplicate([1, 2, 3]) == False
has_duplicate([1, 2, 1]) == True
has_duplicate(["a", "b", "a"]) == True
has_duplicate(list(range(200000))) == False
has_duplicate(list(range(200000)) + [0]) == True
```

```python solution
def has_duplicate(xs):
    seen = set()
    for x in xs:
        if x in seen:
            return True
        seen.add(x)
    return False
```

## Hints

1. The pairs loop is O(n²). Aim for one pass over the list.
2. Remember what you've already seen in something with fast lookups.
3. Keep a `set`. For each `x`, return `True` if it's already in the set, else add it.
