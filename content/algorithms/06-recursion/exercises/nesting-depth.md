---
id: nesting-depth
title: Nesting depth
level: core
---

`items` is a list whose entries are numbers or other lists. Return how deeply it nests: a list with no lists inside has depth 1, and each level of lists adds 1. `[1, [2, [3]], [4]]` has depth 3, because `[3]` sits inside `[2, [3]]`, which sits inside the outer list.

```python starter
def nesting_depth(items):
    pass
```

```tests
nesting_depth([1, [2, [3]], [4]]) == 3
nesting_depth([]) == 1
nesting_depth([5]) == 1
nesting_depth([1, 2, 3]) == 1
nesting_depth([[]]) == 2
nesting_depth([[[[[]]]]]) == 5
nesting_depth([[1], [[2]], [3]]) == 3
nesting_depth([[[-1]], [[-1]]]) == 3
nesting_depth([1, [2], 3, [4, [5, [6, [7]]]]]) == 5
```

```python solution
def nesting_depth(items):
    deepest = 0
    for item in items:
        if isinstance(item, list):
            deepest = max(deepest, nesting_depth(item))
    return 1 + deepest
```

## Hints

1. The depth of a list is 1 more than the depth of its deepest inner list.
2. Ask each inner list for its depth with a recursive call and keep the largest. A list with no inner lists adds nothing.
3. Start `deepest = 0`. For each item that is a list, `deepest = max(deepest, nesting_depth(item))`. Return `1 + deepest`.
