---
id: heap-shape
title: The heap property
---

A min-heap is a binary tree with one rule: every parent is less than or equal to its children.

```diagram
tree
1 -> 3 2
3 -> 7 4
2 -> 5 _
highlight 1
```

Follow any path down from the root and the numbers never shrink. So the smallest number is always at the root.

The rule says nothing about siblings. Here 3 sits left of 2, and that's fine. A heap is only half sorted, which is what makes it cheap to keep up to date.

---

A heap also has a fixed shape. Levels fill from top to bottom, and each level from left to right, with no gaps.

That shape means the tree fits in a plain list with no pointers. Read it level by level:

```diagram
tree
1 -> 3 2
3 -> 7 4
2 -> 5 _

array heap [1, 3, 2, 7, 4, 5]
```

The item at index `i` has its children at `2i + 1` and `2i + 2`, and its parent at `(i - 1) // 2`.

---

Index 1 holds 3. Its children are at 3 and 4.

```python
heap = [1, 3, 2, 7, 4, 5]
i = 1
print("left", heap[2 * i + 1])
print("right", heap[2 * i + 2])
print("parent", heap[(i - 1) // 2])
```

---

The root has index 0. What does this print?

```python predict
heap = [1, 3, 2, 7, 4, 5]
for i in range(1, len(heap)):
    p = (i - 1) // 2
    print(heap[p], "->", heap[i])
```

---

Which list is a min-heap?

- [ ] `[1, 4, 2, 3, 5]`
- [x] `[2, 5, 3, 6, 9, 4]`
- [ ] `[3, 1, 2]`

---

To check a whole list, compare each item with its parent. This list has a problem somewhere.

```python trace stop=15
heap = [1, 3, 2, 7, 0, 5]
for i in range(1, len(heap)):
    p = (i - 1) // 2
    if heap[p] > heap[i]:
        break
print(i, p)
```

The loop has stopped. Where?

- [ ] `i` is 4, `p` is 2
- [x] `i` is 4, `p` is 1
- [ ] `i` is 5, `p` is 2

---

Every level of a heap holds twice as many items as the one above. How many levels does a heap of n items have?

- [ ] About n / 2
- [x] About log₂ n
- [ ] About √n

---

In a min-heap, where can the largest item be?

- [ ] At index 1 or 2
- [ ] Always at the last index
- [x] At any leaf, which is any index from `n // 2` on

---

[Is it a min-heap](exercises/is-min-heap.md)

[Largest in a min-heap](exercises/max-in-min-heap.md)
