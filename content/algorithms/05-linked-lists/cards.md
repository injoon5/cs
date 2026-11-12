## What does a linked list node hold?
A value and `next`, a reference to the following node. The last node's `next` is `None`, and the list is just a reference to the first node.

## What does it cost to reach the node at index i?
O(i). You start at the head and follow `next` i times. A Python list does `a[i]` in O(1).

## What does it cost to add a node at the front of a linked list?
O(1): `head = Node(val, head)`. On a Python list, `insert(0, x)` is O(n) because every item shifts.

## You hold node `a`. In what order do you link a new node in after it?
First `new.next = a.next`, then `a.next = new`. The other order loses the rest of the list.

## How do you delete the node after `prev`?
`prev.next = prev.next.next`. It's O(1) once you have `prev`; finding `prev` is the walk.

## What problem does a dummy head solve?
The first node has no node before it, so deletes and inserts at the front need a special case. A spare node in front gives every real node a predecessor. Return `dummy.next`.

## When removing every match with `prev`, why doesn't `prev` move after a delete?
The new `prev.next` hasn't been checked yet. It might match too.

## How do you merge two sorted linked lists?
Keep a `tail` starting on a dummy. Move the smaller front node onto `tail` until one list runs out, then attach the other. O(n + m) time, O(1) extra space.

## What are the three pointers in an in-place reversal?
`prev` for the part already reversed, `cur` for the node being flipped, and `nxt` to save `cur.next` before it is overwritten.

## What does reversing a linked list in place cost?
O(n) time and O(1) extra space. Each node's arrow flips once and no nodes are made.

## How do fast and slow pointers find the middle?
`slow` moves one node per step and `fast` two. Loop `while fast and fast.next`; when it stops, `slow` is on the middle (the second middle for even lengths).

## How does Floyd's check detect a cycle?
Run fast and slow pointers. Without a cycle `fast` reaches `None`. With one, `fast` gains one node per step inside the loop, so the two meet.

## After fast and slow meet in a cycle, how do you find where it starts?
Move one pointer back to the head and step both one node at a time. They meet at the start of the cycle.

## How do you find the k-th node from the end in one pass?
Move `fast` k nodes ahead, then move `fast` and `slow` together until `fast` falls off the end. `slow` is on the k-th node from the end.

## When does a linked list beat a Python list?
When you insert or delete at the front, or next to a node you already hold, and rarely need an item by index.
