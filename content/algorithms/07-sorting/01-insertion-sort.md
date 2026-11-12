---
id: insertion-sort
title: Insertion sort
---

Sort a hand of cards the way most people do: keep the cards on the left in order, and slide each new card left until it fits.

```diagram
array a [2, 5, 8, 4, 1]
shade 0..2
pointer i 3
```

The shaded part, `2, 5, 8`, is already sorted. The next card is 4. It is smaller than 8, so they swap. It is smaller than 5, so they swap again. It is not smaller than 2, so it stops.

```diagram
array a [2, 4, 5, 8, 1]
shade 0..3
pointer i 4
```

Now four cards are sorted, and 1 is next.

---

In code, `i` is the next item to insert and `j` walks it left, one swap at a time.

```python
def insertion_sort(a):
    for i in range(1, len(a)):
        j = i
        while j > 0 and a[j - 1] > a[j]:
            a[j - 1], a[j] = a[j], a[j - 1]
            j -= 1
    return a

print(insertion_sort([2, 5, 8, 4, 1]))
```

The loop starts at 1 because a list of one item is already sorted.

---

Run this to watch each item slide into the sorted part.

```python
import viz

a = [2, 5, 8, 4, 1]
viz.array(a, range=(0, 0), note="one item is sorted")
for i in range(1, len(a)):
    j = i
    while j > 0 and a[j - 1] > a[j]:
        a[j - 1], a[j] = a[j], a[j - 1]
        j -= 1
        viz.array(a, range=(0, i), highlight=j, note=f"swap {a[j]} left")
    viz.array(a, range=(0, i), note=f"{a[j]} is in place")
```

---

```python trace stop=19
a = [2, 5, 8, 4, 1]
for i in range(1, len(a)):
    j = i
    while j > 0 and a[j - 1] > a[j]:
        a[j - 1], a[j] = a[j], a[j - 1]
        j -= 1
print(a)
```

`i` has just become 4, so 1 is next. What is `a` now?

- [ ] `[2, 5, 8, 4, 1]`
- [x] `[2, 4, 5, 8, 1]`
- [ ] `[1, 2, 4, 5, 8]`

---

This version counts the swaps. One list is almost sorted and the other is backwards. What does it print?

```python predict
def swaps(a):
    count = 0
    for i in range(1, len(a)):
        j = i
        while j > 0 and a[j - 1] > a[j]:
            a[j - 1], a[j] = a[j], a[j - 1]
            j -= 1
            count += 1
    return count

print(swaps([1, 2, 3, 5, 4, 6]))
print(swaps([6, 5, 4, 3, 2, 1]))
```

---

Call a pair of items that is in the wrong order an inversion. `[1, 2, 3, 5, 4, 6]` has one: 5 before 4. A backwards list of 6 has every pair wrong, 15 of them.

Each swap puts one pair of neighbors right, so it removes exactly one inversion. The number of swaps is the number of inversions, and the work is O(n + inversions). A nearly sorted list has few, so insertion sort is fast there. A random list has about n²/4, so it is O(n²) on average.

It also never swaps equal items, because the test is `>`, not `>=`. Equal items keep their order. A sort with that property is called stable.

---

On a list that is already sorted, insertion sort takes

- [x] O(n) time, because the `while` test fails at once for every item
- [ ] O(n log n) time
- [ ] O(n²) time, because of the loop inside a loop

---

Every item in a list of n is at most k places away from where it belongs. Insertion sort takes

- [ ] O(n²) time
- [x] O(n·k) time
- [ ] O(n log n) time

---

Swapping writes two items per step. Shifting writes one: hold the new item in `x`, move bigger items one place right, and drop `x` into the gap. Put the lines in order.

```python arrange
def insertion_sort(a):
    for i in range(1, len(a)):
        x = a[i]
        j = i - 1
        while j >= 0 and a[j] > x:
            a[j + 1] = a[j]
            j -= 1
        a[j + 1] = x
    return a
```

```tests
insertion_sort([2, 5, 8, 4, 1]) == [1, 2, 4, 5, 8]
insertion_sort([3, 3, 1]) == [1, 3, 3]
insertion_sort([-1, -5, 0]) == [-5, -1, 0]
insertion_sort([7]) == [7]
insertion_sort([]) == []
```

---

[Insert in order](exercises/insert-in-order.md)
