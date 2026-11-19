---
id: range-max-count
title: Largest and how often
level: core
---

Finish `MaxCountTree`, a segment tree whose `query(l, r)` returns a tuple: the largest number in `nums[l..r]`, both ends included, and how many times it appears there. `update(i, x)` sets `nums[i]` to `x`. Both must cost O(log n).

`play` runs a list of operations and collects what each `query` returned. For `nums = [3, 1, 3, 2]`, `query(0, 3)` is `(3, 2)`, and after `update(1, 3)` it is `(3, 3)`.

```python starter
class MaxCountTree:
    def __init__(self, nums):
        pass

    def update(self, i, x):
        pass

    def query(self, l, r):
        pass


def play(nums, ops):
    tree = MaxCountTree(nums)
    out = []
    for name, *args in ops:
        result = getattr(tree, name)(*args)
        if name == "query":
            out.append(result)
    return out
```

```tests
play([3, 1, 3, 2], [("query", 0, 3), ("update", 1, 3), ("query", 0, 3)]) == [(3, 2), (3, 3)]
play([3, 1, 3, 2], [("query", 1, 1), ("query", 1, 3), ("query", 3, 3)]) == [(1, 1), (3, 1), (2, 1)]
play([5], [("query", 0, 0)]) == [(5, 1)]
play([4, 4, 4, 4, 4], [("query", 0, 4), ("update", 2, 1), ("query", 0, 4), ("query", 2, 2)]) == [(4, 5), (4, 4), (1, 1)]
play([-5, -1, -1, -3], [("query", 0, 3), ("query", 0, 0)]) == [(-1, 2), (-5, 1)]
play([1, 2, 3], [("update", 0, 9), ("query", 0, 2), ("update", 0, 3), ("query", 0, 2)]) == [(9, 1), (3, 2)]
play([0] * 65536, [op for k in range(10000) for op in (("update", k, 1), ("query", 0, 65535))]) == [(1, k + 1) for k in range(10000)]
```

```python tests
import random

rng = random.Random(6)
for _ in range(150):
    nums = [rng.randint(-4, 4) for _ in range(rng.randint(1, 20))]
    tree = MaxCountTree(nums)
    ref = list(nums)
    for _ in range(40):
        if rng.random() < 0.4:
            i, x = rng.randrange(len(ref)), rng.randint(-4, 4)
            tree.update(i, x)
            ref[i] = x
        else:
            l = rng.randrange(len(ref))
            r = rng.randrange(l, len(ref))
            part = ref[l:r + 1]
            assert tree.query(l, r) == (max(part), part.count(max(part))), (nums, l, r)
```

```python solution
EMPTY = (float("-inf"), 0)


def combine(a, b):
    if a[0] > b[0]:
        return a
    if b[0] > a[0]:
        return b
    return (a[0], a[1] + b[1])


class MaxCountTree:
    def __init__(self, nums):
        self.n = 1
        while self.n < len(nums):
            self.n *= 2
        leaves = [(x, 1) for x in nums]
        self.tree = [EMPTY] * self.n + leaves + [EMPTY] * (self.n - len(nums))
        for i in range(self.n - 1, 0, -1):
            self.tree[i] = combine(self.tree[2 * i], self.tree[2 * i + 1])

    def update(self, i, x):
        i += self.n
        self.tree[i] = (x, 1)
        while i > 1:
            i //= 2
            self.tree[i] = combine(self.tree[2 * i], self.tree[2 * i + 1])

    def query(self, l, r):
        result = EMPTY
        l += self.n
        r += self.n
        while l <= r:
            if l % 2 == 1:
                result = combine(result, self.tree[l])
                l += 1
            if r % 2 == 0:
                result = combine(result, self.tree[r])
                r -= 1
            l //= 2
            r //= 2
        return result


def play(nums, ops):
    tree = MaxCountTree(nums)
    out = []
    for name, *args in ops:
        result = getattr(tree, name)(*args)
        if name == "query":
            out.append(result)
    return out
```

## Hints

1. One number per node isn't enough, but a pair is: each node holds `(largest, count)` for its range, and a leaf holds `(x, 1)`.
2. Two pairs combine like this: if one largest is bigger, keep that pair; if they are equal, keep the number and add the counts. The empty pair `(float("-inf"), 0)` changes nothing.
3. Write `combine(a, b)` and use it everywhere the sum tree used `+`: building, updating and in the climb, which starts from the empty pair.
