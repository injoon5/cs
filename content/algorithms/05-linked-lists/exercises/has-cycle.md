---
id: has-cycle
title: Has a cycle
level: core
---

Return `True` if following `next` from `head` loops back to a node already visited, and `False` if it reaches `None`. Use O(1) extra memory. `make_cycle([1, 2, 3, 4], 1)` builds `1 -> 2 -> 3 -> 4` with 4 pointing back to 2, which has a cycle. A `pos` of -1 means no cycle.

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


def has_cycle(head):
    pass
```

```tests
has_cycle(make_cycle([1, 2, 3, 4], 1)) == True
has_cycle(make_cycle([1, 2, 3, 4], -1)) == False
has_cycle(make_cycle([1, 2], 0)) == True
has_cycle(make_cycle([1], 0)) == True
has_cycle(make_cycle([1], -1)) == False
has_cycle(None) == False
has_cycle(make_cycle([5, 5, 5], -1)) == False
has_cycle(make_cycle([-1, -2, -3], 2)) == True
has_cycle(make_cycle(list(range(10000)), 5000)) == True
has_cycle(make_cycle(list(range(10000)), -1)) == False
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


def has_cycle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow is fast:
            return True
    return False
```

## Hints

1. Without a cycle, a pointer that moves fast reaches `None`. With one, it never does.
2. Move `slow` one node and `fast` two per step. If they ever land on the same node, there is a cycle.
3. Loop `while fast and fast.next`, advance both, and return `True` when `slow is fast`. Compare nodes with `is`, not values. After the loop, return `False`.
