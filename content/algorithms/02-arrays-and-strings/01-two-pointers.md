---
id: two-pointers
title: Two pointers
---

Find two numbers in this sorted list that add up to 10.

```diagram
array nums [1, 3, 4, 6, 8, 11]
pointer lo 0
pointer hi 5
```

Checking every pair works, but six numbers already make 15 pairs, and n numbers make about n²/2. Start at both ends instead: `lo` on the smallest number, `hi` on the largest.

---

The sum `1 + 11` is 12, too big. Every other partner for 11 is at least 1, so 11 can't be part of any answer. Drop it: move `hi` left.

Now `1 + 8` is 9, too small. Every other partner for 1 is at most 8, so 1 is out too. Move `lo` right.

```diagram
array nums [1, 3, 4, 6, 8, 11]
pointer lo 1
pointer hi 4
shade 1..4
```

Each comparison rules out one number for good. Only the shaded part is still in play.

The rule: too big, move `hi` left. Too small, move `lo` right. Stop when the sum matches or the pointers meet.

---

```python trace stop=9
nums = [1, 3, 4, 6, 8, 11]
target = 10
lo, hi = 0, len(nums) - 1
while lo < hi:
    s = nums[lo] + nums[hi]
    if s == target:
        break
    if s < target:
        lo += 1
    else:
        hi -= 1
print(lo, hi)
```

The loop has run once. Where are the pointers?

- [ ] `lo` is 1, `hi` is 5
- [x] `lo` is 0, `hi` is 4
- [ ] `lo` is 1, `hi` is 4

---

Run this to watch the search. The shaded cells are the ones still in play.

```python
import viz

nums = [1, 3, 4, 6, 8, 11]
target = 10
lo, hi = 0, len(nums) - 1
while lo < hi:
    s = nums[lo] + nums[hi]
    if s == target:
        viz.array(nums, pointers={"lo": lo, "hi": hi}, highlight=[lo, hi], note=f"{nums[lo]} + {nums[hi]} = {s}, found")
        break
    viz.array(nums, pointers={"lo": lo, "hi": hi}, range=(lo, hi), note=f"{nums[lo]} + {nums[hi]} = {s}")
    if s < target:
        lo += 1
    else:
        hi -= 1
```

---

The same two pointers can walk a string from both ends. Which pairs does this compare?

```python predict
s = "level"
i, j = 0, len(s) - 1
while i < j:
    print(s[i], s[j])
    i += 1
    j -= 1
```

---

Put the lines in order so `reverse` flips the list in place and returns it.

```python arrange
def reverse(a):
    i, j = 0, len(a) - 1
    while i < j:
        a[i], a[j] = a[j], a[i]
        i += 1
        j -= 1
    return a
```

```tests
reverse([1, 2, 3, 4]) == [4, 3, 2, 1]
reverse([1, 2, 3]) == [3, 2, 1]
reverse([7]) == [7]
reverse([]) == []
```

---

Each pass of the pair search moves `lo` or `hi` one step closer. On a sorted list of n numbers, the search takes

- [ ] O(n²) time, O(1) extra space
- [x] O(n) time, O(1) extra space
- [ ] O(n) time, O(n) extra space

---

Why does the pair search need the list to be sorted?

- [ ] So the pointers can start at both ends
- [x] So a sum that is too big means the right number is too big for every partner
- [ ] So the loop stops when `lo` meets `hi`

---

[Pair with a sum](exercises/pair-sum.md)
