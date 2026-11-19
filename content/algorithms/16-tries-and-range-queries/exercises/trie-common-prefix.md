---
id: trie-common-prefix
title: Longest common prefix
level: warmup
---

Return the longest string that every word in `words` starts with. Build a trie of the words and walk down from the root while the path doesn't branch. For `["flower", "flow", "flight"]` the answer is `"fl"`. For an empty list, return `""`.

```python starter
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def common_prefix(words):
    pass
```

```tests
common_prefix(["flower", "flow", "flight"]) == "fl"
common_prefix(["dog", "racecar", "car"]) == ""
common_prefix([]) == ""
common_prefix(["alone"]) == "alone"
common_prefix(["flow", "flower"]) == "flow"
common_prefix(["flower", "flow"]) == "flow"
common_prefix(["same", "same", "same"]) == "same"
common_prefix(["", "abc"]) == ""
common_prefix(["ab", "abc", "a"]) == "a"
common_prefix(["Apple", "apple"]) == ""
```

```python tests
import os
import random

rng = random.Random(11)
for _ in range(300):
    words = ["".join(rng.choice("ab") for _ in range(rng.randint(0, 5))) for _ in range(rng.randint(1, 5))]
    assert common_prefix(words) == os.path.commonprefix(words), words
```

```python solution
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def common_prefix(words):
    root = TrieNode()
    for word in words:
        node = root
        for ch in word:
            if ch not in node.children:
                node.children[ch] = TrieNode()
            node = node.children[ch]
        node.end = True

    prefix = ""
    node = root
    while len(node.children) == 1 and not node.end:
        ch = next(iter(node.children))
        prefix += ch
        node = node.children[ch]
    return prefix
```

## Hints

1. Insert every word. The common prefix is the path from the root down to the first place where the words part ways.
2. Words part ways where a node has two or more children, and also where a word ends, since the prefix can't be longer than any word.
3. Start at the root with `prefix = ""`. While the node has exactly one child and `end` isn't set, add that child's letter to `prefix` and step down. `next(iter(node.children))` gives the only key.
