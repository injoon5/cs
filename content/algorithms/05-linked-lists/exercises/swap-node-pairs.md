---
id: swap-node-pairs
title: Swap pairs of nodes
level: core
---

Swap every two neighboring nodes and return the new head. `1 -> 2 -> 3 -> 4` becomes `2 -> 1 -> 4 -> 3`. A last node without a partner stays where it is. Move the nodes themselves; don't swap their values.

```python starter
class Node:
    def __init__(self, val, next=None):
        self.val = val
        self.next = next


def from_list(values):
    head = None
    for v in reversed(values):
        head = Node(v, head)
    return head


def to_list(head):
    out = []
    while head:
        out.append(head.val)
        head = head.next
    return out


def swap_pairs(head):
    pass
```

```tests
to_list(swap_pairs(from_list([1, 2, 3, 4]))) == [2, 1, 4, 3]
to_list(swap_pairs(from_list([1, 2, 3]))) == [2, 1, 3]
to_list(swap_pairs(from_list([1, 2]))) == [2, 1]
to_list(swap_pairs(from_list([7]))) == [7]
to_list(swap_pairs(None)) == []
to_list(swap_pairs(from_list([5, 5, 6, 6]))) == [5, 5, 6, 6]
to_list(swap_pairs(from_list([-1, -2, -3, -4, -5]))) == [-2, -1, -4, -3, -5]
to_list(swap_pairs(from_list(list(range(1000))))) == [i ^ 1 for i in range(1000)]
```

```python tests
head = from_list([1, 2, 3, 4])
a, b, c, d = head, head.next, head.next.next, head.next.next.next
new_head = swap_pairs(head)
assert new_head is b, "move the nodes, not the values"
assert b.next is a and a.next is d and d.next is c
assert c.next is None
```

```python solution
class Node:
    def __init__(self, val, next=None):
        self.val = val
        self.next = next


def from_list(values):
    head = None
    for v in reversed(values):
        head = Node(v, head)
    return head


def to_list(head):
    out = []
    while head:
        out.append(head.val)
        head = head.next
    return out


def swap_pairs(head):
    dummy = prev = Node(0, head)
    while prev.next and prev.next.next:
        first = prev.next
        second = first.next
        first.next = second.next
        second.next = first
        prev.next = second
        prev = first
    return dummy.next
```

## Hints

1. The head changes after the first swap, so a dummy node in front saves a special case.
2. Keep `prev` on the node before the pair. A swap rewires three pointers: `prev.next`, `first.next` and `second.next`.
3. With `first = prev.next` and `second = first.next`: set `first.next = second.next`, then `second.next = first`, then `prev.next = second`. Move `prev` to `first`.
