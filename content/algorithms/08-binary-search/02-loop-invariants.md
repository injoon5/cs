---
id: loop-invariants
title: Loop invariants
---

Where is the first number that is at least 6?

```diagram
array nums [2, 4, 5, 6, 6, 9]
shade 3..5
```

Ask "is it at least 6?" of every item and the answers are no, no, no, yes, yes, yes. Because the list is sorted, all the no answers come first. The answer is where no turns into yes, index 3.

Most binary searches are this question in disguise: find the first index where a yes-or-no test turns true.

---

Keep two pointers with a promise about each:

- everything left of `lo` is a no
- everything from `hi` on is a yes

```diagram
array nums [2, 4, 5, 6, 6, 9]
pointer lo 0
pointer hi 6
shade 0..5
```

At the start nothing is known, so `lo` is 0 and `hi` is `len(nums)`, one past the end. The shaded cells between them are unknown. A promise like this, true before and after every pass of a loop, is a loop invariant.

---

Each pass tests `mid` and moves one pointer so the promise still holds.

```python
def first_at_least(nums, x):
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] >= x:
            hi = mid      # mid is a yes
        else:
            lo = mid + 1  # mid is a no
    return lo

print(first_at_least([2, 4, 5, 6, 6, 9], 6))
print(first_at_least([2, 4, 5, 6, 6, 9], 10))
```

A yes at `mid` might be the first yes, so `hi` stops on it. A no at `mid` can't be the answer, so `lo` steps past it. When `lo == hi` nothing is unknown, and both point at the first yes. If there is no yes, that is `len(nums)`.

---

```python trace stop=16
nums = [2, 4, 5, 6, 6, 9]
x = 6
lo, hi = 0, len(nums)
while lo < hi:
    mid = (lo + hi) // 2
    if nums[mid] >= x:
        hi = mid
    else:
        lo = mid + 1
print(lo)
```

The loop is about to check `lo < hi` for the last time. What are `lo` and `hi`?

- [ ] `lo` is 3, `hi` is 4
- [x] `lo` is 3, `hi` is 3
- [ ] `lo` is 2, `hi` is 3

---

There are two common styles. Pick one and keep all four parts together.

- Closed range, as in the last lesson: `hi = len(nums) - 1`, loop `while lo <= hi`, move with `hi = mid - 1`.
- Half-open range, as here: `hi = len(nums)`, loop `while lo < hi`, move with `hi = mid`.

This unit uses half-open from here on. It answers "first index where" questions directly, and `lo` is always the answer when the loop ends.

---

This copy mixes the styles: half-open start, but `hi = mid - 1`. What does it print?

```python predict
nums = [1, 3, 5, 7]
lo, hi = 0, len(nums)
while lo < hi:
    mid = (lo + hi) // 2
    if nums[mid] >= 5:
        hi = mid - 1
    else:
        lo = mid + 1
print(lo)
```

The right answer is 2. `hi = mid - 1` threw away `mid`, which was the first yes.

---

The other trap is moving `lo` with `lo = mid`. Why does that break the half-open loop?

- [x] When `hi` is `lo + 1`, `mid` equals `lo`, so `lo` never moves and the loop runs forever
- [ ] `mid` is a yes, so `lo` would skip past the answer
- [ ] `lo` could go past `len(nums)` and raise an `IndexError`

---

Put the lines in order so `first_over` returns the index of the first item bigger than `limit` in a sorted list, or `len(nums)` if there is none.

```python arrange
def first_over(nums, limit):
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] > limit:
            hi = mid
        else:
            lo = mid + 1
    return lo
```

```tests
first_over([1, 3, 3, 5], 3) == 3
first_over([1, 3, 3, 5], 0) == 0
first_over([1, 3, 3, 5], 5) == 4
first_over([], 1) == 0
```

---

[First true](exercises/first-true.md)

[Peak of a mountain](exercises/mountain-peak.md)
