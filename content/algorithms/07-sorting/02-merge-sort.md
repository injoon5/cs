---
id: merge-sort
title: Merge sort
---

Two piles are each sorted. To combine them into one sorted pile, look only at the top of each and take the smaller.

```diagram
array left [1, 4, 7]
pointer i 1
highlight 0
array right [2, 3, 9]
pointer j 1
highlight 0
array out [1, 2]
```

`1` and `2` are taken. Now `4` meets `3`, so `3` goes next. Each step moves one item to `out`, so merging n items takes n steps.

---

When one side runs out, the rest of the other side is already sorted and goes on the end.

```python
def merge(left, right):
    out = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            out.append(left[i])
            i += 1
        else:
            out.append(right[j])
            j += 1
    out.extend(left[i:])
    out.extend(right[j:])
    return out

print(merge([1, 4, 7], [2, 3, 9]))
```

The `<=` takes from the left on a tie, so equal items keep their order. Merge sort is stable because of that one character.

---

```python trace stop=17
left = [1, 4, 7]
right = [2, 3, 9]
out = []
i = j = 0
while i < len(left) and j < len(right):
    if left[i] <= right[j]:
        out.append(left[i])
        i += 1
    else:
        out.append(right[j])
        j += 1
out.extend(left[i:])
out.extend(right[j:])
```

Three items have been taken. Where are the pointers?

- [ ] `i` is 2, `j` is 1
- [x] `i` is 1, `j` is 2
- [ ] `i` is 1, `j` is 1

---

Merging needs two sorted lists. Merge sort gets them by sorting each half the same way: split until every piece has one item, which is sorted already, then merge back up.

```diagram
tree
node all "5 2 4 1"
node l "5 2"
node r "4 1"
node a "5"
node b "2"
node c "4"
node d "1"
all -> l r
l -> a b
r -> c d
```

On the way back up, `5` and `2` merge to `2 5`, `4` and `1` merge to `1 4`, and those two merge to `1 2 4 5`.

```python
def merge_sort(a):
    if len(a) <= 1:
        return a
    mid = len(a) // 2
    left = merge_sort(a[:mid])
    right = merge_sort(a[mid:])
    return merge(left, right)
```

---

Run this to watch the merges. Each shaded range has just been merged into place. `heapq.merge` is the standard library's version of `merge`.

```python
import heapq
import viz

def sort(a, lo, hi):
    if hi - lo <= 1:
        return
    mid = (lo + hi) // 2
    sort(a, lo, mid)
    sort(a, mid, hi)
    a[lo:hi] = heapq.merge(a[lo:mid], a[mid:hi])
    viz.array(a, range=(lo, hi - 1), note=f"merge {lo}..{mid - 1} with {mid}..{hi - 1}")

a = [5, 2, 4, 1, 6, 3]
viz.array(a, note="start")
sort(a, 0, len(a))
```

---

Each call halves the list. How many levels of halving does it take to get down to one item?

```python predict
def levels(n):
    if n <= 1:
        return 0
    return 1 + levels(n - n // 2)

print(levels(8))
print(levels(1000))
```

---

On each level, the merges together touch every item once, so a level costs O(n). There are about log₂ n levels. That gives O(n log n), on every input: sorted, backwards or random.

The merged output goes into a new list, so merge sort also needs O(n) extra space. That is its main cost compared to sorting in place.

---

Merge sort on a list that is already sorted takes

- [ ] O(n) time, because every merge takes from the left only
- [x] O(n log n) time, because it still splits and merges every level
- [ ] O(n²) time

---

Put the lines in order so `merge` combines two sorted lists.

```python arrange
def merge(left, right):
    out = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            out.append(left[i])
            i += 1
        else:
            out.append(right[j])
            j += 1
    out.extend(left[i:])
    out.extend(right[j:])
    return out
```

```tests
merge([1, 4, 7], [2, 3, 9]) == [1, 2, 3, 4, 7, 9]
merge([1, 1], [1]) == [1, 1, 1]
merge([], [5]) == [5]
merge([-3, 0], []) == [-3, 0]
merge([], []) == []
```

---

[Merge two sorted lists](exercises/merge-sorted-lists.md)

[Count inversions](exercises/count-inversions.md)
