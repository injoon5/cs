---
id: dedupe-sorted-list
title: Remove repeats from a sorted list
level: warmup
---

The list at `head` is sorted, so equal values sit next to each other. Delete nodes so each value appears once, and return the head. `1 -> 1 -> 2 -> 3 -> 3` becomes `1 -> 2 -> 3`.

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


def dedupe_sorted(head):
    pass
```

```tests
to_list(dedupe_sorted(from_list([1, 1, 2, 3, 3]))) == [1, 2, 3]
to_list(dedupe_sorted(from_list([1, 2, 3]))) == [1, 2, 3]
to_list(dedupe_sorted(from_list([4, 4, 4, 4]))) == [4]
to_list(dedupe_sorted(from_list([5]))) == [5]
to_list(dedupe_sorted(None)) == []
to_list(dedupe_sorted(from_list([-3, -3, -1, 0, 0]))) == [-3, -1, 0]
to_list(dedupe_sorted(from_list([1, 2, 2, 2, 3, 4, 4]))) == [1, 2, 3, 4]
to_list(dedupe_sorted(from_list(sorted(list(range(500)) * 3)))) == list(range(500))
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


def dedupe_sorted(head):
    cur = head
    while cur and cur.next:
        if cur.next.val == cur.val:
            cur.next = cur.next.next
        else:
            cur = cur.next
    return head
```

## Hints

1. The first node always stays, so the head never changes.
2. Compare each node with the one after it. If they match, unlink the one after.
3. While `cur` and `cur.next` exist: if `cur.next.val == cur.val`, set `cur.next = cur.next.next` and stay put; otherwise move `cur` forward.
