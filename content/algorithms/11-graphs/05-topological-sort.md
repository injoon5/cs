---
id: topological-sort
title: Cycles and topological order
---

Some things have to happen before others. The shirt goes on before the tie, and the belt before the jacket. An edge `a → b` says `a` comes first.

```diagram
digraph
shirt -> tie
shirt -> belt
pants -> belt
pants -> shoes
tie -> jacket
belt -> jacket
```

A topological order lists every node so that every edge points forward, from earlier in the list to later. Shirt, pants, tie, belt, shoes, jacket is one. There are usually several.

---

Which of these is also a topological order?

- [ ] pants, shoes, belt, shirt, tie, jacket
- [x] shirt, tie, pants, shoes, belt, jacket
- [ ] shirt, pants, tie, jacket, belt, shoes

---

Sometimes there is no order at all.

```diagram
digraph
a -> b
b -> c
c -> a
```

Whichever of `a`, `b` and `c` you put first, another one has an edge into it and should have gone before it. A directed graph has a topological order exactly when it has no cycle. Such a graph is called a DAG, a directed acyclic graph.

---

Kahn's algorithm builds the order from the front. A node's in-degree counts the things that must come before it. Nodes with in-degree 0 are free to go now, so they wait in a queue.

Take a free node and append it to the order. Then cross off its edges: everything it points to has one less thing to wait for. A node whose count reaches 0 becomes free and joins the queue.

```python trace stop=57
from collections import deque

graph = {"shirt": ["tie", "belt"], "pants": ["belt", "shoes"],
         "tie": ["jacket"], "belt": ["jacket"],
         "shoes": [], "jacket": []}
indegree = {v: 0 for v in graph}
for v in graph:
    for w in graph[v]:
        indegree[w] += 1
queue = deque([v for v in graph if indegree[v] == 0])
order = []
while queue:
    v = queue.popleft()
    order.append(v)
    for w in graph[v]:
        indegree[w] -= 1
        if indegree[w] == 0:
            queue.append(w)
print(order)
```

Pants has just been placed and its edges crossed off. What is in `queue`?

- [ ] belt, shoes
- [x] tie, belt, shoes
- [ ] tie, belt

---

If there is a cycle, its nodes keep waiting on each other, and their counts never reach 0. So Kahn's algorithm also detects cycles: the order comes out shorter than the graph. What does this print?

```python predict
from collections import deque

graph = {0: [1], 1: [2], 2: [3], 3: [1], 4: [0]}
indegree = {v: 0 for v in graph}
for v in graph:
    for w in graph[v]:
        indegree[w] += 1
queue = deque([v for v in graph if indegree[v] == 0])
order = []
while queue:
    v = queue.popleft()
    order.append(v)
    for w in graph[v]:
        indegree[w] -= 1
        if indegree[w] == 0:
            queue.append(w)
print(order, len(order) == len(graph))
```

---

DFS can find a cycle too: deep in a path, it finds an edge back to a node still on that path. A seen set alone can't tell. In this diamond, DFS reaches 3 a second time, through 2, and there is no cycle.

```diagram
digraph
0 -> 1
0 -> 2
1 -> 3
2 -> 3
```

So each node gets one of three states. New: not reached yet. Open: on the current path, its call hasn't returned. Done: its call has returned. An edge to an open node closes a cycle. An edge to a done node doesn't. Textbooks call the three white, gray and black.

---

```python trace stop=31
def has_cycle(graph, node, state):
    state[node] = "open"
    for nxt in graph[node]:
        if state[nxt] == "open":
            return True
        if state[nxt] == "new" and has_cycle(graph, nxt, state):
            return True
    state[node] = "done"
    return False


graph = {0: [1, 2], 1: [3], 2: [3], 3: []}
state = {v: "new" for v in graph}
print(has_cycle(graph, 0, state))
```

The call for 2 is looking at its neighbor 3. What is `state`?

- [ ] 0, 1, 2 and 3 are all open
- [x] 0 and 2 are open, 1 and 3 are done
- [ ] 0 is open, 1, 2 and 3 are done

This only searches from 0. To check a whole graph, start it from every node that is still new.

---

DFS also gives a topological order for free, as long as there is no cycle. A node's call finishes only after the calls for everything it points to have finished. So in finishing order, every node comes after everything that must follow it. Reverse that list and every edge points forward. What does this print?

```python predict
graph = {"shirt": ["tie", "belt"], "pants": ["belt", "shoes"],
         "tie": ["jacket"], "belt": ["jacket"],
         "shoes": [], "jacket": []}
seen = set()
finished = []


def visit(v):
    seen.add(v)
    for w in graph[v]:
        if w not in seen:
            visit(w)
    finished.append(v)


for v in graph:
    if v not in seen:
        visit(v)
print(finished[::-1])
```

---

On a graph with V nodes and E edges, Kahn's algorithm and the DFS version each take

- [ ] O(V²) time
- [x] O(V + E) time
- [ ] O((V + E) log V) time

---

[Cycle in a directed graph](exercises/directed-has-cycle.md)

[Course order](exercises/course-order.md)

[Project time](exercises/project-finish-time.md)
