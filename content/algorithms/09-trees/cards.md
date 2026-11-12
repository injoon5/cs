## What is the depth of a node, and the height of a tree?
Depth is the number of edges from the root down to the node. Height is the depth of the deepest node. One node has height 0, the empty tree -1.

## What is the recursive pattern for most tree functions?
Answer the empty tree directly, ask the left and right subtrees the same question, and combine their answers with the node.

## In what order do preorder, in-order and postorder visit a node?
Preorder: node, left, right. In-order: left, node, right. Postorder: left, right, node.

## When do you want postorder?
When a node needs answers from its children first: height, size, diameter, or freeing a tree from the bottom up.

## How does level order work?
Keep a queue. Take the node at the front, record it, and push its children at the back. Each level leaves the queue before the next one starts.

## How do you split level order into one list per level?
At the start of each level, `len(queue)` is the size of that level. Pop exactly that many before starting the next list.

## How do you find a tree's diameter in one pass?
Compute heights bottom up. At each node, the longest path bending there has `height(left) + height(right) + 2` edges. Keep the best.

## How does the recursive lowest common ancestor work?
Return the node if it is `None`, `p` or `q`. Recurse on both sides. If both sides find something, this node is the answer; otherwise pass up whichever side found one.

## What is the binary search tree rule?
At every node, all values in the left subtree are smaller and all values in the right subtree are bigger.

## What does in-order traversal give on a binary search tree?
The values in sorted order.

## Why isn't comparing each node with its children enough to validate a BST?
A node deep in the left subtree can still be bigger than an ancestor. Pass down a lower and upper limit and check every node against both.

## How do you delete a BST node with two children?
Copy in its in-order successor, the smallest value in its right subtree, then delete that successor from the right subtree.

## What do search and insert cost in a BST of height h?
O(h). That is O(log n) when balanced, but O(n) when sorted input builds a chain.

## What does a rotation do?
It lifts a child into its parent's place and moves one subtree across, in O(1). In-order is unchanged, so the tree stays a valid BST, but the heights of the two sides shift by one.

## What rule does an AVL tree keep?
At every node, the heights of the two subtrees differ by at most 1. That keeps the height O(log n).
