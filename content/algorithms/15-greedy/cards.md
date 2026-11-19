## What is a greedy algorithm?
One that builds the answer one choice at a time, always takes the choice that looks best right now, and never goes back on it. Most are a sort and one pass, O(n log n).

## When is a greedy choice safe?
When some best answer makes the same choice. Then taking it loses nothing, and what's left is the same problem, smaller.

## Greedy or dynamic programming?
DP tries every option for the next choice and keeps the best. Greedy commits to one. Use greedy only when you can show that one choice is safe; otherwise use DP.

## Why does greedy change work for coins 1, 5, 10 and 25 but not for 1, 3 and 4?
With 1, 5, 10 and 25, a best answer's coins under 25 add up to at most 24, so any amount of 25 or more needs a 25, and the same holds for each smaller coin. With 1, 3 and 4, greedy pays 6 as 4 + 1 + 1, but 3 + 3 is two coins.

## Fractional knapsack or 0/1 knapsack: where does greedy work?
Fractional: take items by value per kilo and cut the last one to fit. In the 0/1 knapsack items can't be cut, so greedy can leave room it can't fill well, and it needs DP.

## How do you check a greedy you can't prove?
Compare it with a brute force on thousands of small random inputs. Counterexamples are often small but easy to miss by hand.

## What is an exchange argument?
Take any best answer that differs from the greedy one. Swap part of it to match the greedy choice, and show the swap doesn't make it worse. So the greedy answer is a best answer too.

## In what order should jobs at one counter be served to make the total wait smallest?
Shortest first. Swapping a longer job with the shorter job right after it lowers the total by the difference in their lengths and changes no other wait.

## How do you fit the most non-overlapping intervals?
Sort by end and take each interval that starts at or after the end of the last one taken. Earliest end leaves the most room for the rest. O(n log n).

## Why not pick intervals by earliest start or by shortest length?
Earliest start can take one long interval that blocks many short ones. Shortest can take a short interval that overlaps two others that would have fit together.

## How do you find the fewest points that hit every interval?
Sort by end. Put a point at the end of the first interval not hit yet, and skip every interval that starts at or before that point.

## How do you merge overlapping intervals?
Sort by start. Each interval either reaches the last merged block, so stretch its end to the larger of the two ends, or it starts a new block. O(n log n).

## How do you cover a range with the fewest intervals?
From the point covered so far, look at every interval that starts at or before it and take the one that reaches furthest. If none gets past the point, there is a gap. The jump game is the same problem, with index `i` covering `i` to `i + nums[i]`.

## What is a sweep line?
Turn each interval into a +1 event at its start and a -1 event at its end. Sort the events and walk them keeping a running count. The count at each moment is how many intervals are open. O(n log n).

## In a sweep, which event comes first when a start and an end share a coordinate?
For half-open intervals, where touching isn't overlapping, ends first: `(x, -1)` sorts before `(x, 1)`. For closed intervals, where touching overlaps, starts first.

## How do you join ropes, or build a Huffman code, at the least cost?
Keep the lengths in a min-heap and always join the two smallest, pushing their sum back. Each length is paid once per join above it, so small ones belong deep. O(n log n).
