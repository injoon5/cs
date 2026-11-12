---
id: chained-map
title: A chained hash map
level: core
---

Finish `HashMap`, a key-value table with 8 buckets and chaining. Each bucket is a list of `[key, value]` pairs.

- `put(key, value)` adds the pair, or replaces the value if the key is already there.
- `get(key)` returns the value, or `None` if the key is missing.
- `remove(key)` deletes the pair, and does nothing if the key is missing.

`play` runs a list of operations and collects what each `get` returned. For example, after `put(1, "a")` and `put(9, "b")`, both keys share bucket 1, and `get(9)` returns `"b"`.

```python starter
class HashMap:
    def __init__(self, size=8):
        self.buckets = [[] for _ in range(size)]

    def bucket(self, key):
        i = hash(key) % len(self.buckets)
        return self.buckets[i]

    def put(self, key, value):
        pass

    def get(self, key):
        pass

    def remove(self, key):
        pass


def play(ops):
    m = HashMap()
    out = []
    for name, *args in ops:
        result = getattr(m, name)(*args)
        if name == "get":
            out.append(result)
    return out
```

```tests
play([("put", 1, "a"), ("get", 1)]) == ["a"]
play([("get", 5)]) == [None]
play([("put", 1, "a"), ("put", 1, "b"), ("get", 1)]) == ["b"]
play([("put", 1, "a"), ("put", 9, "b"), ("get", 1), ("get", 9)]) == ["a", "b"]
play([("put", 1, "a"), ("put", 9, "b"), ("remove", 1), ("get", 1), ("get", 9)]) == [None, "b"]
play([("remove", 3), ("get", 3)]) == [None]
play([("put", "x", 1), ("put", (2, 3), 2), ("get", "x"), ("get", (2, 3))]) == [1, 2]
play([("put", -4, "neg"), ("get", -4), ("get", 4)]) == ["neg", None]
play([("put", 0, 0), ("put", 8, 8), ("put", 16, 16), ("remove", 8), ("get", 0), ("get", 16)]) == [0, 16]
```

```python tests
m = HashMap()
m.put(1, "a")
m.put(9, "b")
m.put(1, "c")
assert len(m.buckets[1]) == 2, "1 and 9 share bucket 1, and 1 is stored once"
assert sum(len(b) for b in m.buckets) == 2

import random
rng = random.Random(3)
m = HashMap()
ref = {}
for step in range(2000):
    key = rng.randrange(50)
    roll = rng.random()
    if roll < 0.5:
        m.put(key, step)
        ref[key] = step
    elif roll < 0.7:
        m.remove(key)
        ref.pop(key, None)
    else:
        assert m.get(key) == ref.get(key)
assert sum(len(b) for b in m.buckets) == len(ref)
```

```python solution
class HashMap:
    def __init__(self, size=8):
        self.buckets = [[] for _ in range(size)]

    def bucket(self, key):
        i = hash(key) % len(self.buckets)
        return self.buckets[i]

    def put(self, key, value):
        bucket = self.bucket(key)
        for pair in bucket:
            if pair[0] == key:
                pair[1] = value
                return
        bucket.append([key, value])

    def get(self, key):
        for k, v in self.bucket(key):
            if k == key:
                return v
        return None

    def remove(self, key):
        bucket = self.bucket(key)
        for i, pair in enumerate(bucket):
            if pair[0] == key:
                del bucket[i]
                return


def play(ops):
    m = HashMap()
    out = []
    for name, *args in ops:
        result = getattr(m, name)(*args)
        if name == "get":
            out.append(result)
    return out
```

## Hints

1. Every method starts the same way: `self.bucket(key)` gives the one list the key can be in.
2. Scan that list for a pair whose key matches. `put` updates it or appends a new pair, `get` returns its value, `remove` deletes it.
3. In `put`, loop `for pair in bucket:` and set `pair[1] = value` on a match, then `return`. After the loop, `bucket.append([key, value])`.
