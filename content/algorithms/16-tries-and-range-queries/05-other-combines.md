---
id: segment-tree-combines
title: Minimum, maximum and more
---

Now the question is the smallest number in `nums[l..r]`, while `nums` keeps changing. Prefix sums worked for sums because `prefix[r + 1] - prefix[l]` takes away the part before `l`. Try the same with running minimums.

```diagram
array nums [1, 5, 3, 4]
shade 1..3
array prefix_min [1, 1, 1, 1]
```

The smallest of `nums[1..3]` is 3, but every running minimum is 1, because they all include `nums[0]`. A minimum can't be taken away the way a sum can.

---

A segment tree never takes anything away. It only puts two neighboring ranges together. So swap `+` for `min` in the build, the update and the climb, and the shape of the code stays the same. What does this print?

```python predict
nums = [5, 3, 7, 1]
n = len(nums)
tree = [0] * n + nums
for i in range(n - 1, 0, -1):
    tree[i] = min(tree[2 * i], tree[2 * i + 1])
print(tree[1:])
```

---

The value a query starts from changes too. For sums it was 0, which changes no sum. For a minimum it must be a value that loses to every number, `float("inf")`.

A min query starts its result at 0, as the sum query did. What happens?

- [ ] Nothing, since 0 is replaced by the first node taken
- [x] Every range of positive numbers comes out as 0
- [ ] Ranges with negative numbers come out wrong, the others are fine

Pad `nums` up to a power of two with the same value, so the root still holds the minimum of everything.

---

The climb splits a range into pieces of its own choosing: `nums[1..6]` became the pieces `1`, `2..3`, `4..5` and `6`. Any way of grouping must give the same answer. An operation where `(a ∘ b) ∘ c` always equals `a ∘ (b ∘ c)` is called associative.

Sum, min, max, gcd and product are all associative. Their starting values are 0, `float("inf")`, `float("-inf")`, 0 and 1.

Which of these can't a segment tree keep, one value per node, combined from the two children?

- [ ] The largest number in the range
- [ ] The gcd of the range
- [x] The median of the range
- [ ] The product of the range

The medians of two halves don't give the median of both. When one number isn't enough, a node can hold a tuple: the mean of a range comes from `(sum, count)`, and the largest number with how often it appears comes from `(largest, count)`.

---

Associative is not the same as order not mattering. Joining strings is associative, but `"a" + "b"` isn't `"b" + "a"`. What does this print?

```python predict
words = ["a", "b", "c", "d"]
n = 4
tree = [""] * n + words
for i in range(n - 1, 0, -1):
    tree[i] = tree[2 * i] + tree[2 * i + 1]

l, r = 0 + n, 2 + n
total = ""
while l <= r:
    if l % 2 == 1:
        total += tree[l]
        l += 1
    if r % 2 == 0:
        total += tree[r]
        r -= 1
    l //= 2
    r //= 2
print(tree[1], total)
```

The climb found `c`, at the right end, before `ab`, further left. For sums and minimums that doesn't matter. To keep the order, collect two results: `left` grows to the right, `right` grows to the left, and the answer is `left` joined with `right`.

---

Here is the whole thing as one class. It takes the combine and its starting value, and keeps `left` and `right` apart so the order is right for any combine.

```python
from math import gcd


class SegmentTree:
    def __init__(self, nums, combine, empty):
        self.n = 1
        while self.n < len(nums):
            self.n *= 2
        self.combine = combine
        self.empty = empty
        pad = [empty] * (self.n - len(nums))
        self.tree = [empty] * self.n + list(nums) + pad
        for i in range(self.n - 1, 0, -1):
            self.tree[i] = combine(self.tree[2 * i], self.tree[2 * i + 1])

    def update(self, i, x):
        i += self.n
        self.tree[i] = x
        while i > 1:
            i //= 2
            self.tree[i] = self.combine(self.tree[2 * i], self.tree[2 * i + 1])

    def query(self, l, r):
        left = right = self.empty
        l += self.n
        r += self.n
        while l <= r:
            if l % 2 == 1:
                left = self.combine(left, self.tree[l])
                l += 1
            if r % 2 == 0:
                right = self.combine(self.tree[r], right)
                r -= 1
            l //= 2
            r //= 2
        return self.combine(left, right)


nums = [12, 18, 7, 30, 24]
lowest = SegmentTree(nums, min, float("inf"))
highest = SegmentTree(nums, max, float("-inf"))
gcds = SegmentTree(nums, gcd, 0)
words = SegmentTree(["a", "b", "c", "d"], lambda a, b: a + b, "")
print(lowest.query(0, 2), highest.query(0, 2), gcds.query(3, 4))
gcds.update(2, 6)
print(gcds.query(0, 3), words.query(0, 2))
```

---

Point updates change one number. Some problems change a whole range at once: add 5 to every number in `nums[l..r]`. With only point updates, that costs

- [ ] O(log n)
- [x] O((r - l + 1) × log n), one update per number
- [ ] O(n log n), since the whole tree is rebuilt

There is a known fix, lazy propagation. A node whose whole range gets the change records it as a note, "add 5 to everything below me", and passes the note down to its children only when a later request has to look below it. Range updates and range queries then both cost O(log n). It is worth knowing it exists; the problems here don't need it.

---

[Range minimum](exercises/range-min-updates.md)

[Largest and how often](exercises/range-max-count.md)
