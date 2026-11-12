---
id: halving
title: Halving the range
---

Is 11 in this sorted list?

```diagram
array nums [1, 3, 5, 7, 9, 11, 13, 15]
pointer lo 0
pointer mid 3
pointer hi 7
```

Checking from the left takes up to 8 looks. Look at the middle instead. `nums[3]` is 7, which is smaller than 11. The list is sorted, so 7 and everything to its left are smaller too. None of them can be 11.

---

One comparison ruled out half the list. Move `lo` past the middle and look at the middle of what is left.

```diagram
array nums [1, 3, 5, 7, 9, 11, 13, 15]
pointer lo 4
pointer mid 5
pointer hi 7
shade 4..7
```

`nums[5]` is 11. Found, after two looks instead of six.

The rule: too small, move `lo` to `mid + 1`. Too big, move `hi` to `mid - 1`. If `lo` passes `hi`, nothing is left and the target isn't there.

---

```python
def find(nums, target):
    lo, hi = 0, len(nums) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if nums[mid] == target:
            return mid
        if nums[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1

nums = [1, 3, 5, 7, 9, 11, 13, 15]
print(find(nums, 11))
print(find(nums, 4))
```

`lo` and `hi` are both inside the range still in play, so the loop runs while `lo <= hi`. A range with one item still needs a look.

---

```python trace stop=9
nums = [1, 3, 5, 7, 9, 11, 13, 15]
target = 11
lo, hi = 0, len(nums) - 1
while lo <= hi:
    mid = (lo + hi) // 2
    if nums[mid] == target:
        break
    if nums[mid] < target:
        lo = mid + 1
    else:
        hi = mid - 1
print(mid)
```

The first look found 7, which is too small. Where are the pointers now?

- [x] `lo` is 4, `hi` is 7
- [ ] `lo` is 3, `hi` is 7
- [ ] `lo` is 0, `hi` is 3

---

Run this to watch a search for 10, which isn't in the list. The shaded cells are still in play.

```python
import viz

nums = [1, 3, 5, 7, 9, 11, 13, 15]
target = 10
lo, hi = 0, len(nums) - 1
while lo <= hi:
    mid = (lo + hi) // 2
    p = {"lo": lo, "mid": mid, "hi": hi}
    if nums[mid] < target:
        msg = f"{nums[mid]} < {target}, go right"
        viz.array(nums, pointers=p, range=(lo, hi), note=msg)
        lo = mid + 1
    else:
        msg = f"{nums[mid]} > {target}, go left"
        viz.array(nums, pointers=p, range=(lo, hi), note=msg)
        hi = mid - 1
viz.array(nums, pointers={"lo": lo, "hi": hi}, note="lo passed hi, not found")
```

---

A search for 10, which is missing. What does this print?

```python predict
nums = [1, 3, 5, 7, 9, 11, 13]
target = 10
lo, hi = 0, len(nums) - 1
while lo <= hi:
    mid = (lo + hi) // 2
    print(mid)
    if nums[mid] < target:
        lo = mid + 1
    else:
        hi = mid - 1
print(lo, hi)
```

When the search fails, `lo` stops at the index where 10 would go. That comes back in the next lessons.

---

Each look halves the range. A sorted list of a million numbers needs at most about

- [ ] 1,000 looks
- [ ] 500,000 looks
- [x] 20 looks

---

On a sorted list of n numbers, binary search takes

- [ ] O(n) time, O(1) extra space
- [x] O(log n) time, O(1) extra space
- [ ] O(log n) time, O(n) extra space

---

What goes wrong if the list isn't sorted?

- [ ] The loop never ends
- [x] It can say the target is missing when it is there
- [ ] It still works, just slower

---

[Find in a sorted list](exercises/sorted-find.md)

[Closest value](exercises/closest-value.md)
