---
id: reverse-linked-list
title: Reverse a linked list
level: warmup
---

Reverse the list in place and return the new head. `1 -> 2 -> 3` becomes `3 -> 2 -> 1`. Flip the `next` pointers; don't make new nodes.

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


def reverse_list(head):
    pass
```

```tests
to_list(reverse_list(from_list([1, 2, 3]))) == [3, 2, 1]
to_list(reverse_list(from_list([1, 2]))) == [2, 1]
to_list(reverse_list(from_list([5]))) == [5]
to_list(reverse_list(None)) == []
to_list(reverse_list(from_list([4, 4, 1, 4]))) == [4, 1, 4, 4]
to_list(reverse_list(from_list([-1, 0, -2]))) == [-2, 0, -1]
to_list(reverse_list(from_list(list(range(10000))))) == list(range(9999, -1, -1))
```

```python tests
head = from_list([1, 2, 3])
last = head.next.next
new_head = reverse_list(head)
assert new_head is last, "reuse the nodes"
assert head.next is None, "the old head ends the list"
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


def reverse_list(head):
    prev, cur = None, head
    while cur:
        nxt = cur.next
        cur.next = prev
        prev = cur
        cur = nxt
    return prev
```

## Hints

1. Every arrow needs to point the other way, and the old head ends up pointing at `None`.
2. Keep `prev` (the reversed part) and `cur` (the next node to flip). Save `cur.next` before you overwrite it.
3. In the loop: `nxt = cur.next`, `cur.next = prev`, `prev = cur`, `cur = nxt`. Return `prev`.
