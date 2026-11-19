---
id: floyd-warshall
title: All pairs with Floyd-Warshall
---

Sometimes you need the distance between every pair of nodes, like the table of driving times in a road atlas. The answer is a V × V matrix: row `i`, column `j` holds the distance from `i` to `j`.

Start from what the edges alone say: 0 from a node to itself, the weight where there's an edge, infinity elsewhere.

```diagram
digraph
node 0 at 0,0
node 1 at 1,0
node 2 at 1,1
node 3 at 0,1
0 -> 1 3
0 -> 3 7
1 -> 0 8
1 -> 2 2
2 -> 0 5
2 -> 3 1
3 -> 0 2

grid d
col-labels [0, 1, 2, 3]
row-labels [0, 1, 2, 3]
row [0, 3, ∞, 7]
row [8, 0, 2, ∞]
row [5, ∞, 0, 1]
row [2, ∞, ∞, 0]
```

---

Floyd-Warshall improves the matrix by letting in one stopover at a time. In round `k`, every pair `i`, `j` asks one question: is it shorter to go from `i` to `k`, then from `k` to `j`? If so, `d[i][j]` becomes `d[i][k] + d[k][j]`.

Before round 0, `d[i][j]` only counts direct edges. After round `k`, it is the shortest path from `i` to `j` whose stopovers are all among nodes 0 to `k`. After the last round every node is allowed, so every entry is a distance.

---

The whole algorithm is three nested loops.

```python
inf = float("inf")
n = 4
edges = [(0, 1, 3), (0, 3, 7), (1, 0, 8), (1, 2, 2),
         (2, 0, 5), (2, 3, 1), (3, 0, 2)]
d = [[0 if i == j else inf for j in range(n)] for i in range(n)]
for a, b, w in edges:
    d[a][b] = w
for k in range(n):
    for i in range(n):
        for j in range(n):
            if d[i][k] + d[k][j] < d[i][j]:
                d[i][j] = d[i][k] + d[k][j]
for row in d:
    print(row)
```

---

```python trace stop=52
inf = float("inf")
d = [[0, 3, inf, 7],
     [8, 0, 2, inf],
     [5, inf, 0, 1],
     [2, inf, inf, 0]]
for k in range(4):
    for i in range(4):
        for j in range(4):
            if d[i][k] + d[k][j] < d[i][j]:
                d[i][j] = d[i][k] + d[k][j]
print(d)
```

Round `k = 0` has just finished. What is row 3, `d[3]`?

- [ ] `[2, inf, inf, 0]`
- [x] `[2, 5, inf, 0]`
- [ ] `[2, 5, 7, 0]`

Node 0 as a stopover gives 3 → 0 → 1, for 2 + 3 = 5. There's still no way from 3 to 2 through 0 alone.

---

The finished matrix:

```diagram
grid d
col-labels [0, 1, 2, 3]
row-labels [0, 1, 2, 3]
row [0, 3, 5, 6]
row [5, 0, 2, 3]
row [3, 6, 0, 1]
row [2, 5, 7, 0]
highlight 1,0
```

`d[1][0]` started at 8, the direct edge. It is 5 now, along 1, 2, 3, 0. In which round did it become 5?

- [ ] Round 0
- [ ] Round 2
- [x] Round 3

The path stops over at 2 and 3, so it only counts once 3 is allowed. Round 2 had found 1, 2, 0 for 7.

---

Why must `k` be the outer loop?

- [ ] So that each row `i` is finished before the next row starts
- [x] Round `k` reads `d[i][k]` and `d[k][j]`, which must already be best over stopovers 0 to `k - 1`
- [ ] With `k` inside, the loops would run more than V³ times

With `k` as the inner loop, each `d[i][j]` is settled in one go, from rows and columns that aren't finished yet. On this graph `d[1][0]` comes out 7 instead of 5.

---

Three nested loops over V nodes. Floyd-Warshall takes

- [ ] O(V²) time, O(V²) space
- [x] O(V³) time, O(V²) space
- [ ] O(V³) time, O(V³) space

It updates one matrix in place: no heap, no adjacency list.

---

Running Dijkstra from every node also gives all pairs, in O(V (V + E) log V). When is Floyd-Warshall the better choice?

- [x] The graph is dense, with close to V² edges, or has negative edges
- [ ] The graph is huge and sparse, like a road network
- [ ] You only need the distances from one node

Negative edges are fine as long as there's no negative cycle. If there is one, some node ends up with `d[i][i] < 0`: a path from `i` back to itself that costs less than nothing.

---

[All-pairs distances](exercises/all-pairs-distances.md)

[City with the fewest neighbors](exercises/fewest-reachable-city.md)
