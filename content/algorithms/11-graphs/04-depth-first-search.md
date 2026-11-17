---
id: depth-first-search
title: Depth-first search
---

BFS spreads out evenly in rings. Depth-first search, DFS, does the opposite: it follows one path as far as it can, and only backs up when every neighbor is already seen. It moves the way backtracking did in the recursion unit.

```diagram
graph
node 0 at 0.5,0
node 1 at 0.89,0.19
node 2 at 0.99,0.61
node 3 at 0.72,0.95
node 4 at 0.28,0.95
node 5 at 0.01,0.61
node 6 at 0.11,0.19
0 -- 1
0 -- 6
1 -- 2
1 -- 5
2 -- 3
4 -- 5
5 -- 6
highlight 0
```

From 0, DFS goes to 1, then 2, then 3. At 3 it's stuck, so it backs up to 2, which has nothing new either, then to 1, and tries 5 next.

---

Recursion does the backing up for free: when a call runs out of neighbors, it returns to the call that found it.

```python trace stop=51
graph = {0: [1, 6], 1: [0, 2, 5], 2: [1, 3], 3: [2],
         4: [5], 5: [1, 4, 6], 6: [0, 5]}
seen = set()
order = []


def dfs(node):
    seen.add(node)
    order.append(node)
    for nxt in graph[node]:
        if nxt not in seen:
            dfs(nxt)


dfs(0)
print(order)
```

`dfs(4)` has just started. Which calls are waiting below it on the stack?

- [ ] `dfs(5)` only
- [x] `dfs(0)`, `dfs(1)` and `dfs(5)`
- [ ] `dfs(0)`, `dfs(1)`, `dfs(2)`, `dfs(3)` and `dfs(5)`

---

Run this to watch the calls. Outlined nodes are on the current path, which is exactly the stack of open calls: one `dfs` call per node.

```python
import viz

graph = {0: [1, 6], 1: [0, 2, 5], 2: [1, 3], 3: [2],
         4: [5], 5: [1, 4, 6], 6: [0, 5]}
seen = set()
path = []


def dfs(node):
    seen.add(node)
    path.append(node)
    viz.graph(graph, visited=seen, frontier=path, active=node, note=f"visit {node}")
    for nxt in graph[node]:
        if nxt not in seen:
            dfs(nxt)
    path.pop()
    if path:
        viz.graph(graph, visited=seen, frontier=path, active=path[-1], note=f"back to {path[-1]}")


dfs(0)
```

---

You can also keep the stack yourself. Take BFS and swap the queue for a list: `pop()` takes the newest node instead of the oldest. What does this print?

```python predict
graph = {0: [1, 2], 1: [3], 2: [4], 3: [], 4: []}
seen = {0}
stack = [0]
order = []
while stack:
    node = stack.pop()
    order.append(node)
    for nxt in graph[node]:
        if nxt not in seen:
            seen.add(nxt)
            stack.append(nxt)
print(order)
```

It still goes deep before wide, but it takes the last neighbor first, so the order differs from the recursive version. When the question is only what can be reached, the order doesn't matter.

---

A grid of 300 × 300 open cells is one big region. A recursive DFS from a corner can be

- [ ] at most about 600 calls deep, the length of a path across the grid
- [x] up to 90,000 calls deep, far past Python's limit of about 1,000, so use your own stack
- [ ] at most 4 calls deep, since each cell has 4 neighbors

---

A graph can fall into separate pieces with no edges between them. Each piece is a connected component.

```diagram
graph
0 -- 1
1 -- 2
3 -- 4
node 5
```

To count them, go through every node. If it isn't seen yet, it starts a new component: count it and run DFS from it to mark the whole piece.

---

```python
graph = {0: [1], 1: [0, 2], 2: [1], 3: [4], 4: [3], 5: []}
seen = set()


def dfs(node):
    seen.add(node)
    for nxt in graph[node]:
        if nxt not in seen:
            dfs(nxt)


count = 0
for node in graph:
    if node not in seen:
        dfs(node)
        count += 1
print(count)
```

The outer loop starts many searches, but each node is visited by exactly one of them. Counting components costs O(V + E) in total. When edges keep arriving one at a time, union-find, two units on, keeps the components up to date without searching again.

---

On a grid, a component is a region of touching cells, and marking one is a flood fill, the paint bucket in a drawing app.

Put the lines in order so `sink` turns the land cell at `(r, c)`, and all land connected to it, into water, and returns how many cells it sank. `#` is land, `.` is water, and each row is a list so cells can change. Recursion keeps it short; on a big map, use a stack as above.

```python arrange
def sink(grid, r, c):
    if r < 0 or r >= len(grid) or c < 0 or c >= len(grid[0]):
        return 0
    if grid[r][c] != "#":
        return 0
    grid[r][c] = "."
    size = 1
    for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        size += sink(grid, r + dr, c + dc)
    return size
```

```tests
sink([list("##."), list(".#."), list("..#")], 0, 0) == 3
sink([list("##."), list(".#."), list("..#")], 2, 2) == 1
sink([list("##."), list(".#."), list("..#")], 0, 2) == 0
sink([list("#")], 0, 0) == 1
sink([list("###"), list("#.#"), list("###")], 1, 0) == 8
```

---

Which of these needs BFS rather than DFS?

- [ ] Counting the islands on a map
- [ ] Checking whether one node can reach another
- [x] Finding the fewest moves to solve a puzzle

---

[Count the islands](exercises/island-count.md)

[Friend groups](exercises/friend-groups.md)

[Split into two teams](exercises/two-teams.md)
