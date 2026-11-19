---
id: using-tries
title: Using tries
---

How many words start with `ca`? Walking every word below the `ca` node would answer it, but there is a cheaper way: let each node count the words that pass through it.

```diagram
tree
node root "5"
node c "c 3"
node ca "a 3"
node car "r 2"
node card "d 1"
node cat "t 1"
node d "d 2"
node do "o 2"
node dog "g 1"
root -> c d
c -> ca
ca -> car cat
car -> card
d -> do
do -> dog
highlight ca
```

These are car, card, cat, do and dog again, and each node shows its letter and its count. Insert adds 1 to every node on the word's path, the root included, so the root counts all 5 words. The count on the `ca` node, 3, is the answer, and finding it costs only the length of the prefix.

---

Here `car` is inserted twice, so it counts twice. What does this print?

```python predict
class TrieNode:
    def __init__(self):
        self.children = {}
        self.end = False
        self.count = 0


def insert(root, word):
    node = root
    node.count += 1
    for ch in word:
        if ch not in node.children:
            node.children[ch] = TrieNode()
        node = node.children[ch]
        node.count += 1
    node.end = True


def count_prefix(root, prefix):
    node = root
    for ch in prefix:
        if ch not in node.children:
            return 0
        node = node.children[ch]
    return node.count


root = TrieNode()
for word in ["car", "card", "cat", "car", "do"]:
    insert(root, word)
for prefix in ["ca", "car", "d", "", "x"]:
    print(repr(prefix), count_prefix(root, prefix))
```

---

Autocomplete wants the words themselves. Walk down to the prefix's node, then visit everything below it, carrying the letters spelled so far in `path`. Each node that ends a word adds `path` to the list.

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


def collect(node, path, out):
    if node.end:
        out.append(path)
    for ch in sorted(node.children):
        collect(node.children[ch], path + ch, out)


def complete(root, prefix):
    node = root
    for ch in prefix:
        if ch not in node.children:
            return []
        node = node.children[ch]
    out = []
    collect(node, prefix, out)
    return out


root = TrieNode()
for word in ["dog", "cat", "card", "care", "car", "do"]:
    insert(root, word)
print(complete(root, "car"))
print(complete(root, "d"))
print(complete(root, "x"))
```

---

Here `collect` starts at the root, so it lists every word in the trie.

```python trace stop=119
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


def collect(node, path, out):
    if node.end:
        out.append(path)
    for ch in sorted(node.children):
        collect(node.children[ch], path + ch, out)


root = TrieNode()
for word in ["care", "card", "car"]:
    insert(root, word)
out = []
collect(root, "", out)
print(out)
```

`collect` has just been called with `path` set to `care`. What is in `out`?

- [ ] `[]`, since words are only added on the way back up
- [x] `['car', 'card']`
- [ ] `['car', 'card', 'care']`

---

The words went in out of order, yet `collect` returns them sorted. Why?

- [ ] A dict keeps its keys in sorted order
- [x] A word is added before the longer words below it, and children are visited in sorted order
- [ ] The trie sorts its words as they are inserted

That is alphabetical order: `car` comes before `card`, and `card` before `care`.

---

Finding the node costs O(P) for a prefix of length P. After that, `collect` costs

- [ ] O(P) as well
- [x] O(size of the subtree under that node)
- [ ] O(number of words in the whole trie)

A short prefix like `a` can sit above a large part of the trie. To stop after the first 3 words, have `collect` return as soon as `out` holds 3.

---

A trie also fits in a few lines with plain nested dicts. Each node is a dict from letter to child dict, and a key that is never a letter, here `$`, marks the end of a word. What does this print?

```python predict
trie = {}
for word in ["to", "tea", "ten"]:
    node = trie
    for ch in word:
        node = node.setdefault(ch, {})
    node["$"] = True
print(trie)
```

`node.setdefault(ch, {})` returns the child for `ch`, adding an empty one first if it is missing.

---

The longest common prefix of a list of words is a walk from the root: keep going while the path doesn't branch.

```diagram
tree
node root " "
node f "f"
node fl "l"
node flo "o"
node flow "w"
node flowe "e"
node flower "r"
node fli "i"
node flig "g"
node fligh "h"
node flight "t"
root -> f
f -> fl
fl -> flo fli
flo -> flow
flow -> flowe
flowe -> flower
fli -> flig
flig -> fligh
fligh -> flight
highlight f fl
```

For flow, flower and flight, the path splits after `fl`, so that is the answer.

---

The walk stops when a node has more than one child. For the words `flow` and `flower`, the path never branches. Why must the walk also stop at a node where a word ends?

- [ ] It doesn't need to, the answer is `flower`
- [x] Every word has to start with the prefix, and `flow` ends there
- [ ] The node where `flow` ends has no children

---

Letters are only one alphabet. Numbers can go in a trie as their bits, highest bit first. Xor, `x ^ y`, has a 1 bit wherever `x` and `y` differ, so the number with the largest xor with `x` is the one that differs from it in the highest bits. Walk down for `x` and, at each level, take the child with the opposite bit when there is one. A 1 in a high bit is worth more than all the lower bits together, so winning the high bits first is never wrong.

---

[Words with a prefix](exercises/count-with-prefix.md)

[Longest common prefix](exercises/trie-common-prefix.md)

[Autocomplete](exercises/autocomplete-top-three.md)

[Largest xor of a pair](exercises/max-xor-pair.md)
