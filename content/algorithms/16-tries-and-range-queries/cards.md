## What is a trie?
A tree of letters. Each node is a dict from letter to child plus a flag for "a word ends here", so each node stands for the prefix on the path to it. Words with a common start share that path.

## What do insert and search cost in a trie?
O(L) for a word of length L, however many words are stored. Each letter is one dict lookup.

## In a trie, what separates a word from a prefix?
The end flag on the last node. The path for `ca` exists once `cat` is inserted, but `ca` is a word only if its node has the flag set.

## When is a trie better than a set of words?
When you ask about prefixes: which words start with this, how many, or what comes next. For whole-word lookups a set is as fast and far smaller.

## How does a trie count the words with a given prefix?
Each node keeps a count of the words that pass through it, raised on every node of a word's path when it is inserted. The answer is the count at the prefix's node, O(length of the prefix).

## How does a trie give autocomplete suggestions in sorted order?
Walk to the prefix's node, then visit the nodes below it with children in sorted order, recording a word whenever a node ends one. A word comes before the longer words below it, which is alphabetical order.

## How do you find the largest xor of a number with any number in a list?
Store the numbers in a trie of bits, highest bit first. Walk down for `x`, taking the opposite bit whenever that child exists. A high bit is worth more than all lower bits together.

## Why don't prefix sums work when the numbers change?
Changing `nums[i]` changes every prefix after it, so one update costs O(n).

## What does a segment tree store?
A tree of ranges: each leaf is one number, each parent combines its two children's ranges, the root covers everything. Stored like a heap from index 1, the children of `i` are `2i` and `2i + 1` and `nums[i]` is at `n + i`.

## What do segment tree operations cost?
Build O(n). A point update fixes one node per level, O(log n). A range query takes at most two nodes per level, O(log n). Space O(n).

## How does the bottom-up segment tree query climb?
Start `l` and `r` at the end leaves. An odd `l` is taken alone and moves right, an even `r` is taken alone and moves left. Then both halve, while `l <= r`.

## What can a segment tree combine?
Any associative operation with a starting value that changes nothing: sum and 0, min and infinity, max and minus infinity, gcd and 0. When order matters, keep the left and right results apart.

## What is lazy propagation?
A segment tree trick for range updates: a node covering the whole changed range keeps a pending change and passes it to its children only when a later request needs to look below it. Range updates and queries stay O(log n).

## What does cell `i` of a Fenwick tree hold?
The sum of the `i & -i` positions that end at `i`, where `i & -i` is the lowest 1 bit of `i`. Positions count from 1.

## How do Fenwick tree updates and prefix sums walk?
A prefix sum adds cells going down with `i -= i & -i` until 0. An update fixes cells going up with `i += i & -i` past n. Each is O(log n).

## Fenwick tree or segment tree?
A Fenwick tree is smaller and shorter but gets a range as `prefix(r) - prefix(l - 1)`, so it needs an operation that can be undone, like sums or counts. Minimum, maximum and gcd need a segment tree.
