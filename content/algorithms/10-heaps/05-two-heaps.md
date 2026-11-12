---
id: two-heaps
title: Two heaps and scheduling
---

Numbers arrive one at a time, and after each one you want the median. Sorting after every number costs O(n log n) each time.

Split the numbers into two halves instead. The lower half goes in a max-heap, the upper half in a min-heap. Then the two middle numbers are the two roots.

```diagram
array low [1, 2, 5]
highlight 2

array high [8, 9]
highlight 0
```

Keep `low` the same size as `high`, or one bigger. With an odd count the median is the top of `low`. With an even count it is the mean of both tops.

---

Each new number goes into `low`, then `low` hands its largest to `high`. That keeps every number in `low` below every number in `high`. If `high` grows bigger than `low`, it hands its smallest back.

```python
import heapq

low, high = [], []  # low holds negated numbers


def add(x):
    heapq.heappush(low, -x)
    heapq.heappush(high, -heapq.heappop(low))
    if len(high) > len(low):
        heapq.heappush(low, -heapq.heappop(high))


def median():
    if len(low) > len(high):
        return -low[0]
    return (-low[0] + high[0]) / 2


for x in [5, 2, 8, 1, 9]:
    add(x)
    print(x, median())
```

---

```python trace stop=17
import heapq

low, high = [], []
for x in [5, 2, 8, 1]:
    heapq.heappush(low, -x)
    heapq.heappush(high, -heapq.heappop(low))
    if len(high) > len(low):
        heapq.heappush(low, -heapq.heappop(high))
print(-low[0], high[0])
```

The loop has just handled `x = 8`. What do the heaps hold?

- [ ] `low` is `[-2]`, `high` is `[5, 8]`
- [x] `low` is `[-5, -2]`, `high` is `[8]`
- [ ] `low` is `[-8, -5, -2]`, `high` is `[]`

---

With two heaps, adding a number and reading the median cost

- [x] O(log n) to add, O(1) to read
- [ ] O(1) to add, O(log n) to read
- [ ] O(n) to add, O(1) to read

---

Heaps also run schedules. One machine runs jobs one at a time, and whenever it is free it picks the shortest job that has arrived. The heap holds the jobs that are waiting, ordered by length. What does this print?

```python predict
import heapq

# (arrives, length, name), sorted by arrival
jobs = [(0, 3, "a"), (1, 9, "b"), (2, 2, "c")]
ready, t, i = [], 0, 0
while i < len(jobs) or ready:
    while i < len(jobs) and jobs[i][0] <= t:
        _, length, name = jobs[i]
        heapq.heappush(ready, (length, name))
        i += 1
    if not ready:
        t = jobs[i][0]
        continue
    length, name = heapq.heappop(ready)
    t += length
    print(name, "done at", t)
```

---

The same shape answers how many meeting rooms a calendar needs. Go through the meetings by start time, and keep a min-heap of the end times of rooms in use. The root is the room that frees up first.

```diagram
array starts [9, 9, 10, 11]
pointer now 2

array ends [10, 12]
highlight 0
```

The meeting at 10 can take the room whose meeting ends at 10: pop it, then push the new end time. If the earliest end is still later than the start, every room is busy, and the heap grows by one.

---

Which of these is a job for a heap?

- [ ] Checking whether a number is in a sorted list
- [x] Repeatedly taking the task with the earliest deadline while new tasks keep arriving
- [ ] Finding the sum of every window of 3 numbers

---

[Meeting rooms](exercises/meeting-rooms-needed.md)

[Running median](exercises/running-median.md)
