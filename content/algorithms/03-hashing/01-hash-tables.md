---
id: hash-tables
title: How a hash table works
---

You want to store some numbers and later ask "is 20 in here?" In a plain list, that question checks every item: O(n).

A hash table skips the search. It keeps a row of buckets and turns each key into a bucket number. Here there are 8 buckets, and the bucket is `key % 8`.

```diagram
array buckets [, 33, , , 12, , , 7]
highlight 4
```

`12 % 8` is 4, so 12 lives in bucket 4. To find 12 later, compute 4 again and look in one place.

---

Two keys can land in the same bucket. `20 % 8` is also 4. That's a collision, and it can't be avoided: there are far more possible keys than buckets.

The simplest fix is chaining. Each bucket holds a short list, and a lookup scans only that list.

```diagram
grid buckets
row-labels [0, 1, 2, 3, 4, 5, 6, 7]
row [, ]
row [33, ]
row [, ]
row [, ]
row [12, 20]
row [, ]
row [, ]
row [7, ]
highlight 4,1
```

```python
buckets = [[] for _ in range(8)]
for key in [12, 7, 20, 33]:
    buckets[key % 8].append(key)
print(buckets)
print(20 in buckets[20 % 8])
```

---

A hash function should spread keys out. `key % 8` is fine for random numbers, but some keys follow a pattern. Which buckets do these go to?

```python predict
for key in [8, 16, 25, 40, 49]:
    print(key, key % 8)
```

---

Multiples of 8 all pile into bucket 0. Real tables don't use the raw key. Python calls `hash(key)`, which mixes up strings and tuples so similar keys end up far apart, then picks a bucket from that number.

Here is a table with 4 buckets.

```python trace stop=8
buckets = [[] for _ in range(4)]
for key in [5, 2, 9, 12]:
    buckets[key % 4].append(key)
print(buckets)
```

Three keys are in. What is `buckets` now?

- [ ] `[[], [5], [2], [9]]`
- [x] `[[], [5, 9], [2], []]`
- [ ] `[[9], [5], [2], []]`

---

Run this to watch keys drop into buckets. Bucket 4 collects a chain of three.

```python
import viz

size = 8
buckets = [[] for _ in range(size)]
for key in [12, 7, 20, 33, 28]:
    b = key % size
    buckets[b].append(key)
    rows = [c + [None] * (3 - len(c))
            for c in buckets]
    viz.grid(rows,
             row_labels=list(range(size)),
             highlight=(b, len(buckets[b]) - 1),
             note=f"{key} % {size} = {b}")
```

---

Chains stay short only while the table isn't too full. The load factor is keys divided by buckets. With 6 keys in 8 buckets it is 0.75, so an average chain holds less than one key.

When the load factor passes a limit, the table doubles its buckets and moves every key to its new bucket. That one insert costs O(n). As with `append` in the complexity unit, doubling keeps the moves under 2n over n inserts, so each insert is amortized O(1).

---

Python's `dict` and `set` don't chain. They use open addressing: every key sits directly in a slot, and on a collision the table tries other slots until it finds a free one. The simplest version, linear probing, tries the next slot to the right.

```diagram
array slots [, 33, , , 12, 20, , 7]
pointer home 4
highlight 5
```

20 wanted slot 4, found 12 there, and took slot 5. A lookup for 20 follows the same path and gives up at the first empty slot.

---

With a good hash and a capped load factor, a lookup in a table of n keys takes O(1) on average. What if every key lands in the same bucket?

- [ ] O(1), because the bucket is computed directly
- [ ] O(log n), because the table halves the search
- [x] O(n), because the lookup scans one chain that holds every key

---

Put the lines in order so `build` puts each key into bucket `key % size`.

```python arrange
def build(keys, size):
    buckets = [[] for _ in range(size)]
    for key in keys:
        buckets[key % size].append(key)
    return buckets
```

```tests
build([12, 7, 20], 8) == [[], [], [], [], [12, 20], [], [], [7]]
build([5, 2, 9], 4) == [[], [5, 9], [2], []]
build([], 2) == [[], []]
build([3, 3], 1) == [[3, 3]]
```

---

[Bucket sizes](exercises/bucket-sizes.md)

[A chained hash map](exercises/chained-map.md)

[Linear probing](exercises/linear-probe.md)
