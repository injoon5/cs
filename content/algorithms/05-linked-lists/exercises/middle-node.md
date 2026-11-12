---
id: middle-node
title: Middle node
level: warmup
---

Return the middle node of a non-empty list. With an even number of nodes, return the second of the two middles. For `1 -> 2 -> 3 -> 4 -> 5` it is the node holding 3, and for `1 -> 2 -> 3 -> 4` the node holding 3. Walk the list once.

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


def middle_node(head):
    pass
```

```tests
to_list(middle_node(from_list([1, 2, 3, 4, 5]))) == [3, 4, 5]
to_list(middle_node(from_list([1, 2, 3, 4]))) == [3, 4]
to_list(middle_node(from_list([1, 2]))) == [2]
to_list(middle_node(from_list([8]))) == [8]
to_list(middle_node(from_list([1, 2, 3]))) == [2, 3]
to_list(middle_node(from_list([6, 6, 6, 6, 6, 6]))) == [6, 6, 6]
to_list(middle_node(from_list([-4, -3, -2]))) == [-3, -2]
to_list(middle_node(from_list(list(range(10001))))) == list(range(5000, 10001))
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


def middle_node(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
    return slow
```

## Hints

1. Two pointers that move at different speeds cover different distances in the same number of steps.
2. Move `slow` one node and `fast` two nodes per step. Stop when `fast` can't take a full step.
3. Loop `while fast and fast.next`, then return `slow`.
