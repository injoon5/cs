---
id: fewest-coins
title: Fewest coins
level: core
---

`coins` holds the coin values, all positive, and you have as many of each as you like. Return the fewest coins that add up to exactly `amount`, or -1 if no mix of coins does. With coins 1, 3 and 4, the amount 6 takes 2 coins: 3 + 3.

```python starter
def fewest_coins(coins, amount):
    pass
```

```tests
fewest_coins([1, 3, 4], 6) == 2
fewest_coins([1, 5, 10, 25], 63) == 6
fewest_coins([7, 3], 20) == 4
fewest_coins([2], 3) == -1
fewest_coins([5, 10], 3) == -1
fewest_coins([1], 0) == 0
fewest_coins([], 0) == 0
fewest_coins([], 5) == -1
fewest_coins([4, 4, 2], 8) == 2
fewest_coins([186, 419, 83, 408], 6249) == 20
fewest_coins([1, 2, 5], 10000) == 2000
```

```python tests
import random
from itertools import combinations_with_replacement


def brute(coins, amount):
    for k in range(amount + 1):
        if any(sum(c) == amount for c in combinations_with_replacement(coins, k)):
            return k
    return -1


for _ in range(150):
    coins = random.sample(range(1, 10), random.randint(1, 3))
    amount = random.randint(0, 14)
    assert fewest_coins(coins, amount) == brute(coins, amount)
```

```python solution
def fewest_coins(coins, amount):
    inf = float("inf")
    fewest = [0] + [inf] * amount
    for a in range(1, amount + 1):
        for c in coins:
            if c <= a:
                fewest[a] = min(fewest[a], fewest[a - c] + 1)
    return -1 if fewest[amount] == inf else fewest[amount]
```

## Hints

1. Taking the biggest coin first can use too many coins. Think about the last coin instead: it is one of the coin values.
2. `fewest[a]` is 1 plus the smallest `fewest[a - c]` over coins `c <= a`, with `fewest[0] = 0`. Fill it for every amount from 1 up.
3. Start every other entry at `float("inf")` so amounts that can't be made never win a `min`, and turn infinity into -1 at the end.
