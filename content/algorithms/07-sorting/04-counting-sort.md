---
id: counting-sort
title: Counting sort and the n log n limit
---

One more comparison sort first. Heap sort puts the items in a heap, a tree where every parent is at least as big as its children, so the biggest item sits at the root.

```diagram
tree
9 -> 7 8
7 -> 2 5
8 -> 4
```

Take the root, put it at the end, and repair the heap in O(log n). Do that n times for O(n log n), in place, with no bad inputs. It is not stable, and in practice it is slower than quicksort. Heaps get their own unit later, with the details.

---

Merge sort, heap sort and quicksort all stop at n log n. That is not a coincidence. A sort that only compares items learns one yes or no answer per comparison.

Take three items `a`, `b` and `c`. They can be in 6 orders, and each comparison splits the orders still possible in two.

```diagram
tree
node q1 "a < b?"
node q2 "b < c?"
node q3 "a < c?"
node q4 "a < c?"
node q5 "b < c?"
node l1 "a b c"
node l2 "a c b"
node l3 "c a b"
node l4 "b a c"
node l5 "b c a"
node l6 "c b a"
q1 -> q2 q4
q2 -> l1 q3
q3 -> l2 l3
q4 -> l4 q5
q5 -> l5 l6
```

Left is yes, right is no. Two comparisons can tell apart at most 4 orders, so some orders need 3.

---

With n items there are n! orders, and k comparisons tell apart at most 2ᵏ of them. So a comparison sort needs at least log₂(n!) comparisons in the worst case. What does this print?

```python predict
import math

for n in [3, 10]:
    orders = math.factorial(n)
    print(n, orders, math.ceil(math.log2(orders)))
```

log₂(n!) grows like n log n, so no comparison sort can do better than O(n log n) in the worst case.

---

The limit is only for sorts that compare. If the items are small whole numbers, say from 0 to k, count how many times each one appears and write them out in order. No item is ever compared with another.

```diagram
array nums [3, 1, 3, 0, 2]
array counts [1, 1, 1, 2]
```

`counts[3]` is 2 because 3 appears twice.

```python
nums = [3, 1, 3, 0, 2]
k = 3
counts = [0] * (k + 1)
for x in nums:
    counts[x] += 1
out = []
for v in range(k + 1):
    out.extend([v] * counts[v])
print(out)
```

---

```python trace stop=10
nums = [3, 1, 3, 0, 2]
k = 3
counts = [0] * (k + 1)
for x in nums:
    counts[x] += 1
out = []
for v in range(k + 1):
    out.extend([v] * counts[v])
print(out)
```

Three numbers have been counted. What is `counts`?

- [ ] `[1, 1, 1, 0]`
- [x] `[0, 1, 0, 2]`
- [ ] `[0, 1, 0, 1]`

---

Counting sort on n numbers, each from 0 to k, takes

- [ ] O(n log n) time
- [x] O(n + k) time and O(k) extra space
- [ ] O(n · k) time

---

When is counting sort a bad choice?

- [ ] When the list has many duplicates
- [x] When the values range up to a billion, even if there are only ten of them
- [ ] When the list is already sorted

---

Bucket sort stretches the same idea to values that are spread out. Split the range into n buckets, say 0–9, 10–19 and so on, drop each item into its bucket, sort each small bucket, and join them. If the values are spread evenly, each bucket holds a few items and the whole sort is close to O(n). If they all land in one bucket, it is no faster than the sort used inside.

---

Put the lines in order so `counting_sort` sorts numbers from 0 to `k`.

```python arrange
def counting_sort(nums, k):
    counts = [0] * (k + 1)
    for x in nums:
        counts[x] += 1
    out = []
    for v in range(k + 1):
        out.extend([v] * counts[v])
    return out
```

```tests
counting_sort([3, 1, 3, 0, 2], 3) == [0, 1, 2, 3, 3]
counting_sort([5, 5, 5], 5) == [5, 5, 5]
counting_sort([0], 0) == [0]
counting_sort([], 4) == []
```

---

[Sort exam scores](exercises/sort-scores.md)
