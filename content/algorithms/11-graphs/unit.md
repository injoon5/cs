---
id: graphs
title: Graphs
requires: [trees, hashing]
---

Roads, friendships, mazes and course prerequisites are all graphs. Store one as a dict of neighbor lists, then walk it breadth first for the fewest steps, depth first for everything reachable, and in topological order when some things must come before others.
