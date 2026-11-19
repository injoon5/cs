---
id: interval-scheduling
title: Interval scheduling
---

One room, and these requests to use it. Each is a `(start, end)` pair on the hour, and each column is one hour: (1, 4) fills hours 1, 2 and 3. A meeting that ends at 5 frees the room for one that starts at 5. What is the most meetings the room can hold?

```diagram
grid
col-labels [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
row-labels ["(0, 2)", "(1, 4)", "(2, 7)", "(3, 5)", "(5, 6)", "(6, 9)", "(8, 10)"]
row [■, ■, , , , , , , , ]
row [, ■, ■, ■, , , , , , ]
row [, , ■, ■, ■, ■, ■, , , ]
row [, , , ■, ■, , , , , ]
row [, , , , , ■, , , , ]
row [, , , , , , ■, ■, ■, ]
row [, , , , , , , , ■, ■]
```

A greedy answer sorts the meetings somehow, then takes each one that doesn't clash with those already taken. The whole question is which order to sort by.

---

Sort by start time, and the earliest meeting goes first. Here that is a bad idea:

```diagram
grid
col-labels [0, 1, 2, 3, 4, 5, 6, 7, 8]
row-labels ["(0, 9)", "(1, 3)", "(4, 6)", "(7, 9)"]
row [■, ■, ■, ■, ■, ■, ■, ■, ■]
row [, ■, ■, , , , , , ]
row [, , , , ■, ■, , , ]
row [, , , , , , , ■, ■]
highlight 0,0 0,1 0,2 0,3 0,4 0,5 0,6 0,7 0,8
```

(0, 9) starts first and blocks the whole day. The three short meetings fit together.

---

Then try the shortest meetings first, since they use the least of the room's time.

```diagram
grid
col-labels [0, 1, 2, 3, 4, 5, 6, 7]
row-labels ["(0, 4)", "(3, 5)", "(4, 8)"]
row [■, ■, ■, ■, , , , ]
row [, , , ■, ■, , , ]
row [, , , , ■, ■, ■, ■]
```

What does shortest first do here?

- [ ] It takes (0, 4) and (4, 8), the best answer
- [x] It takes (3, 5), which clashes with both others, so it holds 1 meeting instead of 2
- [ ] It takes all three, since short meetings never clash

---

The rule that works: earliest end first. The meeting that ends first leaves the room free as early as possible, and so leaves the most room for everything else.

Run this to watch it on the first set of meetings, sorted by end. Highlighted rows are taken, dotted rows are skipped.

```python
import viz

meetings = [(0, 2), (1, 4), (2, 7), (3, 5), (5, 6), (6, 9), (8, 10)]
meetings.sort(key=lambda m: m[1])
rows = [["■" if s <= t < e else None for t in range(10)] for s, e in meetings]
labels = [f"({s}, {e})" for s, e in meetings]
taken = []
free = float("-inf")
viz.grid(rows, row_labels=labels, col_labels=range(10), note="sorted by end")
for i, (s, e) in enumerate(meetings):
    if s >= free:
        taken += [(i, t) for t in range(s, e)]
        free = e
        note = f"({s}, {e}) fits, take it; the room is free at {e}"
    else:
        rows[i] = ["·" if cell else None for cell in rows[i]]
        note = f"({s}, {e}) starts before {free}, skip"
    viz.grid(rows, highlight=taken, row_labels=labels, col_labels=range(10), note=note)
```

`free` is the time the room comes free. It starts at minus infinity, so the first meeting always fits.

---

Why is earliest end safe? Let `f` be the meeting that ends first. Take any best schedule, and let `g` be its first meeting. Swap `g` out and `f` in.

Why can't `f` clash with `h`, the second meeting of that schedule?

- [ ] `f` is the shortest meeting, so it clashes with nothing
- [x] `h` starts no earlier than `g` ends, and `g` ends no earlier than `f`
- [ ] `f` starts before every other meeting

The new schedule has as many meetings and starts with `f`. What's left is the same problem on the meetings that start once `f` is over.

---

Here the meetings are already sorted by end.

```python trace stop=16
meetings = [(1, 3), (2, 4), (3, 6), (4, 6), (5, 8), (6, 9)]
count, free = 0, float("-inf")
for start, end in meetings:
    if start >= free:
        count += 1
        free = end
print(count)
```

The loop is about to check (5, 8). What are `count` and `free`?

- [ ] `count` is 3, `free` is 6
- [x] `count` is 2, `free` is 6
- [ ] `count` is 2, `free` is 4

---

Put the lines in order so `max_meetings` returns the most meetings that fit in one room. A meeting may start the moment the one before it ends.

```python arrange
def max_meetings(meetings):
    count, free = 0, float("-inf")
    for start, end in sorted(meetings, key=lambda m: m[1]):
        if start >= free:
            count += 1
            free = end
    return count
```

```tests
max_meetings([(1, 4), (0, 2), (3, 5), (5, 6), (2, 7), (6, 9), (8, 10)]) == 4
max_meetings([(0, 9), (1, 3), (4, 6), (7, 9)]) == 3
max_meetings([(0, 4), (3, 5), (4, 8)]) == 2
max_meetings([(1, 2), (1, 2), (1, 2)]) == 1
max_meetings([(5, 7)]) == 1
max_meetings([]) == 0
```

---

Removing the fewest meetings so that the rest don't clash is the same problem in disguise. Keep as many as you can, and remove the rest: n minus the most that fit.

A close cousin: balloons are intervals on a line, and an arrow shot at `x` bursts every balloon with `start <= x <= end`. Here each column is a point, and a balloon covers both its ends.

```diagram
grid
col-labels [0, 1, 2, 3, 4, 5, 6, 7, 8]
row-labels ["(0, 3)", "(1, 4)", "(4, 6)", "(5, 8)"]
row [■, ■, ■, ■, , , , , ]
row [, ■, ■, ■, ■, , , , ]
row [, , , , ■, ■, ■, , ]
row [, , , , , ■, ■, ■, ■]
highlight 0,3 1,3 2,6 3,6
```

Two arrows do it, at 3 and at 6.

---

Where should the first arrow go?

- [ ] At the start of the balloon that starts first
- [x] At the end of the balloon that ends first
- [ ] In the middle of the longest balloon

The balloon that ends first needs an arrow somewhere at or before its end. Moving that arrow right, up to its end, keeps every balloon it hit: they all start at or before the arrow and end no earlier than that first end.

---

Sorting n intervals by end, then one pass, takes

- [ ] O(n) time
- [x] O(n log n) time
- [ ] O(n²) time, since each interval is checked against the ones taken

Only the last one taken matters, through `free`, so each check is O(1).

---

[Fewest removals](exercises/min-removals-overlap.md)

[Burst the balloons](exercises/min-arrows-burst.md)
