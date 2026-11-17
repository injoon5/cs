---
id: increasing-subsequences
title: Longest increasing subsequence
---

An increasing subsequence keeps some numbers in their order, each bigger than the one before. How long is the longest one here?

```diagram
array nums [10, 9, 2, 5, 3, 7, 101, 18]
highlight 2 4 5 7
```

The answer is 4, and there is more than one: 2, 3, 7, 18 and 2, 5, 7, 101 both work.

---

"The longest increasing subsequence of `nums[:i]`" is a poor state: to extend it with the next number, you need to know where it ends, and the state doesn't say.

So put the end in the state. `ends[i]` is the length of the longest increasing subsequence that ends at `nums[i]`. It extends the best one ending at some earlier, smaller number:

`ends[i] = 1 + max(ends[j])` over `j < i` with `nums[j] < nums[i]`, or 1 when there is none.

The answer is the largest `ends[i]`.

---

```python trace stop=26
nums = [3, 1, 4, 1, 5]
ends = [1] * len(nums)
for i in range(len(nums)):
    for j in range(i):
        if nums[j] < nums[i]:
            ends[i] = max(ends[i], ends[j] + 1)
print(max(ends))
```

The outer loop is starting `i = 4`. What is `ends`?

- [x] `[1, 1, 2, 1, 1]`
- [ ] `[1, 1, 2, 2, 1]`
- [ ] `[1, 2, 3, 3, 1]`

---

For n numbers, this version takes

- [ ] O(n) time
- [ ] O(n log n) time
- [x] O(n²) time

---

A faster idea keeps one number per length. `tails[k]` is the smallest number that ends an increasing subsequence of length `k + 1` so far. A smaller end is better, because more numbers can follow it.

`tails` is always sorted, so each new number `x` finds its place with a binary search:

- If `x` is bigger than every tail, it extends the longest subsequence: append it.
- Otherwise it replaces the first tail that is `>= x`, at index `k`. The tail before it is smaller than `x`, so `x` can follow that subsequence, and length `k + 1` gets a smaller end.

The length of `tails` at the end is the answer.

---

Run this to watch `tails` change. Each frame is one number from `nums`.

```python
from bisect import bisect_left
import viz

nums = [10, 9, 2, 5, 3, 7, 101, 18]
tails = []
for i, x in enumerate(nums):
    k = bisect_left(tails, x)
    if k == len(tails):
        tails.append(x)
        note = f"{x} extends to length {k + 1}"
    else:
        note = f"{x} replaces {tails[k]}"
        tails[k] = x
    with viz.frame():
        viz.array(nums, name="nums", pointers={"x": i})
        viz.array(tails, name="tails", highlight=k,
                  note=note)
```

---

What does this print?

```python predict
from bisect import bisect_left

tails = []
for x in [3, 4, 5, 1, 2]:
    k = bisect_left(tails, x)
    if k == len(tails):
        tails.append(x)
    else:
        tails[k] = x
print(tails, len(tails))
```

---

`[1, 2, 5]` isn't an increasing subsequence of `[3, 4, 5, 1, 2]`: the 5 comes before the 1. What does `tails` tell you?

- [x] Only its length is right: some increasing subsequence has 3 numbers
- [ ] The longest increasing subsequence is 1, 2, 5
- [ ] The search went wrong: 1 and 2 should have been appended

---

The numbers must strictly increase. Why `bisect_left` and not `bisect_right`?

- [ ] `bisect_right` would put `x` past the end of `tails`
- [x] A number equal to a tail must replace it, not extend past it: 2, 2 isn't increasing
- [ ] `bisect_left` is faster on lists with repeats

---

Each of the n numbers costs one binary search on a list of at most n tails. The `tails` version takes

- [ ] O(n) time
- [x] O(n log n) time
- [ ] O(n²) time

---

[Longest increasing subsequence](exercises/lis-length.md)
