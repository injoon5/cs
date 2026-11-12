---
id: cycle-start
title: Where the cycle starts
level: stretch
---

Return the node where the cycle begins: the first node you reach twice when following `next` from `head`. Return `None` if there is no cycle. Use O(1) extra memory. In `make_cycle([3, 2, 0, -4], 1)` the last node points back to the node holding 2, so that node is the answer.

```python starter
class Node:
    def __init__(self, val, next=None):
        self.val = val
        self.next = next


def make_cycle(values, pos):
    nodes = [Node(v) for v in values]
    for a, b in zip(nodes, nodes[1:]):
        a.next = b
    if nodes and pos >= 0:
        nodes[-1].next = nodes[pos]
    return nodes[0] if nodes else None


def cycle_start(head):
    pass
```

```tests
cycle_start(make_cycle([3, 2, 0, -4], 1)).val == 2
cycle_start(make_cycle([1, 2], 0)).val == 1
cycle_start(make_cycle([1], 0)).val == 1
cycle_start(make_cycle([1, 2, 3, 4, 5, 6], 2)).val == 3
cycle_start(make_cycle([1, 2, 3, 4, 5, 6], 5)).val == 6
cycle_start(make_cycle(list(range(10000)), 6000)).val == 6000
cycle_start(make_cycle([1, 2, 3], -1)) is None
cycle_start(None) is None
```

```python tests
nodes = [Node(7) for _ in range(5)]
for a, b in zip(nodes, nodes[1:]):
    a.next = b
nodes[-1].next = nodes[3]
assert cycle_start(nodes[0]) is nodes[3], "return the node itself"
```

```python solution
class Node:
    def __init__(self, val, next=None):
        self.val = val
        self.next = next


def make_cycle(values, pos):
    nodes = [Node(v) for v in values]
    for a, b in zip(nodes, nodes[1:]):
        a.next = b
    if nodes and pos >= 0:
        nodes[-1].next = nodes[pos]
    return nodes[0] if nodes else None


def cycle_start(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow is fast:
            break
    else:
        return None
    slow = head
    while slow is not fast:
        slow = slow.next
        fast = fast.next
    return slow
```

## Hints

1. First find out whether there is a cycle at all, with fast and slow pointers.
2. If the start is `a` steps from the head and they meet `b` steps past the start, then `a + b` is a whole number of laps. So walking `a` more steps from the meeting point lands on the start.
3. After they meet, move `slow` back to `head` and step both pointers one node at a time. Return the node where `slow is fast`.
