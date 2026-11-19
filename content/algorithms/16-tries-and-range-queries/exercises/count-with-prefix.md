---
id: count-with-prefix
title: Words with a prefix
level: warmup
---

For each string in `prefixes`, count how many words in `words` start with it, and return the counts as a list. A word that appears twice counts twice. Every word starts with the empty prefix.

For `words = ["car", "card", "cat", "car", "do"]` and `prefixes = ["ca", "car", "d", "x"]`, the answer is `[4, 3, 1, 0]`.

```python starter
class TrieNode:
    def __init__(self):
        self.children = {}
        self.count = 0


def count_prefixes(words, prefixes):
    pass
```

```tests
count_prefixes(["car", "card", "cat", "car", "do"], ["ca", "car", "d", "x"]) == [4, 3, 1, 0]
count_prefixes([], ["a"]) == [0]
count_prefixes(["a", "b"], []) == []
count_prefixes(["apple", "app"], ["", "app", "apple", "apples"]) == [2, 2, 1, 0]
count_prefixes(["x", "x", "x"], ["x", "xx"]) == [3, 0]
count_prefixes(["", "a"], ["", "a"]) == [2, 1]
count_prefixes(["Tea", "tea"], ["t", "T"]) == [1, 1]
count_prefixes(["a" * (i % 20 + 1) for i in range(20000)], ["a" * (j % 25 + 1) for j in range(20000)]) == [1000 * max(0, 20 - j % 25) for j in range(20000)]
```

```python tests
import random

rng = random.Random(7)
for _ in range(200):
    words = ["".join(rng.choice("ab") for _ in range(rng.randint(0, 4))) for _ in range(rng.randint(0, 8))]
    prefixes = ["".join(rng.choice("ab") for _ in range(rng.randint(0, 4))) for _ in range(rng.randint(0, 8))]
    want = [sum(w.startswith(p) for w in words) for p in prefixes]
    assert count_prefixes(words, prefixes) == want, (words, prefixes)
```

```python solution
class TrieNode:
    def __init__(self):
        self.children = {}
        self.count = 0


def count_prefixes(words, prefixes):
    root = TrieNode()
    for word in words:
        node = root
        node.count += 1
        for ch in word:
            if ch not in node.children:
                node.children[ch] = TrieNode()
            node = node.children[ch]
            node.count += 1

    def count(prefix):
        node = root
        for ch in prefix:
            if ch not in node.children:
                return 0
            node = node.children[ch]
        return node.count

    return [count(p) for p in prefixes]
```

## Hints

1. Checking every word against every prefix is too slow for the last test. Put the words in a trie once, then answer each prefix with one walk.
2. Give each node a count of the words whose path passes through it. Inserting a word adds 1 to every node on its path, the root included.
3. To answer a prefix, walk down its letters. Return 0 at a missing letter, else the `count` of the node you end on.
