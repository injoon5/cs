---
id: fenwick-trees
title: Fenwick trees
---

Sums have something minimums don't: they can be taken away. The sum of positions `l..r` is the sum of the first `r` minus the sum of the first `l - 1`. So for sums, prefix sums are enough, as long as an update doesn't have to fix all of them.

A Fenwick tree, also called a binary indexed tree, keeps partial prefix sums in a list `bit` of n + 1 cells. Positions count from 1, and `bit[0]` is unused. Cell `i` holds the sum of a stretch of numbers that ends at position `i`. The stretch is as long as the lowest 1 bit of `i` is worth: 1 for odd `i`, 2 for 6, 4 for 4 and 12, 8 for 8.

```diagram
grid
col-labels [1, 2, 3, 4, 5, 6, 7, 8]
row [8, 8, 8, 8, 8, 8, 8, 8]
row [4, 4, 4, 4, , , , ]
row [2, 2, , , 6, 6, , ]
row [1, , 3, , 5, , 7, ]
```

The columns are positions 1 to 8, and each run of one number is the stretch that cell covers. Cell 6 covers positions 5 and 6, cell 4 covers 1 to 4, and cell 8 covers all of them.

---

`i & -i` keeps only the lowest 1 bit of `i`. 6 is `110` in binary, so `6 & -6` is `010`, which is 2. The Bits unit shows why it works; here only the result matters. What does this print?

```python predict
for i in range(1, 9):
    low = i & -i
    print(i, low, f"{i - low + 1}..{i}")
```

---

To sum the first `i` numbers, take `bit[i]`, which covers the stretch ending at `i`, then jump to just before that stretch, `i - (i & -i)`, and repeat until `i` is 0.

For the first 7: cell 7 covers 7, cell 6 covers 5 and 6, cell 4 covers 1 to 4. In binary, `i` goes `111`, `110`, `100`, `0`: each jump clears the lowest 1 bit.

```python trace stop=12
def prefix(bit, i):
    total = 0
    while i > 0:
        total += bit[i]
        i -= i & -i
    return total


# nums is [5, 3, 7, 1, 4, 2, 6, 8], from position 1
bit = [0, 5, 8, 7, 16, 4, 6, 6, 36]
print(prefix(bit, 7))
```

Two cells have been added. What are `total` and `i`?

- [ ] `total` is 12, `i` is 5
- [x] `total` is 12, `i` is 4
- [ ] `total` is 13, `i` is 4

---

To add `delta` to position `i`, fix every cell whose stretch contains `i`. They are `i`, then `i + (i & -i)`, and so on until it passes n. Adding the lowest bit carries it upward, so each step lands on a cell with a longer stretch that still contains position `i`.

```python
def add(bit, i, delta):
    while i < len(bit):
        bit[i] += delta
        i += i & -i


def prefix(bit, i):
    total = 0
    while i > 0:
        total += bit[i]
        i -= i & -i
    return total


nums = [5, 3, 7, 1, 4, 2, 6, 8]
bit = [0] * (len(nums) + 1)
for i, x in enumerate(nums, start=1):
    add(bit, i, x)
print(bit)
print(prefix(bit, 6) - prefix(bit, 1))
```

`nums` goes in one number at a time. The last line sums positions 2 to 6.

---

Run this to watch an update climb and a prefix sum walk down.

```python
import viz

bit = [0, 5, 8, 7, 16, 4, 6, 6, 36]
i = 3
viz.array(bit, name="bit", pointers={"i": i}, note="add 2 at position 3")
while i < len(bit):
    bit[i] += 2
    viz.array(bit, name="bit", pointers={"i": i}, highlight=i, note=f"cell {i} covers {i - (i & -i) + 1}..{i}: add 2")
    i += i & -i

i, total = 7, 0
viz.note("sum the first 7")
while i > 0:
    total += bit[i]
    viz.array(bit, name="bit", pointers={"i": i}, highlight=i, note=f"cell {i} covers {i - (i & -i) + 1}..{i}: total {total}")
    i -= i & -i
viz.note(f"the first 7 sum to {total}")
```

---

Put the lines in order: `add` adds `delta` at position `i`, and `range_sum` returns the sum of positions `l` to `r`.

```python arrange
def add(bit, i, delta):
    while i < len(bit):
        bit[i] += delta
        i += i & -i


def range_sum(bit, l, r):
    total = 0
    i = r
    while i > 0:
        total += bit[i]
        i -= i & -i
    i = l - 1
    while i > 0:
        total -= bit[i]
        i -= i & -i
    return total
```

```python tests
bit = [0] * 9
for i, x in enumerate([5, 3, 7, 1, 4, 2, 6, 8], start=1):
    add(bit, i, x)
assert bit == [0, 5, 8, 7, 16, 4, 6, 6, 36]
assert range_sum(bit, 1, 8) == 36
assert range_sum(bit, 2, 6) == 17
assert range_sum(bit, 4, 4) == 1
add(bit, 4, 10)
assert range_sum(bit, 3, 5) == 22
assert range_sum(bit, 5, 8) == 20
```

---

Each walk clears or carries the lowest bit, and there are about log₂ n bits. With n numbers, an update and a prefix sum each cost

- [ ] O(1)
- [x] O(log n)
- [ ] O(√n)

---

A Fenwick tree has n + 1 cells to the segment tree's 2n, and each walk is three lines. But it gets a range from two prefixes, `prefix(r) - prefix(l - 1)`, so it only works when the left part can be taken away. You need the largest number in `nums[l..r]` while `nums` changes. Which do you use?

- [ ] A Fenwick tree, since it is smaller and simpler
- [x] A segment tree, since a maximum can't be taken away
- [ ] Either, since both answer range questions in O(log n)

---

A Fenwick tree can also count. Index it by value instead of position, and add 1 at `x` each time `x` is seen. Then `prefix(bit, x)` counts the numbers seen so far that are at most `x`. Here the values are 1 to 4. What does this print?

```python predict
def add(bit, i, delta):
    while i < len(bit):
        bit[i] += delta
        i += i & -i


def prefix(bit, i):
    total = 0
    while i > 0:
        total += bit[i]
        i -= i & -i
    return total


bit = [0] * 5
seen = 0
for x in [3, 1, 4, 2]:
    print(x, seen - prefix(bit, x))
    add(bit, x, 1)
    seen += 1
```

Each line shows how many earlier numbers are bigger than `x`. Their total, 3, counts the pairs where a bigger number comes before a smaller one, the inversions from the sorting unit. Values that aren't 1 to n are first replaced by their rank in sorted order.

---

[A Fenwick tree](exercises/fenwick-tree-class.md)

[Inversions with a Fenwick tree](exercises/fenwick-inversions.md)

[Smaller numbers after](exercises/smaller-after-self.md)
