---
id: xor-single-number
title: The odd one out
level: core
---

Every number in `nums` appears exactly twice, except one that appears once. Return that one, in O(n) time and O(1) extra space, so no set or dict. Numbers can be negative. `single([4, 1, 2, 1, 2])` is 4.

```python starter
def single(nums):
    pass
```

```tests
single([4, 1, 2, 1, 2]) == 4
single([7]) == 7
single([0, 3, 3]) == 0
single([2, 2, 1]) == 1
single([-1, 5, 5]) == -1
single([-3, -3, -7, 9, 9]) == -7
single([10**18, 1, 1]) == 10**18
single(list(range(100000)) * 2 + [123456]) == 123456
```

```python tests
import random

for _ in range(200):
    pairs = random.sample(range(-1000, 1000), random.randint(1, 30))
    lone = pairs.pop()
    nums = pairs * 2 + [lone]
    random.shuffle(nums)
    assert single(nums) == lone
```

```python solution
def single(nums):
    acc = 0
    for x in nums:
        acc ^= x
    return acc
```

## Hints

1. `x ^ x` is 0, `x ^ 0` is `x`, and the order of xors doesn't matter.
2. Xor every number together. Each pair cancels to 0.
3. Start with `acc = 0` and do `acc ^= x` for every `x`. Negative numbers work too, since a Python int has a sign bit that goes on forever.
