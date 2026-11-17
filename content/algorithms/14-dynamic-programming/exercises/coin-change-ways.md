---
id: coin-change-ways
title: Ways to make change
level: core
---

`coins` holds distinct positive coin values, and you have as many of each as you like. Return the number of ways to make exactly `amount`, counting each set of coins once, whatever its order. With coins 1, 2 and 5 there are 4 ways to make 5: 5, 2+2+1, 2+1+1+1 and 1+1+1+1+1.

```python starter
def change_ways(coins, amount):
    pass
```

```tests
change_ways([1, 2, 5], 5) == 4
change_ways([1, 2], 4) == 3
change_ways([2], 3) == 0
change_ways([10], 10) == 1
change_ways([1, 2], 0) == 1
change_ways([], 0) == 1
change_ways([], 3) == 0
change_ways([5, 2, 1], 5) == 4
change_ways([3, 7], 20) == 1
change_ways([1, 2, 5, 10, 20, 50, 100, 200], 200) == 73682
change_ways([1, 2, 5, 10, 20, 50, 100, 200], 1000) == 321335886
```

```python tests
import random
from itertools import combinations_with_replacement


def brute(coins, amount):
    total = 0
    for k in range(amount + 1):
        total += sum(1 for c in combinations_with_replacement(coins, k) if sum(c) == amount)
    return total


for _ in range(150):
    coins = random.sample(range(1, 8), random.randint(1, 3))
    amount = random.randint(0, 12)
    assert change_ways(coins, amount) == brute(coins, amount)
```

```python solution
def change_ways(coins, amount):
    ways = [1] + [0] * amount
    for c in coins:
        for a in range(c, amount + 1):
            ways[a] += ways[a - c]
    return ways[amount]
```

## Hints

1. Looping over amounts on the outside counts 1 + 2 and 2 + 1 as two ways. Which loop order counts each set once?
2. Put the coins on the outside. After the loop for a coin, `ways[a]` counts the sets that use only the coins seen so far.
3. Start with `ways = [1] + [0] * amount`. For each coin `c`, for `a` from `c` up to `amount`, add `ways[a - c]` to `ways[a]`.
