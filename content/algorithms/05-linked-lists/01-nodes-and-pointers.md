---
id: nodes-and-pointers
title: Nodes and pointers
---

A Python list keeps its items side by side in one block of memory. A linked list keeps each value in its own node, and each node only knows where the next one is.

```diagram
linked-list [3, 8, 5]
pointer head 0
```

The whole list is `head`, a reference to the first node. The last node's `next` is `None`.

```python
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(3, Node(8, Node(5)))
print(head.val, head.next.val)
print(head.next.next.next)
```

---

There is no `head[2]`. To reach a node, start at `head` and follow `next` until you get there. Run this to watch `cur` walk the list.

```python
import viz

class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(3, Node(8, Node(5, Node(1))))
cur = head
while cur:
    viz.linked_list(head, pointers={"cur": cur}, note=f"visit {cur.val}")
    cur = cur.next
viz.linked_list(head, pointers={"cur": cur}, note="cur is None, stop")
```

The loop stops when `cur` falls off the end and becomes `None`.

---

```python trace stop=23
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(4, Node(9, Node(2, Node(7))))
cur, i = head, 0
while cur and cur.val != 2:
    cur = cur.next
    i += 1
print(i)
```

The loop body has run once. Where is the walk?

- [ ] `cur.val` is 4, `i` is 1
- [x] `cur.val` is 9, `i` is 1
- [ ] `cur.val` is 9, `i` is 0

---

Adding a node at the front takes one step, however long the list is: `head = Node(1, head)`.

Adding after a node `a` takes two. Point the new node at what follows `a`, then point `a` at the new node.

```diagram
linked-list [3, 8, 5]
pointer a 0
```

```diagram
linked-list [3, 6, 8, 5]
pointer a 0
pointer new 1
```

The order matters. Set `a.next` first and nothing points at 8 any more, so the rest of the list is lost.

---

What does this print?

```python predict
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(3, Node(8, Node(5)))
head = Node(1, head)
a = head.next
a.next = Node(6, a.next)
vals = []
cur = head
while cur:
    vals.append(cur.val)
    cur = cur.next
print(vals)
```

---

Put the lines in order so `index_of` returns the position of the first node holding `target`, or -1.

```python arrange
def index_of(head, target):
    i = 0
    cur = head
    while cur:
        if cur.val == target:
            return i
        cur = cur.next
        i += 1
    return -1
```

```python tests
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(4, Node(9, Node(2, Node(9))))
assert index_of(head, 4) == 0
assert index_of(head, 9) == 1
assert index_of(head, 2) == 2
assert index_of(head, 5) == -1
assert index_of(None, 1) == -1
```

---

You only have `head`. Which of these is O(1) for a linked list but O(n) for a Python list?

- [x] Add an item at the front
- [ ] Read the item at index i
- [ ] Add an item at the end

---

Reading `a[i]` from a Python list is O(1), because it computes where item i sits. Getting the node at index i of a linked list is

- [ ] O(1), because nodes are numbered
- [x] O(i), because it follows i `next` links
- [ ] O(log n), because it can skip ahead

---

[Length of a linked list](exercises/linked-list-length.md)

[Insert into a sorted list](exercises/insert-sorted-node.md)
