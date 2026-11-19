---
id: max-xor-pair
title: Largest xor of a pair
level: stretch
---

Return the largest `nums[i] ^ nums[j]` over all pairs `i < j`, or 0 if `nums` has fewer than 2 numbers. All numbers are 0 or more. Checking every pair is too slow for the last test.

`a ^ b` (xor) has a 1 bit wherever `a` and `b` differ, and `x >> b & 1` is bit `b` of `x`, counting from 0 at the right. For `[3, 10, 5, 25, 2, 8]` the answer is 28, from `5 ^ 25`: `00101 ^ 11001` is `11100`.

```python starter
class TrieNode:
    def __init__(self):
        self.children = {}


def max_xor(nums):
    pass
```

```tests
max_xor([3, 10, 5, 25, 2, 8]) == 28
max_xor([]) == 0
max_xor([7]) == 0
max_xor([0, 0]) == 0
max_xor([5, 5, 5]) == 0
max_xor([1, 2]) == 3
max_xor([8, 1, 2, 12]) == 14
max_xor([0, 2 ** 30]) == 2 ** 30
max_xor([14, 70, 53, 83, 49, 91, 36, 80, 92, 51, 66, 70]) == 127
max_xor([i * 7919 % 100003 for i in range(1, 14001)]) == 131069
```

```python tests
import random

rng = random.Random(9)
for _ in range(300):
    nums = [rng.randint(0, 63) for _ in range(rng.randint(0, 9))]
    want = max((a ^ b for i, a in enumerate(nums) for b in nums[i + 1:]), default=0)
    assert max_xor(nums) == want, nums
```

```python solution
class TrieNode:
    def __init__(self):
        self.children = {}


def max_xor(nums):
    if len(nums) < 2:
        return 0
    bits = max(nums).bit_length()
    root = TrieNode()
    best = 0
    for i, x in enumerate(nums):
        if i > 0:
            node, value = root, 0
            for b in range(bits - 1, -1, -1):
                want = 1 - (x >> b & 1)
                if want in node.children:
                    value |= 1 << b
                    node = node.children[want]
                else:
                    node = node.children[1 - want]
            best = max(best, value)
        node = root
        for b in range(bits - 1, -1, -1):
            bit = x >> b & 1
            if bit not in node.children:
                node.children[bit] = TrieNode()
            node = node.children[bit]
    return best
```

## Hints

1. Store each number in a trie as its bits, highest first, all padded to the same length. Then, for a number `x`, find the stored number that differs from `x` in the highest bits possible.
2. Walking down for `x`, take the child with the opposite bit whenever it exists, and add that bit to the xor. A 1 in a high bit beats all the lower bits together, so this choice is never wrong.
3. Use `bits = max(nums).bit_length()` and go through `nums`: query each number against the trie of the numbers before it, then insert it. At level `b` the bit is `x >> b & 1`, and an opposite child adds `1 << b`.
