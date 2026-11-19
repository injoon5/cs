---
id: greedy-choices
title: Greedy choices
---

A shop owes you 63 cents, in coins of 25, 10, 5 and 1. Most people count it out without thinking: take the biggest coin that fits, keep taking it while it still fits, then move on to the next coin down.

```python trace stop=13
coins = [25, 10, 5, 1]
left = 63
used = []
for c in coins:
    while c <= left:
        used.append(c)
        left -= c
print(used)
```

The loop has moved on to the 10. What is `left`?

- [ ] 38
- [x] 13
- [ ] 3

---

That is a greedy algorithm. It builds the answer one choice at a time, takes the choice that looks best right now, and never takes it back. There is no table of subproblems and no trying the other options.

Here it is as a function. What does this print?

```python predict
def greedy_change(coins, amount):
    used = []
    for c in sorted(coins, reverse=True):
        while c <= amount:
            used.append(c)
            amount -= c
    return used


print(greedy_change([25, 10, 5, 1], 63))
print(greedy_change([4, 3, 1], 6))
```

---

You met coins of 4, 3 and 1 in the dynamic programming unit: 3 + 3 makes 6 with two coins. The greedy choice took the 4 first, and nothing it did later could undo that.

Coins come in 1, 6 and 10. For which amount does greedy change use more coins than it needs?

- [ ] 11
- [x] 12
- [ ] 16
- [ ] 20

Greedy pays 12 as 10 + 1 + 1. Two 6s do it with two coins.

---

So greedy is right for some coins and wrong for others. The question is always the same: is the greedy choice safe? A choice is safe when some best answer makes it too. Then taking it loses nothing, and what's left is the same problem with a smaller amount.

For 25, 10, 5 and 1, look at what a best answer can't contain. Five 1s can be one 5. Two 5s can be one 10. Three 10s can be a 25 and a 5, and two 10s with a 5 can be a 25. Every swap uses fewer coins.

So in a best answer, the coins under 25 add up to at most 24: two 10s and four 1s.

---

Why does that make the 25 safe whenever 25 or more is left?

- [ ] The 25 is the biggest coin, and the biggest coin is always best
- [x] Without a 25 the other coins can't reach the amount, so every best answer uses one
- [ ] Greedy tries the 25 first and puts it back if the rest doesn't work

The same check works for 10 (the coins under it add up to at most 9) and for 5. With 1, 3 and 4 it breaks: a best answer can hold two 3s, which add up to more than 4, so nothing forces a 4.

---

The knapsack lesson had another greedy that failed. Packing by value per kilo got 8 out of a 7-kilo bag when 9 was possible.

Change one rule: you may take part of an item, like flour or gold dust. Now value per kilo is exactly right. Fill the bag from the best value per kilo down, and cut the last item to fit.

```python
items = [(1, 1), (3, 4), (4, 5), (5, 7)]  # (weight, value)
room = 7
total = 0
for wt, val in sorted(items, key=lambda it: it[1] / it[0], reverse=True):
    take = min(wt, room)
    total += val * take / wt
    room -= take
print(round(total, 2))
```

All 5 kilos of the best item, then 2 of the 3 kilos of the next: 7 + 8/3.

---

Why does going by value per kilo fail for the 0/1 knapsack, when items can't be split?

- [ ] Value per kilo is the wrong measure; going by value alone works
- [x] The best item can leave room that only worse items fit, and they can't be cut to size
- [ ] Greedy needs the items sorted by weight first

With splitting, every kilo in the bag is the best kilo still available. Trading any kilo for a kilo of a better item can only add value, so nothing beats the greedy bag.

---

Dynamic programming tries every option for the next choice and keeps the best. Greedy tries one. When that one is safe, the others never need to be looked at, and most greedy algorithms come down to a sort and one pass: O(n log n) time.

The catch is that a wrong greedy looks just as convincing as a right one. Your greedy passes 20 tests you made by hand. What should you do next?

- [ ] Nothing: 20 passing tests show it's right
- [ ] Run it on one very large input
- [x] Compare it with a brute force on thousands of small random inputs, or prove the choice is safe

A counterexample like 12 with coins 1, 6 and 10 is easy to miss by hand and quick for a brute force to find. The next lesson shows how to prove a choice is safe.

---

[Lemonade change](exercises/lemonade-change.md)

[Where greedy change fails](exercises/greedy-change-miss.md)
