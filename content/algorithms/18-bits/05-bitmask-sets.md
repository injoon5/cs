---
id: bitmask-sets
title: Bitmasks as sets
---

Number n items 0 to n - 1. Any subset of them fits in one n-bit integer: bit i is 1 when item i is in the subset. Such an integer is called a bitmask.

With items `["a", "b", "c", "d"]`, the mask below has bits 0, 1 and 3 set, so it stands for a, b and d. Bit 0 is on the right.

```diagram
bits 1011
group 4
```

---

The set operations become single bitwise operations, each one O(1) for a mask that fits in a machine word.

- Union is `x | y`, intersection is `x & y`, and `x & ~y` keeps what is in `x` but not in `y`.
- Item i is in `x` when `x >> i & 1` is 1. `x | (1 << i)` adds it.
- `x.bit_count()` is the size of the set.

What does this print?

```python predict
items = ["a", "b", "c", "d"]

def show(mask):
    return [items[i] for i in range(len(items)) if mask >> i & 1]

x = 0b1011
y = 0b0110
print(show(x | y), show(x & y), show(x & ~y))
```

---

Which expression is nonzero exactly when item 2 is in `mask`?

- [x] `mask >> 2 & 1`
- [ ] `mask & 2`
- [ ] `mask >> 2 == 1`

---

Every subset of n items is a mask from 0 to 2ⁿ - 1, and every number in that range is a subset. So one loop over `range(1 << n)` lists each subset exactly once.

```python
nums = [1, 2, 3]
n = len(nums)
for mask in range(1 << n):
    subset = [nums[i] for i in range(n) if mask >> i & 1]
    print(format(mask, "03b"), subset)
```

This is the take-or-leave tree from the recursion unit, flattened. Each bit is one take-or-leave choice.

---

```python trace stop=81
nums = [1, 2, 3]
out = []
for mask in range(1 << 3):
    subset = []
    for i in range(3):
        if mask >> i & 1:
            subset.append(nums[i])
    out.append(subset)
```

`mask` is 6, `110`, and its subset is complete. What is `subset`?

- [ ] `[1, 2]`
- [x] `[2, 3]`
- [ ] `[3]`

---

The loop visits 2ⁿ masks and spends O(n) on each to read its bits. Listing every subset this way costs

- [ ] O(n²)
- [ ] O(2ⁿ)
- [x] O(2ⁿ · n)

---

Sometimes you need the subsets of one mask, not of everything. Start at the mask itself and step with `sub = (sub - 1) & mask`. Subtracting 1 gives the next smaller number, and `& mask` drops the bits outside the mask, so each step lands on the next smaller subset. What does this print?

```python predict
mask = 0b1011
sub = mask
while True:
    print(format(sub, "04b"))
    if sub == 0:
        break
    sub = (sub - 1) & mask
```

---

A mask is a plain int, so it can be a dict key or a list index. A `set` can't be a dict key, because it can change. That makes masks the usual way to remember which group of items a partial answer has used, with one list entry per mask.

A list with one entry per subset of n items is practical for n up to about

- [x] 20
- [ ] 1,000
- [ ] any n, since Python ints have no size limit

---

[Subsets by mask](exercises/subsets-by-mask.md)

[Every subset sum](exercises/subset-sums-by-mask.md)

[Gray code](exercises/gray-code-sequence.md)
