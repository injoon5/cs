---
id: append-copies
title: Append copies
level: core
---

A list starts empty with room for 1 item. When an append finds it full, it copies every item into a new block with twice the room, then adds the new item.

Return the total number of items copied over `n` appends. Make it fast for `n` up to 10¹⁸.

```python starter
def append_copies(n):
    pass
```

```tests
append_copies(0) == 0
append_copies(1) == 0
append_copies(2) == 1
append_copies(3) == 3
append_copies(5) == 7
append_copies(8) == 7
append_copies(9) == 15
append_copies(1000) == 1023
append_copies(10 ** 18) == 1152921504606846975
```

```python solution
def append_copies(n):
    capacity, copies = 1, 0
    while capacity < n:
        copies += capacity
        capacity *= 2
    return copies
```

## Hints

1. A copy happens only when the room doubles. How many times does that happen for `n` items?
2. Loop over the capacities 1, 2, 4, ... instead of over the appends.
3. While `capacity < n`, the block fills and gets copied: add `capacity` to the total, then double it.
