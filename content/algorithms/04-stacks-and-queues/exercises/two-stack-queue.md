---
id: two-stack-queue
title: Queue from two stacks
level: stretch
---

Build a queue using only two Python lists used as stacks: `append`, `pop()` and `[-1]`, nothing at the front. `push(x)` adds at the back, `pop()` removes and returns the front, `peek()` returns the front without removing it, and `len(q)` is the size. `pop` and `peek` are never called on an empty queue. Every operation should be amortized O(1).

After `push(1)`, `push(2)`, `pop()` returns 1. Then `push(3)`, and `pop()` returns 2.

```python starter
class TwoStackQueue:
    def __init__(self):
        self.inbox = []
        self.outbox = []

    def push(self, x):
        pass

    def pop(self):
        pass

    def peek(self):
        pass

    def __len__(self):
        return 0
```

```python tests
q = TwoStackQueue()
assert len(q) == 0
q.push(1)
q.push(2)
assert q.peek() == 1
assert q.pop() == 1
q.push(3)
assert len(q) == 2
assert q.pop() == 2
assert q.pop() == 3
assert len(q) == 0

q = TwoStackQueue()
q.push(None)
q.push(None)
assert q.pop() is None and len(q) == 1

q = TwoStackQueue()
for i in range(1000):
    q.push(i)
    if i % 3 == 0:
        assert q.pop() == i // 3
expected = list(range(334, 1000))
assert [q.pop() for _ in range(len(q))] == expected
```

```python solution
class TwoStackQueue:
    def __init__(self):
        self.inbox = []
        self.outbox = []

    def push(self, x):
        self.inbox.append(x)

    def _refill(self):
        if not self.outbox:
            while self.inbox:
                self.outbox.append(self.inbox.pop())

    def pop(self):
        self._refill()
        return self.outbox.pop()

    def peek(self):
        self._refill()
        return self.outbox[-1]

    def __len__(self):
        return len(self.inbox) + len(self.outbox)
```

## Hints

1. Pouring one stack into another reverses its order, and reversing a stack puts the oldest item on top.
2. Push into `inbox`. To pop, take from the top of `outbox`. Only when `outbox` is empty, move everything from `inbox` into it.
3. Never refill `outbox` while it still has items, or newer items would jump ahead. Each item is moved at most once, which is why `pop` is amortized O(1).
