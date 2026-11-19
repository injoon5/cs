---
id: kruskal-mst
title: Minimum spanning trees
---

Six towns need roads so that every town can reach every other. Each number is what that road would cost to build. Which roads should be built to make the total as small as possible?

```diagram
graph
node 0 at 0.5,0
node 1 at 0.93,0.25
node 2 at 0.93,0.75
node 3 at 0.5,1
node 4 at 0.07,0.75
node 5 at 0.07,0.25
0 -- 1 4
1 -- 2 7
2 -- 3 5
3 -- 4 8
4 -- 5 6
5 -- 0 3
1 -- 5 1
2 -- 4 2
```

---

With positive costs, the cheapest network has no cycle. If it had one, you could drop the priciest road on the cycle, and every town could still reach every other the other way around.

So the answer is a tree that reaches every node, a spanning tree. One with the smallest total weight is a minimum spanning tree, MST. A spanning tree on V nodes has

- [ ] V edges, one per node
- [x] V - 1 edges, since each node but the root hangs from one edge
- [ ] Anywhere from V - 1 to V(V - 1) / 2 edges

---

One rule says which edges are safe to take. Split the nodes into two sides, any way you like. The cheapest edge that crosses between the sides belongs to some minimum spanning tree.

```diagram
graph
node 0 at 0.5,0
node 1 at 0.93,0.25
node 2 at 0.93,0.75
node 3 at 0.5,1
node 4 at 0.07,0.75
node 5 at 0.07,0.25
0 -- 1 4
1 -- 2 7
2 -- 3 5
3 -- 4 8
4 -- 5 6
5 -- 0 3
1 -- 5 1
2 -- 4 2
visited 0 1 5
```

Here one side is the filled nodes, 0, 1 and 5, and the other side is 2, 3 and 4. Which road does the rule say is safe?

- [ ] 1 – 5, cost 1, the cheapest road of all
- [x] 4 – 5, cost 6
- [ ] 1 – 2, cost 7

---

This is the cut property. Here is why it holds. Take a minimum spanning tree that leaves out the cheapest crossing edge `e`. Add `e`, and the tree gets a cycle. Going around that cycle you cross between the sides on `e`, so you must cross back on some other edge `f`. Remove `f`: the network is a spanning tree again, and since `e` costs no more than `f`, the total didn't go up. So it is a minimum spanning tree too, and it contains `e`.

---

Kruskal's algorithm applies the rule over and over. Go through the edges from cheapest to priciest. Take an edge if its two ends are in different trees so far. Skip it if they're already connected, since it would close a cycle. Union-find answers exactly that.

Run this to watch the network grow. Only the roads taken so far are drawn, plus the highlighted one being considered. Below the graph is the union-find.

```python
import viz

n = 6
edges = [(0, 1, 4), (1, 2, 7), (2, 3, 5), (3, 4, 8),
         (4, 5, 6), (5, 0, 3), (1, 5, 1), (2, 4, 2)]
parent = list(range(n))
tree = {v: [] for v in range(n)}
total = 0


def find(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


def show(note, edge=None):
    adj = {v: list(tree[v]) for v in tree}
    active = []
    if edge:
        a, b, w = edge
        adj[a].append((b, w))
        active = [a, b]
    with viz.frame():
        viz.graph(adj, active=active, note=note)
        viz.array(parent, name="parent")


show("every town alone")
for a, b, w in sorted(edges, key=lambda e: e[2]):
    ra, rb = find(a), find(b)
    if ra == rb:
        show(f"{a} and {b} are connected already, skip", (a, b, w))
    else:
        parent[rb] = ra
        tree[a].append((b, w))
        total += w
        show(f"take {a} – {b} for {w}", (a, b, w))
show(f"total {total}")
```

---

Why does each edge Kruskal takes pass the cut property? When it takes an edge from `a` to `b`, put the tree `a` is in on one side and every other node on the other.

Every cheaper edge has been looked at already. None of them crosses: one that did would have been taken, and its far end would be in `a`'s tree. So this edge is the cheapest crossing edge, and it is safe.

---

Here is Kruskal without the drawing.

```python trace stop=89
edges = [(0, 1, 4), (1, 2, 7), (2, 3, 5), (3, 4, 8),
         (4, 5, 6), (5, 0, 3), (1, 5, 1), (2, 4, 2)]
parent = list(range(6))


def find(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


tree = []
total = 0
for a, b, w in sorted(edges, key=lambda e: e[2]):
    ra, rb = find(a), find(b)
    if ra != rb:
        parent[rb] = ra
        tree.append((a, b))
        total += w
print(tree, total)
```

The loop has just looked at the road from 0 to 1, cost 4. What is `tree`?

- [x] `[(1, 5), (2, 4), (5, 0)]`
- [ ] `[(1, 5), (2, 4), (5, 0), (0, 1)]`
- [ ] `[(0, 1), (1, 2), (2, 3)]`

---

Union by size is missing here. Path halving alone keeps a union-find call at O(log V) on average, and the sort costs more than that anyway.

Kruskal sorts the E edges, then makes two finds per edge. It takes

- [ ] O(V + E)
- [x] O(E log E)
- [ ] O(E × V)

A graph has fewer than V² edges, so log E is less than 2 log V, and O(E log E) is the same as O(E log V).

---

Kruskal runs on a graph whose nodes fall into two components with no edge between them. It ends with

- [ ] a spanning tree, plus one extra edge between the components
- [x] a minimum spanning tree for each component, and V - 2 edges in all
- [ ] nothing, since it stops at the first edge it skips

Checking whether it took V - 1 edges tells you whether the graph was connected.

---

[Is it a spanning tree](exercises/is-spanning-tree.md)

[Minimum spanning tree weight](exercises/kruskal-total-weight.md)

[Everyone connected](exercises/everyone-connected-time.md)
