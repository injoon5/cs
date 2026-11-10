---
id: count-sum-runs
title: Runs that add up to k
level: stretch
---

Count the runs of items in a row in `nums` that add up to exactly `k`. Numbers can be negative or zero, so a sliding window won't work. In `[1, 2, 3]` with `k = 3` there are 2: `[1, 2]` and `[3]`.

```python starter
def count_sum_runs(nums, k):
    pass
```

```tests
count_sum_runs([1, 2, 3], 3) == 2
count_sum_runs([1, 1, 1], 2) == 2
count_sum_runs([1, -1, 1, -1], 0) == 4
count_sum_runs([0, 0, 0], 0) == 6
count_sum_runs([3, 4, -7, 3], 3) == 3
count_sum_runs([-2, -3, 5], -5) == 1
count_sum_runs([5], 5) == 1
count_sum_runs([5], 4) == 0
count_sum_runs([], 0) == 0
```

```python solution
def count_sum_runs(nums, k):
    seen = {0: 1}
    running = 0
    count = 0
    for x in nums:
        running += x
        count += seen.get(running - k, 0)
        seen[running] = seen.get(running, 0) + 1
    return count
```

## Hints

1. A run from `l` to `r` adds up to `prefix[r + 1] - prefix[l]`. You want that difference to be `k`.
2. Walk left to right with a running total. For each new total, ask how many earlier totals equal `running - k`.
3. Keep a dict of how many times each running total has appeared, starting with `{0: 1}` for the empty start. Add `seen.get(running - k, 0)` before recording `running`.
