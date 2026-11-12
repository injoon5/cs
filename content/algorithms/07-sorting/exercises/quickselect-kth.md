---
id: quickselect-kth
title: Kth smallest
level: stretch
---

Return the `k`th smallest number in `nums`, counting from 1, in O(n) expected time. Sorting the whole list is O(n log n), more than needed. For example, the 2nd smallest in `[7, 2, 9, 4]` is 4. `k` is always between 1 and `len(nums)`. You may reorder `nums`.

Partition around a random pivot, then keep only the side that holds position `k - 1`.

```python starter
def kth_smallest(nums, k):
    pass
```

```tests
kth_smallest([7, 2, 9, 4], 2) == 4
kth_smallest([7, 2, 9, 4], 1) == 2
kth_smallest([7, 2, 9, 4], 4) == 9
kth_smallest([5], 1) == 5
kth_smallest([3, 3, 3, 3], 3) == 3
kth_smallest([1, 2, 2, 3], 3) == 2
kth_smallest([-4, 8, -10, 0], 2) == -4
kth_smallest(list(range(1, 100001)), 50000) == 50000
kth_smallest([7] * 50000 + [1], 1) == 1
```

```python tests
import random

rng = random.Random(11)
for _ in range(100):
    xs = [rng.randint(-20, 20) for _ in range(rng.randint(1, 40))]
    k = rng.randint(1, len(xs))
    assert kth_smallest(list(xs), k) == sorted(xs)[k - 1], (xs, k)
```

```python solution
import random

def kth_smallest(nums, k):
    target = k - 1
    lo, hi = 0, len(nums) - 1
    while True:
        r = random.randint(lo, hi)
        pivot = nums[r]
        smaller = [x for x in nums[lo:hi + 1] if x < pivot]
        equal = [x for x in nums[lo:hi + 1] if x == pivot]
        bigger = [x for x in nums[lo:hi + 1] if x > pivot]
        nums[lo:hi + 1] = smaller + equal + bigger
        first = lo + len(smaller)
        last = first + len(equal) - 1
        if target < first:
            hi = first - 1
        elif target > last:
            lo = last + 1
        else:
            return pivot
```

## Hints

1. After partitioning, the pivot is at its sorted position `p`. If `p` is `k - 1`, it is the answer. Otherwise the answer is on one side only.
2. Unlike quicksort, follow only one side, so the work shrinks like n + n/2 + n/4 and adds up to O(n) on average. Pick the pivot at random so a sorted list isn't slow.
3. Split the range into smaller, equal and bigger than the pivot, so a list of equal numbers ends at once. If `k - 1` falls in the equal block, return the pivot; otherwise narrow `lo` and `hi` to the side that holds it.
