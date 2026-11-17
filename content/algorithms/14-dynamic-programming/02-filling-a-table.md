---
id: filling-a-table
title: Filling a table
---

A memo starts from the big question and recurses down to the small ones. Tabulation goes the other way: answer the smallest states first, in a loop, and store them in a list. By the time you reach a state, everything it needs is already there.

```python
n = 10
ways = [0] * (n + 1)
ways[0] = ways[1] = 1
for i in range(2, n + 1):
    ways[i] = ways[i - 1] + ways[i - 2]
print(ways)
```

No recursion, so no depth limit. The one rule is the order: fill each state after the states it reads. Here those are to its left, so the loop runs left to right.

---

Each house on this street holds some money. A thief can't rob two neighbors, or the alarm goes off. What is the most the thief can take?

```diagram
array houses [2, 7, 9, 3, 1]
highlight 0 2 4
```

Robbing 2, 9 and 1 gives 12, the best here. Robbing every other house isn't always best: in `[2, 1, 1, 2]` the best is the two ends, 4.

The state is `best[i]`, the most from the first `i` houses. The last of those is house `i - 1`. Either skip it and keep `best[i - 1]`, or rob it, which rules out its neighbor: `best[i - 2] + houses[i - 1]`.

---

```python trace stop=15
houses = [2, 7, 9, 3, 1]
best = [0] * (len(houses) + 1)
best[1] = houses[0]
for i in range(2, len(best)):
    skip = best[i - 1]
    take = best[i - 2] + houses[i - 1]
    best[i] = max(skip, take)
print(best[-1])
```

The loop is on `i = 4`, deciding about the house with 3. What will `best[4]` be?

- [ ] 10, robbing it
- [x] 11, skipping it
- [ ] 14, robbing it on top of `best[3]`

---

Each step reads only the last two entries. Keep those in two variables instead of a list, and the space drops from O(n) to O(1). Here `prev` and `cur` play `best[i - 1]` and `best[i]`. What does this print?

```python predict
houses = [2, 7, 9, 3, 1]
prev, cur = 0, 0
for h in houses:
    prev, cur = cur, max(cur, prev + h)
    print(prev, cur)
```

---

Coins come in 1, 3 and 4. What is the smallest number of coins that makes 6? Taking the biggest coin first gives 4 + 1 + 1, three coins, but 3 + 3 needs only two.

The state is `fewest[a]`, the fewest coins that make the amount `a`. The last coin is one of the three, so `fewest[a]` is 1 plus the smallest `fewest[a - c]` over the coins `c` that fit.

```diagram
grid fewest
col-labels [0, 1, 2, 3, 4, 5, 6]
row [0, 1, 2, 1, 1, 2, 2]
highlight 0,6
arrow 0,6 -> 0,5
arrow 0,6 -> 0,3
arrow 0,6 -> 0,2
```

---

Amounts no coins can make stay at infinity. Infinity plus one is still infinity, so they never win a `min`.

```python
def fewest_coins(coins, amount):
    inf = float("inf")
    fewest = [0] + [inf] * amount
    for a in range(1, amount + 1):
        for c in coins:
            if c <= a:
                fewest[a] = min(fewest[a], fewest[a - c] + 1)
    return fewest[amount]


print(fewest_coins([1, 3, 4], 6))
print(fewest_coins([5, 10], 3))
```

---

With k kinds of coin and an amount A, `fewest_coins` takes

- [ ] O(A) time and O(A) space
- [x] O(A · k) time and O(A) space
- [ ] O(kᴬ) time and O(A) space

---

Now count the ways to make an amount. 1 + 1 + 2 and 2 + 1 + 1 are the same coins, so they count once: from coins 1 and 2 there are 3 ways to make 4.

These two loops differ only in which one is outside. What do they print?

```python predict
coins, amount = [1, 2], 4

a_first = [1] + [0] * amount
for a in range(1, amount + 1):
    for c in coins:
        if c <= a:
            a_first[a] += a_first[a - c]

c_first = [1] + [0] * amount
for c in coins:
    for a in range(c, amount + 1):
        c_first[a] += c_first[a - c]

print(a_first[amount], c_first[amount])
```

---

`a_first` counts 2 + 1 + 1, 1 + 2 + 1 and 1 + 1 + 2 as three ways: it is the stairs problem, counting orders. Why does `c_first` count each set of coins once?

- [x] It adds one kind of coin at a time, so every set is built with its 1s first and its 2s after: one order per set
- [ ] It skips amounts smaller than the coin, so it can't count a set twice
- [ ] It counts every order too, but the orders cancel out in the sum

---

[House robber](exercises/rob-houses.md)

[Fewest coins](exercises/fewest-coins.md)

[Ways to make change](exercises/coin-change-ways.md)

[Split into words](exercises/split-into-words.md)
