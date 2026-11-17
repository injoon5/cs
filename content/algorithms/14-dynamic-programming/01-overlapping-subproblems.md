---
id: overlapping-subproblems
title: Overlapping subproblems
---

You climb a staircase one or two stairs at a time. How many ways are there to climb 4 stairs?

There are five: 1+1+1+1, 1+1+2, 1+2+1, 2+1+1 and 2+2. Instead of listing them, look at the last move. It climbs one stair or two, so every way to climb 4 is a way to climb 3 plus a final 1, or a way to climb 2 plus a final 2.

```python
def ways(n):
    if n <= 1:
        return 1
    return ways(n - 1) + ways(n - 2)


print(ways(4), ways(10))
```

`ways(0)` is 1: there is one way to climb no stairs, which is to stay put.

---

This is the Fibonacci recursion with a new name, and it has the same problem. The code counts the calls, and how many different `n` they were for. What does it print?

```python predict
calls = 0
asked = set()


def ways(n):
    global calls
    calls += 1
    asked.add(n)
    if n <= 1:
        return 1
    return ways(n - 1) + ways(n - 2)


for n in (10, 20):
    calls = 0
    asked = set()
    ways(n)
    print(n, calls, len(asked))
```

---

Twenty-one different questions, asked 21,891 times. When a recursion keeps asking the same smaller questions, the problem has overlapping subproblems.

Merge every repeated call into one and the call tree collapses into a row, one cell per `n`:

```diagram
grid ways
col-labels [0, 1, 2, 3, 4, 5, 6]
row [1, 1, 2, 3, 5, 8, 13]
highlight 0,6
arrow 0,6 -> 0,5
arrow 0,6 -> 0,4
```

Each cell needs only the two to its left. Dynamic programming means working out each cell once and reusing it.

---

The recursion unit fixed Fibonacci with a dict of answers, a memo. The same fix works here.

```python trace stop=34
memo = {}


def ways(n):
    if n <= 1:
        return 1
    if n not in memo:
        memo[n] = ways(n - 1) + ways(n - 2)
    return memo[n]


print(ways(4))
```

`ways(4)` has asked for `ways(2)` a second time. What happens next?

- [ ] It calls `ways(1)` and `ways(0)` again
- [x] It finds 2 in `memo` and returns `memo[2]`
- [ ] It returns 1, since 2 is a base case

---

`functools.cache` does the bookkeeping for you. It wraps the function with a dict keyed by the arguments, so the code reads like the plain recursion.

```python
from functools import cache


@cache
def ways(n):
    if n <= 1:
        return 1
    return ways(n - 1) + ways(n - 2)


print(ways(80))
```

The arguments become dict keys, so they must be hashable: pass a tuple or a string, not a list.

---

Every dynamic programming solution names three things:

- The state: what one subproblem is. Here it is `n`, the number of stairs to climb.
- The transition: how a state's answer comes from smaller states. Here `ways(n) = ways(n - 1) + ways(n - 2)`.
- The base cases: states answered directly. Here `ways(0)` and `ways(1)` are 1.

A state is good when its answer depends only on the state, not on how you got there. Then one stored answer serves every caller.

---

A new problem. Climbing up from stair `i` costs `cost[i]`. You start on stair 0 or stair 1 for free, climb one or two stairs at a time, and finish at the top, one past the last stair.

The state is `best(i)`, the cheapest way to reach stair `i`. You arrive from `i - 1` or from `i - 2`, and pay for the stair you left. What does this print?

```python predict
from functools import cache

cost = [10, 15, 20]


@cache
def best(i):
    if i <= 1:
        return 0
    one = best(i - 1) + cost[i - 1]
    two = best(i - 2) + cost[i - 2]
    return min(one, two)


print(best(len(cost)))
```

---

Put the lines in order so `min_cost` returns the cheapest climb for any list of costs.

```python arrange
from functools import cache


def min_cost(cost):
    @cache
    def best(i):
        if i <= 1:
            return 0
        one = best(i - 1) + cost[i - 1]
        two = best(i - 2) + cost[i - 2]
        return min(one, two)

    return best(len(cost))
```

```tests
min_cost([10, 15, 20]) == 15
min_cost([1, 100, 1, 1, 1, 100, 1, 1, 100, 1]) == 6
min_cost([3, 2]) == 2
min_cost([5]) == 0
min_cost([]) == 0
```

---

Memoizing merge sort's recursion would not make it any faster. Why?

- [ ] Lists can't be dict keys, so there is nothing to cache
- [x] Its subproblems are different parts of the list, and none is asked for twice
- [ ] The recursion is only O(log n) deep, so there are too few calls to save

---

With a memo, each state is worked out once. So a memoized function costs the number of states times the work done in each one.

A memoized function has `n · m` states, and each one tries `m` options. It runs in

- [ ] O(n · m)
- [x] O(n · m²)
- [ ] O(2ⁿ)

---

A memo keeps the recursion, and with it the depth. `ways(5000)` waits on `ways(4999)`, which waits on `ways(4998)`, thousands of frames deep.

```python
from functools import cache


@cache
def ways(n):
    if n <= 1:
        return 1
    return ways(n - 1) + ways(n - 2)


try:
    ways(5000)
except RecursionError:
    print("too deep")
```

The next lesson fills the answers in with a loop, smallest first, and the depth goes away.

---

[Stairs with any step sizes](exercises/stair-step-ways.md)

[Count decodings](exercises/count-decodings.md)
