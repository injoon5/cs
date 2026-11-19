---
id: assign-cookies
title: Hand out cookies
level: warmup
---

`greed[i]` is the smallest cookie that makes child `i` happy, and `cookies[j]` is the size of cookie `j`. Each child gets at most one cookie, and each cookie goes to at most one child. Return the most children you can make happy.

For `greed = [1, 2, 3]` and `cookies = [1, 3]` the answer is 2: cookie 1 to the first child, cookie 3 to the second.

```python starter
def happy_children(greed, cookies):
    pass
```

```tests
happy_children([1, 2, 3], [1, 3]) == 2
happy_children([1, 2], [1, 2, 3]) == 2
happy_children([1, 2, 3], [1, 1]) == 1
happy_children([], [1, 2]) == 0
happy_children([1, 2], []) == 0
happy_children([5], [4]) == 0
happy_children([2, 2, 2], [2, 2]) == 2
happy_children([3, 1, 2], [2, 3, 1]) == 3
happy_children([10, 1], [3, 9, 1]) == 1
happy_children(list(range(1, 100001)), list(range(100000, 0, -1))) == 100000
happy_children(list(range(50001, 100001)), list(range(100000, 0, -1))) == 50000
```

```python tests
import random


def slow(greed, cookies):
    def go(i, used):
        if i == len(greed):
            return 0
        best = go(i + 1, used)
        for j, c in enumerate(cookies):
            if j not in used and c >= greed[i]:
                best = max(best, 1 + go(i + 1, used | {j}))
        return best
    return go(0, frozenset())


for _ in range(300):
    greed = [random.randint(1, 6) for _ in range(random.randint(0, 5))]
    cookies = [random.randint(1, 6) for _ in range(random.randint(0, 5))]
    assert happy_children(greed, cookies) == slow(greed, cookies), (greed, cookies)
```

```python solution
def happy_children(greed, cookies):
    greed = sorted(greed)
    cookies = sorted(cookies)
    child = 0
    for cookie in cookies:
        if child < len(greed) and cookie >= greed[child]:
            child += 1
    return child
```

## Hints

1. Deal with the least greedy child first. They are the easiest to please.
2. Sort both lists. The least greedy child should get the smallest cookie that fits them, so bigger cookies are left for greedier children.
3. Walk the sorted cookies with one pointer `child` into the sorted greed list. A cookie that fits `greed[child]` makes that child happy, so move `child` on. A cookie that doesn't fit is too small for everyone left, so skip it.
