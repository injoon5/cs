---
id: remove-kth-from-end
title: Remove the k-th node from the end
level: core
---

Delete the node that is `k` places from the end and return the head. `k = 1` is the last node. With `k = 2`, `1 -> 2 -> 3 -> 4 -> 5` becomes `1 -> 2 -> 3 -> 5`. You can assume `1 <= k <= length`. Walk the list once.

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


def remove_kth_from_end(head, k):
    pass
```

```tests
to_list(remove_kth_from_end(from_list([1, 2, 3, 4, 5]), 2)) == [1, 2, 3, 5]
to_list(remove_kth_from_end(from_list([1, 2, 3, 4, 5]), 1)) == [1, 2, 3, 4]
to_list(remove_kth_from_end(from_list([1, 2, 3, 4, 5]), 5)) == [2, 3, 4, 5]
to_list(remove_kth_from_end(from_list([1]), 1)) == []
to_list(remove_kth_from_end(from_list([1, 2]), 2)) == [2]
to_list(remove_kth_from_end(from_list([7, 7, 7]), 2)) == [7, 7]
to_list(remove_kth_from_end(from_list([-3, 0, -1]), 3)) == [0, -1]
to_list(remove_kth_from_end(from_list(list(range(10000))), 1000)) == list(range(9000)) + list(range(9001, 10000))
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


def remove_kth_from_end(head, k):
    dummy = Node(0, head)
    fast = slow = dummy
    for _ in range(k):
        fast = fast.next
    while fast.next:
        slow = slow.next
        fast = fast.next
    slow.next = slow.next.next
    return dummy.next
```

## Hints

1. To delete a node you need the node before it, and the head itself might be the one to go.
2. Start both pointers on a dummy in front of the head. Move `fast` k nodes ahead, then move both until `fast` is on the last node.
3. Then `slow` sits just before the node to delete: `slow.next = slow.next.next`, and return `dummy.next`.
