---
id: dummy-head
title: The dummy head
---

To delete the node after `prev`, point `prev.next` past it: `prev.next = prev.next.next`.

```diagram
linked-list [7, 3, 9]
pointer prev 0
```

```diagram
linked-list [7, 9]
pointer prev 0
```

Nothing points at 3 any more, so Python frees it. The delete is O(1) once you hold `prev`. Finding `prev` is the walk.

---

The first node has no `prev`. Deleting every 7 needs a separate loop just for the front:

```python
def remove_all(head, x):
    while head and head.val == x:
        head = head.next
    cur = head
    while cur and cur.next:
        if cur.next.val == x:
            cur.next = cur.next.next
        else:
            cur = cur.next
    return head
```

Two loops for one job, and the front case is the one people forget.

---

Put a spare node in front of the head. Now every real node has a node before it, so the front is no longer special.

```diagram
linked-list [0, 7, 3, 7]
pointer dummy 0
pointer prev 0
pointer head 1
```

```python
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

def remove_all(head, x):
    dummy = Node(0, head)
    prev = dummy
    while prev.next:
        if prev.next.val == x:
            prev.next = prev.next.next
        else:
            prev = prev.next
    return dummy.next

head = Node(7, Node(7, Node(3)))
head = remove_all(head, 7)
print(head.val, head.next)
```

The answer is `dummy.next`, not `head`. The old head may have been deleted.

---

```python trace stop=27
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(7, Node(3, Node(7, Node(5))))
dummy = Node(0, head)
prev = dummy
while prev.next:
    if prev.next.val == 7:
        prev.next = prev.next.next
    else:
        prev = prev.next
head = dummy.next
```

The first 7 is gone. Which node is `prev` on?

- [x] The dummy
- [ ] The node holding 3
- [ ] The node holding 7

---

This version moves `prev` forward every time. What does it print?

```python predict
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

dummy = Node(0, Node(7, Node(7, Node(3))))
prev = dummy
while prev.next:
    if prev.next.val == 7:
        prev.next = prev.next.next
    prev = prev.next
vals = []
cur = dummy.next
while cur:
    vals.append(cur.val)
    cur = cur.next
print(vals)
```

---

A dummy also helps when building a list. `tail` starts on the dummy, and each new node goes after `tail`. Here two sorted lists merge into one, reusing their nodes.

```python
import viz

class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

a = Node(1, Node(4, Node(6)))
b = Node(2, Node(3, Node(7)))
dummy = tail = Node("d")
while a and b:
    if a.val <= b.val:
        tail.next, a = a, a.next
    else:
        tail.next, b = b, b.next
    tail = tail.next
    viz.linked_list(
        dummy,
        pointers={"tail": tail, "a": a, "b": b},
        note=f"take {tail.val}",
    )
tail.next = a or b
viz.linked_list(dummy, note="attach what is left")
```

Each step takes the smaller front node. When one list runs out, the other is already sorted, so it goes on the end in one step.

---

Merging sorted lists of length n and m this way takes

- [ ] O(n + m) time and O(n + m) extra space
- [x] O(n + m) time and O(1) extra space
- [ ] O(n · m) time and O(1) extra space

---

Why does the merge return `dummy.next` instead of `dummy`?

- [ ] `dummy` is `None` after the loop
- [x] The dummy is a placeholder, and the first real node comes after it
- [ ] `tail` moved past `dummy`, so `dummy` is cut off from the list

---

[Remove repeats from a sorted list](exercises/dedupe-sorted-list.md)

[Partition a list](exercises/partition-list.md)

[Merge two sorted lists](exercises/merge-sorted-lists.md)
