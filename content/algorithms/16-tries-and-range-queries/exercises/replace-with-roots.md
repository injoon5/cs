---
id: replace-with-roots
title: Shortest root
level: core
---

`roots` is a list of word beginnings. Replace each word in `sentence` that starts with a root by the shortest root it starts with, and return the new sentence. Words are separated by single spaces, and a word with no root stays as it is.

With roots `["cat", "bat", "rat"]`, the sentence `"the cattle was rattled by the battery"` becomes `"the cat was rat by the bat"`.

```python starter
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def replace_words(roots, sentence):
    pass
```

```tests
replace_words(["cat", "bat", "rat"], "the cattle was rattled by the battery") == "the cat was rat by the bat"
replace_words(["a", "b", "c"], "aadsfasf absbs bbab cadsfafs") == "a a b c"
replace_words(["aaa", "aa", "a"], "aaaa aa a b") == "a a a b"
replace_words(["catt", "cat"], "cattle") == "cat"
replace_words(["cat"], "cat ca dog") == "cat ca dog"
replace_words([], "nothing changes here") == "nothing changes here"
replace_words(["a"], "") == ""
replace_words(["re", "rest"], "rest restore ore") == "re re ore"
replace_words([f"r{i}x" for i in range(5000)], " ".join(f"r{i}xyz" for i in range(40000))) == " ".join(f"r{i}x" if i < 5000 else f"r{i}xyz" for i in range(40000))
```

```python tests
import random

rng = random.Random(5)
for _ in range(300):
    roots = ["".join(rng.choice("ab") for _ in range(rng.randint(1, 4))) for _ in range(rng.randint(0, 5))]
    words = ["".join(rng.choice("ab") for _ in range(rng.randint(1, 6))) for _ in range(rng.randint(0, 6))]
    want = []
    for w in words:
        found = [r for r in roots if w.startswith(r)]
        want.append(min(found, key=len) if found else w)
    assert replace_words(roots, " ".join(words)) == " ".join(want), (roots, words)
```

```python solution
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def replace_words(roots, sentence):
    trie = TrieNode()
    for root in roots:
        node = trie
        for ch in root:
            if ch not in node.children:
                node.children[ch] = TrieNode()
            node = node.children[ch]
        node.end = True

    def shortest_root(word):
        node = trie
        for i, ch in enumerate(word):
            if ch not in node.children:
                return word
            node = node.children[ch]
            if node.end:
                return word[:i + 1]
        return word

    return " ".join(shortest_root(w) for w in sentence.split())
```

## Hints

1. Comparing every word with every root is slow for many roots. Put the roots in a trie, so each word needs one walk.
2. Walk down the trie along the word. The first node you reach that ends a root gives the shortest root.
3. For each word, step through its letters; if a letter is missing, keep the word, and if the node after letter `i` has `end` set, use `word[:i + 1]`. Join the results with `" "`.
