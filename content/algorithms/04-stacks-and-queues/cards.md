## Why is the top of a list-based stack at the end?
`append` and `pop()` at the end touch one slot, so they are O(1). Working at the front shifts every other item, which is O(n).

## How do you check that brackets are balanced?
Push each opener. At each closer, pop and check that the top is the matching opener; fail if the stack is empty. At the end the stack must be empty.

## How do you evaluate a postfix expression like `3 4 + 2 *`?
Push numbers. At an operator, pop the right operand, then the left, apply it, and push the result. The last value left is the answer.

## Why not use `list.pop(0)` for a queue?
Every other item shifts left to fill the gap, so each pop is O(n), and emptying a queue of n items is O(n²).

## What does `collections.deque` do fast, and what does it do slowly?
`append`, `appendleft`, `pop` and `popleft` are O(1). Indexing into the middle, `dq[i]`, is O(n).

## How do you build a queue from two stacks?
Push into an inbox. Pop from an outbox, and only when the outbox is empty, pour the whole inbox into it. Each item moves once, so every operation is amortized O(1).

## What is a monotonic stack?
A stack whose items stay in sorted order from bottom to top. Before pushing, you pop every item that would break the order.

## How do you find the next bigger number for every item in one pass?
Keep a stack of indexes still waiting, values falling toward the top. Each new number pops every smaller waiting item and is its answer. Then push the new index.

## Why is the next-bigger scan O(n) despite the `while` inside the `for`?
Each index is pushed once and popped at most once, so all the pops together are at most n.

## Next bigger or previous bigger: which comparison and which answer?
Next bigger: the item doing the popping is the answer for each item it pops. Previous bigger: after popping, the item left on top is the answer for the new item.

## In the largest rectangle in a histogram, what do the stack neighbors of a bar mean?
When a bar is popped by a shorter bar at `i`, `i` is its right edge and the bar below it on the stack is its left edge. Width is `i - left - 1`.

## How does a monotonic deque give the maximum of a sliding window?
Keep indexes with values falling from front to back. A new number pops smaller ones off the back. The front leaves when it slides out of the window. The front is the maximum.

## Why can a smaller number be dropped from the window-maximum deque when a bigger one joins?
The bigger one is newer, so it stays in the window at least as long. The smaller one can never be the maximum again.

## Stack, queue or deque: which for which job?
Stack for the most recent first (undo, brackets, nesting). Queue for the oldest first (fair turns, BFS). Deque when you add or remove at both ends, like the sliding-window maximum.
