---
id: sort-scores
title: Sort exam scores
level: core
---

`results` is a list of `(name, score)` pairs, with whole-number scores from 0 to 100. Return the names from the highest score to the lowest. Names with the same score keep their order from `results`. Do it in O(n) time, with one bucket per score, instead of a comparison sort. For example, `[("ana", 70), ("bo", 95), ("cy", 70)]` gives `["bo", "ana", "cy"]`.

```python starter
def sort_scores(results):
    pass
```

```tests
sort_scores([("ana", 70), ("bo", 95), ("cy", 70)]) == ["bo", "ana", "cy"]
sort_scores([("a", 0), ("b", 100)]) == ["b", "a"]
sort_scores([("a", 50), ("b", 50), ("c", 50)]) == ["a", "b", "c"]
sort_scores([("solo", 88)]) == ["solo"]
sort_scores([]) == []
sort_scores([("x", 1), ("y", 2), ("z", 3)]) == ["z", "y", "x"]
sort_scores([("d", 0), ("e", 0), ("f", 100), ("g", 0)]) == ["f", "d", "e", "g"]
sort_scores([(str(i), i % 101) for i in range(50000)])[:3] == ["100", "201", "302"]
```

```python tests
import random

rng = random.Random(5)
rows = [(f"p{i}", rng.randint(0, 100)) for i in range(500)]
want = [name for name, _ in sorted(rows, key=lambda r: -r[1])]
assert sort_scores(rows) == want
```

```python solution
def sort_scores(results):
    buckets = [[] for _ in range(101)]
    for name, score in results:
        buckets[score].append(name)
    out = []
    for score in range(100, -1, -1):
        out.extend(buckets[score])
    return out
```

## Hints

1. There are only 101 possible scores, so you can give each score its own list.
2. Walk `results` once and append each name to the list for its score. Appending keeps names with the same score in input order.
3. Make `buckets = [[] for _ in range(101)]`, fill it, then walk the scores from 100 down to 0 and `extend` the output with each bucket.
