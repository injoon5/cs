---
id: xor-missing-number
title: Missing number
level: core
---

`nums` holds n different numbers taken from 0 to n, so exactly one number in that range is missing. Return it in O(n) time and O(1) extra space. `missing([3, 0, 1])` is 2: n is 3, and 0 to 3 is missing 2.

```python starter
def missing(nums):
    pass
```

```tests
missing([3, 0, 1]) == 2
missing([]) == 0
missing([0]) == 1
missing([1]) == 0
missing([0, 1, 2, 3]) == 4
missing([4, 2, 1, 0]) == 3
missing([9, 6, 4, 2, 3, 5, 7, 0, 1]) == 8
missing(list(range(100000, 0, -1))) == 0
```

```python tests
import random

for n in range(60):
    nums = list(range(n + 1))
    gone = random.choice(nums)
    nums.remove(gone)
    random.shuffle(nums)
    assert missing(nums) == gone
```

```python solution
def missing(nums):
    acc = len(nums)
    for i, x in enumerate(nums):
        acc ^= i ^ x
    return acc
```

## Hints

1. Xor every number from 0 to n together with every number in `nums`. What survives?
2. Every number that is present appears twice in that xor and cancels. Only the missing one appears once.
3. Start with `acc = len(nums)`, which is n, and for each index `i` do `acc ^= i ^ nums[i]`.
