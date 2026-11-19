---
id: edge-relaxation
title: Weighted edges and relaxation
---

Each edge here is a one-way road, and its number is the length. What is the shortest route from 0 to 3?

```diagram
digraph
node 0 at 0,0.5
node 1 at 0.5,0
node 2 at 0.5,1
node 3 at 1,0.5
0 -> 1 4
0 -> 2 1
2 -> 1 2
1 -> 3 1
2 -> 3 5
highlight 0 3
```

The two-edge routes cost 4 + 1 = 5 through 1, and 1 + 5 = 6 through 2. The three-edge route 0, 2, 1, 3 costs 1 + 2 + 1 = 4, the shortest of all. More edges can add up to less.

The length of a path is the sum of its edge weights, and the distance from one node to another is the length of the shortest path between them.

---

A weighted graph is stored like an unweighted one, except each neighbor comes with the weight of the edge: a dict from each node to a list of `(neighbor, weight)` pairs.

```python
graph = {
    0: [(1, 4), (2, 1)],
    1: [(3, 1)],
    2: [(1, 2), (3, 5)],
    3: [],
}
for nxt, w in graph[2]:
    print("2 ->", nxt, "weighs", w)
```

The graphs in this unit are directed. For an undirected graph, store each edge in both lists, as in the last unit.

---

Weighted edges usually arrive as triples `(a, b, w)`. `dict(graph[a])` turns a neighbor list into a dict from neighbor to weight, which is handy for looking up one edge. What does this print?

```python predict
edges = [(0, 1, 4), (0, 2, 1), (2, 1, 2), (1, 3, 1), (2, 3, 5)]
graph = {v: [] for v in range(4)}
for a, b, w in edges:
    graph[a].append((b, w))

for path in ([0, 1, 3], [0, 2, 1, 3]):
    total = 0
    for a, b in zip(path, path[1:]):
        total += dict(graph[a])[b]
    print(path, total)
```

---

BFS from 0 reaches 3 along 0, 1, 3, which costs 5. One fix: split every edge of weight w into a chain of w edges of weight 1, then run BFS on the bigger graph. For whole-number weights that gives the right answer. Why not always do it?

- [ ] BFS can't handle the extra nodes the chains add
- [x] The graph grows with the weights: one edge of weight 1,000,000 becomes a million edges
- [ ] It only works when the graph has no cycles

The algorithms in this unit work with the weights directly, so their cost depends on the number of nodes and edges, not on how big the weights are.

---

Every algorithm in this unit keeps a best distance found so far for each node. At the start nothing has been reached, so every distance is infinity except the start's, which is 0.

```python
inf = float("inf")
dist = {v: inf for v in range(4)}
dist[0] = 0
print(dist)
print(inf + 5, 7 < inf, min(inf, 9))
```

`float("inf")` behaves the way infinity should: adding to it leaves it infinite, and every number is smaller. So "not reached yet" needs no special case.

---

Say the best distance found so far to `u` is 4, and to `v` is 9. There is an edge from `u` to `v` of weight 3.

```diagram
digraph
node s "0" at 0,0.5
node u at 0.5,0
node v at 1,0.5
s -> u 4
s -> v 9
u -> v 3
highlight u v
```

Going through `u` reaches `v` for 4 + 3 = 7, which beats 9. So `dist[v]` becomes 7. Checking one edge this way and keeping the shorter distance is called relaxing the edge:

```python
dist = {"u": 4, "v": 9}
u, v, w = "u", "v", 3
if dist[u] + w < dist[v]:
    dist[v] = dist[u] + w
print(dist)
```

---

Here every edge of the first graph is relaxed once, in this order, starting from 0.

```python trace stop=13
inf = float("inf")
edges = [(0, 1, 4), (0, 2, 1), (2, 1, 2), (1, 3, 1), (2, 3, 5)]
dist = [0, inf, inf, inf]
for u, v, w in edges:
    if dist[u] + w < dist[v]:
        dist[v] = dist[u] + w
print(dist)
```

The edge `(2, 1, 2)` has just been relaxed. What is `dist`?

- [ ] `[0, 4, 1, inf]`
- [x] `[0, 3, 1, inf]`
- [ ] `[0, 3, 1, 4]`

---

One pass found every distance, because this order happened to relax each edge after its start node's distance was already final. Here are the same edges in a worse order, relaxed in passes until a pass changes nothing. What does this print?

```python predict
inf = float("inf")
edges = [(1, 3, 1), (2, 3, 5), (2, 1, 2), (0, 1, 4), (0, 2, 1)]
dist = [0, inf, inf, inf]
passes = 0
changed = True
while changed:
    changed = False
    for u, v, w in edges:
        if dist[u] + w < dist[v]:
            dist[v] = dist[u] + w
            changed = True
    passes += 1
    print(passes, dist)
```

---

Relaxing an edge only ever lowers `dist[v]` to `dist[u] + w`, the length of a real path to `u` plus one more edge. So at every moment, `dist[v]` is

- [ ] the distance from the start to `v`
- [x] the length of some real path to `v`, or infinity, so never less than the distance
- [ ] the fewest edges from the start to `v`

So relaxing, in any order, never pushes a distance below the true one. A bad order only costs more passes. The algorithms in this unit differ in the order they choose. Dijkstra's algorithm picks an order where each edge needs relaxing once. Bellman-Ford doesn't pick: it relaxes everything, pass after pass.

---

[Route cost](exercises/route-cost.md)
