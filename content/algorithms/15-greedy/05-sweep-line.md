---
id: sweep-line
title: The sweep line
---

How many meetings are going on at the busiest moment? Each column is an hour again, and the last row counts the meetings in that hour.

```diagram
grid
col-labels [0, 1, 2, 3, 4, 5, 6, 7, 8]
row-labels ["(1, 4)", "(2, 6)", "(5, 8)", "(3, 5)", count]
row [, ■, ■, ■, , , , , ]
row [, , ■, ■, ■, ■, , , ]
row [, , , , , ■, ■, ■, ]
row [, , , ■, ■, , , , ]
row [0, 1, 2, 3, 2, 2, 1, 1, 0]
highlight 4,3
```

The heaps unit answered this with a heap of end times, to count meeting rooms. Here is another way, and it answers many more questions about intervals.

---

The count only changes where a meeting starts or ends. So turn each meeting into two events: +1 at its start and -1 at its end.

```python
meetings = [(1, 4), (2, 6), (5, 8), (3, 5)]
events = []
for start, end in meetings:
    events.append((start, 1))
    events.append((end, -1))
events.sort()
print(events)
```

Sorted, the events are the moments where something happens, from left to right.

---

Now sweep a line across them from left to right, keeping a running count. The busiest moment is the largest count it sees.

```python trace stop=34
meetings = [(1, 4), (2, 6), (5, 8), (3, 5)]
events = []
for start, end in meetings:
    events.append((start, 1))
    events.append((end, -1))
events.sort()
count = best = 0
for x, delta in events:
    count += delta
    best = max(best, count)
print(best)
```

The sweep has reached the start at 5 and is about to add it. What are `count` and `best`?

- [ ] `count` is 2, `best` is 3
- [x] `count` is 1, `best` is 3
- [ ] `count` is 3, `best` is 3

---

Run this to watch the line move. The highlighted column is where the sweep is.

```python
import viz

meetings = [(1, 4), (2, 6), (5, 8), (3, 5)]
rows = [["■" if s <= t < e else None for t in range(9)] for s, e in meetings]
labels = [f"({s}, {e})" for s, e in meetings]
events = []
for i, (s, e) in enumerate(meetings):
    events.append((s, 1, i))
    events.append((e, -1, i))
events.sort()
count = 0
viz.grid(rows, row_labels=labels, col_labels=range(9), note="count 0")
for x, delta, i in events:
    count += delta
    what = "starts" if delta == 1 else "ends"
    line = [(r, x) for r in range(len(rows))]
    note = f"{labels[i]} {what} at {x}, count {count}"
    viz.grid(rows, highlight=line, row_labels=labels, col_labels=range(9), note=note)
```

At 5, (3, 5) ends and (5, 8) starts. The end comes first, so the count dips to 1 and never reads 3 there.

---

That order wasn't luck. Tuples compare item by item, and -1 sorts before 1, so at the same coordinate ends come before starts. That's right for meetings, where touching isn't overlapping.

Closed intervals, like the balloons, are different: (1, 3) and (3, 5) both hold the point 3. What does this print?

```python predict
events = [(3, 1), (1, 1), (3, -1), (5, -1)]
print(sorted(events))
print(sorted(events, key=lambda ev: (ev[0], -ev[1])))
```

---

Sweeping closed intervals, which events must come first at the same coordinate?

- [x] Starts, so the intervals that touch are both counted there
- [ ] Ends, as with meetings
- [ ] Either order gives the same largest count

Get this wrong and the answer is off by one exactly when intervals touch, which is easy to miss in tests.

---

When the coordinates are small whole numbers, the events can go in a list indexed by coordinate instead of being sorted. This is the prefix sums from the arrays unit, run over +1 and -1 marks. `accumulate` from `itertools` returns the running sums.

```python
from itertools import accumulate

meetings = [(1, 4), (2, 6), (5, 8), (3, 5)]
diff = [0] * 9
for s, e in meetings:
    diff[s] += 1
    diff[e] -= 1
print(diff)
print(list(accumulate(diff)))
```

The running sums are the count row from the first diagram. The list has to be as long as the time span, though. Sorting the events works for any coordinates, even floats or times in the billions.

---

The same sweep answers other questions. To find the total time when at least one meeting is going on, what does the loop need besides `count`?

- [ ] The list of meetings that are open right now
- [x] The coordinate of the previous event, to add `x - prev` whenever `count` was above 0
- [ ] The length of the longest meeting

And a delta doesn't have to be 1. A trip that carries 3 passengers adds 3 when it starts and takes 3 away when it ends.

---

A sweep over n intervals sorts 2n events, then makes one pass. It takes

- [ ] O(n) time
- [x] O(n log n) time
- [ ] O(n · T) time, where T is the time span

---

[Car pool](exercises/car-pool-fits.md)

[Covered length](exercises/covered-length.md)
