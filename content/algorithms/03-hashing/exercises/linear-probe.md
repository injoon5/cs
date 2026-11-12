---
id: linear-probe
title: Linear probing
level: stretch
---

Insert `keys` one at a time into a table of `size` slots, all `None` at first. A key starts at slot `key % size`. If that slot holds another key, try the next slot to the right, wrapping from the end back to 0. If it finds the same key, the key is already in, so skip it. Return the slots.

For keys `[12, 7, 20, 33]` and 8 slots, 20 finds 12 in slot 4 and moves to 5: `[None, 33, None, None, 12, 20, None, 7]`. Every test has room for all its keys.

```python starter
def probe_table(keys, size):
    pass
```

```tests
probe_table([12, 7, 20, 33], 8) == [None, 33, None, None, 12, 20, None, 7]
probe_table([], 4) == [None, None, None, None]
probe_table([3], 4) == [None, None, None, 3]
probe_table([7, 15], 8) == [15, None, None, None, None, None, None, 7]
probe_table([1, 1, 1], 4) == [None, 1, None, None]
probe_table([0, 4, 8, 12], 4) == [0, 4, 8, 12]
probe_table([-1, 3], 4) == [3, None, None, -1]
probe_table([5, 6, 13], 8) == [None, None, None, None, None, 5, 6, 13]
probe_table([5, 13, 5, 21], 8) == [None, None, None, None, None, 5, 13, 21]
```

```python solution
def probe_table(keys, size):
    slots = [None] * size
    for key in keys:
        i = key % size
        while slots[i] is not None and slots[i] != key:
            i = (i + 1) % size
        slots[i] = key
    return slots
```

## Hints

1. A key walks right from its home slot until it finds either an empty slot or itself.
2. Keep an index `i` that starts at `key % size` and moves with `i = (i + 1) % size` so it wraps.
3. `while slots[i] is not None and slots[i] != key:` step `i` forward. After the loop, `slots[i] = key` is right in both cases.
