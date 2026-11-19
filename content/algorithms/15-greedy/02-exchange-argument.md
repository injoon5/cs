---
id: exchange-argument
title: The exchange argument
---

Three people wait at one counter. Serving them takes 6, 1 and 3 minutes, one at a time. Each person waits from the start until their own service ends. Which order makes the total wait smallest?

```diagram
grid
col-labels [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
row-labels ["6, 1, 3", "1, 3, 6"]
row [6, 6, 6, 6, 6, 6, 1, 3, 3, 3]
row [1, 3, 3, 3, 6, 6, 6, 6, 6, 6]
highlight 0,5 0,6 0,9 1,0 1,3 1,9
```

Each column is a minute, and each person's wait ends at a highlighted cell. In the first order they wait 6 + 7 + 10 = 23 minutes in all. In the second, 1 + 4 + 10 = 15.

---

Three people have only six orders, so try them all.

```python
from itertools import permutations


def total_wait(order):
    t = total = 0
    for length in order:
        t += length
        total += t
    return total


for order in permutations([6, 1, 3]):
    print(order, total_wait(order))
```

Shortest first wins. The greedy rule is to serve the quickest job next.

---

Trying every order stops working fast: 10 people have 3,628,800 orders. A proof is better. Start with what changes when two neighbors in the line swap places. What does this print?

```python predict
def ends(order):
    t, out = 0, []
    for length in order:
        t += length
        out.append(t)
    return out


print(ends([2, 6, 1, 4]))
print(ends([2, 1, 6, 4]))
```

---

Only one end time moved. The people before the pair are served as before, and the people after it start once both are done, whatever order the two went in.

Say a job of length `a` sits right before a shorter job of length `b`, and everything before them ends at time `T`. Before the swap they end at `T + a` and `T + a + b`. After it, at `T + b` and `T + b + a`. Swapping them lowers the total wait by

- [ ] `a + b`
- [x] `a - b`
- [ ] `b`

---

So any order with a longer job right before a shorter one can be made better by swapping that pair. The only order with no such pair is sorted from shortest to longest, and so that order is the best.

This is the exchange argument, the usual way to prove a greedy choice is safe:

1. Take any best answer.
2. If it differs from the greedy answer, swap something in it to make it more like the greedy one.
3. Show the swap doesn't make it worse.

Keep swapping, and the best answer becomes the greedy one without ever getting worse. So the greedy answer is a best answer too.

---

Where does the swap fail? Say the jobs also have weights, and the goal is the smallest total of weight × end time. Swapping a long job `a` with a short job `b` right after it changes only their two terms. Is shortest first still always best?

- [ ] Yes, the swap still lowers the total by `a - b`
- [x] No, a long job with a large weight can be worth doing first
- [ ] No, with weights the order doesn't matter

Checking the swap tells you which rule is right. One of the exercises asks for it.

---

Here is a second problem. Each child wants a cookie at least as big as their greed, and each child gets at most one cookie. How many children can you make happy?

```diagram
array greed [1, 2, 3]
pointer child 0

array cookies [1, 3]
pointer cookie 0
```

Sort both lists. Take the least greedy child first, and give them the smallest cookie that fits. Here the child with greed 1 gets cookie 1, and the child with greed 2 gets cookie 3: two happy children. Hand cookie 3 to the first child instead, and only one is happy.

---

The exchange argument again. Suppose a best answer gives the least greedy child a cookie `c'` bigger than `c`, the smallest cookie that fits them. Give that child `c` instead, and if some other child had `c`, give them `c'`. Why is the other child still happy?

- [ ] Every child's greed is at most the smallest cookie
- [x] They were happy with `c`, and `c'` is at least as big as `c`
- [ ] They are the least greedy child, so any cookie fits them

Nobody lost a cookie, so the count is the same. If the least greedy child got no cookie at all, give them `c`, taking it from whoever had it: the count can't go down.

---

With n children and m cookies, the sort is the expensive part, and then one pass with two pointers does the rest. The whole thing costs

- [ ] O(n · m)
- [x] O(n log n + m log m)
- [ ] O(n + m)

---

[Hand out cookies](exercises/assign-cookies.md)

[Weighted waiting time](exercises/weighted-wait.md)
