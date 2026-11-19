---
id: trie-insert-search
title: Build a trie
level: warmup
---

Finish `Trie`, built from the `TrieNode` class in the starter.

- `insert(word)` adds the word.
- `search(word)` returns `True` if the word was inserted.
- `starts_with(prefix)` returns `True` if some inserted word starts with `prefix`.

`play` runs a list of operations and collects what each `search` and `starts_with` returned. After inserting `car`, `search("ca")` is `False` and `starts_with("ca")` is `True`.

```python starter
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word):
        pass

    def search(self, word):
        pass

    def starts_with(self, prefix):
        pass


def play(ops):
    trie = Trie()
    out = []
    for name, arg in ops:
        result = getattr(trie, name)(arg)
        if name != "insert":
            out.append(result)
    return out
```

```tests
play([("insert", "car"), ("search", "car"), ("search", "ca"), ("starts_with", "ca")]) == [True, False, True]
play([("search", "a"), ("starts_with", "a")]) == [False, False]
play([("insert", "card"), ("search", "car"), ("starts_with", "car"), ("insert", "car"), ("search", "car")]) == [False, True, True]
play([("insert", "dog"), ("search", "dogs"), ("starts_with", "dogs"), ("starts_with", "do")]) == [False, False, True]
play([("insert", "a"), ("insert", "a"), ("search", "a"), ("search", "aa")]) == [True, False]
play([("insert", "Cat"), ("search", "cat"), ("search", "Cat")]) == [False, True]
play([("insert", "to"), ("starts_with", "")]) == [True]
play([("insert", ""), ("search", ""), ("search", "a")]) == [True, False]
play([("insert", "tea"), ("insert", "ten"), ("insert", "to"), ("search", "te"), ("starts_with", "te"), ("search", "ten")]) == [False, True, True]
```

```python tests
import random


def count_nodes(node):
    return 1 + sum(count_nodes(child) for child in node.children.values())


t = Trie()
for word in ["tea", "ten", "team", "to"]:
    t.insert(word)
assert count_nodes(t.root) == 7, "shared prefixes must share nodes: root, t, e, a, m, n, o"

rng = random.Random(16)
t = Trie()
words = set()
for _ in range(3000):
    w = "".join(rng.choice("abc") for _ in range(rng.randint(0, 5)))
    roll = rng.random()
    if roll < 0.4:
        t.insert(w)
        words.add(w)
    elif roll < 0.7:
        assert t.search(w) == (w in words), w
    else:
        assert t.starts_with(w) == any(x.startswith(w) for x in words), w
```

```python solution
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


class Trie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word):
        node = self.root
        for ch in word:
            if ch not in node.children:
                node.children[ch] = TrieNode()
            node = node.children[ch]
        node.end = True

    def find(self, s):
        node = self.root
        for ch in s:
            if ch not in node.children:
                return None
            node = node.children[ch]
        return node

    def search(self, word):
        node = self.find(word)
        return node is not None and node.end

    def starts_with(self, prefix):
        return self.find(prefix) is not None


def play(ops):
    trie = Trie()
    out = []
    for name, arg in ops:
        result = getattr(trie, name)(arg)
        if name != "insert":
            out.append(result)
    return out
```

## Hints

1. All three methods walk down from `self.root` one letter at a time, following `node.children[ch]`.
2. `insert` adds a missing child as it walks and sets `end` on the last node. `search` and `starts_with` stop with `False` at a missing letter.
3. At the end of the walk, `search` returns `node.end` and `starts_with` returns `True`. Since the walk is the same, a helper `find(s)` that returns the last node or `None` serves both.
