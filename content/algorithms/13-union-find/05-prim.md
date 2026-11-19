---
id: prim-mst
title: Prim's algorithm
---

Kruskal grows many small trees and merges them. Prim's algorithm grows one tree from a start node. At every step it takes the cheapest edge with one end in the tree and the other end outside, and the outside end joins the tree.

That is the cut property with the tree on one side, so every edge Prim takes is safe. Here it started at 0 and has taken 0 – 5 and 5 – 1. The filled nodes are the tree.

```diagram
graph
node 0 at 0.5,0
node 1 at 0.93,0.25
node 2 at 0.93,0.75
node 3 at 0.5,1
node 4 at 0.07,0.75
node 5 at 0.07,0.25
0 -- 1 4
1 -- 2 7
2 -- 3 5
3 -- 4 8
4 -- 5 6
5 -- 0 3
1 -- 5 1
2 -- 4 2
visited 0 1 5
```

Which edge does Prim take next?

- [ ] 0 – 1, cost 4
- [x] 4 – 5, cost 6
- [ ] 2 – 4, cost 2

---

A min-heap finds the cheapest crossing edge. When a node joins the tree, push `(w, v)` for each of its edges to a node `v` outside the tree. Then pop the cheapest entry.

An entry can go stale. When 1 joined through the edge of cost 1, the entry `(4, 1)`, pushed when 0 joined, was still in the heap. When a popped entry leads to a node already in the tree, skip it. Leaving old entries in the heap and skipping them later is called lazy deletion.

---

The start node goes in the heap with cost 0. What does this print?

```python predict
import heapq

graph = {0: [(1, 4), (5, 3)], 1: [(0, 4), (2, 7), (5, 1)],
         2: [(1, 7), (3, 5), (4, 2)], 3: [(2, 5), (4, 8)],
         4: [(3, 8), (5, 6), (2, 2)], 5: [(4, 6), (0, 3), (1, 1)]}
in_tree = set()
heap = [(0, 0)]
total = 0
order = []
while heap:
    w, v = heapq.heappop(heap)
    if v in in_tree:
        continue
    in_tree.add(v)
    order.append(v)
    total += w
    for nxt, cost in graph[v]:
        if nxt not in in_tree:
            heapq.heappush(heap, (cost, nxt))
print(order, total)
```

---

The total is 17, the same as Kruskal's. When no two edges have the same weight, there is only one minimum spanning tree, and both algorithms find it.

Run this to watch the tree grow. Filled nodes are in the tree, and outlined nodes have an entry in the heap. The heap is listed below, cheapest first.

```python
import heapq
import viz

graph = {0: [(1, 4), (5, 3)], 1: [(0, 4), (2, 7), (5, 1)],
         2: [(1, 7), (3, 5), (4, 2)], 3: [(2, 5), (4, 8)],
         4: [(3, 8), (5, 6), (2, 2)], 5: [(4, 6), (0, 3), (1, 1)]}
in_tree = set()
tree = {v: [] for v in graph}
heap = [(0, 0, None)]


def show(active, note):
    waiting = [v for _, v, _ in heap if v not in in_tree]
    with viz.frame():
        viz.graph(tree, visited=in_tree, frontier=waiting, active=active, note=note)
        viz.queue([(w, v) for w, v, _ in sorted(heap)], name="heap")


show(None, "0 waits in the heap with cost 0")
while heap:
    w, v, came_from = heapq.heappop(heap)
    if v in in_tree:
        show(None, f"({w}, {v}) is stale, skip")
        continue
    in_tree.add(v)
    if came_from is None:
        note = f"{v} starts the tree"
    else:
        tree[came_from].append((v, w))
        note = f"{v} joins for {w}"
    for nxt, cost in graph[v]:
        if nxt not in in_tree:
            heapq.heappush(heap, (cost, nxt, v))
    show(v, note)
```

Each entry also remembers the tree node it came from, only so the drawing knows which edge to add.

---

Here is the same loop without the drawing.

```python trace stop=66
import heapq

graph = {0: [(1, 4), (5, 3)], 1: [(0, 4), (2, 7), (5, 1)],
         2: [(1, 7), (3, 5), (4, 2)], 3: [(2, 5), (4, 8)],
         4: [(3, 8), (5, 6), (2, 2)], 5: [(4, 6), (0, 3), (1, 1)]}
in_tree = set()
heap = [(0, 0)]
total = 0
while heap:
    w, v = heapq.heappop(heap)
    if v in in_tree:
        continue
    in_tree.add(v)
    total += w
    for nxt, cost in graph[v]:
        if nxt not in in_tree:
            heapq.heappush(heap, (cost, nxt))
print(total)
```

4 has just joined the tree, and its edges are pushed. Which entries are in `heap`?

- [ ] `(2, 2)` and `(8, 3)`
- [x] `(2, 2)`, `(7, 2)` and `(8, 3)`
- [ ] `(2, 2)`, `(4, 1)`, `(7, 2)` and `(8, 3)`

---

An edge is pushed at most once, when the first of its two ends joins the tree, so the heap never holds more than E entries. Each push and pop costs O(log E), which is O(log V). On a graph with V nodes and E edges, Prim's algorithm takes

- [ ] O(V log V)
- [x] O(E log V)
- [ ] O(V × E)

If you have seen Dijkstra's shortest paths algorithm, this loop has the same shape. Dijkstra orders the heap by distance from the start. Prim orders it by the cost of the one edge that would join a node to the tree.

---

Both algorithms take O(E log V). Kruskal fits a list of edges, since it only needs to sort them. Prim fits adjacency lists, and never sorts anything.

On a dense graph, where nearly every pair of nodes has an edge, E is about V² / 2. Prim can drop the heap there. Keep, for every node outside the tree, the cost of its cheapest edge into the tree. Each step scans those costs for the smallest, adds that node, and updates the costs from it.

On a complete graph with V nodes, this array version of Prim takes

- [x] O(V²), less than the O(V² log V) the heap would take
- [ ] O(V log V)
- [ ] O(V³), since every step looks at every edge

---

[Prim's algorithm](exercises/prim-total-weight.md)

[Connect the points](exercises/connect-points-cost.md)
