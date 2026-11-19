---
id: segment-trees
title: Segment trees
---

A segment tree is the tree of ranges from the last lesson, with a sum in every node.

```diagram
tree
node n1 "0..7: 36"
node n2 "0..3: 16"
node n3 "4..7: 20"
node n4 "0..1: 8"
node n5 "2..3: 8"
node n6 "4..5: 6"
node n7 "6..7: 14"
node n8 "5"
node n9 "3"
node n10 "7"
node n11 "1"
node n12 "4"
node n13 "2"
node n14 "6"
node n15 "8"
n1 -> n2 n3
n2 -> n4 n5
n3 -> n6 n7
n4 -> n8 n9
n5 -> n10 n11
n6 -> n12 n13
n7 -> n14 n15

array nums [5, 3, 7, 1, 4, 2, 6, 8]
```

The leaves are `nums` itself. Every other node holds the sum of its range, which is the sum of its two children.

---

The tree lives in a list, laid out like a heap but counting from 1: node `i` has children `2i` and `2i + 1`, and its parent is `i // 2`. Index 0 is unused. A segment tree can also be built from node objects and recursion, but the list version is shorter and its layout is one you already know.

With n numbers, n a power of two, the leaves fill `tree[n]` to `tree[2n - 1]`, so `nums[i]` sits at `tree[n + i]`. The parents are built from the bottom up. What does this print?

```python predict
nums = [2, 1, 3, 4]
n = len(nums)
tree = [0] * n + nums
for i in range(n - 1, 0, -1):
    tree[i] = tree[2 * i] + tree[2 * i + 1]
print(tree)
```

If n is not a power of two, pad `nums` with zeros up to the next one. Zeros change no sum.

---

To set `nums[i]` to `x`, change its leaf, then walk up to the root, recomputing each parent from its two children. Here `nums[2]` becomes 9.

```python trace stop=27
nums = [5, 3, 7, 1, 4, 2, 6, 8]
n = len(nums)
tree = [0] * n + nums
for i in range(n - 1, 0, -1):
    tree[i] = tree[2 * i] + tree[2 * i + 1]

i = 2 + n
tree[i] = 9
while i > 1:
    i //= 2
    tree[i] = tree[2 * i] + tree[2 * i + 1]
print(tree[1])
```

Two parents have been fixed. What are `i` and `tree[i]`?

- [ ] `i` is 5, `tree[i]` is 10
- [ ] `i` is 2, `tree[i]` is 16
- [x] `i` is 2, `tree[i]` is 18

---

A sum over a range adds up a few nodes that together cover it exactly. For `nums[1..6]` those are the highlighted ones: `3 + 8 + 6 + 6 = 23`.

```diagram
tree
node n1 "0..7: 36"
node n2 "0..3: 16"
node n3 "4..7: 20"
node n4 "0..1: 8"
node n5 "2..3: 8"
node n6 "4..5: 6"
node n7 "6..7: 14"
node n8 "5"
node n9 "3"
node n10 "7"
node n11 "1"
node n12 "4"
node n13 "2"
node n14 "6"
node n15 "8"
n1 -> n2 n3
n2 -> n4 n5
n3 -> n6 n7
n4 -> n8 n9
n5 -> n10 n11
n6 -> n12 n13
n7 -> n14 n15
highlight n9 n5 n6 n14
```

Find them by climbing. Start `l` and `r` at the leaves of the two ends, `n + 1` and `n + 6`, which are 9 and 14.

- If `l` is a right child, an odd index, its parent also covers the number to its left, which is outside the range. So take `tree[l]` alone and move `l` one node right.
- If `r` is a left child, an even index, its parent reaches past the right end. Take `tree[r]` alone and move `r` one node left.
- Now `l` is a left child and `r` a right child, so the nodes from `l` to `r` come in whole pairs, and their parents cover the same numbers. Go up a level, `l //= 2` and `r //= 2`, and repeat while `l <= r`.

---

Run this to watch the climb. Highlighted nodes have been added to the total, and the shaded part of `nums` is still left to cover. The lists `lo` and `hi` hold each node's range, only for the labels.

