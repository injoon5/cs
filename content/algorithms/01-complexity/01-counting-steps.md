---
id: counting-steps
title: Counting steps
---

This loop adds up five numbers. Its body runs five times, once per item.

```python
nums = [4, 8, 15, 16, 23]
total = 0
for x in nums:
    total += x
print(total)
```

Give it ten numbers and the body runs ten times. We measure a program by counting steps like this, not by timing it. The count is the same on any machine.

---

```python trace stop=8
total = 0
for x in [3, 1, 4, 1]:
    total += x
```

Three items have been added. What is `total` now?

- [ ] 4
- [x] 8
- [ ] 9

---

A loop inside a loop multiplies. What does this print?

```python predict
steps = 0
for i in range(4):
    for j in range(4):
        steps += 1
print(steps)
```

---

Each cell is one run of `steps += 1`. Four rows of four.

```diagram
grid
col-labels [j=0, j=1, j=2, j=3]
row-labels [i=0, i=1, i=2, i=3]
row [1, 2, 3, 4]
row [5, 6, 7, 8]
row [9, 10, 11, 12]
row [13, 14, 15, 16]
highlight 3,3
```

With `n` in place of 4, that's `n * n` steps.

---

Now the inner loop starts one past `i`, so each pair is visited once. What does this print?

```python predict
steps = 0
for i in range(4):
    for j in range(i + 1, 4):
        steps += 1
print(steps)
```

---

Only the cells above the diagonal are left.

```diagram
grid
col-labels [j=0, j=1, j=2, j=3]
row-labels [i=0, i=1, i=2, i=3]
row [, 1, 2, 3]
row [, , 4, 5]
row [, , , 6]
row [, , , ]
```

Row `i` has `n - 1 - i` cells. Added up, that's `n * (n - 1) / 2`. Still about half of `n * n`.

---

To count steps, find the line that runs most often and count its runs as a function of the input size `n`.

For a list of `n` items, how many times does the inner line of the second loop run?

- [ ] `n`
- [x] `n * (n - 1) / 2`
- [ ] `n * n`
- [ ] `2 * n`

---

[Sum to n](exercises/sum-to.md)
