## What two parts does every recursive function need?
A base case that answers the smallest input directly, and a recursive case that makes the input smaller and calls the function again.

## What does it mean to trust the recursive call?
While writing the recursive case, assume the call on the smaller input already returns the right answer. Only work out how to combine it with the current step.

## What goes wrong if a recursive call doesn't shrink its input?
It never reaches the base case. In Python it keeps adding frames until it raises `RecursionError`.

## What is a stack frame?
The record for one function call: its local variables and the line it is on. Each call gets its own, and only the top frame runs.

## In what order does code after a recursive call run?
On the way back up, so the deepest call runs it first.

## How deep can recursion go in Python by default?
About 1,000 frames. `sys.getrecursionlimit()` reports the cap. When depth grows with the input, use a loop.

## How much space does recursion `n` levels deep use?
O(n), one frame per waiting call, even if the function keeps no list.

## Why is naive recursive Fibonacci slow?
Each call makes two more, and the same values are recomputed over and over. The call tree has O(2ⁿ) nodes.

## What does memoization do?
Saves each answer the first time it is computed, keyed by the input, and returns it on later calls. Naive Fibonacci drops from O(2ⁿ) to O(n).

## How many calls does fast power, `power(x, n)` by halving, make?
O(log n). Each call computes `power(x, n // 2)` once and squares it, with one extra `x` when `n` is odd.

## What is divide and conquer?
Split the problem into parts, usually halves, solve each part recursively, and combine the answers. Halving keeps the stack O(log n) deep.

## What is the backtracking pattern?
Choose, explore, unchoose: make a choice, recurse on what is left, then undo the choice so the next branch starts clean.

## Why save `picked[:]` instead of `picked` at a backtracking leaf?
There is only one `picked` list, and every choice is undone by the end. Without a copy, every saved entry is that same list, empty at the end.

## How many subsets and permutations do n distinct items have?
2ⁿ subsets and n! permutations. Listing them costs O(2ⁿ · n) and O(n! · n) time.

## What is pruning?
Stopping a branch of a search as soon as it can't lead to an answer. With sorted candidates, the first number bigger than what is left ends the loop.

## In n-queens, how do you check diagonals in O(1)?
Keep sets of taken `r - c` values (down-right diagonals) and `r + c` values (up-right diagonals), plus taken columns.