```python
import viz

nums = [5, 3, 7, 1, 4, 2, 6, 8]
n = len(nums)
tree = [0] * n + nums
lo = [0] * n + list(range(n))
hi = [0] * n + list(range(n))
for i in range(n - 1, 0, -1):
    tree[i] = tree[2 * i] + tree[2 * i + 1]
    lo[i], hi[i] = lo[2 * i], hi[2 * i + 1]
labels = [f"{lo[i]}..{hi[i]}: {tree[i]}" if i < n else tree[i] for i in range(1, 2 * n)]


def name(i):
    return f"nums[{lo[i]}]" if i >= n else f"{lo[i]}..{hi[i]}"


def show(note):
    with viz.frame():
        # viz draws a list as a heap counted from 0, so node i is drawn at i - 1.
        viz.tree(labels, active=[i - 1 for i in taken])
        shaded = (lo[l], hi[r]) if l <= r else None
        viz.array(nums, name="nums", range=shaded, note=note)


l, r = 1 + n, 6 + n
total = 0
taken = []
show("sum of nums[1..6]")
while l <= r:
    if l % 2 == 1:
        total += tree[l]
        taken.append(l)
        note = f"l is a right child: take {name(l)} = {tree[l]}, total {total}"
        l += 1
        show(note)
    if r % 2 == 0:
        total += tree[r]
        taken.append(r)
        note = f"r is a left child: take {name(r)} = {tree[r]}, total {total}"
        r -= 1
        show(note)
    l //= 2
    r //= 2
    if l <= r:
        show(f"up a level: l is {name(l)}, r is {name(r)}")
print(total)
```

---

Here is the climb as a function. It takes positions in `nums` and moves them to the leaves first.

```python trace stop=15
def query(tree, n, l, r):
    total = 0
    l += n
    r += n
    while l <= r:
        if l % 2 == 1:
            total += tree[l]
            l += 1
        if r % 2 == 0:
            total += tree[r]
            r -= 1
        l //= 2
        r //= 2
    return total


tree = [0, 36, 16, 20, 8, 8, 6, 14, 5, 3, 7, 1, 4, 2, 6, 8]
print(query(tree, 8, 0, 4))
```

This sums `nums[0..4]`. The loop has gone up one level. What are `total`, `l` and `r`?

- [x] `total` is 4, `l` is 4, `r` is 5
- [ ] `total` is 4, `l` is 8, `r` is 11
- [ ] `total` is 9, `l` is 4, `r` is 5

---

Put the lines in order so `query` returns the sum of `nums[l..r]`, both ends included.

```python arrange
def query(tree, n, l, r):
    total = 0
    l += n
    r += n
    while l <= r:
        if l % 2 == 1:
            total += tree[l]
            l += 1
        if r % 2 == 0:
            total += tree[r]
            r -= 1
        l //= 2
        r //= 2
    return total
```

```tests
query([0, 36, 16, 20, 8, 8, 6, 14, 5, 3, 7, 1, 4, 2, 6, 8], 8, 1, 6) == 23
query([0, 36, 16, 20, 8, 8, 6, 14, 5, 3, 7, 1, 4, 2, 6, 8], 8, 0, 7) == 36
query([0, 36, 16, 20, 8, 8, 6, 14, 5, 3, 7, 1, 4, 2, 6, 8], 8, 3, 3) == 1
query([0, 36, 16, 20, 8, 8, 6, 14, 5, 3, 7, 1, 4, 2, 6, 8], 8, 4, 7) == 20
query([0, 10, 3, 7, 2, 1, 3, 4], 4, 1, 2) == 4
query([0, 5], 1, 0, 0) == 5
```

---

An update fixes one node per level, and a sum takes at most one node at each end per level, so each costs O(log n). With n numbers and q requests mixing updates and sums, a segment tree takes

- [ ] O(n × q) time
- [x] O(n + q log n) time, O(n) space
- [ ] O(q log n) time, O(n log n) space

Building costs O(n), since each of the n - 1 parents is one addition. The list has 2n entries.

---

[Range sums with updates](exercises/segment-tree-sums.md)
