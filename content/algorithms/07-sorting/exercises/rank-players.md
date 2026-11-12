---
id: rank-players
title: Rank players
level: core
---

Each player is a `(name, points, minutes)` tuple. Rank them: more points first; on equal points, fewer minutes first; on equal points and minutes, by name from A to Z. Return the names in rank order. For example, `[("ana", 10, 30), ("bo", 12, 40), ("cy", 10, 25)]` gives `["bo", "cy", "ana"]`.

```python starter
def rank_players(players):
    pass
```

```tests
rank_players([("ana", 10, 30), ("bo", 12, 40), ("cy", 10, 25)]) == ["bo", "cy", "ana"]
rank_players([("b", 5, 10), ("a", 5, 10)]) == ["a", "b"]
rank_players([("a", 1, 50), ("b", 1, 20), ("c", 1, 35)]) == ["b", "c", "a"]
rank_players([("a", 0, 0), ("b", -3, 0), ("c", 2, 0)]) == ["c", "a", "b"]
rank_players([("zed", 7, 7), ("amy", 7, 8), ("bob", 6, 1)]) == ["zed", "amy", "bob"]
rank_players([("solo", 3, 3)]) == ["solo"]
rank_players([]) == []
rank_players([(f"p{i:05}", i % 7, i % 5) for i in range(10000)])[:3] == ["p00020", "p00055", "p00090"]
```

```python solution
def rank_players(players):
    ranked = sorted(players, key=lambda p: (-p[1], p[2], p[0]))
    return [name for name, _, _ in ranked]
```

## Hints

1. A tuple key compares its first item, then the second on a tie, and so on.
2. Points go high to low, but minutes and names go low to high. Flip just the points.
3. `key=lambda p: (-p[1], p[2], p[0])`, then take the names.
