---
id: unique-permutations
title: Unique permutations
level: core
---

`nums` may contain repeated values. Return every distinct ordering of `nums`, each once, sorted. For `[1, 1, 2]` there are 3, not 6: `[[1, 1, 2], [1, 2, 1], [2, 1, 1]]`.

Don't generate all n! orderings and remove the repeats afterwards. Skip a repeated choice at the point where you would make it.

```python starter
def unique_permutations(nums):
    pass
```

```tests
unique_permutations([1, 1, 2]) == [[1, 1, 2], [1, 2, 1], [2, 1, 1]]
unique_permutations([1, 2, 3]) == [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
unique_permutations([2, 1]) == [[1, 2], [2, 1]]
unique_permutations([4, 4, 4]) == [[4, 4, 4]]
unique_permutations([7]) == [[7]]
unique_permutations([]) == [[]]
unique_permutations([-1, 0, -1]) == [[-1, -1, 0], [-1, 0, -1], [0, -1, -1]]
len(unique_permutations([1, 1, 2, 2, 3, 3])) == 90
len(unique_permutations([0] * 11 + [1])) == 12
```

```python solution
def unique_permutations(nums):
    nums = sorted(nums)
    out = []
    picked = []
    used = [False] * len(nums)

    def explore():
        if len(picked) == len(nums):
            out.append(picked[:])
            return
        for i, x in enumerate(nums):
            if used[i]:
                continue
            if i > 0 and x == nums[i - 1] and not used[i - 1]:
                continue
            used[i] = True
            picked.append(x)
            explore()
            picked.pop()
            used[i] = False

    explore()
    return out
```

## Hints

1. Sort first, so equal values sit next to each other. The answer then comes out sorted too.
2. Two equal values in the same position give the same orderings. At each level, try each distinct value only once.
3. Skip `nums[i]` when it equals `nums[i - 1]` and `nums[i - 1]` is not in use. That forces equal values to be used left to right.
