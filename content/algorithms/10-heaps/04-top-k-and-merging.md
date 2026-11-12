---
id: top-k-and-merging
title: Top k and merging
---

Find the 3 largest numbers in `[5, 1, 9, 3, 7, 6]` without sorting the whole list.

Keep a min-heap of the best 3 seen so far. Its root is the weakest of them, the one a new number has to beat. A bigger number replaces the root. A smaller one can't be in the top 3, so skip it.

```diagram
array nums [5, 1, 9, 3, 7, 6]
pointer x 3

tree
1 -> 5 9
highlight 1
```

Here 3 beats 1, so 3 takes the root's place and sifts down.

---

Run this to watch the heap. It never holds more than 3 items.

```python
import heapq
import viz

nums = [5, 1, 9, 3, 7, 6]
k = 3
heap = []
for i, x in enumerate(nums):
    if len(heap) < k:
        heapq.heappush(heap, x)
        note = f"push {x}"
    elif x > heap[0]:
        note = f"{x} beats {heap[0]}"
        heapq.heapreplace(heap, x)
    else:
        note = f"{x} can't beat {heap[0]}, skip"
    with viz.frame():
        viz.array(nums, name="nums", pointers={"x": i})
        viz.tree(heap, active=0, note=note)
```

`heapreplace` pops the root and pushes the new item in one sift down.

---

```python trace stop=18
import heapq

nums = [5, 1, 9, 3, 7, 6]
k = 3
heap = []
for x in nums:
    if len(heap) < k:
        heapq.heappush(heap, x)
    elif x > heap[0]:
        heapq.heapreplace(heap, x)
print(heap[0])
```

The loop has just handled `x = 3`. What is in `heap`?

- [ ] `[1, 5, 9]`
- [x] `[3, 5, 9]`
- [ ] `[5, 7, 9]`

---

Why keep a min-heap to find the largest numbers?

- [ ] `heapq` has no max-heap, so a min-heap is the only choice
- [x] The root is the smallest of the k kept, which is exactly the one a new number must beat
- [ ] A min-heap keeps the k numbers in sorted order

---

Each of the n numbers costs at most one O(log k) step on a heap of size k. Finding the k largest this way takes

- [ ] O(n log n) time, O(n) extra space
- [x] O(n log k) time, O(k) extra space
- [ ] O(k log n) time, O(k) extra space

`heapq.nlargest(k, nums)` and `heapq.nsmallest(k, nums)` do the same thing for you.

---

Put the lines in order so `k_smallest` returns the k smallest numbers, sorted. It keeps a max-heap of size k by negating.

```python arrange
import heapq


def k_smallest(nums, k):
    heap = []
    for x in nums:
        heapq.heappush(heap, -x)
        if len(heap) > k:
            heapq.heappop(heap)
    return sorted(-x for x in heap)
```

```tests
k_smallest([5, 1, 9, 3, 7, 6], 3) == [1, 3, 5]
k_smallest([4, 4, 2], 2) == [2, 4]
k_smallest([-1, -5, 0], 1) == [-5]
k_smallest([3], 1) == [3]
k_smallest([], 2) == []
```

---

The same root-is-next idea merges sorted lists. Keep one item from each list in a heap: the front of what's left. The smallest front is the next item overall.

```diagram
array a [1, 4, 7]
pointer front 1

array b [2, 5]
pointer front 1

array c [3, 6, 9]
pointer front 0
```

After taking 1 and 2, the heap holds 4, 5 and 3. Next out is 3, from `c`.

---

Each heap entry is `(value, list, position)`, so after a pop you know where the next item comes from. What does this print?

```python predict
import heapq

lists = [[1, 4], [2, 3], [0, 5]]
heap = [(l[0], i, 0) for i, l in enumerate(lists)]
heapq.heapify(heap)
while heap:
    val, i, j = heapq.heappop(heap)
    print(val, "from list", i)
    if j + 1 < len(lists[i]):
        nxt = lists[i][j + 1]
        heapq.heappush(heap, (nxt, i, j + 1))
```

---

Merging k sorted lists with N items in total, the heap never holds more than k entries. The merge takes

- [ ] O(N k)
- [ ] O(N log N)
- [x] O(N log k)

---

[K-th largest](exercises/kth-largest-item.md)

[Merge k sorted lists](exercises/merge-k-sorted.md)
