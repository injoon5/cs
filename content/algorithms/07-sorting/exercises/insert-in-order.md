---
id: insert-in-order
title: Insert in order
level: warmup
---

`a` is sorted from smallest to largest. Add `x` so that `a` stays sorted, by appending it and moving it left the way insertion sort does. Change `a` in place and return it. Don't call `sort` or `sorted`. For example, `insert_in_order([1, 4, 6], 5)` gives `[1, 4, 5, 6]`.

```python starter
def insert_in_order(a, x):
    pass
```

```tests
insert_in_order([1, 4, 6], 5) == [1, 4, 5, 6]
insert_in_order([1, 4, 6], 0) == [0, 1, 4, 6]
insert_in_order([1, 4, 6], 9) == [1, 4, 6, 9]
insert_in_order([], 3) == [3]
insert_in_order([2], 2) == [2, 2]
insert_in_order([1, 3, 3, 5], 3) == [1, 3, 3, 3, 5]
insert_in_order([-5, -2, 0], -3) == [-5, -3, -2, 0]
insert_in_order(list(range(0, 2000, 2)), 999) == sorted(list(range(0, 2000, 2)) + [999])
```

```python tests
a = [10, 20, 30]
assert insert_in_order(a, 25) is a, "change a in place and return it"
```

```python solution
def insert_in_order(a, x):
    a.append(x)
    j = len(a) - 1
    while j > 0 and a[j - 1] > a[j]:
        a[j - 1], a[j] = a[j], a[j - 1]
        j -= 1
    return a
```

## Hints

1. After `a.append(x)`, everything but the last item is sorted. That is one step of insertion sort.
2. Walk `j` from the last index to the left, swapping `a[j - 1]` and `a[j]` while the left one is bigger.
3. Loop `while j > 0 and a[j - 1] > a[j]`, swap, then `j -= 1`. Return `a`.
