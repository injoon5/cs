---
id: bellman-ford
title: Negative weights and Bellman-Ford
---

Some weights are negative. An edge can be a refund, a downhill stretch that charges a battery, or a trade that gains money. One negative edge is enough to break Dijkstra.

```diagram
digraph
node 0 at 0,0.5
node 1 at 0.5,0
node 2 at 0.5,1
node 3 at 1,0
0 -> 1 2
0 -> 2 5
2 -> 1 -4
1 -> 3 1
```

The shortest route to 3 is 0, 2, 1, 3, which costs 5 − 4 + 1 = 2.

---

Here is Dijkstra from the last lessons on that graph. What does it print?

```python predict
import heapq

graph = {0: [(1, 2), (2, 5)], 1: [(3, 1)], 2: [(1, -4)], 3: []}
dist = {v: float("inf") for v in graph}
dist[0] = 0
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

Node 1 was settled at 2, and its edge set `dist[3]` to 3. Later, the edge from 2 lowered `dist[1]` to 1, but 1 was already done, so its edge to 3 was never relaxed again.

---

Bellman-Ford makes no guess about which node is final. It relaxes every edge, and does that in rounds. After round 1, every node whose shortest path has one edge has its distance. After round 2, every node whose shortest path has at most two edges, and so on.

Unless there is a negative cycle, which comes up below, a shortest path never needs to visit a node twice. So it needs at most V − 1 edges, and V − 1 rounds are enough.

```python trace stop=29
inf = float("inf")
n = 4
edges = [(1, 3, 1), (2, 1, -4), (0, 1, 2), (0, 2, 5)]
dist = [0, inf, inf, inf]
for rnd in range(1, n):
    for u, v, w in edges:
        if dist[u] + w < dist[v]:
            dist[v] = dist[u] + w
print(dist)
```

Round 2 has just ended. What is `dist`?

- [ ] `[0, 2, 5, inf]`
- [x] `[0, 1, 5, 3]`
- [ ] `[0, 1, 5, 2]`

The edges are in the worst order here, so each round gets one edge further. In a good order, fewer rounds would do, and a round that changes nothing means every distance is final, so you can stop early.

---

Each round relaxes all E edges, and there are V − 1 rounds. Bellman-Ford takes

- [ ] O(V + E) time
- [ ] O((V + E) log V) time
- [x] O(V × E) time

Slower than Dijkstra, but it doesn't care about signs.

---

A cycle whose weights add up to less than 0 is a negative cycle. Here 1, 2, 3 and back to 1 costs 1 − 3 + 1 = −1.

```diagram
digraph
node 0 at 0,0.5
node 1 at 0.4,0.5
node 2 at 1,0
node 3 at 1,1
0 -> 1 1
1 -> 2 1
2 -> 3 -3
3 -> 1 1
```

Each lap lowers the cost by 1, so there's no shortest path to 1, 2 or 3: every route can be beaten by going around once more. Distances only make sense when no negative cycle can be reached.

---

That gives Bellman-Ford a second job. Without a negative cycle, every distance is final after V − 1 rounds. So run one more round: if any edge still relaxes, there is a negative cycle. What does this print?

```python predict
def has_negative_cycle(n, edges, start):
    dist = [float("inf")] * n
    dist[start] = 0
    for _ in range(n - 1):
        for u, v, w in edges:
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
    for u, v, w in edges:
        if dist[u] + w < dist[v]:
            return True
    return False


edges = [(0, 1, 1), (1, 2, 1), (2, 3, -3), (3, 1, 1)]
print(has_negative_cycle(4, edges, 0))
edges[2] = (2, 3, -2)
print(has_negative_cycle(4, edges, 0))
```

A cycle of total 0 isn't negative: going around changes nothing. This only finds cycles that `start` can reach, since the others never get a finite distance.

---

Rounds have a meaning of their own: after round k, every path of at most k edges has been tried. That answers questions like "cheapest flight with at most k legs".

But a round that relaxes edges in place can chain several edges at once, if they come in the right order. What does this print?

```python predict
inf = float("inf")
edges = [(0, 1, 1), (1, 2, 1), (2, 3, 1), (0, 3, 10)]

dist = [0, inf, inf, inf]
for u, v, w in edges:
    if dist[u] + w < dist[v]:
        dist[v] = dist[u] + w
print("in place", dist)

dist = [0, inf, inf, inf]
prev = dist[:]
for u, v, w in edges:
    if prev[u] + w < dist[v]:
        dist[v] = prev[u] + w
print("from a copy", dist)
```

One round in place reached 3 for 3, along three edges. Reading from a copy of the last round's distances allows one more edge per round and no more. So for "at most k edges", copy `dist` at the start of each round and run k rounds.

---

A graph has some negative edges but no negative cycle. How do you find the distances from one node?

- [ ] Dijkstra, since there is no negative cycle
- [x] Bellman-Ford
- [ ] Dijkstra, after adding the same constant to every weight so they are all positive

Adding a constant charges a path once per edge. It punishes paths with many edges and can change which path is shortest: in the first graph, adding 4 makes 0, 2, 1, 3 cost 14 and 0, 1, 3 cost 11.

---

[Distances with negative edges](exercises/bellman-ford-distances.md)

[Negative cycle check](exercises/negative-cycle-check.md)

[Cheapest flight within k stops](exercises/cheapest-flight-k-stops.md)
