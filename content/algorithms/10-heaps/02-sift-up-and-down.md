---
id: sift-up-and-down
title: Sift up and sift down
---

To push 0 onto this heap, append it. The shape stays right: the new item fills the next free slot on the bottom level.

```diagram
tree
1 -> 3 2
3 -> 7 4
2 -> 5 0
highlight 0

array heap [1, 3, 2, 7, 4, 5, 0]
pointer i 6
```

The order is now broken: 0 sits under 2. Swap it with its parent, and keep swapping while it is smaller than the parent above. This is called sifting up.

---

Run this to watch 0 rise to the root. Each swap moves it up one level.

```python
import viz


def show(heap, i, note):
    with viz.frame():
        viz.tree(heap, active=i)
        viz.array(heap, name="heap", pointers={"i": i}, note=note)


heap = [1, 3, 2, 7, 4, 5]
heap.append(0)
i = len(heap) - 1
show(heap, i, "append 0")
while i > 0:
    p = (i - 1) // 2
    if heap[p] <= heap[i]:
        break
    note = f"{heap[i]} < {heap[p]}, swap"
    heap[i], heap[p] = heap[p], heap[i]
    i = p
    show(heap, i, note)
show(heap, i, "at the root, stop")
```

---

```python trace stop=10
heap = [1, 3, 2, 7, 4, 5]
heap.append(0)
i = len(heap) - 1
while i > 0:
    p = (i - 1) // 2
    if heap[p] <= heap[i]:
        break
    heap[i], heap[p] = heap[p], heap[i]
    i = p
print(heap)
```

One swap has happened. What is `heap` now?

- [ ] `[0, 3, 1, 7, 4, 5, 2]`
- [x] `[1, 3, 0, 7, 4, 5, 2]`
- [ ] `[1, 0, 2, 7, 4, 5, 3]`

---

Popping takes the root, the smallest item. That leaves a hole at the top, and the only item that can leave without breaking the shape is the last one.

So move the last item to the root, then sift it down: swap it with its smaller child until both children are bigger.

```diagram
tree
5 -> 3 2
3 -> 7 4
highlight 5

array heap [5, 3, 2, 7, 4]
pointer i 0
```

Here 5 swaps with 2, then has no children left, so it stops.

---

What does this print?

```python predict
heap = [1, 3, 2, 7, 4, 5]
smallest = heap[0]
heap[0] = heap.pop()
i = 0
while 2 * i + 1 < len(heap):
    c = 2 * i + 1
    if c + 1 < len(heap):
        if heap[c + 1] < heap[c]:
            c += 1
    if heap[i] <= heap[c]:
        break
    heap[i], heap[c] = heap[c], heap[i]
    i = c
print(smallest, heap)
```

---

Why does sifting down swap with the smaller child?

- [ ] The smaller child is always the left one
- [x] The child that moves up becomes the parent of the other child, so it must be the smaller one
- [ ] Swapping with the bigger child would take more swaps

---

Put the lines in order so `sift_up` moves the item at index `i` up to its place and returns the heap.

```python arrange
def sift_up(heap, i):
    while i > 0:
        p = (i - 1) // 2
        if heap[p] <= heap[i]:
            break
        heap[i], heap[p] = heap[p], heap[i]
        i = p
    return heap
```

```tests
sift_up([1, 3, 2, 7, 4, 5, 0], 6) == [0, 3, 1, 7, 4, 5, 2]
sift_up([1, 3, 2, 7, 4, 5, 6], 6) == [1, 3, 2, 7, 4, 5, 6]
sift_up([2, 5, 1], 2) == [1, 5, 2]
sift_up([3, 3], 1) == [3, 3]
sift_up([4], 0) == [4]
```

---

A push or a pop does at most one swap per level. On a heap of n items, each one costs

- [ ] O(1)
- [x] O(log n)
- [ ] O(n)

---

To turn a whole list into a heap, n pushes would cost O(n log n). There is a faster way: sift down every parent, starting from the last parent and walking back to the root.

```python
def sift_down(a, i):
    while 2 * i + 1 < len(a):
        c = 2 * i + 1
        if c + 1 < len(a) and a[c + 1] < a[c]:
            c += 1
        if a[i] <= a[c]:
            return
        a[i], a[c] = a[c], a[i]
        i = c


a = [9, 7, 5, 3, 1, 8, 2]
for i in range(len(a) // 2 - 1, -1, -1):
    sift_down(a, i)
print(a)
```

Most items sit near the bottom, where a sift down is short. In this list of 7, the 4 leaves do nothing, 2 parents move at most one level and only the root can move two.

---

Half the items move 0 levels, a quarter move at most 1, an eighth at most 2, and so on. Building a heap this way costs

- [ ] O(log n)
- [x] O(n)
- [ ] O(n log n)

---

[Push onto a heap](exercises/heap-push.md)

[Pop from a heap](exercises/heap-pop-min.md)

[Build a heap](exercises/build-min-heap.md)
