---
id: huffman-code-lengths
title: Huffman code lengths
level: stretch
---

`freq` maps each symbol to how many times it appears, all at least 1. Build a Huffman code: repeatedly join the two least frequent groups, the way the lesson joined ropes. Return a dict from each symbol to the length of its code, which is the number of joins above it. A lone symbol still needs one bit, so give it length 1.

For `{"a": 5, "b": 2, "c": 1, "d": 1}` the answer is `{"a": 1, "b": 2, "c": 3, "d": 3}`.

When counts tie, several codes are equally good. Any of them is right, as long as the total number of bits is the smallest possible and the lengths fit a real code.

```python starter
import heapq


def code_lengths(freq):
    pass
```

```tests
code_lengths({"a": 5, "b": 2, "c": 1, "d": 1}) == {"a": 1, "b": 2, "c": 3, "d": 3}
code_lengths({}) == {}
code_lengths({"x": 7}) == {"x": 1}
code_lengths({"x": 1, "y": 9}) == {"x": 1, "y": 1}
code_lengths({"a": 1, "b": 1, "c": 1, "d": 1}) == {"a": 2, "b": 2, "c": 2, "d": 2}
code_lengths({"a": 1, "b": 2, "c": 4, "d": 8, "e": 16}) == {"a": 4, "b": 4, "c": 3, "d": 2, "e": 1}
```

```python tests
import heapq
import random
from fractions import Fraction


def best_bits(counts):
    heap = list(counts)
    heapq.heapify(heap)
    total = 0
    while len(heap) > 1:
        a, b = heapq.heappop(heap), heapq.heappop(heap)
        total += a + b
        heapq.heappush(heap, a + b)
    return total


def check(freq):
    lengths = code_lengths(freq)
    assert set(lengths) == set(freq), (freq, lengths)
    if len(freq) == 1:
        assert list(lengths.values()) == [1], (freq, lengths)
        return
    bits = sum(freq[s] * lengths[s] for s in freq)
    assert bits == best_bits(freq.values()), (freq, lengths)
    assert sum(Fraction(1, 2 ** n) for n in lengths.values()) == 1, (freq, lengths)


for _ in range(300):
    symbols = "abcdefghij"[:random.randint(2, 10)]
    check({s: random.randint(1, 12) for s in symbols})

check({s: 3 for s in "abcdefgh"})
check({i: 1 << i for i in range(30)})
```

```python solution
import heapq
from itertools import count


def code_lengths(freq):
    if len(freq) == 1:
        return {s: 1 for s in freq}
    length = {s: 0 for s in freq}
    order = count()
    heap = [(f, next(order), [s]) for s, f in freq.items()]
    heapq.heapify(heap)
    while len(heap) > 1:
        f1, _, group1 = heapq.heappop(heap)
        f2, _, group2 = heapq.heappop(heap)
        for s in group1 + group2:
            length[s] += 1
        heapq.heappush(heap, (f1 + f2, next(order), group1 + group2))
    return length
```

## Hints

1. Every join adds one bit to the code of every symbol in the two groups it joins.
2. Keep a heap of `(count, tie_breaker, symbols)` groups. The tie-breaker stops Python from comparing the lists of symbols when counts are equal.
3. Pop two groups, add 1 to the length of every symbol in both, and push one group with the summed count and both symbol lists. Stop when one group is left. Handle a single symbol on its own.
