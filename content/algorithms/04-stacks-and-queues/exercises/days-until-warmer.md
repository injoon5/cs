---
id: days-until-warmer
title: Days until warmer
level: warmup
---

`temps` holds one temperature per day. For each day, return how many days you wait for a warmer one, or 0 if no warmer day comes. For `[73, 74, 75, 71, 69, 72, 76, 73]` the answer is `[1, 1, 4, 2, 1, 1, 0, 0]`. Day 2 is 75, and the next warmer day is day 6, four days later.

```python starter
def days_until_warmer(temps):
    pass
```

```tests
days_until_warmer([73, 74, 75, 71, 69, 72, 76, 73]) == [1, 1, 4, 2, 1, 1, 0, 0]
days_until_warmer([]) == []
days_until_warmer([50]) == [0]
days_until_warmer([30, 40, 50, 60]) == [1, 1, 1, 0]
days_until_warmer([60, 50, 40, 30]) == [0, 0, 0, 0]
days_until_warmer([70, 70, 71]) == [2, 1, 0]
days_until_warmer([-5, -10, -3]) == [2, 1, 0]
days_until_warmer([5, 5, 5]) == [0, 0, 0]
days_until_warmer(list(range(1000, 0, -1)) + [2000])[0] == 1000
```

```python solution
def days_until_warmer(temps):
    ans = [0] * len(temps)
    stack = []
    for i, t in enumerate(temps):
        while stack and temps[stack[-1]] < t:
            j = stack.pop()
            ans[j] = i - j
        stack.append(i)
    return ans
```

## Hints

1. This is the next bigger number, but the answer is a distance instead of a value.
2. Keep a stack of the days still waiting. A warmer day pops every colder day on top and answers it.
3. Store indexes on the stack. When day `i` pops day `j`, the answer for `j` is `i - j`.
