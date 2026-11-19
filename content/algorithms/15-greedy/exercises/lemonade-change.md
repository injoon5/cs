---
id: lemonade-change
title: Lemonade change
level: warmup
---

A lemonade costs 5. Customers come one at a time and each pays with a single bill of 5, 10 or 20. You start with no money and must give each customer their change right away, from the bills you've taken so far. Return `True` if every customer gets the right change.

For `[5, 5, 10, 20]`: keep two 5s, give one back for the 10, then give the 10 and the last 5 back for the 20. The answer is `True`.

```python starter
def can_give_change(bills):
    pass
```

```tests
can_give_change([5, 5, 10, 20]) == True
can_give_change([5, 5, 10, 10, 20]) == False
can_give_change([]) == True
can_give_change([5]) == True
can_give_change([10]) == False
can_give_change([20]) == False
can_give_change([5, 20]) == False
can_give_change([5, 5, 5, 20]) == True
can_give_change([5, 5, 5, 5, 10, 20, 10]) == True
can_give_change([5, 10, 5, 20, 5, 5, 5, 20, 5, 10]) == True
can_give_change([5, 10, 5, 20, 5, 5, 5, 20, 10]) == False
```

```python tests
import random
from functools import cache


def slow(bills):
    @cache
    def go(i, fives, tens):
        if i == len(bills):
            return True
        b = bills[i]
        if b == 5:
            return go(i + 1, fives + 1, tens)
        if b == 10:
            return fives > 0 and go(i + 1, fives - 1, tens + 1)
        options = []
        if tens and fives:
            options.append((fives - 1, tens - 1))
        if fives >= 3:
            options.append((fives - 3, tens))
        return any(go(i + 1, f, t) for f, t in options)
    return go(0, 0, 0)


for _ in range(500):
    bills = random.choices([5, 5, 10, 20], k=random.randint(0, 12))
    assert can_give_change(bills) == slow(bills), bills
```

```python solution
def can_give_change(bills):
    fives = tens = 0
    for bill in bills:
        if bill == 5:
            fives += 1
        elif bill == 10:
            if fives == 0:
                return False
            fives -= 1
            tens += 1
        elif tens and fives:
            tens -= 1
            fives -= 1
        elif fives >= 3:
            fives -= 3
        else:
            return False
    return True
```

## Hints

1. Only the 5s and 10s you hold matter. Count them.
2. A 10 needs one 5 back. A 20 needs 15 back, as a 10 and a 5 or as three 5s.
3. For a 20, use a 10 and a 5 when you can. A 5 can pay change for a 10 or a 20, but a 10 can only help with a 20, so keep the 5s.
