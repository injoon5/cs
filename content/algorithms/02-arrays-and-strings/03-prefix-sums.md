---
id: prefix-sums
title: Prefix sums
---

What is the total of `nums[1]` through `nums[3]`?

```diagram
array nums [3, -1, 4, 1, 5]
shade 1..3
array prefix [0, 3, 2, 6, 7, 12]
pointer l 1
pointer r+1 4
```

Adding `-1 + 4 + 1` gives 4. But if you get a thousand of these questions, adding each range again is slow.

The second row keeps running totals. `prefix[4]` is the sum of the first 4 numbers, 7. `prefix[1]` is the sum of the first 1, which is 3. Their difference is exactly the shaded part: `7 - 3 = 4`.

---

`prefix[i]` is the sum of the first `i` numbers, so `prefix[0]` is 0 and the list is one longer than `nums`. Then for any range:

`sum(nums[l..r]) = prefix[r + 1] - prefix[l]`

Build it once, then answer each question with one subtraction.

```python
nums = [3, -1, 4, 1, 5]
prefix = [0]
for x in nums:
    prefix.append(prefix[-1] + x)
print(prefix)
print(prefix[4] - prefix[1])
```

---

```python predict
nums = [2, 2, 2, 2]
prefix = [0]
for x in nums:
    prefix.append(prefix[-1] + x)
print(len(prefix), prefix[-1])
print(prefix[3] - prefix[1])
```

---

```python trace stop=9
nums = [3, -1, 4, 1, 5]
prefix = [0]
for x in nums:
    prefix.append(prefix[-1] + x)
print(prefix)
```

Three numbers have been added. What is `prefix` now?

- [ ] `[3, 2, 6]`
- [x] `[0, 3, 2, 6]`
- [ ] `[0, 3, 7, 8]`

---

Run this to watch the running totals build up, then answer one range question.

```python
import viz

nums = [3, -1, 4, 1, 5]
prefix = [0]
for i, x in enumerate(nums):
    prefix.append(prefix[-1] + x)
    with viz.frame():
        viz.array(nums, name="nums", range=(0, i))
        viz.array(prefix, name="prefix", highlight=i + 1, note=f"prefix[{i + 1}] = {prefix[i]} + {x}")

l, r = 1, 3
with viz.frame():
    viz.array(nums, name="nums", range=(l, r))
    viz.array(prefix, name="prefix", pointers={"l": l, "r+1": r + 1}, note=f"{prefix[r + 1]} - {prefix[l]} = {prefix[r + 1] - prefix[l]}")
```

---

Which gives the sum of `nums[2]` through `nums[4]`?

- [ ] `prefix[4] - prefix[2]`
- [x] `prefix[5] - prefix[2]`
- [ ] `prefix[5] - prefix[1]`

---

Put the lines in order so `range_sums` answers every `(l, r)` query, both ends included.

```python arrange
def range_sums(nums, queries):
    prefix = [0]
    for x in nums:
        prefix.append(prefix[-1] + x)
    answers = []
    for l, r in queries:
        answers.append(prefix[r + 1] - prefix[l])
    return answers
```

```tests
range_sums([3, -1, 4, 1, 5], [(1, 3), (0, 4), (2, 2)]) == [4, 12, 4]
range_sums([5], [(0, 0)]) == [5]
range_sums([1, 2, 3], []) == []
range_sums([-2, -2, -2], [(0, 1), (0, 2)]) == [-4, -6]
```

---

With n numbers and q range questions, building the prefix list and answering every question takes

- [ ] O(n·q) time
- [x] O(n + q) time
- [ ] O(q) time

---

[Balance point](exercises/balance-point.md)
