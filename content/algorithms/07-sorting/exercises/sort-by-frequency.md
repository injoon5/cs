---
id: sort-by-frequency
title: Sort by frequency
level: core
---

Return the numbers in `nums` reordered so that numbers that appear more often come first, with all copies of a number together. When two numbers appear equally often, the smaller one comes first. For example, in `[4, 1, 4, 2, 2, 4]`, 4 appears 3 times, 2 twice and 1 once, so the answer is `[4, 4, 4, 2, 2, 1]`.

```python starter
def sort_by_frequency(nums):
    pass
```

```tests
sort_by_frequency([4, 1, 4, 2, 2, 4]) == [4, 4, 4, 2, 2, 1]
sort_by_frequency([3, 1, 2]) == [1, 2, 3]
sort_by_frequency([5, 5, 1, 1]) == [1, 1, 5, 5]
sort_by_frequency([2, 3, 2, 3, 3]) == [3, 3, 3, 2, 2]
sort_by_frequency([-1, -1, 0, 7]) == [-1, -1, 0, 7]
sort_by_frequency([9]) == [9]
sort_by_frequency([]) == []
sort_by_frequency([i % 3 for i in range(30000)] + [2]) == [2] * 10001 + [0] * 10000 + [1] * 10000
```

```python solution
from collections import Counter

def sort_by_frequency(nums):
    counts = Counter(nums)
    return sorted(nums, key=lambda x: (-counts[x], x))
```

## Hints

1. Count each number first. Then the order depends on two things: its count and its value.
2. Use a `Counter`, then sort with a tuple key. More frequent should come first, so flip the count.
3. `sorted(nums, key=lambda x: (-counts[x], x))` keeps copies together, because equal numbers have equal keys.
