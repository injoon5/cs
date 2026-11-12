---
id: linked-list-length
title: Length of a linked list
level: warmup
---

Return the number of nodes in the list that starts at `head`. For `3 -> 8 -> 5` it is 3. An empty list is `None` and has length 0.

`from_list` and `to_list` turn Python lists into linked lists and back, for testing.

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


def length(head):
    pass
```

```tests
length(from_list([3, 8, 5])) == 3
length(from_list([7])) == 1
length(None) == 0
length(from_list([2, 2, 2, 2])) == 4
length(from_list([-1, 0, -5])) == 3
length(from_list([None, None])) == 2
length(from_list(list(range(10000)))) == 10000
length(from_list(list("linked"))) == 6
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


def length(head):
    count = 0
    cur = head
    while cur:
        count += 1
        cur = cur.next
    return count
```

## Hints

1. There is no stored length. You have to visit each node.
2. Walk with `cur` from `head` to `None` and count the steps.
3. Start `count` at 0. While `cur` is not `None`, add 1 and set `cur = cur.next`.
