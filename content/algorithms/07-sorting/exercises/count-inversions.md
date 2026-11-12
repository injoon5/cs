---
id: count-inversions
title: Count inversions
level: stretch
---

An inversion is a pair of indexes `i < j` with `nums[i] > nums[j]`. Return how many inversions `nums` has, in O(n log n) time. For example, `[3, 1, 2]` has 2: `(3, 1)` and `(3, 2)`. Checking every pair is too slow for the last test.

```python starter
def count_inversions(nums):
    pass
```

```tests
count_inversions([3, 1, 2]) == 2
count_inversions([1, 2, 3, 4]) == 0
count_inversions([4, 3, 2, 1]) == 6
count_inversions([2, 2, 1]) == 2
count_inversions([5, 5, 5]) == 0
count_inversions([7]) == 0
count_inversions([]) == 0
count_inversions([-1, -3, 2, -2]) == 3
count_inversions(list(range(20000, 0, -1))) == 199990000
```

```python tests
import random

rng = random.Random(7)
for _ in range(50):
    xs = [rng.randint(-5, 5) for _ in range(rng.randint(0, 30))]
    want = sum(1 for i in range(len(xs)) for j in range(i + 1, len(xs)) if xs[i] > xs[j])
    assert count_inversions(xs) == want, xs
```

```python solution
def count_inversions(nums):
    def sort(a):
        if len(a) <= 1:
            return a, 0
        mid = len(a) // 2
        left, x = sort(a[:mid])
        right, y = sort(a[mid:])
        out = []
        count = x + y
        i = j = 0
        while i < len(left) and j < len(right):
            if left[i] <= right[j]:
                out.append(left[i])
                i += 1
            else:
                out.append(right[j])
                j += 1
                count += len(left) - i
        out.extend(left[i:])
        out.extend(right[j:])
        return out, count

    return sort(nums)[1]
```

## Hints

1. Split the list in half. Every inversion is inside the left half, inside the right half, or has one item on each side.
2. Count the cross pairs while merging. When `right[j]` is taken before `left[i]`, it is smaller than `left[i]` and everything after it in `left`.
3. Have merge sort return `(sorted list, count)`. On taking from the right, add `len(left) - i`. Take from the left on a tie, so equal items don't count.
