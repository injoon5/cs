## What are overlapping subproblems?
A recursion that asks the same smaller questions many times. Naive stair counting makes 21,891 calls for `n = 20` but only asks about 21 different values of `n`.

## What three things define a dynamic programming solution?
The state (what one subproblem is), the transition (how a state's answer comes from smaller states) and the base cases (states answered directly).

## What makes a state good?
Its answer depends only on the state, not on how you reached it. Then one stored answer serves every caller.

## Memoization or tabulation: what is the difference?
A memo recurses from the big question and caches each answer, for example with `@functools.cache`. A table fills answers in a loop, smallest first, in an order where each state's inputs come before it.

## Why can a memoized solution fail in Python where a table works?
The memo keeps the recursion, and its depth grows with the input. Past about 1,000 frames Python raises `RecursionError`. A loop has no depth.

## How do you find the running time of a DP?
Number of states times the work done in each. Coin change with amount A and k coins: A states, k options each, O(A · k).

## When can you drop the table and keep a few variables?
When each state reads only the last few states. House robber reads two, so `prev, cur` replace the list: O(1) space.

## To count ways to make change, which loop goes outside?
The coins. Each set of coins is then built in one order. With amounts outside, you count every order of the same coins.

## What is the LCS transition?
If `a[i - 1] == b[j - 1]`, `dp[i][j] = dp[i - 1][j - 1] + 1`. Otherwise `max(dp[i - 1][j], dp[i][j - 1])`. Row 0 and column 0 are 0. O(m · n).

## What is the edit distance transition?
On a match, `dp[i - 1][j - 1]`. Otherwise 1 plus the smallest of replace `dp[i - 1][j - 1]`, delete `dp[i - 1][j]` and insert `dp[i][j - 1]`. `dp[i][0]` is `i` and `dp[0][j]` is `j`.

## How do you rebuild the answer itself from a filled table?
Start at the final cell and step back to the cell its value came from, recording each choice that added something, until you reach a base case. The choices come out in reverse.

## What is the 0/1 knapsack transition, and what does it cost?
`best[i][w] = max(best[i - 1][w], best[i - 1][w - wt] + val)`. O(n · W) time for n items and capacity W, which is pseudo-polynomial: it grows with the value of W, not its number of digits.

## In the one-list knapsack, why does the capacity loop run downward?
So `best[w - wt]` still holds the value from before this item, and each item is used at most once. Running upward lets an item be reused, which is the unbounded knapsack.

## What does `tails` hold in the O(n log n) longest increasing subsequence?
`tails[k]` is the smallest number that ends an increasing subsequence of length `k + 1`. It stays sorted; each number replaces the first tail `>= x` (`bisect_left`) or is appended. Its length is the answer, but it isn't itself a subsequence.

## In what order do you fill a DP over intervals `[i, j]`?
By increasing length, so every shorter piece inside is already done. Rows from the bottom up, each left to right from the diagonal, also works.

## What does a split-point interval DP cost?
O(n²) intervals, each trying O(n) split points: O(n³). Cutting a stick: `cost(i, j) = marks[j] - marks[i] + min(cost(i, k) + cost(k, j))`.
