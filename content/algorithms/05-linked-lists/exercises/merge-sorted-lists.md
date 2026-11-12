---
id: merge-sorted-lists
title: Merge two sorted lists
level: core
---

`a` and `b` are sorted linked lists. Join their nodes into one sorted list and return its head. Merging `1 -> 4 -> 6` and `2 -> 3 -> 7` gives `1 -> 2 -> 3 -> 4 -> 6 -> 7`. Reuse the nodes; don't make new ones for the values.

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


def merge_sorted(a, b):
    pass
```

```tests
to_list(merge_sorted(from_list([1, 4, 6]), from_list([2, 3, 7]))) == [1, 2, 3, 4, 6, 7]
to_list(merge_sorted(from_list([1, 2, 3]), from_list([4, 5]))) == [1, 2, 3, 4, 5]
to_list(merge_sorted(from_list([4, 5]), from_list([1, 2, 3]))) == [1, 2, 3, 4, 5]
to_list(merge_sorted(None, from_list([1, 2]))) == [1, 2]
to_list(merge_sorted(from_list([1, 2]), None)) == [1, 2]
to_list(merge_sorted(None, None)) == []
to_list(merge_sorted(from_list([2, 2]), from_list([2]))) == [2, 2, 2]
to_list(merge_sorted(from_list([-5, 0]), from_list([-3, 8]))) == [-5, -3, 0, 8]
to_list(merge_sorted(from_list(list(range(0, 2000, 2))), from_list(list(range(1, 2000, 2))))) == list(range(2000))
```

```python tests
a = from_list([1, 5])
b = from_list([3])
nodes = [a, b, a.next]
head = merge_sorted(a, b)
assert head is nodes[0], "reuse the nodes"
assert head.next is nodes[1] and head.next.next is nodes[2]
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


def merge_sorted(a, b):
    dummy = tail = Node(0)
    while a and b:
        if a.val <= b.val:
            tail.next, a = a, a.next
        else:
            tail.next, b = b, b.next
        tail = tail.next
    tail.next = a or b
    return dummy.next
```

## Hints

1. The smallest remaining value is always at the front of `a` or the front of `b`.
2. Start a dummy node with a `tail` pointer on it. Each step, move the smaller front node onto `tail`.
3. While both lists have nodes, set `tail.next` to the smaller front, advance that list and `tail`. Then attach `a or b` and return `dummy.next`.
