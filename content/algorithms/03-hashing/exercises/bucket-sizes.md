---
id: bucket-sizes
title: Bucket sizes
level: warmup
---

A table has `size` buckets, and each key goes into bucket `key % size`. Return a list with the number of keys in each bucket, repeats included. For keys `[12, 7, 20, 33]` and 8 buckets the answer is `[0, 1, 0, 0, 2, 0, 0, 1]`.

```python starter
def bucket_sizes(keys, size):
    pass
```

```tests
bucket_sizes([12, 7, 20, 33], 8) == [0, 1, 0, 0, 2, 0, 0, 1]
bucket_sizes([], 3) == [0, 0, 0]
bucket_sizes([5], 1) == [1]
bucket_sizes([4, 4, 4], 2) == [3, 0]
bucket_sizes([-1, -2, 3], 4) == [0, 0, 1, 2]
bucket_sizes([0, 10, 20, 30], 10) == [4, 0, 0, 0, 0, 0, 0, 0, 0, 0]
bucket_sizes([1, 2, 3], 5) == [0, 1, 1, 1, 0]
bucket_sizes(list(range(100000)), 10) == [10000] * 10
```

```python solution
def bucket_sizes(keys, size):
    counts = [0] * size
    for key in keys:
        counts[key % size] += 1
    return counts
```

## Hints

1. Start with one counter per bucket, all zero.
2. For each key, work out its bucket and add one to that counter.
3. `counts = [0] * size`, then `counts[key % size] += 1` in the loop. Python's `%` already gives a bucket from 0 to `size - 1` for negative keys.
