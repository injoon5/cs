---
id: top-k-frequent
title: Most frequent items
level: core
---

Return the `k` items that appear most often in `items`, most frequent first. When two items have the same count, the one that appears first in `items` comes first. If there are fewer than `k` different items, return them all. For `[1, 1, 1, 2, 2, 3]` and `k = 2` the answer is `[1, 2]`.

```python starter
def top_k(items, k):
    pass
```

```tests
top_k([1, 1, 1, 2, 2, 3], 2) == [1, 2]
top_k([], 3) == []
top_k(["a"], 1) == ["a"]
top_k([4, 4, 5, 5, 6], 2) == [4, 5]
top_k([3, 1, 2], 5) == [3, 1, 2]
top_k([2, 1, 1, 2, 3, 3, 3], 1) == [3]
top_k([-1, -1, 0], 1) == [-1]
top_k([5, 6, 6, 5, 7], 3) == [5, 6, 7]
top_k([1, 2, 2], 0) == []
top_k([i % 100 for i in range(100000)] + [42], 2) == [42, 0]
```

```python solution
from collections import Counter


def top_k(items, k):
    counts = Counter(items)
    return [x for x, _ in counts.most_common(k)]
```

## Hints

1. Count every item first. Then the question is only about ordering the counts.
2. A `Counter` keeps items in the order they first appeared, and `most_common` keeps that order for ties.
3. `[x for x, _ in Counter(items).most_common(k)]`. Without `Counter`, sort the dict's keys by `-counts[x]`; Python's sort is stable, so ties keep first-seen order.
