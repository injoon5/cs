## What is an adjacency list?
A dict from each node to the list of its neighbors. An undirected edge appears in both lists, a directed one only in the list of the node it leaves. It takes O(V + E) space.

## Adjacency list or adjacency matrix?
A matrix checks one edge in O(1) but takes V² space, and listing a node's neighbors scans a whole row. A list takes O(V + E) space and hands you the neighbors directly. Most graphs have few edges per node, so use a list.

## How does breadth-first search work?
Put the start in a queue and in a seen set. Take a node from the front, and add each unseen neighbor to the seen set and to the back of the queue. Nodes come out in order of distance from the start.

## Why does BFS mark a node seen when it joins the queue, not when it leaves?
So each node joins the queue at most once. Marking on the way out lets a node be queued again by every neighbor that finds it before it is taken out.

## Why does BFS find shortest paths in an unweighted graph?
Every node at distance d leaves the queue before any node at d + 1, so the first time BFS reaches a node it comes from a node as close to the start as possible.

## How do you get the path itself out of BFS?
Record each node's parent, the node it was found from. Then walk the parents back from the goal to the start and reverse the list.

## What do BFS and DFS cost on adjacency lists?
O(V + E) time: each node is visited once and each neighbor list is read once. O(V) extra space for the queue or stack and the seen set.

## What are the neighbors of a grid cell?
The cells up, down, left and right that are inside the grid and open. Check `0 <= nr` too: in Python `grid[-1]` quietly reads the last row.

## What is multi-source BFS?
Put every source in the queue at distance 0 before starting. One BFS then gives each cell its distance to the nearest source, in O(R × C) on a grid.

## When should DFS use its own stack instead of recursion?
When a path can be long, as in a big grid or a long chain. Python stops at about 1,000 nested calls.

## How do you count connected components?
Go through every node. Each one not seen yet starts a new component: count it and search from it to mark the whole component. O(V + E) in total.

## When do you need BFS rather than DFS?
When you need the fewest steps. For reachability, components or flood fill, either works.

## What is a topological order, and when does one exist?
An order of all the nodes where every edge points from earlier to later. One exists exactly when the directed graph has no cycle.

## How does Kahn's algorithm work?
Count each node's in-degree and queue the nodes with in-degree 0. Take one, append it to the order, and lower the in-degree of everything it points to, queueing any that reach 0. If the order ends up shorter than the graph, there is a cycle.

## How does DFS give a topological order?
A node's call finishes only after everything it points to has finished. Append each node when its call finishes, then reverse the list.

## How does DFS find a cycle in a directed graph?
Mark each node new, open while its call is running, or done once it returns. An edge to an open node closes a cycle. An edge to a done node doesn't.
