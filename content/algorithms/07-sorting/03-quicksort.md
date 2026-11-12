---
id: quicksort
title: Quicksort
---

Merge sort does its work on the way back up, when it merges. Quicksort does it on the way down. Pick one item, the pivot. Move everything smaller to its left and everything else to its right.

```diagram
array before [3, 7, 1, 8, 2, 5]
highlight 5
array after [3, 1, 2, 5, 7, 8]
highlight 3
shade 0..2
```

The pivot 5 is now exactly where it will end up. The left side and the right side never need to mix again, so sort each one the same way and nothing is left to merge.

---

This step is called partitioning. One way, Lomuto's, uses the last item as the pivot and walks `j` from left to right. `i` marks where the next small item goes.

```diagram
array a [3, 1, 7, 8, 2, 5]
pointer i 2
pointer j 4
shade 0..1
highlight 5
```

Everything before `i` is smaller than the pivot. Everything from `i` up to just before `j` is not. When `a[j]` is smaller, swap it to `i` and move `i` on. At the end, swap the pivot into `i`.

```python
def partition(a, lo, hi):
    pivot = a[hi]
    i = lo
    for j in range(lo, hi):
        if a[j] < pivot:
            a[i], a[j] = a[j], a[i]
            i += 1
    a[i], a[hi] = a[hi], a[i]
    return i
```

---

```python trace stop=18
a = [3, 7, 1, 8, 2, 5]
lo, hi = 0, 5
pivot = a[hi]
i = lo
for j in range(lo, hi):
    if a[j] < pivot:
        a[i], a[j] = a[j], a[i]
        i += 1
a[i], a[hi] = a[hi], a[i]
print(a, i)
```

`j` has just reached 4. What are `a` and `i`?

- [ ] `[3, 7, 1, 8, 2, 5]`, `i` is 2
- [x] `[3, 1, 7, 8, 2, 5]`, `i` is 2
- [ ] `[3, 1, 2, 8, 7, 5]`, `i` is 3

---

Quicksort partitions, then sorts the two sides. The pivot is already in place, so it is left out of both.

```python
def quicksort(a, lo, hi):
    if lo >= hi:
        return
    p = partition(a, lo, hi)
    quicksort(a, lo, p - 1)
    quicksort(a, p + 1, hi)
```

It sorts in place: no new lists, only swaps.

---

Run this to watch the swaps. The shaded range is the part being partitioned, and the highlight is its pivot.

```python
import viz

def quicksort(a, lo, hi):
    if lo >= hi:
        return
    pivot = a[hi]
    i = lo
    for j in range(lo, hi):
        if a[j] < pivot:
            a[i], a[j] = a[j], a[i]
            viz.array(a, pointers={"i": i, "j": j}, range=(lo, hi), highlight=hi, note=f"{a[i]} < {pivot}")
            i += 1
    a[i], a[hi] = a[hi], a[i]
    viz.array(a, range=(lo, hi), highlight=i, note=f"{pivot} is in place")
    quicksort(a, lo, i - 1)
    quicksort(a, i + 1, hi)

a = [3, 7, 1, 8, 2, 5]
viz.array(a, note="start")
quicksort(a, 0, len(a) - 1)
```

---

The list is already sorted. Where does the pivot land?

```python predict
def partition(a, lo, hi):
    pivot = a[hi]
    i = lo
    for j in range(lo, hi):
        if a[j] < pivot:
            a[i], a[j] = a[j], a[i]
            i += 1
    a[i], a[hi] = a[hi], a[i]
    return i

a = [1, 2, 3, 4, 5]
p = partition(a, 0, 4)
print(p, a[:p], a[p + 1:])
```

---

A good pivot splits the range near the middle. Then there are about log₂ n levels, each level of partitions touches n items in total, and quicksort takes O(n log n).

On a sorted list, the last item is the biggest. Every split leaves n - 1 items on one side and none on the other, so there are n levels and about n²/2 comparisons. That is O(n²), on the input people sort most often.

The fix is to pick the pivot at random: swap a random item into `hi` before partitioning. No input is bad every time, and the expected time is O(n log n) on every input.

```python
import random

def random_partition(a, lo, hi):
    r = random.randint(lo, hi)
    a[r], a[hi] = a[hi], a[r]
    return partition(a, lo, hi)
```

---

With a random pivot, quicksort on a sorted list of n items takes

- [ ] O(n²) time, because the list is sorted
- [x] O(n log n) expected time
- [ ] O(n) time

---

A list where every item is equal, like `[4, 4, 4, 4]`, is also slow for Lomuto, even with random pivots. Why?

- [x] Nothing is smaller than the pivot, so every split leaves all the other items on one side
- [ ] The swaps cancel out, so the list never changes
- [ ] Random pivots can't be picked when the items are equal

Splitting into three parts, smaller, equal and bigger, fixes it. That is the idea behind sort colors below.

---

Quicksort is not stable. Why?

- [ ] It compares with `<` instead of `<=`
- [x] A swap can jump an item over others, including ones equal to it
- [ ] It sorts the right side before the left

---

[Partition by pivot](exercises/partition-by-pivot.md)

[Sort colors](exercises/sort-colors.md)

[Kth smallest](exercises/quickselect-kth.md)
