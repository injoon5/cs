---
id: insert-sorted-node
title: Insert into a sorted list
level: core
---

The list at `head` is sorted from small to large. Add a new node holding `val` so it stays sorted, and return the head. Inserting 4 into `1 -> 3 -> 5` gives `1 -> 3 -> 4 -> 5`. The new value may belong at the front, so the head can change.

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


def insert_sorted(head, val):
    pass
```

```tests
to_list(insert_sorted(from_list([1, 3, 5]), 4)) == [1, 3, 4, 5]
to_list(insert_sorted(from_list([1, 3, 5]), 0)) == [0, 1, 3, 5]
to_list(insert_sorted(from_list([1, 3, 5]), 9)) == [1, 3, 5, 9]
to_list(insert_sorted(None, 2)) == [2]
to_list(insert_sorted(from_list([4]), 4)) == [4, 4]
to_list(insert_sorted(from_list([2, 2, 2]), 2)) == [2, 2, 2, 2]
to_list(insert_sorted(from_list([-5, -1]), -3)) == [-5, -3, -1]
to_list(insert_sorted(from_list(list(range(0, 2000, 2))), 999)) == list(range(0, 1000, 2)) + [999] + list(range(1000, 2000, 2))
```

```python tests
head = from_list([1, 3, 5])
second = head.next
new_head = insert_sorted(head, 2)
assert new_head is head, "keep the existing nodes"
assert new_head.next.next is second
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


def insert_sorted(head, val):
    if head is None or val < head.val:
        return Node(val, head)
    cur = head
    while cur.next and cur.next.val < val:
        cur = cur.next
    cur.next = Node(val, cur.next)
    return head
```

## Hints

1. To link in a new node you need the node just before where it goes.
2. Handle the front separately: an empty list, or `val` smaller than the head. Otherwise walk while the next value is still smaller than `val`.
3. Stop on `cur` where `cur.next` is `None` or `cur.next.val >= val`, then `cur.next = Node(val, cur.next)`.
