## What does binary search need from the data?
A yes-or-no test that is no up to some point and yes after it, such as "is `nums[i] >= x`?" on a sorted list.

## How long does binary search take on n items?
O(log n) time and O(1) extra space. Each look halves the range, so a million items take about 20 looks.

## What are the loop invariants of the half-open search?
Everything left of `lo` is a no, and everything from `hi` on is a yes. Start with `lo = 0` and `hi = len(nums)`.

## In the half-open search, how do the pointers move?
A yes at `mid` sets `hi = mid`, since it might be the first yes. A no sets `lo = mid + 1`.

## What does `lo` mean when the half-open search ends?
The first index where the test is true, or `len(nums)` if it is never true.

## How do the closed and half-open styles differ?
Closed: `hi = len(nums) - 1`, `while lo <= hi`, `hi = mid - 1`. Half-open: `hi = len(nums)`, `while lo < hi`, `hi = mid`. Mixing them gives wrong answers or endless loops.

## Why does `lo = mid` break the `while lo < hi` loop?
When `hi` is `lo + 1`, `mid` equals `lo`, so `lo` never moves and the loop runs forever.

## What are the lower and upper bound of `x` in a sorted list?
Lower: the first index with `nums[i] >= x`. Upper: the first index with `nums[i] > x`. The copies of `x` fill the indices between them.

## Which `bisect` function is the lower bound, and which the upper?
`bisect_left` is the lower bound. `bisect_right`, also called `bisect`, is the upper bound.

## How do you count copies of `x` in a sorted list in O(log n)?
`bisect_right(nums, x) - bisect_left(nums, x)`.

## Why does `insort` take O(n) though its search is O(log n)?
Inserting into a Python list shifts every item after the spot one place right.

## When can you binary search on the answer?
When the check "does answer `k` work?" is monotone: once it passes, every bigger `k` passes too. Then search the range of possible answers for the first pass.

## What does binary search on the answer cost?
O(log R) checks over a range of R candidates, times the cost of one check. Shipping n packages with total weight S is O(n log S).

## How do you find the smallest item of a rotated sorted list?
Search for the first index with `nums[i] <= nums[-1]`. The left run says no and the right run says yes.

## Why do repeats break the rotated-list search?
With repeats, like `[1, 1, 1, 0, 1]`, the test can say yes on both runs, so it no longer flips once. The worst case becomes O(n).
