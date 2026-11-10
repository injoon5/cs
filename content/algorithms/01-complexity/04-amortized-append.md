---
id: amortized-append
title: Amortized cost of append
---

A Python list stores its items in one block of slots. Usually the block has room to spare, and `append` just fills the next slot.

When the block is full, Python gets a bigger block and copies every item across. That one append costs `n` copies.

---

This list holds 5 items in room for 8. The next three appends are cheap. The fourth one copies.

```diagram
array [a, b, c, d, e, , , ]
shade 0..4
pointer size 5
```

---

This code acts out a list that doubles its room when full. `copies` counts the items moved. (CPython grows by about an eighth, not double, but any fixed fraction gives the same result. Doubling keeps the numbers easy.)

```python trace stop=18
capacity = 1
size = 0
copies = 0
for item in range(5):
    if size == capacity:
        copies += size
        capacity *= 2
    size += 1
```

Three items are in. What is `capacity`?

- [ ] 3
- [x] 4
- [ ] 8

---

How many copies do 1,000 appends cause in total?

```python predict
capacity, size, copies = 1, 0, 0
for _ in range(1000):
    if size == capacity:
        copies += size
        capacity *= 2
    size += 1
print(copies, copies / 1000)
```

---

The copies were 1 + 2 + 4 + ... + 512. Each term is bigger than all the ones before it put together, so the sum is less than twice the last term. That's always under `2n`.

So `n` appends cost under `3n` steps in total: `n` slot fills and fewer than `2n` copies. Spread over the appends, that's a constant per append. We say `append` is amortized O(1). A single append can still be O(n); the average over a run of them can't.

---

Suppose the list grew by 10 slots each time instead of doubling. What would `n` appends cost in total?

- [ ] O(n)
- [ ] O(n log n)
- [x] O(n²)

---

Changing the front of a list moves every item after it by one slot. Which of these are amortized O(1) on a Python list?

- [x] `xs.append(v)`
- [x] `xs.pop()`
- [ ] `xs.insert(0, v)`
- [ ] `xs.pop(0)`

---

[Append copies](exercises/append-copies.md)

---

[Grow and shrink](exercises/grow-and-shrink.md)
