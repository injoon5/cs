---
id: sliding-window
title: Sliding window
---

These are step counts in thousands, one per day. Which 3 days in a row have the biggest total?

```diagram
array steps [2, 1, 5, 1, 3, 2]
pointer left 0
pointer right 2
shade 0..2
```

The first window, days 0 to 2, adds up to 8. Adding up every window from scratch costs 3 additions each. With n days and windows of k, that is about n·k work.

---

Move the window one day to the right. Day 0 leaves and day 3 joins. The total goes from 8 to `8 - 2 + 1`, which is 7. One subtraction and one addition, however wide the window is.

```diagram
array steps [2, 1, 5, 1, 3, 2]
pointer left 1
pointer right 3
shade 1..3
```

```python
steps = [2, 1, 5, 1, 3, 2]
k = 3
window = sum(steps[:k])
best = window
for right in range(k, len(steps)):
    window += steps[right] - steps[right - k]
    best = max(best, window)
print(best)
```

---

```python trace stop=10
steps = [2, 1, 5, 1, 3, 2]
k = 3
window = sum(steps[:k])
best = window
for right in range(k, len(steps)):
    window += steps[right] - steps[right - k]
    best = max(best, window)
print(best)
```

The window has slid twice. What is `window` now?

- [ ] 7
- [x] 9
- [ ] 11

---

A window of 2 over numbers that include a negative. What does this print?

```python predict
nums = [4, -1, 2, 1]
k = 2
window = nums[0] + nums[1]
sums = [window]
for right in range(k, len(nums)):
    window += nums[right] - nums[right - k]
    sums.append(window)
print(sums)
```

---

Some windows change size. Find the longest run of days whose total is at most 8.

```diagram
array steps [3, 1, 2, 7, 4, 2, 1, 1, 5]
pointer left 4
pointer right 7
shade 4..7
```

Move `right` forward one day at a time and add that day. When the total goes over 8, drop days from the left until it fits again. After each step the window is the longest one that fits and ends at `right`. Here the best is 4 days, `4 + 2 + 1 + 1`.

---

Run this to watch the window grow on the right and shrink on the left.

```python
import viz

steps = [3, 1, 2, 7, 4, 2, 1, 1, 5]
budget = 8
left = 0
total = 0
best = 0
for right in range(len(steps)):
    total += steps[right]
    while total > budget:
        viz.array(steps, pointers={"left": left, "right": right}, range=(left, right), note=f"total {total} is over {budget}, drop {steps[left]}")
        total -= steps[left]
        left += 1
    best = max(best, right - left + 1)
    viz.array(steps, pointers={"left": left, "right": right}, range=(left, right), note=f"total {total}, best {best}")
print(best)
```

---

Put the lines in order so `window_sums` returns the total of every window of `k` items.

```python arrange
def window_sums(nums, k):
    window = sum(nums[:k])
    sums = [window]
    for right in range(k, len(nums)):
        window += nums[right] - nums[right - k]
        sums.append(window)
    return sums
```

```tests
window_sums([2, 1, 5, 1, 3, 2], 3) == [8, 7, 9, 6]
window_sums([4, -1, 2, 1], 2) == [3, 1, 3]
window_sums([5, 5, 5], 3) == [15]
window_sums([7], 1) == [7]
```

---

In the longest-run code, the inner `while` can run many times for one `right`. Over the whole loop, the code takes

- [ ] O(n²) time, because of the loop inside a loop
- [x] O(n) time, because each day joins once and leaves at most once
- [ ] O(n·k) time, where k is the longest window

---

[Shortest window with a sum](exercises/shortest-window.md)
