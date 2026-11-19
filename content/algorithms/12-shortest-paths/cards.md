## Why doesn't BFS find shortest paths when edges have weights?
BFS finds the path with the fewest edges. A path with more edges can weigh less in total.

## What does it mean to relax an edge `(u, v, w)`?
If `dist[u] + w < dist[v]`, set `dist[v] = dist[u] + w`. `dist[v]` only ever drops to the length of a real path, so it never goes below the true distance.

## How does Dijkstra's algorithm work?
Start with `dist[start] = 0` and a heap of `(dist, node)`. Pop the closest node; if it isn't settled yet, settle it and relax its edges, pushing every distance that improves.

## Why is the closest unsettled node final in Dijkstra?
Any other path to it leaves the settled nodes through an unsettled node that is at least as far, and the rest of the path can only add weight. That needs every weight to be 0 or more.

## What is lazy deletion in Dijkstra?
When a distance improves, push a new entry and leave the old one in the heap. When an entry pops for a node that is already settled, skip it.

## What does Dijkstra cost?
O((V + E) log V) time with a binary heap, and O(V + E) space. There are at most E pushes, each O(log E) = O(log V).

## How do you get the path out of Dijkstra?
Set `parent[nxt] = node` each time relaxing lowers `dist[nxt]`. Walk the parents back from the goal and reverse.

## When can Dijkstra stop early for one goal?
When the goal comes off the heap and is settled. The first distance found for it can still drop.

## What goes wrong with Dijkstra on a negative edge?
A node can be settled, then a cheaper path to it found later through the negative edge. Its edges were already relaxed with the old distance, so nodes after it can come out wrong.

## How does Bellman-Ford work, and what does it cost?
Relax every edge, V − 1 times. After round k, every shortest path of at most k edges has been found. O(V × E) time. Negative weights are fine.

## How does Bellman-Ford detect a negative cycle?
Run one more round after V − 1. If any edge still relaxes, a negative cycle can be reached from the start.

## How do you find the cheapest path with at most k edges?
Run k rounds of Bellman-Ford, and in each round read distances from a copy made at the start of the round. Relaxing in place can chain several edges in one round.

## How does Floyd-Warshall work?
Start with the edge weights in a V × V matrix. For each `k`, for each pair `i`, `j`: `d[i][j] = min(d[i][j], d[i][k] + d[k][j])`. After round `k`, paths may stop over at nodes 0 to `k`. `k` must be the outer loop.

## When is Floyd-Warshall a good choice?
For all-pairs distances on a small or dense graph, or with negative edges. O(V³) time, O(V²) space. A negative cycle shows up as `d[i][i] < 0`.

## How do you find shortest paths in a DAG?
Relax each node's edges in topological order. One pass, O(V + E), and negative weights are fine.

## What is 0-1 BFS?
Dijkstra for weights of 0 and 1 with a deque in place of a heap: `appendleft` over a 0 edge, `append` over a 1 edge. O(V + E).
