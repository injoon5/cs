---
id: lower-upper-bound
title: First and last position
---

Where are the 2s in this list?

```diagram
array nums [1, 2, 2, 2, 3, 5]
pointer lower 1
pointer upper 4
shade 1..3
```

A search that stops on any match could land on index 1, 2 or 3. Two first-yes searches pin down the run instead:

- the lower bound is the first index with `nums[i] >= 2`, here 1
- the upper bound is the first index with `nums[i] > 2`, here 4

The 2s fill `lower` up to, but not including, `upper`. There are `upper - lower` of them, 3.

---

The two searches differ in one character.

```python
def lower_bound(nums, x):
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] >= x:
            hi = mid
        else:
            lo = mid + 1
    return lo

def upper_bound(nums, x):
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] > x:
            hi = mid
        else:
            lo = mid + 1
    return lo

nums = [1, 2, 2, 2, 3, 5]
print(lower_bound(nums, 2), upper_bound(nums, 2))
```

---

```python trace stop=7
nums = [1, 2, 2, 2, 3, 5]
x = 2
lo, hi = 0, len(nums)
while lo < hi:
    mid = (lo + hi) // 2
    if nums[mid] > x:
        hi = mid
    else:
        lo = mid + 1
print(lo)
```

This is the upper bound search. `nums[3]` is 2, which isn't bigger than 2, so the highlighted line runs next. What will `lo` be?

- [ ] 3
- [x] 4
- [ ] 5

---

When `x` is missing, both bounds land on the same index: where `x` would be inserted to keep the list sorted. Then `upper - lower` is 0.

```diagram
array nums [1, 2, 2, 2, 3, 5]
pointer lower 5
pointer upper 5
```

For 4, both bounds are 5, between the 3 and the 5.

---

Python ships both searches in the `bisect` module. `bisect_left` is the lower bound and `bisect_right` is the upper bound. What does this print?

```python predict
from bisect import bisect_left, bisect_right

nums = [1, 2, 2, 2, 3, 5]
print(bisect_left(nums, 2), bisect_right(nums, 2))
print(bisect_left(nums, 4), bisect_right(nums, 4))
print(bisect_left(nums, 0), bisect_right(nums, 9))
```

---

`insort` finds the spot with a binary search and inserts there, so the list stays sorted. Since Python 3.10 each function also takes `key=`, like `sorted`.

```python
from bisect import bisect_right, insort

scores = [55, 70, 70, 90]
insort(scores, 70)
print(scores)

cutoffs = [60, 70, 80, 90]
grades = "FDCBA"
for s in [55, 70, 89, 95]:
    print(s, grades[bisect_right(cutoffs, s)])
```

The grades use the upper bound: a 70 counts as reaching the 70 cutoff.

---

`nums` is sorted and holds `x`. Which index is the last `x`?

- [ ] `bisect_left(nums, x)`
- [ ] `bisect_left(nums, x) + 1`
- [x] `bisect_right(nums, x) - 1`

---

Counting how often `x` appears in a sorted list of n numbers with `bisect_right(nums, x) - bisect_left(nums, x)` takes

- [ ] O(n), because every copy of `x` is counted
- [x] O(log n), whatever the number of copies
- [ ] O(1), because the list is sorted

---

`insort` finds its spot in O(log n). On a list of n numbers, one `insort` takes

- [ ] O(log n), the same as the search
- [x] O(n), because the items after the spot shift right
- [ ] O(n log n), because the list is sorted again

---

[Count in a sorted list](exercises/count-in-sorted.md)

[First and last index](exercises/target-range.md)
