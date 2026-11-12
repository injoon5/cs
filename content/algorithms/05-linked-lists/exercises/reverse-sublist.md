---
id: reverse-sublist
title: Reverse part of a list
level: stretch
---

Reverse the nodes from index `left` to index `right`, both included and counted from 0, and return the head. Leave the rest in place. With `left = 1` and `right = 3`, `1 -> 2 -> 3 -> 4 -> 5` becomes `1 -> 4 -> 3 -> 2 -> 5`. You can assume `0 <= left <= right < length`.

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


def reverse_between(head, left, right):
    pass
```

```tests
to_list(reverse_between(from_list([1, 2, 3, 4, 5]), 1, 3)) == [1, 4, 3, 2, 5]
to_list(reverse_between(from_list([1, 2, 3, 4, 5]), 0, 4)) == [5, 4, 3, 2, 1]
to_list(reverse_between(from_list([1, 2, 3, 4, 5]), 0, 1)) == [2, 1, 3, 4, 5]
to_list(reverse_between(from_list([1, 2, 3, 4, 5]), 3, 4)) == [1, 2, 3, 5, 4]
to_list(reverse_between(from_list([1, 2, 3]), 1, 1)) == [1, 2, 3]
to_list(reverse_between(from_list([9]), 0, 0)) == [9]
to_list(reverse_between(from_list([3, 3, -1, 3]), 1, 2)) == [3, -1, 3, 3]
to_list(reverse_between(from_list(list(range(1000))), 100, 899)) == list(range(100)) + list(range(899, 99, -1)) + list(range(900, 1000))
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


def reverse_between(head, left, right):
    dummy = before = Node(0, head)
    for _ in range(left):
        before = before.next
    start = before.next
    prev, cur = None, start
    for _ in range(right - left + 1):
        nxt = cur.next
        cur.next = prev
        prev = cur
        cur = nxt
    before.next = prev
    start.next = cur
    return dummy.next
```

## Hints

1. This is the full reversal on a stretch of the list, plus two links to repair at the edges.
2. Walk a pointer `before` to the node just before index `left`. A dummy node in front covers `left = 0`. Then reverse `right - left + 1` nodes starting at `before.next`.
3. Remember `start = before.next`. After the reversal loop, `prev` is the new front of the stretch and `cur` is the first node after it: set `before.next = prev` and `start.next = cur`.
