---
id: queues
title: Queues
---

A print queue sends out jobs in the order they arrived. New jobs join at the back. The printer takes from the front.

```diagram
queue jobs [report, photo, ticket]
highlight 0
```

That is a queue: first in, first out. The front is the item that has waited longest.

---

A list could do it with `append` at the back and `pop(0)` at the front. But `pop(0)` leaves a gap at index 0, and every other item shifts left to fill it.

```diagram
array [report, photo, ticket, memo, map]
highlight 0
shade 1..4
```

One `pop(0)` on n items moves n - 1 of them. Serving a whole queue of n jobs this way moves about n²/2 items.

---

A list of n items is emptied with `pop(0)` until nothing is left. In total this takes

- [ ] O(n) time, one step per pop
- [ ] O(n log n) time
- [x] O(n²) time, because each pop shifts what is left

---

`collections.deque` is built for this. It stores items in linked blocks, so both ends can grow and shrink without shifting anything. `append`, `appendleft`, `pop` and `popleft` are all O(1).

```python
from collections import deque

jobs = deque(["report", "photo"])
jobs.append("ticket")
print(jobs.popleft())
print(list(jobs))
```

What it gives up is fast indexing in the middle: `jobs[i]` is O(n) away from the ends.

---

What does this print?

```python predict
from collections import deque

q = deque([1, 2, 3])
q.append(4)
q.popleft()
q.appendleft(0)
print(list(q), q[0], q[-1])
```

---

Queues share time fairly. Each job needs some seconds of work, and the machine gives one second at a time. A job that isn't done goes to the back of the line.

```python
import viz
from collections import deque

left = {"a": 2, "b": 1, "c": 3}
q = deque(left)
while q:
    viz.queue(q, highlight=0)
    job = q.popleft()
    left[job] -= 1
    if left[job] > 0:
        q.append(job)
    else:
        viz.note(f"{job} is done")
```

---

```python trace stop=20
from collections import deque

left = {"a": 2, "b": 1, "c": 3}
q = deque(left)
done = []
while q:
    job = q.popleft()
    left[job] -= 1
    if left[job] > 0:
        q.append(job)
    else:
        done.append(job)
print(done)
```

Each job has had one turn. What is in `q`?

- [ ] `a`, `b`, `c`
- [x] `a`, `c`
- [ ] `c`, `a`

---

Put the lines in order so `finish_order` returns the jobs in the order they finish.

```python arrange
from collections import deque

def finish_order(left):
    q = deque(left)
    done = []
    while q:
        job = q.popleft()
        left[job] -= 1
        if left[job] > 0:
            q.append(job)
        else:
            done.append(job)
    return done
```

```tests
finish_order({"a": 2, "b": 1, "c": 3}) == ["b", "a", "c"]
finish_order({"x": 1}) == ["x"]
finish_order({}) == []
finish_order({"p": 2, "q": 2}) == ["p", "q"]
```

---

When should you reach for a `deque` instead of a list?

- [x] When items leave from the front
- [ ] When you need `a[i]` for any `i` in O(1)
- [ ] When items only join and leave at the end

---

[Recent requests](exercises/recent-requests.md)

[Last one standing](exercises/last-one-standing.md)

[Queue from two stacks](exercises/two-stack-queue.md)
