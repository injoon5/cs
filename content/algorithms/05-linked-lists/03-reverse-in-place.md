---
id: reverse-in-place
title: Reversing in place
---

Turn this list around without making new nodes.

```diagram
linked-list [1, 2, 3, 4]
pointer head 0
```

```diagram
linked-list [4, 3, 2, 1]
pointer head 0
```

The values stay where they are. Every arrow flips to point at the node before it, and the old last node becomes the head.

---

Flip one arrow at a time, front to back, with three pointers:

- `prev`: the part already reversed. It starts as `None`, since the old head will end up last.
- `cur`: the node whose arrow flips next.
- `nxt`: the rest of the list, saved before the flip.

```python
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(1, Node(2, Node(3, Node(4))))
prev, cur = None, head
while cur:
    nxt = cur.next
    cur.next = prev
    prev = cur
    cur = nxt
head = prev
print(head.val, head.next.val)
```

Once `cur.next = prev` runs, `cur` no longer leads to the rest of the list. `nxt` is the only way back to it.

---

Run this to watch it. The reversed part grows behind `prev` while `cur` works through the rest.

```python
import viz

class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(1, Node(2, Node(3, Node(4))))
prev, cur = None, head
viz.linked_list(head, pointers={"prev": prev, "cur": cur})
while cur:
    nxt = cur.next
    cur.next = prev
    prev = cur
    cur = nxt
    viz.linked_list(
        prev,
        pointers={"prev": prev, "cur": cur},
        note=f"flip {prev.val}",
    )
head = prev
viz.linked_list(head, pointers={"head": head}, note="done")
```

---

```python trace stop=27
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(1, Node(2, Node(3)))
prev, cur = None, head
while cur:
    nxt = cur.next
    cur.next = prev
    prev = cur
    cur = nxt
head = prev
```

Two arrows have flipped. Where are the pointers?

- [ ] `prev` is on 1, `cur` is on 2
- [x] `prev` is on 2, `cur` is on 3
- [ ] `prev` is on 3, `cur` is `None`

---

This version skips `nxt`. What does it print?

```python predict
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(1, Node(2, Node(3)))
prev, cur = None, head
while cur:
    cur.next = prev
    prev = cur
    cur = cur.next
vals = []
cur = prev
while cur:
    vals.append(cur.val)
    cur = cur.next
print(vals)
```

---

Put the lines in order so `reverse_list` reverses the list and returns the new head.

```python arrange
def reverse_list(head):
    prev, cur = None, head
    while cur:
        nxt = cur.next
        cur.next = prev
        prev = cur
        cur = nxt
    return prev
```

```python tests
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

def to_list(head):
    out = []
    while head:
        out.append(head.val)
        head = head.next
    return out

assert to_list(reverse_list(Node(1, Node(2, Node(3))))) == [3, 2, 1]
assert to_list(reverse_list(Node(5))) == [5]
assert reverse_list(None) is None
```

---

Reversing a list of n nodes this way takes

- [ ] O(n) time and O(n) extra space
- [x] O(n) time and O(1) extra space
- [ ] O(n²) time and O(1) extra space

---

Copying the values into a Python list, reversing that and building new nodes also works. What does in-place reversal save?

- [ ] Time: it is O(n) and the copy is O(n²)
- [x] Memory: it reuses the nodes instead of making n new ones
- [ ] Nothing: both make new nodes

---

[Reverse a linked list](exercises/reverse-linked-list.md)

[Swap pairs of nodes](exercises/swap-node-pairs.md)

[Reverse part of a list](exercises/reverse-sublist.md)
