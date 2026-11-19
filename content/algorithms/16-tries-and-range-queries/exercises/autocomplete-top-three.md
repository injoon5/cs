---
id: autocomplete-top-three
title: Autocomplete
level: core
---

As someone types `typed` one letter at a time, suggest up to 3 words from `words` after each letter: the alphabetically first words that start with what has been typed so far. Return one list of suggestions per letter. A word that appears in `words` twice is suggested once.

For `words = ["mouse", "mobile", "moneypot", "monitor", "mousepad"]` and `typed = "mou"`:

- after `m`: `["mobile", "moneypot", "monitor"]`
- after `mo`: `["mobile", "moneypot", "monitor"]`
- after `mou`: `["mouse", "mousepad"]`

```python starter
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def suggestions(words, typed):
    pass
```

```tests
suggestions(["mouse", "mobile", "moneypot", "monitor", "mousepad"], "mou") == [["mobile", "moneypot", "monitor"], ["mobile", "moneypot", "monitor"], ["mouse", "mousepad"]]
suggestions(["havana"], "havana") == [["havana"]] * 6
suggestions(["havana"], "tatiana") == [[]] * 7
suggestions(["bags", "baggage", "banner", "box", "cloths"], "bags") == [["baggage", "bags", "banner"], ["baggage", "bags", "banner"], ["baggage", "bags"], ["bags"]]
suggestions(["ab", "ab", "abc"], "ab") == [["ab", "abc"], ["ab", "abc"]]
suggestions([], "a") == [[]]
suggestions(["a", "b"], "") == []
suggestions(["cat", "car", "ca", "cab", "c"], "ca") == [["c", "ca", "cab"], ["ca", "cab", "car"]]
suggestions(["ax", "b"], "abc") == [["ax"], [], []]
```

```python tests
import random

rng = random.Random(3)
for _ in range(300):
    words = ["".join(rng.choice("abc") for _ in range(rng.randint(1, 4))) for _ in range(rng.randint(0, 10))]
    typed = "".join(rng.choice("abc") for _ in range(rng.randint(0, 4)))
    pool = sorted(set(words))
    want = [[w for w in pool if w.startswith(typed[:i])][:3] for i in range(1, len(typed) + 1)]
    assert suggestions(words, typed) == want, (words, typed)
```

```python solution
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def suggestions(words, typed):
    root = TrieNode()
    for word in words:
        node = root
        for ch in word:
            if ch not in node.children:
                node.children[ch] = TrieNode()
            node = node.children[ch]
        node.end = True

    def collect(node, path, out):
        if len(out) == 3:
            return
        if node.end:
            out.append(path)
        for ch in sorted(node.children):
            collect(node.children[ch], path + ch, out)

    result = []
    node = root
    for i, ch in enumerate(typed):
        node = node.children.get(ch) if node else None
        out = []
        if node:
            collect(node, typed[:i + 1], out)
        result.append(out)
    return result
```

## Hints

1. Each new letter moves one step further down the trie from where the last letter ended. Once a letter is missing, every later list is empty.
2. Below the node for what has been typed, visit children in sorted order and add a word whenever a node ends one. That gives words alphabetically, a prefix before the words that continue it.
3. Write `collect(node, path, out)` as in the lesson, returning at once when `out` holds 3 words. Keep `node` as you go through `typed`, and set it to `None` when a letter is missing.
