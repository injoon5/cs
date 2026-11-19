---
id: using-dijkstra
title: Using Dijkstra
---

To get the route and not only its length, record parents as BFS did. The one change: a node's parent can change. Whenever relaxing an edge from `node` lowers `dist[nxt]`, set `parent[nxt] = node`, replacing any earlier parent.

To go from one start to one goal, you can also stop as soon as the goal is settled.

```python
import heapq

graph = {0: [(1, 7), (2, 2)], 1: [(3, 1)], 2: [(1, 3), (3, 8), (4, 5)],
         3: [(5, 2)], 4: [(3, 1), (5, 6)], 5: []}


def cheapest(graph, start, goal):
    dist = {v: float("inf") for v in graph}
    dist[start] = 0
    parent = {start: None}
    heap = [(0, start)]
    done = set()
    while heap:
        d, node = heapq.heappop(heap)
        if node in done:
            continue
        if node == goal:
            break
        done.add(node)
        for nxt, w in graph[node]:
            if d + w < dist[nxt]:
                dist[nxt] = d + w
                parent[nxt] = node
                heapq.heappush(heap, (dist[nxt], nxt))
    path = []
    node = goal
    while node is not None:
        path.append(node)
        node = parent[node]
    return dist[goal], path[::-1]


print(cheapest(graph, 0, 5))
print(cheapest(graph, 0, 1))
```

Node 1's parent was first 0, when `dist[1]` was 7, then 2 when it dropped to 5.

---

BFS could stop the moment it first saw the goal. Why does Dijkstra have to wait until the goal comes off the heap?

- [ ] The goal has no entry in `parent` until it is settled
- [x] The first distance found can still drop: 1 is first reached at 7, and its distance is 5
- [ ] A node can't be pushed onto the heap until its parent is settled

---

Grids come with costs too. Each cell holds the cost of standing on it, and a path costs the sum of its cells. Moves go up, down, left or right. What is the cheapest way from the top-left corner to the bottom-right?

```diagram
grid
row [1, 9, 1, 1, 1]
row [1, 9, 1, 9, 1]
row [1, 1, 1, 9, 1]
highlight 0,0 1,0 2,0 2,1 2,2 1,2 0,2 0,3 0,4 1,4 2,4
```

The cheap path snakes down, across and back up. It is 11 cells long and costs 11. A grid where you may only move right and down could be filled in row by row, but once paths can turn back, there is no row order to follow.

---

Dijkstra runs on the grid unchanged. A cell `(r, c)` is a node, and its neighbors come from the four moves, as in the grids lesson. An edge into `(nr, nc)` weighs `grid[nr][nc]`, and the start costs its own cell. Here the heap holds `(cost, r, c)`. What does this print?

```python predict
import heapq

grid = [[1, 3, 1],
        [1, 5, 1],
        [4, 2, 1]]
rows, cols = len(grid), len(grid[0])
dist = {(0, 0): grid[0][0]}
heap = [(grid[0][0], 0, 0)]
done = set()
while heap:
    d, r, c = heapq.heappop(heap)
    if (r, c) in done:
        continue
    done.add((r, c))
    for nr, nc in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
        if 0 <= nr < rows and 0 <= nc < cols:
            nd = d + grid[nr][nc]
            if nd < dist.get((nr, nc), float("inf")):
                dist[(nr, nc)] = nd
                heapq.heappush(heap, (nd, nr, nc))
print(dist[(2, 2)], dist[(2, 0)])
```

`dist.get(cell, float("inf"))` treats a cell with no entry yet as unreached, so there's no need to fill in every cell first.

---

Sometimes a path isn't judged by its total. A hiker cares about the steepest single climb, not the sum: a path's cost is its largest edge weight.

```diagram
digraph
node 0 at 0,0.5
node 1 at 0.5,0
node 2 at 0.5,1
node 3 at 1,0.5
0 -> 1 5
1 -> 3 5
0 -> 2 1
2 -> 3 8
```

By total length, 0, 2, 3 wins with 9. By largest step, 0, 1, 3 wins: its worst edge is 5, and the other route has an 8.

Dijkstra still works with one change. Extending a path to `nxt` costs `max(d, w)` instead of `d + w`. What does this print?

```python predict
import heapq

graph = {0: [(1, 5), (2, 1)], 1: [(3, 5)], 2: [(3, 8)], 3: []}
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
        cost = max(d, w)
        if cost < dist[nxt]:
            dist[nxt] = cost
            heapq.heappush(heap, (cost, nxt))
print(dist)
```

---

The proof that the closest unsettled node is final leaned on one fact: making a path longer never makes it cheaper. For which of these path costs does Dijkstra, with the matching combine step, find the best path?

- [x] The total weight, all weights 0 or more: `d + w`
- [x] The largest weight on the path: `max(d, w)`
- [x] The chance of getting through, when each edge succeeds with probability `p`: `d * p`, keeping the largest
- [ ] The total weight, some weights negative: `d + w`

The first three keep that fact. Probabilities are at most 1, so multiplying by another one never raises the chance. That case wants the largest value first: push `-chance` so the min-heap pops the most likely path first, the max-heap trick from the heaps unit. A negative weight breaks the fact, and the next lesson shows what goes wrong.

---

[Cheapest route](exercises/cheapest-route.md)

[Cheapest path through a grid](exercises/grid-min-cost-path.md)

[Least effort](exercises/min-effort-path.md)

[Most reliable path](exercises/most-reliable-path.md)
