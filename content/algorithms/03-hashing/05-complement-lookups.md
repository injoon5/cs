---
id: complement-lookups
title: Looking up the complement
---

Find two numbers that add up to 9 in this list. It isn't sorted, so the two pointers from the arrays unit don't work, and sorting it would lose the original positions.

```diagram
array nums [3, 8, 2, 7]
pointer i 3
shade 0..2
```

Walk left to right. When you reach 7, the partner it needs is `9 - 7 = 2`, its complement. If every number so far sits in a dict from value to index, "have I seen 2?" is one lookup. Here 2 is at index 2, so the answer is `(2, 3)`.

---

```python trace stop=11
nums = [3, 8, 2, 7]
target = 9
seen = {}
for i, x in enumerate(nums):
    if target - x in seen:
        print(seen[target - x], i)
        break
    seen[x] = i
```

The loop is about to check the complement of 2. What is `seen`?

- [ ] `{}`
- [x] `{3: 0, 8: 1}`
- [ ] `{3: 0, 8: 1, 2: 2}`

---

Run this to watch the dict fill up until a complement is found.

```python
import viz

nums = [3, 8, 2, 7]
target = 9
seen = {}
for i, x in enumerate(nums):
    need = target - x
    with viz.frame():
        viz.array(nums, name="nums",
                  pointers={"i": i},
                  range=(0, i - 1),
                  note=f"{x} needs {need}")
        if seen:
            viz.grid([list(seen.values())],
                     name="seen",
                     col_labels=list(seen))
    if need in seen:
        break
    seen[x] = i
```

---

The code checks for the complement before it stores `x`. Here the order is swapped, with target 6. What does it print?

```python predict
nums = [3, 4]
target = 6
seen = {}
for i, x in enumerate(nums):
    seen[x] = i
    if target - x in seen:
        print("pair", seen[target - x], i)
```

---

The same idea counts runs that add up to k, even with negative numbers, where the sliding window fails.

From the prefix sums lesson, the run from `l` to `r` adds up to `prefix[r + 1] - prefix[l]`. Walking left to right with a running total, a run ending here adds up to k exactly when an earlier total equals `running - k`. That's a complement lookup, on totals instead of numbers.

```diagram
array nums [1, 2, 3]
array prefix [0, 1, 3, 6]
pointer l 2
pointer r+1 3
```

With k = 3, the total 6 looks for 3, which appeared once, so `[3]` is one run. Keep a count of each total seen, starting with `{0: 1}` for the empty start.

---

```python trace stop=13
nums = [1, 2, 3]
k = 3
seen = {0: 1}
running = 0
count = 0
for x in nums:
    running += x
    count += seen.get(running - k, 0)
    seen[running] = seen.get(running, 0) + 1
print(count)
```

`running` is 3, and `count` was just updated. What is `count`?

- [ ] 0
- [x] 1
- [ ] 2

---

Put the lines in order so `two_sum` returns the indices of two numbers that add up to `target`, or `None`.

```python arrange
def two_sum(nums, target):
    seen = {}
    for i, x in enumerate(nums):
        if target - x in seen:
            return (seen[target - x], i)
        seen[x] = i
    return None
```

```tests
two_sum([3, 8, 2, 7], 9) == (2, 3)
two_sum([3, 3], 6) == (0, 1)
two_sum([3, 4], 6) == None
two_sum([], 1) == None
```

---

Checking every pair of n numbers takes O(n²). The dict version takes

- [x] O(n) time on average and O(n) extra space
- [ ] O(n) time and O(1) extra space
- [ ] O(n log n) time and O(n) extra space

---

[Two sum, unsorted](exercises/two-sum-lookup.md)

[Longest run with a sum](exercises/longest-sum-run.md)
