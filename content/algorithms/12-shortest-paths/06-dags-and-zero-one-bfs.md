---
id: dag-and-zero-one-bfs
title: Shortcuts for DAGs and 0-1 weights
---

Two kinds of graph have a faster way than Dijkstra. The first is a DAG, a directed graph with no cycles, like the task graphs from the last unit.

```diagram
digraph
node 0 at 0,0.5
node 1 at 0.3,0
node 3 at 0.65,0
node 2 at 0.65,1
node 4 at 1,0.5
0 -> 1 2
0 -> 2 6
1 -> 2 3
1 -> 3 1
3 -> 2 -2
3 -> 4 5
2 -> 4 1
```

Go through the nodes in topological order and relax each node's edges. Every edge into `v` comes from a node earlier in the order. So by the time `v`'s turn comes, every edge into it has been relaxed from a final distance, and `dist[v]` is final too. One pass, no heap.

---

Here Kahn's algorithm from the last unit gives the order, then one loop relaxes the edges. The weight from 3 to 2 is negative, and that's fine: with no cycles there is nothing to loop around. What does this print?

```python predict
from collections import deque

graph = {0: [(1, 2), (2, 6)], 1: [(2, 3), (3, 1)], 2: [(4, 1)],
         3: [(2, -2), (4, 5)], 4: []}
indegree = {v: 0 for v in graph}
for v in graph:
    for nxt, _ in graph[v]:
        indegree[nxt] += 1
queue = deque(v for v in graph if indegree[v] == 0)
order = []
while queue:
    v = queue.popleft()
    order.append(v)
    for nxt, _ in graph[v]:
        indegree[nxt] -= 1
        if indegree[nxt] == 0:
            queue.append(nxt)

dist = {v: float("inf") for v in graph}
dist[0] = 0
for u in order:
    for v, w in graph[u]:
        if dist[u] + w < dist[v]:
            dist[v] = dist[u] + w
print(order)
print(dist)
```

The topological sort and the pass each take O(V + E), so the whole thing does too.

---

The longest path in a DAG, like the project time from the last unit, falls out the same way: negate every weight and find the shortest path, or use `max` in place of `min`. Why doesn't negating work for longest paths in a graph with cycles?

- [ ] Kahn's algorithm can't handle negative weights
- [x] A cycle with positive weights becomes a negative cycle, so there is no shortest path to find
- [ ] Bellman-Ford can't handle the negated weights

No fast algorithm is known for the longest simple path in a general graph.

---

The second kind has every weight 0 or 1. Say you walk through a building where open doors are free and each locked door costs 1 to break.

Dijkstra works, but look at its heap. When it pops a node at distance `d`, it pushes entries at `d` (over a 0 edge) or `d + 1` (over a 1 edge). So every entry waiting in the heap has distance `d` or `d + 1`. A deque can keep them in order without a heap: put `d` entries at the front with `appendleft`, and `d + 1` entries at the back with `append`.

```diagram
digraph
node 0 at 0,0.5
node 1 at 0.5,0
node 2 at 0.33,1
node 3 at 0.67,1
node 4 at 1,0.5
0 -> 1 1
0 -> 2 0
1 -> 4 0
2 -> 3 1
3 -> 4 1
```

---

This is 0-1 BFS. Apart from the deque, it is the same loop as Dijkstra.

```python trace stop=44
from collections import deque

graph = {0: [(1, 1), (2, 0)], 1: [(4, 0)], 2: [(3, 1)],
         3: [(4, 1)], 4: []}
dist = {v: float("inf") for v in graph}
dist[0] = 0
dq = deque([(0, 0)])
done = set()
while dq:
    d, node = dq.popleft()
    if node in done:
        continue
    done.add(node)
    for nxt, w in graph[node]:
        if d + w < dist[nxt]:
            dist[nxt] = d + w
            if w == 0:
                dq.appendleft((d, nxt))
            else:
                dq.append((d + 1, nxt))
print(dist)
```

Node 1 has just been handled. What is in `dq`?

- [x] `(1, 4), (1, 3)`
- [ ] `(1, 3), (1, 4)`
- [ ] `(1, 3), (2, 4)`

---

Why does an entry over a 0 edge go to the front of the deque?

- [ ] Free edges should be explored first, whatever their distance
- [x] It has distance `d`, the smallest in the deque, so it belongs before every `d + 1` entry
- [ ] The front of a deque is faster to reach than the back

---

Each push and pop on a deque is O(1), and as in Dijkstra each node is handled once. 0-1 BFS takes

- [x] O(V + E) time
- [ ] O((V + E) log V) time
- [ ] O(V × E) time

It is BFS with a second lane. Plain BFS is the case where every weight is 1.

---

[Shortest paths in a DAG](exercises/dag-shortest-paths.md)

[Fewest walls](exercises/fewest-walls-removed.md)
