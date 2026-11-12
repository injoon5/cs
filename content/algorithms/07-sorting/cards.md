## Why is insertion sort fast on a nearly sorted list?
Each swap fixes exactly one inversion, a pair in the wrong order. The work is O(n + inversions), so few inversions means close to O(n).

## What are insertion sort's best and worst cases?
O(n) on a sorted list, O(n²) on a backwards one. It sorts in place and is stable.

## What is a stable sort?
One that keeps items with equal keys in the order they came in.

## How long does merging two sorted lists take?
O(n) for n items in total. Each step moves the smaller front item to the output.

## Why is merge sort O(n log n)?
Halving gives about log₂ n levels, and the merges on each level touch every item once.

## What does merge sort cost besides time?
O(n) extra space for the merged lists. It is stable, and O(n log n) on every input.

## In Lomuto partition, what do `i` and `j` mean?
Everything before `i` is smaller than the pivot. Everything from `i` to just before `j` is not. `j` is the next item to look at.

## When is quicksort O(n²)?
When the pivot keeps landing at one end, like taking the last item of an already sorted list. Pick the pivot at random to get O(n log n) expected time.

## Why does a list of all-equal items slow down Lomuto quicksort?
Nothing is smaller than the pivot, so every split leaves all other items on one side. A three-way partition (smaller, equal, bigger) fixes it.

## What does quickselect do, and how fast is it?
Finds the kth smallest item by partitioning and following only the side that holds it. O(n) expected time.

## Why can't a comparison sort beat O(n log n)?
There are n! possible orders and each comparison at most halves them, so it needs at least log₂(n!) comparisons, which grows like n log n.

## When does counting sort beat comparison sorts?
When the items are whole numbers in a small range 0 to k. It takes O(n + k) time and O(k) space.

## How do you sort by points high to low, then name A to Z, in Python?
`sorted(xs, key=lambda p: (-p.points, p.name))`. A tuple key compares item by item; negate the number to flip its direction.

## What does `xs.sort()` return?
`None`. It sorts `xs` in place. `sorted(xs)` returns a new list.

## What does Timsort do with input that is already in order?
It finds the sorted run and stops: O(n) comparisons. It merges runs like merge sort, so the worst case is O(n log n), and it is stable.
