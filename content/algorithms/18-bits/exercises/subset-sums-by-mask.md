---
id: subset-sums-by-mask
title: Every subset sum
level: stretch
---

Return a list `sums` of length 2ⁿ, where `sums[mask]` is the total of the items of `nums` whose bits are set in `mask`. Bit i stands for `nums[i]`. Adding up each subset from scratch costs O(2ⁿ · n), which is too slow for 20 items. Aim for O(2ⁿ): reuse the sum of a smaller mask.

For `[3, 5]` the answer is `[0, 3, 5, 8]`: the empty set, `{3}`, `{5}` and `{3, 5}`.

```python starter
def subset_sums(nums):
    pass
```

```tests
subset_sums([3, 5]) == [0, 3, 5, 8]
subset_sums([]) == [0]
subset_sums([7]) == [0, 7]
subset_sums([1, 2, 4]) == [0, 1, 2, 3, 4, 5, 6, 7]
subset_sums([2, 2]) == [0, 2, 2, 4]
subset_sums([-1, 3]) == [0, -1, 3, 2]
sum(subset_sums(list(range(1, 21)))) == 210 * 2**19
```

```python tests
import random

for _ in range(100):
    n = random.randint(0, 9)
    nums = [random.randint(-20, 20) for _ in range(n)]
    want = [sum(nums[i] for i in range(n) if mask >> i & 1) for mask in range(1 << n)]
    assert subset_sums(nums) == want
```

```python solution
def subset_sums(nums):
    sums = [0] * (1 << len(nums))
    for mask in range(1, len(sums)):
        low = mask & -mask
        i = low.bit_length() - 1
        sums[mask] = sums[mask ^ low] + nums[i]
    return sums
```

## Hints

1. Every nonempty mask is a smaller mask plus one more item. If you fill `sums` in increasing order, the smaller mask is already done.
2. Take out the lowest set bit: `low = mask & -mask`. Then `mask ^ low` is smaller, and `low` stands for item `low.bit_length() - 1`.
3. `sums[mask] = sums[mask ^ low] + nums[low.bit_length() - 1]`, for `mask` from 1 up.
