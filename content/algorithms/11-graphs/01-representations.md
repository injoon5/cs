---
id: graph-representations
title: Representing graphs
---

A graph is a set of nodes joined by edges. A tree is a graph with strict rules: one root, one parent per node, no way to loop back. A graph drops those rules.

```diagram
graph
node 0 at 0,0
node 1 at 0,0.5
node 2 at 0.4,0.25
node 3 at 0.8,0.25
node 4 at 0.8,0.75
node 5 at 0.4,0.75
0 -- 1
0 -- 2
1 -- 2
2 -- 3
3 -- 4
```

Nodes joined by an edge are neighbors. Here 2 has three neighbors, and you can walk 0, 1, 2 and back to 0, which is a cycle. Node 5 has no edges at all. Nothing says every node has to be reachable from every other.

---

Edges can carry more than a link.

```diagram
digraph
0 -> 1 5
0 -> 2 9
1 -> 2 3
2 -> 3 1
```

A directed edge goes one way: 0 → 1 doesn't let you go from 1 to 0. Follows on a social network, links between web pages and "take this course first" are directed. A weighted edge carries a number, like the length of a road. This unit's graphs have no weights; the next unit is about shortest paths when edges have lengths.

---

The usual way to store a graph in Python is an adjacency list: a dict from each node to the list of its neighbors.

```python
graph = {
    0: [1, 2],
    1: [0, 2],
    2: [0, 1, 3],
    3: [2, 4],
    4: [3],
    5: [],
}
print(graph[2])
print(3 in graph[2], 4 in graph[2])
print(len(graph[2]))
```

In an undirected graph each edge shows up twice: 3 is in the list of 2, and 2 is in the list of 3. In a directed graph an edge is stored once, in the list of the node it leaves.

---

Graphs usually arrive as a list of edges, one pair per edge. Give every node an empty list first, so a node with no edges, like 5, is still in the dict. Then file each edge under both of its ends.

```python
edges = [(0, 1), (0, 2), (1, 2), (2, 3), (3, 4)]
graph = {v: [] for v in range(6)}
for a, b in edges:
    graph[a].append(b)
    graph[b].append(a)
print(graph)
```

---

The same edges, read as directed: each pair goes from `a` to `b`. What does this print?

```python predict
edges = [(0, 1), (1, 2), (2, 0), (2, 3)]
graph = {v: [] for v in range(4)}
for a, b in edges:
    graph[a].append(b)
for v in graph:
    print(v, graph[v])
```

---

The degree of a node is its number of neighbors, `len(graph[v])`. In a directed graph that list gives the out-degree, the edges leaving `v`. The in-degree, the edges arriving, takes one pass over the edges.

```python trace stop=9
edges = [(0, 1), (2, 1), (1, 3), (2, 3)]
indegree = [0] * 4
for a, b in edges:
    indegree[b] += 1
print(indegree)
```

The edge `(1, 3)` has just been counted. What is `indegree`?

- [x] `[0, 2, 0, 1]`
- [ ] `[1, 1, 1, 0]`
- [ ] `[0, 2, 0, 2]`

---

An undirected graph has 5 edges. Add up the degrees of all its nodes. The total is

- [ ] 5
- [x] 10
- [ ] It depends on how the edges are arranged

Each edge adds 1 to the degree of both of its ends.

---

An adjacency matrix is the other common layout. For V nodes it is a V × V grid where row `a`, column `b` is 1 when there is an edge from `a` to `b`. This is the first graph again.

```diagram
grid
col-labels [0, 1, 2, 3, 4, 5]
row-labels [0, 1, 2, 3, 4, 5]
row [0, 1, 1, 0, 0, 0]
row [1, 0, 1, 0, 0, 0]
row [1, 1, 0, 1, 0, 0]
row [0, 0, 1, 0, 1, 0]
row [0, 0, 0, 1, 0, 0]
row [0, 0, 0, 0, 0, 0]
highlight 2,3 3,2
```

Checking one edge is an O(1) lookup, but the matrix takes V² cells however few edges there are, and listing the neighbors of a node scans a whole row. An adjacency list takes space for each node and each edge, and hands you the neighbors directly. If you need fast edge checks too, store sets instead of lists.

---

A social network has a million people, each with about 200 friends. Which representation fits?

- [ ] An adjacency matrix, because checking a friendship is O(1)
- [x] An adjacency list, because a matrix would need a trillion cells, almost all 0
- [ ] An edge list, because it is the simplest

---

A graph has V nodes and E edges. With adjacency lists, going through every node and looking at each of its neighbors costs

- [x] O(V + E)
- [ ] O(V²)
- [ ] O(V × E)

With a matrix the same loop costs O(V²), since every row is V cells long. Every search in this unit does this loop once.

---

[Adjacency list from edges](exercises/edges-to-adjacency.md)

[Find the judge](exercises/find-the-judge.md)
