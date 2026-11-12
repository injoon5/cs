---
id: call-stack
title: The call stack
---

Every call gets its own frame: a small record of its local variables and the line it is on. When `fact(3)` calls `fact(2)`, the frame for `fact(3)` waits, with its own `n` still 3, while a new frame goes on top.

```diagram
stack calls ["<module>", "fact(3)", "fact(2)", "fact(1)"]
highlight 3
```

Only the top frame runs. When it returns, it comes off the stack and the frame below carries on from where it stopped.

---

```python trace stop=11
def fact(n):
    if n <= 1:
        return 1
    return n * fact(n - 1)

print(fact(3))
```

The base case is about to return. How many `fact` frames are on the stack?

- [ ] 1
- [ ] 2
- [x] 3
- [ ] 4

---

The way back up is where the work gets done. This version stores the result of the call before adding to it.

```python trace stop=18
def sum_to(n):
    if n == 0:
        return 0
    rest = sum_to(n - 1)
    return n + rest

print(sum_to(3))
```

The top frame has `rest` and is about to return. What does it return?

- [ ] 2
- [x] 3
- [ ] 6

---

Run this to watch frames go on and come off. Each push is a call, each pop is a return.

```python
import viz

calls = []

def fact(n):
    calls.append(f"fact({n})")
    viz.stack(calls, highlight=len(calls) - 1, note=f"call fact({n})")
    result = 1 if n <= 1 else n * fact(n - 1)
    calls.pop()
    viz.stack(calls, note=f"fact({n}) returns {result}")
    return result

print(fact(4))
```

---

A stack can't grow forever. Python stops at about 1,000 frames and raises `RecursionError`. What does this print?

```python predict
def depth(n):
    if n == 0:
        return 0
    return 1 + depth(n - 1)

print(depth(500))
try:
    depth(100_000)
except RecursionError:
    print("too deep")
```

---

`sys.getrecursionlimit()` reports the cap. You can raise it with `sys.setrecursionlimit`, but every frame costs memory, and a very deep stack can crash the process instead of raising an error.

```python
import sys

print(sys.getrecursionlimit())
```

When the depth grows with the input, as in `depth(n)`, a loop is the safer choice in Python. Recursion fits best when the depth stays small, like the height of a balanced tree.

---

At its deepest, `fact(n)` has n frames waiting on the stack. Besides time, `fact(n)` uses

- [ ] O(1) space, because it keeps no list
- [x] O(n) space, one frame per waiting call
- [ ] O(log n) space

---

Put the lines in order so `to_binary` returns `n` written in base 2. The last digit is `n % 2`, and the digits before it are `n // 2` in base 2.

```python arrange
def to_binary(n):
    if n < 2:
        return str(n)
    return to_binary(n // 2) + str(n % 2)
```

```tests
to_binary(6) == "110"
to_binary(1) == "1"
to_binary(0) == "0"
to_binary(8) == "1000"
to_binary(255) == "11111111"
```

---

[Greatest common divisor](exercises/euclid-gcd.md)

[Nesting depth](exercises/nesting-depth.md)
