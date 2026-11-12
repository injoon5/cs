---
id: rotated-arrays
title: Rotated sorted lists
---

Take a sorted list and move its first four items to the end. It is no longer sorted, but it is two sorted runs.

```diagram
array nums [4, 5, 6, 7, 0, 1, 2]
pointer start 4
shade 4..6
```

Where does the smallest item sit? A linear scan finds it in O(n). Binary search needs a yes-or-no test that flips once.

---

Compare each item with the last one, 2. "Is `nums[i] <= 2`?" says no for 4, 5, 6 and 7, and yes for 0, 1 and 2. Every item in the left run is bigger than every item in the right run, so the answers flip exactly once.

The smallest item is the first yes.

```python
def rotation_start(nums):
    last = nums[-1]
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] <= last:
            hi = mid
        else:
            lo = mid + 1
    return lo

print(rotation_start([4, 5, 6, 7, 0, 1, 2]))
print(rotation_start([0, 1, 2, 4, 5, 6, 7]))
```

A list that was never rotated is all yes, so the start is 0.

---

```python trace stop=8
nums = [4, 5, 6, 7, 0, 1, 2]
last = nums[-1]
lo, hi = 0, len(nums)
while lo < hi:
    mid = (lo + hi) // 2
    if nums[mid] <= last:
        hi = mid
    else:
        lo = mid + 1
print(lo)
```

The first look was at `nums[3]`, which is 7. Where are the pointers now?

- [ ] `lo` is 0, `hi` is 3
- [x] `lo` is 4, `hi` is 7
- [ ] `lo` is 3, `hi` is 7

---

Why compare with the last item and not the first?

- [ ] The last item is always the largest
- [x] In a list that was never rotated, "smaller than the first item" is never true, so the search would return `len(nums)`
- [ ] Comparing with the first item takes O(n)

---

Once you know where the small run starts, finding a target is an ordinary search in one run. If the target is at most the last item, it can only be in the right run. Otherwise it can only be in the left one. `bisect_left` takes `lo` and `hi` to search part of a list.

```python
from bisect import bisect_left

nums = [4, 5, 6, 7, 0, 1, 2]
start = 4
for target in [1, 6, 3]:
    if target <= nums[-1]:
        lo, hi = start, len(nums)
    else:
        lo, hi = 0, start
    i = bisect_left(nums, target, lo, hi)
    found = i < hi and nums[i] == target
    print(target, i if found else -1)
```

---

What does this print?

```python predict
from bisect import bisect_left

nums = [30, 40, 50, 10, 20]
start = 3
for target in [20, 40, 35]:
    if target <= nums[-1]:
        lo, hi = start, len(nums)
    else:
        lo, hi = 0, start
    print(target, bisect_left(nums, target, lo, hi))
```

---

With repeats the trick can fail. In `[1, 1, 1, 0, 1]` the test "is `nums[i] <= 1`?" says

- [ ] no, no, no, yes, yes, so the search finds index 3
- [x] yes for every item, so the search returns 0 and misses the 0
- [ ] no for every item, so the search returns `len(nums)`

---

Finding the start and then searching one run takes

- [ ] O(n), because the list isn't sorted
- [x] O(log n), two binary searches in a row
- [ ] O(log² n), a search inside a search

---

[Smallest in a rotated list](exercises/rotation-min.md)

[Search a rotated list](exercises/rotated-find.md)
