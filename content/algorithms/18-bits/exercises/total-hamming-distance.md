---
id: total-hamming-distance
title: Total Hamming distance
level: core
---

The Hamming distance between two numbers is how many bit positions they differ in. Return the sum of the Hamming distances over every pair of numbers in `nums`. All numbers are non-negative and below 2³¹. Comparing every pair is O(n²), which is too slow for the largest test. Aim for O(31 · n).

For `[4, 14, 2]`: 4 is `0100`, 14 is `1110`, 2 is `0010`. The pairs differ in 2, 2 and 2 bits, so the answer is 6.

```python starter
def total_hamming(nums):
    pass
```

```tests
total_hamming([4, 14, 2]) == 6
total_hamming([]) == 0
total_hamming([7]) == 0
total_hamming([5, 5, 5]) == 0
total_hamming([0, 1]) == 1
total_hamming([0, 2**31 - 1]) == 31
total_hamming([1, 2, 3]) == 4
total_hamming(list(range(20000))) == 1452532992
```

```python tests
import random

for _ in range(200):
    nums = [random.randrange(64) for _ in range(random.randint(0, 12))]
    want = sum(bin(a ^ b).count("1") for i, a in enumerate(nums) for b in nums[i + 1:])
    assert total_hamming(nums) == want
```

```python solution
def total_hamming(nums):
    total = 0
    for k in range(31):
        ones = sum(x >> k & 1 for x in nums)
        total += ones * (len(nums) - ones)
    return total
```

## Hints

1. Look at one bit position at a time. A pair differs there when one number has a 1 and the other a 0.
2. If `ones` numbers have a 1 at bit k, then `ones * (n - ones)` pairs differ at bit k.
3. For each `k` in `range(31)`, count `x >> k & 1` over `nums` and add `ones * (len(nums) - ones)` to the total.
