## In the sorted pair search, the sum is too big. Which pointer moves?
`hi` moves left. The number at `hi` is too big even with the smallest partner left, so it can't be in any answer.

## Why does the two-pointer pair search need a sorted list?
Sorting is what lets one comparison rule out a whole number. Without it, a sum that is too big says nothing about the other pairs.

## How long does the two-pointer pair search take on n numbers?
O(n) time and O(1) extra space. Each step moves one pointer inward, so there are at most n - 1 steps.

## When should the loop stop when walking a string from both ends?
When `i < j` is no longer true. The middle character of an odd-length string has nothing to compare against.

## How does a fixed-size window update its total when it slides one step?
Add the item entering on the right and subtract the one leaving on the left: `window += nums[right] - nums[right - k]`.

## In a variable-size window, when does `left` move?
When the window breaks its rule, for example its total goes over the budget. Move `left` forward until the rule holds again.

## Why is a sliding window O(n) even with a `while` inside the `for`?
Each item joins the window once and leaves at most once, so both pointers together move at most 2n times.

## When does a variable-size window on sums stop working?
When numbers can be negative. Shrinking the window no longer always lowers the total, so you can't tell which way to move. Use prefix sums instead.

## What is `prefix[i]` in a prefix sum list?
The sum of the first `i` numbers. `prefix[0]` is 0, and the list is one longer than the input.

## How do you get `sum(nums[l..r])`, both ends included, from prefix sums?
`prefix[r + 1] - prefix[l]`.

## What does answering q range-sum questions on n numbers cost with prefix sums?
O(n) to build the prefix list once, then O(1) per question: O(n + q) in total.

## How do you count runs that add up to k when numbers can be negative?
Keep a running total and a count of every total seen so far, starting with 0 seen once. Each new total adds the count of earlier totals equal to `running - k`.
