# Complexity

## What does Big-O describe?
How the number of steps grows as the input grows, keeping only the fastest-growing term and dropping constants.

## What is `4n² + 100n + 7` in Big-O?
O(n²). The `n²` term outgrows the rest.

## How many pairs `(i, j)` with `i < j` are there among `n` items?
`n * (n - 1) / 2`, which is O(n²).

## How many times can you halve `n` before it reaches 1?
About log₂ n times. A million needs 20.

## Order these from slowest to fastest growth: O(n log n), O(1), O(2ⁿ), O(log n), O(n²), O(n)
O(1), O(log n), O(n), O(n log n), O(n²), O(2ⁿ).

## What are the best and worst cases of linear search?
Best: O(1), the target is first. Worst: O(n), the target is last or missing.

## Without saying which case, what does a Big-O usually mean?
The worst case. It holds for every input.

## What does amortized O(1) mean?
A single operation can be slow, but any run of `n` operations costs O(n) in total, so O(1) each on average.

## Why is `list.append` amortized O(1)?
The list grows its room by a fixed factor when full. The copies add up to less than `2n` over `n` appends.

## What would `n` appends cost if a list grew by a fixed 10 slots each time?
O(n²) in total. Copies happen every 10 appends and each copies the whole list.

## What do `xs.insert(0, v)` and `xs.pop(0)` cost on a Python list?
O(n). Every other item shifts by one slot.

## Why shrink a list at a quarter full, not half?
At half, alternating pop and append right at the boundary would copy the whole list every time.
