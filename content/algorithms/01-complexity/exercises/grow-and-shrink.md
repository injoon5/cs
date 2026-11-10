---
id: grow-and-shrink
title: Grow and shrink
level: stretch
---

A list starts empty with room for 1 item. `ops` is a string of `+` (append) and `-` (pop from the end). A pop never happens on an empty list.

- Append: if the list is full, copy every item into a block with twice the room. Then add the item.
- Pop: remove the item. Then, if the room is more than 1 and the list is at most a quarter full, copy every item into a block with half the room.

Return the total number of items copied.

```python starter
def grow_and_shrink(ops):
    pass
```

```tests
grow_and_shrink("") == 0
grow_and_shrink("+") == 0
grow_and_shrink("+++") == 3
grow_and_shrink("++-") == 1
grow_and_shrink("++--") == 1
grow_and_shrink("+++++-") == 7
grow_and_shrink("+++++---") == 9
grow_and_shrink("+" * 1025 + "-+" * 100000) == 2047
grow_and_shrink("+" * 100000 + "-" * 100000) == 196606
```

```python solution
def grow_and_shrink(ops):
    capacity, size, copies = 1, 0, 0
    for op in ops:
        if op == "+":
            if size == capacity:
                copies += size
                capacity *= 2
            size += 1
        else:
            size -= 1
            if capacity > 1 and size <= capacity // 4:
                copies += size
                capacity //= 2
    return copies
```

## Hints

1. Track three numbers as you go: room, items and copies so far.
2. Handle each character in order. An append may grow before adding; a pop may shrink after removing.
3. On `+`: if `size == capacity`, add `size` to copies and double `capacity`; then `size += 1`. On `-`: `size -= 1`; then if `capacity > 1 and size <= capacity // 4`, add `size` and halve `capacity`.
