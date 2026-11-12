---
id: monotonic-deque
title: Sliding window maximum
---

Slide a window of 3 across this list. What is the biggest number in each window?

```diagram
array nums [1, 3, -1, -3, 5, 3, 6, 7]
pointer i 2
shade 0..2
```

The answers are `3, 3, 5, 5, 6, 7`. Checking all k numbers in each window costs about n·k. A running total doesn't help here: when the biggest number leaves, you can't subtract it to find the next biggest.

---

Look at the window `3, -1, -3`. Then 5 joins.

5 is bigger than all three, and it will stay in the window longer than any of them. None of them can be the biggest again. They can be thrown away.

```diagram
array nums [1, 3, -1, -3, 5, 3, 6, 7]
pointer i 4
shade 2..4
queue kept [5]
highlight 0
```

So keep a queue of candidates, biggest at the front, falling toward the back. A new number pops every smaller candidate off the back, then joins. The front leaves only when the window slides past it.

---

The queue needs both ends, so it is a `deque`. It holds indexes, so you can tell when the front has slid out.

```python
from collections import deque

nums = [1, 3, -1, -3, 5, 3, 6, 7]
k = 3
dq = deque()
out = []
for i, x in enumerate(nums):
    while dq and nums[dq[-1]] <= x:
        dq.pop()
    dq.append(i)
    if dq[0] <= i - k:
        dq.popleft()
    if i >= k - 1:
        out.append(nums[dq[0]])
print(out)
```

---

Run this to watch candidates join at the back and leave from both ends.

```python
import viz
from collections import deque

nums = [1, 3, -1, -3, 5, 3, 6, 7]
k = 3
dq = deque()
for i, x in enumerate(nums):
    while dq and nums[dq[-1]] <= x:
        dq.pop()
    dq.append(i)
    if dq[0] <= i - k:
        dq.popleft()
    if i >= k - 1:
        viz.note(f"max is {nums[dq[0]]}")
    lo = max(0, i - k + 1)
    with viz.frame():
        viz.array(nums, pointers={"i": i}, range=(lo, i))
        viz.queue([nums[j] for j in dq], highlight=0)
```

---

```python trace stop=38
from collections import deque

nums = [1, 3, -1, -3, 5, 3, 6, 7]
k = 3
dq = deque()
out = []
for i, x in enumerate(nums):
    while dq and nums[dq[-1]] <= x:
        dq.pop()
    dq.append(i)
    if dq[0] <= i - k:
        dq.popleft()
    if i >= k - 1:
        out.append(nums[dq[0]])
print(out)
```

`x` is 5 and the `while` has just finished. How many indexes are in `dq`?

- [x] 0
- [ ] 1
- [ ] 3

---

The window is 2 wide and the list has a repeat. What does this print?

```python predict
from collections import deque

nums = [4, 4, 2, 5, 1]
k = 2
dq = deque()
out = []
for i, x in enumerate(nums):
    while dq and nums[dq[-1]] <= x:
        dq.pop()
    dq.append(i)
    if dq[0] <= i - k:
        dq.popleft()
    if i >= k - 1:
        out.append(nums[dq[0]])
print(out)
```

---

On n numbers with a window of k, the deque version takes

- [ ] O(n·k) time, because the `while` can pop up to k items
- [x] O(n) time, because each index joins once and leaves once
- [ ] O(n log k) time, like keeping the window sorted

---

Put the lines in order so `window_max` returns the biggest number in each window of `k`.

```python arrange
from collections import deque

def window_max(nums, k):
    dq = deque()
    out = []
    for i, x in enumerate(nums):
        while dq and nums[dq[-1]] <= x:
            dq.pop()
        dq.append(i)
        if dq[0] <= i - k:
            dq.popleft()
        if i >= k - 1:
            out.append(nums[dq[0]])
    return out
```

```tests
window_max([1, 3, -1, -3, 5, 3, 6, 7], 3) == [3, 3, 5, 5, 6, 7]
window_max([4, 4, 2, 5, 1], 2) == [4, 4, 5, 5]
window_max([9, 8, 7], 1) == [9, 8, 7]
window_max([2, 5, 1], 3) == [5]
```

---

Why does the deque hold indexes rather than the numbers themselves?

- [ ] Indexes are smaller, so the deque uses less memory
- [x] The front has to leave when the window slides past it, and only its index says when
- [ ] Numbers can repeat, so they can't be stored in a deque

---

[First negative in each window](exercises/first-negative.md)

[Window spread](exercises/window-spread.md)

[Longest steady run](exercises/longest-steady-run.md)
