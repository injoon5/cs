---
id: heapq-in-practice
title: heapq and heap sort
---

You rarely write sift up and sift down yourself. Python's `heapq` module does it on a plain list.

```python
import heapq

h = [5, 1, 8, 3]
heapq.heapify(h)          # O(n)
heapq.heappush(h, 2)      # O(log n)
print(h[0])               # peek, O(1)
print(heapq.heappop(h))   # O(log n)
print(h)
```

There is no heap class. The list is the heap, and `heapq` keeps it in order as long as you only change it through these functions.

---

What does this print?

```python predict
import heapq

h = []
for x in [5, 1, 4, 2]:
    heapq.heappush(h, x)
print(h[0])
print(heapq.heappop(h), heapq.heappop(h))
print(len(h))
```

---

`heapq` is a min-heap only. For a max-heap, push each number negated, and negate it again on the way out. The largest number becomes the smallest negative.

```python
import heapq

h = []
for x in [5, 1, 4, 2]:
    heapq.heappush(h, -x)
print(-heapq.heappop(h))
print(-heapq.heappop(h))
```

Python 3.14 also adds `heappush_max` and `heappop_max`, but negating works in every version.

---

To order things by priority, push tuples. Tuples compare item by item, so the first item is the priority. What does this print?

```python predict
import heapq

tasks = []
heapq.heappush(tasks, (2, "write"))
heapq.heappush(tasks, (1, "plan"))
heapq.heappush(tasks, (2, "test"))
while tasks:
    print(heapq.heappop(tasks))
```

---

Two tasks with priority 2 tied, so the names decided. Now each task is a dict: you push `(2, {"name": "write"})`, then `(2, {"name": "test"})`. What happens on the second push?

- [ ] `heapq` keeps them in the order they were pushed
- [x] Python compares the two dicts and raises `TypeError`
- [ ] `heapq` compares only the first item of each tuple

---

The fix is a tie-breaker in the middle: a counter that goes up with every push. Counts are never equal, so Python never reaches the dict, and equal priorities come out in the order they went in.

```python
import heapq
from itertools import count

order = count()
h = []
for prio, name in [(2, "write"), (1, "plan"), (2, "test")]:
    heapq.heappush(h, (prio, next(order), {"name": name}))
while h:
    prio, _, task = heapq.heappop(h)
    print(prio, task["name"])
```

---

A heap also sorts. Build a max-heap, then swap the root, the largest item, with the last item and sift the new root down in the part that is still a heap. The sorted part grows from the right.

```python
import viz


def sift_down(a, i, n):
    while 2 * i + 1 < n:
        c = 2 * i + 1
        if c + 1 < n and a[c + 1] > a[c]:
            c += 1
        if a[i] >= a[c]:
            return
        a[i], a[c] = a[c], a[i]
        i = c


def show(a, end, note):
    with viz.frame():
        viz.tree(a[:end])
        viz.array(a, range=(end, len(a) - 1), note=note)


a = [4, 9, 2, 7, 5, 1]
for i in range(len(a) // 2 - 1, -1, -1):
    sift_down(a, i, len(a))
show(a, len(a), "max-heap")
for end in range(len(a) - 1, 0, -1):
    a[0], a[end] = a[end], a[0]
    sift_down(a, 0, end)
    show(a, end, f"{a[end]} is in place")
```

---

Heap sort builds the heap in O(n), then does n - 1 sift downs inside the list itself. It costs

- [ ] O(n) time, O(1) extra space
- [x] O(n log n) time, O(1) extra space
- [ ] O(n log n) time, O(n) extra space

---

Heap sort is in place and never worse than O(n log n), yet `sorted` uses a merge-based sort instead. Why?

- [ ] Heap sort can be O(n²) on sorted input
- [x] Heap sort isn't stable, and its jumps around the list are slow on real memory
- [ ] Heap sort needs a second list as large as the input

---

[Order by priority](exercises/order-by-priority.md)

[Smash the stones](exercises/stone-smash.md)

[Heap sort in place](exercises/heap-sort-in-place.md)
