---
id: flatten-nested
title: Flatten a nested list
level: core
---

`items` is a list whose entries are numbers or other lists, nested to any depth. Return one flat list of all the numbers, in order. `[1, [2, [3, 4]], 5]` becomes `[1, 2, 3, 4, 5]`.

```python starter
def flatten(items):
    pass
```

```tests
flatten([1, [2, [3, 4]], 5]) == [1, 2, 3, 4, 5]
flatten([]) == []
flatten([7]) == [7]
flatten([[], [[]], [[[]]]]) == []
flatten([[1, 2], [3], [], [4, [5, [6]]]]) == [1, 2, 3, 4, 5, 6]
flatten([[[[[-1]]]], 0]) == [-1, 0]
flatten([2, [2], [[2]]]) == [2, 2, 2]
flatten([1, 2, 3]) == [1, 2, 3]
flatten([[3, 1], [2, [1, 3]]]) == [3, 1, 2, 1, 3]
```

```python solution
def flatten(items):
    out = []
    for item in items:
        if isinstance(item, list):
            out.extend(flatten(item))
        else:
            out.append(item)
    return out
```

## Hints

1. A list inside the list is a smaller version of the same problem.
2. Walk the items. A number goes straight into the result. A list gets flattened first, then added.
3. Use `isinstance(item, list)`. If it is a list, `out.extend(flatten(item))`, otherwise `out.append(item)`.
