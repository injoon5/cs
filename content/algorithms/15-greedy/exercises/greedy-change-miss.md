---
id: greedy-change-miss
title: Where greedy change fails
level: stretch
---

Greedy change takes the biggest coin that fits, again and again. `coins` lists the coin values, in any order, and always includes 1. Return the smallest amount from 1 to `limit` where greedy change uses more coins than the fewest possible, or -1 if greedy is right for every amount up to `limit`.

For `coins = [1, 3, 4]` and `limit = 10` the answer is 6: greedy pays 4 + 1 + 1, but 3 + 3 needs only two coins.

```python starter
def first_greedy_miss(coins, limit):
    pass
```

```tests
first_greedy_miss([1, 3, 4], 10) == 6
first_greedy_miss([1, 3, 4], 5) == -1
first_greedy_miss([4, 1, 3], 10) == 6
first_greedy_miss([1, 5, 10, 25], 500) == -1
first_greedy_miss([1, 6, 10], 100) == 12
first_greedy_miss([1, 7, 10], 100) == 14
first_greedy_miss([1], 50) == -1
first_greedy_miss([1, 2], 50) == -1
first_greedy_miss([1, 15, 25], 100) == 30
first_greedy_miss([1, 5, 10, 25, 50, 100], 100000) == -1
```

```python tests
import random


def slow(coins, limit):
    for amount in range(1, limit + 1):
        greedy, left = 0, amount
        for c in sorted(coins, reverse=True):
            greedy += left // c
            left %= c
        best = [0] + [amount + 1] * amount
        for a in range(1, amount + 1):
            best[a] = min(best[a - c] + 1 for c in coins if c <= a)
        if greedy > best[amount]:
            return amount
    return -1


for _ in range(100):
    coins = [1] + random.sample(range(2, 20), random.randint(0, 3))
    random.shuffle(coins)
    limit = random.randint(1, 40)
    assert first_greedy_miss(coins, limit) == slow(coins, limit), (coins, limit)
```

```python solution
def first_greedy_miss(coins, limit):
    coins = sorted(coins, reverse=True)
    fewest = [0] * (limit + 1)
    for a in range(1, limit + 1):
        fewest[a] = 1 + min(fewest[a - c] for c in coins if c <= a)
        greedy, left = 0, a
        for c in coins:
            greedy += left // c
            left %= c
        if greedy > fewest[a]:
            return a
    return -1
```

## Hints

1. You need two counts for every amount: what greedy uses, and the true fewest. The fewest comes from the coin DP in the dynamic programming unit.
2. Fill `fewest[a]` for amounts from 1 up. The coin 1 means every amount can be made, so no infinity is needed.
3. For each amount, greedy's count is the sum of `left // c` over the coins from biggest to smallest, with `left %= c` after each. Return the first amount where it is more than `fewest[a]`.
