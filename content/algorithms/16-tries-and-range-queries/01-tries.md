---
id: trie-basics
title: Tries
---

A word list holds a hundred thousand words. Is `cat` one of them? A set answers that in O(length of the word). Does any word start with `ca`? A set can't tell without looking at every word.

A trie stores words by their letters instead. Here it holds car, card, cat, do and dog.

```diagram
tree
node root " "
root -> c d
node ca "a"
node car "r"
node card "d"
node cat "t"
node do "o"
node dog "g"
c -> ca
ca -> car cat
car -> card
d -> do
do -> dog
highlight car card cat do dog
```

Each step down spells one letter, so every node stands for the prefix on the path to it. Words that start the same share that path: car, card and cat all go through c, a. The highlighted nodes are where a word ends.

---

Each node is a dict from a letter to a child node, plus a flag that says whether a word ends here. The letter lives in the parent's dict, so the node itself doesn't store one.

To insert a word, walk down letter by letter from the root. Where a letter has no child yet, add one. Set the flag on the last node.

```python
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def insert(root, word):
    node = root
    for ch in word:
        if ch not in node.children:
            node.children[ch] = TrieNode()
        node = node.children[ch]
    node.end = True


root = TrieNode()
for word in ["car", "card", "cat", "do", "dog"]:
    insert(root, word)
print(list(root.children))
print(list(root.children["c"].children["a"].children))
```

---

Run this to watch the trie grow. So the drawing can label the nodes, each one also keeps its letter in `val`.

```python
import viz


class TrieNode:
    def __init__(self, val=""):
        self.val = val
        self.children = {}
        self.end = False


root = TrieNode()
for word in ["car", "cat", "card", "dog"]:
    node = root
    for ch in word:
        if ch in node.children:
            note = f"{word}: {ch} is already there"
        else:
            node.children[ch] = TrieNode(ch)
            note = f"{word}: add {ch}"
        node = node.children[ch]
        viz.tree(root, active=node, note=note)
    node.end = True
```

Only the first word builds its whole path. Later words reuse the prefix they share with words already in the trie.

---

This `insert` returns how many nodes it added. What does this print?

```python predict
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def insert(root, word):
    node = root
    added = 0
    for ch in word:
        if ch not in node.children:
            node.children[ch] = TrieNode()
            added += 1
        node = node.children[ch]
    node.end = True
    return added


root = TrieNode()
for word in ["tea", "ten", "team", "te", "to"]:
    print(word, insert(root, word))
```

---

Searching walks the same way. A missing letter means the word isn't there. If every letter is found, the word is there only if the last node has its flag set.

```python trace stop=80
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def insert(root, word):
    node = root
    for ch in word:
        if ch not in node.children:
            node.children[ch] = TrieNode()
        node = node.children[ch]
    node.end = True


def search(root, word):
    node = root
    for ch in word:
        if ch not in node.children:
            return False
        node = node.children[ch]
    return node.end


root = TrieNode()
insert(root, "car")
insert(root, "card")
print(search(root, "carts"))
```

The trie holds car and card. The search is about to return `False`. How much of `carts` did it find?

- [ ] Nothing, since `c` is the letter it is looking at
- [x] `car`, since `t` is the letter it is looking at
- [ ] `cart`, since `s` is the letter it is looking at

---

The trie holds car, card and cat. Which search returns `True`?

- [ ] `search(root, "ca")`, since the path c, a exists
- [x] `search(root, "card")`
- [ ] `search(root, "cards")`, since card is in the trie

`ca` is only a prefix: its node is there, but no word ends on it. That one flag is the difference between a word and a prefix.

---

`starts_with` asks the prefix question that a set couldn't answer. Put the lines in order. It walks like `search` but ignores the flag.

```python arrange
def starts_with(root, prefix):
    node = root
    for ch in prefix:
        if ch not in node.children:
            return False
        node = node.children[ch]
    return True
```

```python tests
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False


def insert(root, word):
    node = root
    for ch in word:
        node = node.children.setdefault(ch, TrieNode())
    node.end = True


root = TrieNode()
for word in ["car", "card", "cat"]:
    insert(root, word)
assert starts_with(root, "ca")
assert starts_with(root, "card")
assert starts_with(root, "")
assert not starts_with(root, "cab")
assert not starts_with(root, "cards")
assert not starts_with(TrieNode(), "c")
```

---

A trie holds n words. Inserting or searching a word of length L costs

- [x] O(L), however many words are stored
- [ ] O(L log n), like a search in a balanced tree
- [ ] O(n × L), since it may compare with every word

Each letter is one dict lookup and one step down. The other words never come into it.

---

The speed costs memory. Each node is an object with its own dict, a few hundred bytes even when it has one child, and words with nothing in common share no nodes. A set of the same words takes many times less memory.

When is a trie the better choice?

- [ ] When you only check whether whole words are in the list
- [x] When you ask about prefixes: which words start with this, or how many
- [ ] When the words are long and share nothing

For whole words a set is just as fast and much smaller. The trie earns its space on prefix questions, which is what the next lesson is about.

---

[Build a trie](exercises/trie-insert-search.md)

[Shortest root](exercises/replace-with-roots.md)
