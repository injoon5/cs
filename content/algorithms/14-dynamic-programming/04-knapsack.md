---
id: knapsack
title: The 0/1 knapsack
---

A bag holds 7 kilos. Each item has a weight and a value, and you take each one at most once. What is the most value that fits?

```diagram
grid items
row-labels [weight, value]
row [1, 3, 4, 5]
row [1, 4, 5, 7]
highlight 0,1 0,2 1,1 1,2
```

Going by value per kilo, you take the 5-kilo item first, worth 7, then the 1-kilo item: 8 in all. The 3 and the 4 fill the bag exactly and are worth 9. The greedy choice fails, and trying every subset of n items costs O(2ⁿ).

---

The state is `best[i][w]`, the most value from the first `i` items with room for `w` kilos. For item `i - 1`, with weight `wt` and value `val`:

- skip it: `best[i - 1][w]`
- take it, if `wt <= w`: `best[i - 1][w - wt] + val`

Taking it reads the row above, where this item isn't available yet. That is what keeps each item to one use.

---

The full table. Each row adds one item, labeled by its weight and value, and column `w` is the room in the bag. The highlighted cell takes the 4-kilo item: 5 plus the best for 3 kilos without it, which is 4.

```diagram
grid best
col-labels [0, 1, 2, 3, 4, 5, 6, 7]
row-labels [none, "1, 1", "3, 4", "4, 5", "5, 7"]
row [0, 0, 0, 0, 0, 0, 0, 0]
row [0, 1, 1, 1, 1, 1, 1, 1]
row [0, 1, 1, 4, 5, 5, 5, 5]
row [0, 1, 1, 4, 5, 6, 6, 9]
row [0, 1, 1, 4, 5, 7, 8, 9]
highlight 3,7
arrow 3,7 -> 2,7
arrow 3,7 -> 2,3
```

---

In code, each row is built from a copy of the row before.

```python
items = [(1, 1), (3, 4), (4, 5), (5, 7)]
cap = 7
best = [[0] * (cap + 1)]
for wt, val in items:
    prev = best[-1]
    row = prev[:]
    for w in range(wt, cap + 1):
        row[w] = max(prev[w], prev[w - wt] + val)
    best.append(row)
print(best[-1][cap])
```

---

Each row reads only the row above, so one list can do the work of the whole table, updated in place. But the direction of the loop matters. Here is one item, weight 2 and value 3, and a bag of 4. What does this print?

```python predict
wt, val, cap = 2, 3, 4

up = [0] * (cap + 1)
for w in range(wt, cap + 1):
    up[w] = max(up[w], up[w - wt] + val)

down = [0] * (cap + 1)
for w in range(cap, wt - 1, -1):
    down[w] = max(down[w], down[w - wt] + val)

print(up)
print(down)
```

---

`up` claims 6 for a bag of 4: the one item, taken twice. Why does going down keep each item to one use?

- [x] `w - wt` is below `w`, so going down, the entry at `w - wt` hasn't been updated for this item yet
- [ ] Bigger capacities matter more, so they have to come first
- [ ] Going up skips some capacities, and going down visits them all

---

Going up is exactly right when items can be reused, the unbounded knapsack. The coin loops in the tabulation lesson ran upward for that reason: a coin can be used again.

---

Here is the 0/1 version with one list, on two items.

```python trace stop=16
items = [(2, 3), (3, 4)]
cap = 5
best = [0] * (cap + 1)
for wt, val in items:
    for w in range(cap, wt - 1, -1):
        best[w] = max(best[w], best[w - wt] + val)
print(best)
```

The first item is done, and the second, weight 3 and value 4, is at `w = 5`. What will `best[5]` be?

- [ ] 3, the first item alone
- [ ] 4, the second item alone
- [x] 7, both items

---

A table with n items and a capacity of W costs O(n · W). That is called pseudo-polynomial. Why?

- [ ] It is polynomial only when n is small
- [x] W is a number in the input, not a count of things: one more digit in W makes the table 10 times bigger
- [ ] The space is polynomial, but the time is not

---

Drop the values and the same loop answers a yes-or-no question: can some of the numbers add up to exactly `target`? `reach[s]` is `True` when some subset sums to `s`.

Put the lines in order so `can_sum` answers it, using each number at most once.

```python arrange
def can_sum(nums, target):
    reach = [True] + [False] * target
    for x in nums:
        for s in range(target, x - 1, -1):
            if reach[s - x]:
                reach[s] = True
    return reach[target]
```

```tests
can_sum([3, 34, 4, 12, 5, 2], 9) == True
can_sum([3, 34, 4, 12, 5, 2], 30) == False
can_sum([4], 8) == False
can_sum([2, 2], 4) == True
can_sum([5], 3) == False
can_sum([], 0) == True
```

---

[Pack the knapsack](exercises/knapsack-01.md)

[Split into equal sums](exercises/equal-subset-split.md)
