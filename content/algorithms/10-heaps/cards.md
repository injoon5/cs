## What is the min-heap property?
Every parent is less than or equal to its children. So the smallest item is at the root. Siblings can be in any order.

## In a heap stored as a list, where are the children and the parent of index `i`?
Children at `2i + 1` and `2i + 2`, parent at `(i - 1) // 2`.

## Why can a heap live in a plain list with no pointers?
Its shape is fixed: levels fill top to bottom and left to right with no gaps, so every position has a known index.

## How does a push keep the heap in order?
Append the item, then sift it up: swap it with its parent while the parent is bigger. O(log n).

## How does a pop keep the heap in order?
Take the root, move the last item to the root, then sift it down: swap with the smaller child while that child is smaller. O(log n).

## Why does sift down swap with the smaller child?
The child that moves up becomes the parent of the other child, so it has to be the smaller one.

## How long does building a heap from n items take?
O(n) by sifting down every parent from the last one back to the root. Most items sit near the bottom, where sifting is short. n pushes would cost O(n log n).

## Where can the largest item of a min-heap be?
At any leaf: any index from `n // 2` on.

## How do you get a max-heap from `heapq`?
Push each number negated and negate it again when it comes out.

## Why push `(priority, counter, item)` instead of `(priority, item)`?
On a tie Python compares the items, which may be in the wrong order or raise `TypeError`. A counter is unique, so ties go in push order.

## What does heap sort cost?
O(n log n) time and O(1) extra space. It isn't stable.

## How do you find the k largest of n numbers with a heap?
Keep a min-heap of size k. A number bigger than the root replaces it. O(n log k) time, O(k) space. The root at the end is the k-th largest.

## How do you merge k sorted lists with N items in total?
Keep a heap of `(value, list, position)` with one front item per list. Pop the smallest and push the next item from its list. O(N log k).

## How do two heaps give a running median?
A max-heap holds the lower half and a min-heap the upper half, with sizes equal or the lower one bigger. The median comes from the two roots. O(log n) per number.

## How many meeting rooms does a calendar need?
Sort meetings by start and keep a min-heap of end times. Reuse the root's room when it ends by the new start, else add a room. The heap's final size is the answer.
