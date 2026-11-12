---
id: last-one-standing
title: Last one standing
level: core
---

People numbered `1` to `n` stand in a circle. Counting starts at person 1, and every `k`-th person leaves. Counting goes on from the next person. Return the number of the last person left. With `n = 5` and `k = 2`, people leave in the order 2, 4, 1, 5, so the answer is 3.

```python starter
def last_one_standing(n, k):
    pass
```

```tests
last_one_standing(5, 2) == 3
last_one_standing(1, 1) == 1
last_one_standing(1, 3) == 1
last_one_standing(5, 1) == 5
last_one_standing(2, 2) == 1
last_one_standing(6, 3) == 1
last_one_standing(7, 3) == 4
last_one_standing(3, 7) == 3
last_one_standing(1000, 2) == 977
```

```python solution
from collections import deque

def last_one_standing(n, k):
    circle = deque(range(1, n + 1))
    while len(circle) > 1:
        for _ in range(k - 1):
            circle.append(circle.popleft())
        circle.popleft()
    return circle[0]
```

## Hints

1. A circle is a queue where people who are skipped go to the back.
2. Put `1..n` in a deque. Move `k - 1` people from the front to the back, then remove the front person.
3. Loop while `len(circle) > 1`: `circle.append(circle.popleft())` `k - 1` times, then one more `popleft()`. Return `circle[0]`.
