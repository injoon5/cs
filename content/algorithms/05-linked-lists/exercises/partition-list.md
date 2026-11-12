---
id: partition-list
title: Partition a list
level: core
---

Rearrange the list so every node with a value less than `x` comes before every node with a value of `x` or more. Keep the original order within each group, reuse the nodes, and return the new head. With `x = 3`, `1 -> 4 -> 3 -> 2 -> 5 -> 2` becomes `1 -> 2 -> 2 -> 4 -> 3 -> 5`.

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


def partition(head, x):
    pass
```

```tests
to_list(partition(from_list([1, 4, 3, 2, 5, 2]), 3)) == [1, 2, 2, 4, 3, 5]
to_list(partition(from_list([2, 1]), 2)) == [1, 2]
to_list(partition(from_list([5, 6, 7]), 3)) == [5, 6, 7]
to_list(partition(from_list([1, 2, 0]), 3)) == [1, 2, 0]
to_list(partition(from_list([3, 3, 1, 3]), 3)) == [1, 3, 3, 3]
to_list(partition(from_list([4]), 3)) == [4]
to_list(partition(None, 3)) == []
to_list(partition(from_list([0, -2, 5, -7, 1]), 0)) == [-2, -7, 0, 5, 1]
to_list(partition(from_list(list(range(1000, 0, -1))), 500)) == list(range(499, 0, -1)) + list(range(1000, 499, -1))
```

```python tests
head = from_list([3, 1, 2])
nodes = [head, head.next, head.next.next]
new_head = partition(head, 2)
assert new_head is nodes[1], "reuse the nodes"
assert new_head.next is nodes[0] and nodes[0].next is nodes[2]
assert nodes[2].next is None
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


def partition(head, x):
    small = small_tail = Node(0)
    big = big_tail = Node(0)
    cur = head
    while cur:
        if cur.val < x:
            small_tail.next = cur
            small_tail = cur
        else:
            big_tail.next = cur
            big_tail = cur
        cur = cur.next
    big_tail.next = None
    small_tail.next = big.next
    return small.next
```

## Hints

1. Build two separate lists as you walk, then join them.
2. Use two dummy heads, each with its own tail. Append every node to the tail of the list it belongs to.
3. After the walk, set `big_tail.next = None` so the last node doesn't still point into the old order, then `small_tail.next = big.next` and return `small.next`.
