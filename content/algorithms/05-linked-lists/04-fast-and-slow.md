---
id: fast-and-slow
title: Fast and slow pointers
---

Where is the middle of a linked list? You can't compute `len(nodes) // 2` without walking the whole list first.

Walk two pointers at once instead. `slow` moves one node per step, `fast` moves two. When `fast` reaches the end, `slow` has gone half as far.

```diagram
linked-list [1, 2, 3, 4, 5]
pointer slow 2
pointer fast 4
```

---

```python trace stop=26
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(1, Node(2, Node(3, Node(4, Node(5)))))
slow = fast = head
while fast and fast.next:
    slow = slow.next
    fast = fast.next.next
print(slow.val)
```

The loop body has run once. Where are the pointers?

- [ ] `slow` is on 2, `fast` is on 2
- [x] `slow` is on 2, `fast` is on 3
- [ ] `slow` is on 3, `fast` is on 5

---

With an even number of nodes there are two middles. Which one does the same loop find?

```python predict
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(1, Node(2, Node(3, Node(4))))
slow = fast = head
while fast and fast.next:
    slow = slow.next
    fast = fast.next.next
print(slow.val)
```

---

If the last node points back into the list, `while cur` never ends. Remembering every node you've seen in a set would catch it, but costs O(n) memory.

Fast and slow pointers catch it with O(1). Without a cycle, `fast` reaches `None`. With one, both pointers end up going round the loop, and `fast` catches `slow` from behind. Run this to watch them meet.

```python
import viz

class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

nodes = [Node(v) for v in range(1, 7)]
for a, b in zip(nodes, nodes[1:]):
    a.next = b
nodes[-1].next = nodes[2]
head = nodes[0]
slow = fast = head
while fast and fast.next:
    slow = slow.next
    fast = fast.next.next
    viz.linked_list(head, pointers={"slow": slow, "fast": fast})
    if slow is fast:
        viz.note("they meet: there is a cycle")
        break
```

This is Floyd's cycle check.

---

Once both pointers are in the cycle, why can't `fast` jump over `slow` forever?

- [ ] `fast` visits every node in the cycle, so it must land on `slow`
- [x] Each step `fast` closes the gap to `slow` by exactly one node, so the gap reaches 0
- [ ] The cycle always has an even length, so steps of 2 line up with steps of 1

---

On a list of n nodes, Floyd's check takes

- [ ] O(n) time and O(n) extra space
- [x] O(n) time and O(1) extra space
- [ ] O(n²) time and O(1) extra space

---

The same idea finds the k-th node from the end in one pass. Move `fast` k nodes ahead, then move both one at a time. When `fast` falls off the end, `slow` is k nodes behind it.

```diagram
linked-list [1, 2, 3, 4, 5, 6]
pointer slow 4
pointer fast none
```

With k = 2, `slow` stops on 5, the second node from the end.

---

Put the lines in order so `kth_from_end` returns the value k nodes from the end. `k` is at least 1 and at most the length.

```python arrange
def kth_from_end(head, k):
    fast = head
    for _ in range(k):
        fast = fast.next
    slow = head
    while fast:
        slow = slow.next
        fast = fast.next
    return slow.val
```

```python tests
class Node:
    def __init__(self, val, next=None):
        self.val, self.next = val, next

head = Node(1, Node(2, Node(3, Node(4))))
assert kth_from_end(head, 1) == 4
assert kth_from_end(head, 2) == 3
assert kth_from_end(head, 4) == 1
assert kth_from_end(Node(9), 1) == 9
```

---

Floyd's check also finds where the cycle starts. Say the start is `a` steps from the head, and the pointers meet `b` steps past the start, on a cycle of length `c`.

`slow` walked `a + b` steps and `fast` walked twice that. The extra `a + b` steps were whole laps, so `a + b` is a multiple of `c`. From the meeting point, `a` more steps make `a + b` in total: back to the start.

So move one pointer back to the head and step both one at a time. They meet at the start of the cycle.

---

[Middle node](exercises/middle-node.md)

[Has a cycle](exercises/has-cycle.md)

[Remove the k-th node from the end](exercises/remove-kth-from-end.md)

[Where the cycle starts](exercises/cycle-start.md)
