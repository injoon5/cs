---
id: recursion-trees
title: Recursion trees
---

Each Fibonacci number is the sum of the two before it: 0, 1, 1, 2, 3, 5, 8. The definition turns straight into code.

```python
def fib(n):
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)

print(fib(10))
```

This version makes two calls each time, not one. Draw every call as a node, with the calls it makes below it, and you get a recursion tree.

---

The tree for `fib(4)`. The faded part is work already done once on the left.

```diagram
tree
a -> b c
b -> d e
d -> f g
c -> h i
node a "fib(4)"
node b "fib(3)"
node c "fib(2)"
node d "fib(2)"
node e "fib(1)"
node f "fib(1)"
node g "fib(0)"
node h "fib(1)"
node i "fib(0)"
dim c h i
```

`fib(2)` is computed twice. In `fib(5)`, `fib(3)` is computed twice and `fib(2)` three times. The repeats grow with every level.

---

Run this to watch the tree for `fib(4)` grow, call by call. Calls with an `n` already solved are faded.

```python
import viz

class Call:
    def __init__(self, n):
        self.val = f"fib({n})"
        self.children = []

root = Call(4)
solved = set()
repeats = []

def fib(n, node):
    if n in solved:
        repeats.append(node)
    viz.tree(root, active=node, dimmed=repeats)
    if n < 2:
        result = n
    else:
        result = 0
        for k in (n - 1, n - 2):
            child = Call(k)
            node.children.append(child)
            result += fib(k, child)
    solved.add(n)
    return result

print(fib(4, root))
```

---

How many calls does `fib` make? This counts them.

```python predict
calls = 0

def fib(n):
    global calls
    calls += 1
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)

for n in (5, 10, 20):
    calls = 0
    fib(n)
    print(n, calls)
```

---

Each call below the top level makes two more, and the tree is about n levels deep. The naive `fib(n)` takes

- [ ] O(n) time
- [ ] O(n²) time
- [x] O(2ⁿ) time

---

The fix is to remember answers. Keep a dict from `n` to `fib(n)`, and check it before doing the work.

```python
memo = {}

def fib(n):
    if n < 2:
        return n
    if n not in memo:
        memo[n] = fib(n - 1) + fib(n - 2)
    return memo[n]

print(fib(80))
```

Now every faded subtree is a single lookup, and each `n` is computed once: O(n) time. This is memoization. The dynamic programming unit builds on it.

---

Recursion trees also explain why some recursion is fast. To get `x ** 10`, compute `x ** 5` once and square it. Each call halves `n`.

```python trace stop=26
def power(x, n):
    if n == 0:
        return 1
    half = power(x, n // 2)
    if n % 2 == 0:
        return half * half
    return half * half * x

print(power(2, 10))
```

In this frame `n` is 5 and `half` is 4. What does it return?

- [ ] 16
- [ ] 20
- [x] 32

---

`power(x, n)` calls itself once, on `n // 2`. It makes

- [ ] O(n) calls
- [ ] O(√n) calls
- [x] O(log n) calls

---

Splitting a problem into halves, solving each, and combining the answers is called divide and conquer. Summing `[3, 1, 4, 1]` by halves:

```diagram
tree
a -> b c
b -> d e
c -> f g
node a "[3, 1, 4, 1] = 9"
node b "[3, 1] = 4"
node c "[4, 1] = 5"
node d "[3]"
node e "[1]"
node f "[4]"
node g "[1]"
```

Each level of the tree halves the lists, so the tree is only about log₂ n levels deep.

---

Put the lines in order so `half_sum` adds up `nums[lo:hi]` by splitting it in two.

```python arrange
def half_sum(nums, lo, hi):
    if hi - lo == 0:
        return 0
    if hi - lo == 1:
        return nums[lo]
    mid = (lo + hi) // 2
    return half_sum(nums, lo, mid) + half_sum(nums, mid, hi)
```

```tests
half_sum([3, 1, 4, 1], 0, 4) == 9
half_sum([3, 1, 4, 1], 1, 3) == 5
half_sum([7], 0, 1) == 7
half_sum([], 0, 0) == 0
half_sum([-2, 5, -3], 0, 3) == 0
```

---

`half_sum` still visits every number once, so it takes O(n) time. How deep does the call stack get on n numbers?

- [ ] O(1)
- [x] O(log n)
- [ ] O(n)

---

[Largest by halves](exercises/max-by-halves.md)

[Power with a modulus](exercises/power-mod.md)
