---
id: dijkstra
title: Dijkstra's algorithm
---

Start at 0 and relax its two edges. Now `dist[1]` is 7 and `dist[2]` is 2.

```diagram
digraph
node 0 at 0,0.5
node 1 at 0.35,0
node 2 at 0.35,1
node 3 at 0.7,0
node 4 at 0.7,1
node 5 at 1,0.5
0 -> 1 7
0 -> 2 2
1 -> 3 1
2 -> 1 3
2 -> 3 8
2 -> 4 5
3 -> 5 2
4 -> 3 1
4 -> 5 6
visited 0
frontier 1 2
highlight 2
```

Is 2 really 2 away? Any other route to 2 would leave 0 along the edge to 1, which already costs 7, and no edge has a negative weight to bring that back down. So `dist[2]` is final. Call 2 settled.

---

The same reasoning works at every step. Among the nodes that aren't settled, the one with the smallest `dist` is final. Settle it, relax its edges, and repeat. That is Dijkstra's algorithm.

Finding the smallest `dist` over and over is a job for a heap. Push `(dist, node)` tuples, so the heap orders them by distance. Run this to watch it. Filled nodes are settled, and outlined nodes have been reached but not settled yet.

```python
import heapq
import viz

graph = {0: [(1, 7), (2, 2)], 1: [(3, 1)], 2: [(1, 3), (3, 8), (4, 5)],
         3: [(5, 2)], 4: [(3, 1), (5, 6)], 5: []}
inf = float("inf")
dist = [0, inf, inf, inf, inf, inf]
heap = [(0, 0)]
done = []


def show(node, note):
    waiting = sorted({v for _, v in heap} - set(done))
    with viz.frame():
        viz.graph(graph, visited=done, frontier=waiting, active=node, directed=True)
        viz.array(dist, name="dist", highlight=node)
        viz.array(sorted(heap), name="heap", note=note)


show(None, "start at 0")
while heap:
    d, node = heapq.heappop(heap)
    if node in done:
        show(node, f"({d}, {node}) is out of date, skip it")
        continue
    done.append(node)
    for nxt, w in graph[node]:
        if d + w < dist[nxt]:
            dist[nxt] = d + w
            heapq.heappush(heap, (dist[nxt], nxt))
    show(node, f"settle {node} at {d}")
```

Nodes settle in order of distance: 0, 2, 1, 3, 4, 5.

---

Here is the same loop without the drawing.

```python trace stop=39
import heapq

graph = {0: [(1, 7), (2, 2)], 1: [(3, 1)], 2: [(1, 3), (3, 8), (4, 5)],
         3: [(5, 2)], 4: [(3, 1), (5, 6)], 5: []}
inf = float("inf")
dist = [0, inf, inf, inf, inf, inf]
heap = [(0, 0)]
done = set()
while heap:
    d, node = heapq.heappop(heap)
    if node in done:
        continue
    done.add(node)
    for nxt, w in graph[node]:
        if d + w < dist[nxt]:
            dist[nxt] = d + w
            heapq.heappush(heap, (dist[nxt], nxt))
print(dist)
```

Node 2 has just been settled and its edges relaxed. Which entries for node 1 are in `heap`?

- [ ] `(5, 1)` only
- [x] `(7, 1)` and `(5, 1)`
- [ ] `(7, 1)` only

---

When `dist[1]` dropped from 7 to 5, the old entry `(7, 1)` stayed in the heap. Why not find it and lower it instead of pushing a new one?

- [ ] The old entry is still needed in case 5 turns out wrong
- [x] `heapq` can't find an entry in the middle of the heap without a linear scan, but a push is O(log n)
- [ ] Tuples can't be changed, so the heap can't be updated

So the heap can hold out-of-date entries. By the time `(7, 1)` comes out, 1 was settled long ago at 5, and the `node in done` check skips it. This is called lazy deletion: leave the stale entry in place, and throw it away when it surfaces.

---

What does this print?

```python predict
import heapq

graph = {"a": [("b", 5), ("c", 1)], "b": [], "c": [("b", 1)]}
dist = {"a": 0, "b": float("inf"), "c": float("inf")}
heap = [(0, "a")]
done = set()
while heap:
    d, node = heapq.heappop(heap)
    if node in done:
        print("skip", node, d)
        continue
    done.add(node)
    print("settle", node, d)
    for nxt, w in graph[node]:
        if d + w < dist[nxt]:
            dist[nxt] = d + w
            heapq.heappush(heap, (dist[nxt], nxt))
```

---

Why is the closest unsettled node `u` final? Take any path from the start to `u`. It begins among settled nodes, so at some point it first steps onto an unsettled node `x`. That step came from a settled node whose edges were relaxed, so `dist[x]` is at most the length of the path up to `x`. And `dist[x]` is at least `dist[u]`, since `u` is the closest.

The rest of the path, from `x` on to `u`, adds its edge weights. Which assumption makes the whole path at least `dist[u]` long?

- [ ] The graph has no cycles
- [x] Every edge weight is 0 or more, so the rest of the path can't make it shorter
- [ ] Every node is reachable from the start

With a negative edge after `x`, a path could dip below `dist[u]` after `u` is settled. The lesson on Bellman-Ford shows it happening.

---

Put the lines in order so `dijkstra` returns the distance from `start` to every node, with `float("inf")` for nodes it can't reach.

```python arrange
import heapq


def dijkstra(graph, start):
    dist = {v: float("inf") for v in graph}
    dist[start] = 0
    heap = [(0, start)]
    done = set()
    while heap:
        d, node = heapq.heappop(heap)
        if node in done:
            continue
        done.add(node)
        for nxt, w in graph[node]:
            if d + w < dist[nxt]:
                dist[nxt] = d + w
                heapq.heappush(heap, (dist[nxt], nxt))
    return dist
```

```tests
dijkstra({0: [(1, 4), (2, 1)], 1: [(3, 1)], 2: [(1, 2), (3, 5)], 3: []}, 0) == {0: 0, 1: 3, 2: 1, 3: 4}
dijkstra({0: [(1, 2)], 1: [], 2: [(0, 1)]}, 0) == {0: 0, 1: 2, 2: float("inf")}
dijkstra({"a": []}, "a") == {"a": 0}
dijkstra({0: [(1, 0)], 1: [(0, 0)]}, 1) == {0: 0, 1: 0}
```

---

Each node is settled once, and its edges are relaxed once then. So there are at most E + 1 pushes, and the heap never holds more entries than that. On a graph with V nodes and E edges, Dijkstra's algorithm takes

- [ ] O(V + E) time
- [x] O((V + E) log V) time
- [ ] O(V × E) time

Each push and pop costs O(log E), and log E is at most log V² = 2 log V.

---

[Network delay](exercises/network-delay-time.md)
