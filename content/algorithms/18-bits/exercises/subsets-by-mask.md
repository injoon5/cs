---
id: subsets-by-mask
title: Subsets by mask
level: core
---

Return every subset of `nums`, using a loop over bitmasks instead of recursion. List the subsets in mask order, 0 first, and keep the items in each subset in their order in `nums`. Bit i of the mask stands for `nums[i]`.

For `[1, 2, 3]` the answer is `[[], [1], [2], [1, 2], [3], [1, 3], [2, 3], [1, 2, 3]]`.

```python starter
def subsets(nums):
    pass
```

```tests
subsets([1, 2, 3]) == [[], [1], [2], [1, 2], [3], [1, 3], [2, 3], [1, 2, 3]]
subsets([]) == [[]]
subsets([5]) == [[], [5]]
subsets([1, 1]) == [[], [1], [1], [1, 1]]
subsets([-1, 0]) == [[], [-1], [0], [-1, 0]]
len(subsets(list(range(15)))) == 32768
```

```python tests
import itertools

for n in range(9):
    nums = list(range(10, 10 + n))
    got = subsets(nums)
    assert len(got) == 2**n
    for mask, subset in enumerate(got):
        assert subset == [nums[i] for i in range(n) if mask >> i & 1]
    want = sorted(list(c) for k in range(n + 1) for c in itertools.combinations(nums, k))
    assert sorted(got) == want
```

```python solution
def subsets(nums):
    n = len(nums)
    out = []
    for mask in range(1 << n):
        out.append([nums[i] for i in range(n) if mask >> i & 1])
    return out
```

## Hints

1. With n items there are 2ⁿ masks, and each one is a different subset.
2. Loop `mask` over `range(1 << n)`. For each one, collect the items whose bit is set.
3. `[nums[i] for i in range(n) if mask >> i & 1]` is the subset for `mask`.
