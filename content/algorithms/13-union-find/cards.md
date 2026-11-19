## What two operations does union-find support?
`find(x)` returns the representative of the group `x` is in. `union(a, b)` merges the groups of `a` and `b`. Two items are connected exactly when their finds are equal.

## How does union-find store its groups?
As trees in a `parent` list. Each item points to its parent, a root points to itself, and the root is the group's representative.

## Why does `union` link the two roots instead of the two items?
Pointing `b` straight at `a` would move `b` and the items below it, but leave the rest of `b`'s group behind. Linking roots moves whole trees.

## What goes wrong with union-find without any tricks?
The trees can grow into a chain, so one `find` can cost O(n).

## What is union by size?
Keep the size of each tree at its root and point the smaller tree's root at the larger one's. No item ends up deeper than log₂ n.

## Why does union by size keep trees at most log₂ n deep?
An item gets deeper only when its tree is the smaller one in a union, so its tree at least doubles each time. A tree can double at most log₂ n times.

## What is path compression?
After `find(x)` reaches the root, point every item on the path straight at the root. Path halving does a similar job in one pass: point each item at its grandparent while walking up.

## What does union-find cost with union by size and path compression?
O(α(n)) amortized per operation, where α is the inverse Ackermann function: at most 4 for any real n. In practice, constant.

## How do you count connected components as edges arrive?
Start at n. Each union that merges two different groups lowers the count by one.

## How does union-find find a cycle in an undirected graph?
An edge whose two ends already have the same root closes a cycle. It doesn't work for directed graphs, since union-find ignores direction.

## When is union-find a better fit than BFS or DFS?
When edges keep arriving and you need to know what is connected in between. It can't give paths or distances, and it can't remove edges.

## What is a minimum spanning tree?
A set of V - 1 edges that connects all V nodes with no cycle, with the smallest total weight.

## What is the cut property?
Split the nodes into two sides in any way. The cheapest edge crossing between the sides belongs to some minimum spanning tree.

## How does Kruskal's algorithm work, and what does it cost?
Sort the edges by weight. Take each edge whose ends are in different trees, using union-find, and skip the rest. O(E log E) for the sort.

## How does Prim's algorithm work, and what does it cost?
Grow one tree from a start node. A min-heap holds the edges leaving the tree; pop the cheapest, and skip it if its node is already in the tree. O(E log V).

## When do you pick Prim over Kruskal?
Kruskal fits an edge list. Prim fits adjacency lists, and on a dense graph Prim without a heap takes O(V²), less than sorting about V² edges.
