---
id: breadth-first-search
title: Breadth-first search
---

How many edges does it take to get from 0 to each of the other nodes?

```diagram
graph
node 0 at 0.5,0
node 1 at 0.93,0.25
node 2 at 0.93,0.75
node 3 at 0.5,1
node 4 at 0.07,0.75
node 5 at 0.07,0.25
0 -- 1
0 -- 5
1 -- 2
1 -- 4
2 -- 3
3 -- 4
4 -- 5
highlight 0
```

Work outward in rings. 1 and 5 are one edge away. Their new neighbors, 2 and 4, are two away. 3 is three away.

Breadth-first search, BFS, finds the rings in that order. It is level order from the trees unit: take a node from the front of a queue and add its neighbors at the back. One thing is new. A graph can reach the same node by two routes, as 4 is reached from 1 and from 5, so BFS keeps a set of the nodes it has already seen.

---

Here it is on the graph above.

```python
from collections import deque

graph = {0: [1, 5], 1: [0, 2, 4], 2: [1, 3],
         3: [2, 4], 4: [1, 3, 5], 5: [0, 4]}


def bfs(graph, start):
    seen = {start}
    queue = deque([start])
    order = []
    while queue:
        node = queue.popleft()
        order.append(node)
        for nxt in graph[node]:
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return order


print(bfs(graph, 0))
```

---

Run this to watch the rings grow. Outlined nodes are waiting in the queue, and filled nodes are done.

```python
import viz
from collections import deque

graph = {0: [1, 5], 1: [0, 2, 4], 2: [1, 3],
         3: [2, 4], 4: [1, 3, 5], 5: [0, 4]}
seen = {0}
queue = deque([0])
done = []
viz.graph(graph, frontier=queue, note="queue [0]")
while queue:
    node = queue.popleft()
    for nxt in graph[node]:
        if nxt not in seen:
            seen.add(nxt)
            queue.append(nxt)
    done.append(node)
    note = f"take {node}, queue {list(queue)}"
    viz.graph(graph, visited=done, frontier=queue, active=node, note=note)
```

When 5 comes out, 4 is already in the queue, so 5 adds nothing.

---

This version marks a node as seen when it leaves the queue instead of when it joins. What does it print?

```python predict
from collections import deque

graph = {0: [1, 5], 1: [0, 2, 4], 2: [1, 3],
         3: [2, 4], 4: [1, 3, 5], 5: [0, 4]}
seen = set()
queue = deque([0])
order = []
while queue:
    node = queue.popleft()
    seen.add(node)
    order.append(node)
    for nxt in graph[node]:
        if nxt not in seen:
            queue.append(nxt)
print(order)
```

---

Marking a node as seen the moment it joins the queue makes sure that

- [ ] nodes leave the queue in sorted order
- [x] each node joins the queue at most once
- [ ] the start node is never visited

Marked on the way out, 4 was queued by both 1 and 5 before either copy came out, and 3 by 2 and twice by 4. On a graph with many edges the queue can hold far more entries than there are nodes.

---

The seen set can do one more job. Store each node's distance from the start in a dict instead: a neighbor found from `node` is one edge further than `node`. A node is seen exactly when it has a distance.

```python trace stop=31
from collections import deque

graph = {0: [1, 5], 1: [0, 2, 4], 2: [1, 3],
         3: [2, 4], 4: [1, 3, 5], 5: [0, 4]}
dist = {0: 0}
queue = deque([0])
while queue:
    node = queue.popleft()
    for nxt in graph[node]:
        if nxt not in dist:
            dist[nxt] = dist[node] + 1
            queue.append(nxt)
print(dist)
```

Node 1 has just been handled. What is in `queue`?

- [ ] 2, 4
- [x] 5, 2, 4
- [ ] 2, 4, 5

---

The queue only ever holds nodes from two rings: some at distance d, then some at d + 1. Every node at distance d leaves before any node at d + 1. So the first time BFS reaches a node, it comes from a node as close to the start as possible, and the distance it writes down is the fewest edges.

The edges have lengths now, like roads in kilometers. Does BFS still find the shortest route?

- [ ] Yes, BFS always finds the shortest route
- [x] No, it finds the route with the fewest edges, which can be longer in kilometers
- [ ] Only if the graph has no cycles

Weighted shortest paths need Dijkstra's algorithm, in the next unit.

---

To get the route itself and not only its length, record each node's parent: the node it was found from. Start with `parent = {start: None}` and set `parent[nxt] = node` at the moment the distance version sets `dist[nxt]`.

Then walk from the goal back along the parents until you reach `None`, and reverse. What does this print?

```python predict
parent = {0: None, 1: 0, 5: 0, 2: 1, 4: 1, 3: 2}
path = []
node = 3
while node is not None:
    path.append(node)
    node = parent[node]
print(path[::-1])
```

---

Each node joins the queue once, and when it leaves, BFS reads its neighbor list once. On a graph with V nodes and E edges stored as adjacency lists, BFS takes

- [ ] O(V) time
- [x] O(V + E) time, O(V) extra space
- [ ] O(V × E) time

---

[Is there a path](exercises/path-exists.md)

[Shortest route](exercises/fewest-hops-path.md)

[Word ladder](exercises/word-ladder-steps.md)
