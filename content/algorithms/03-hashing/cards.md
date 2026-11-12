## How does a hash table find a key without searching?
It turns the key into a number with a hash function and uses that number to pick a bucket. A lookup computes the same bucket and looks only there.

## What is a collision in a hash table?
Two different keys that land in the same bucket. There are more possible keys than buckets, so collisions always happen.

## How does chaining handle collisions?
Each bucket holds a short list of the keys that landed there. A lookup scans only that one list.

## How does linear probing handle collisions?
Every key sits directly in a slot. If its home slot is taken, it tries the next slot to the right, wrapping around, until it finds a free one.

## What is the load factor of a hash table?
The number of keys divided by the number of buckets. Tables grow when it passes a limit, so chains stay short.

## Why is inserting into a hash table amortized O(1) even though resizing is O(n)?
The table doubles when it grows, so the keys moved over n inserts add up to less than 2n.

## What is the worst case for a hash table lookup, and when does it happen?
O(n), when every key lands in the same bucket, for example with a bad hash or keys chosen to collide.

## Why can't a list be a dict key?
A list can change after it's stored, which would change its hash and leave it in the wrong bucket. Dict keys must be hashable, and lists aren't.

## How do you use a pair of numbers as a dict key?
Use a tuple, like `grid[(row, col)]`. A tuple can't change, so it's hashable as long as everything inside it is.

## How do you remove repeats from a list and keep the original order?
`list(dict.fromkeys(items))`. A dict keeps insertion order; a set doesn't promise any order.

## How do you count how often each item appears?
A dict with `counts[x] = counts.get(x, 0) + 1`, or `collections.Counter(items)`. O(n) time and one entry per different item.

## How do you group anagrams in one pass?
Key each word by its sorted letters, or by a tuple of its 26 letter counts, and append it to a dict of lists under that key.

## How do you find two numbers in an unsorted list that add up to a target?
Walk left to right with a dict from value to index. For each `x`, look up `target - x` before storing `x`. O(n) time on average.

## How do you find the longest run that adds up to k when numbers can be negative?
Keep a running total and a dict from each total to the first index it appeared, starting with `{0: -1}`. A run ends at `i` when `running - k` is in the dict; its length is `i - first[running - k]`.
