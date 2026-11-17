---
id: word-ladder-steps
title: Word ladder
level: stretch
---

A word ladder goes from `begin` to `end` by changing one letter at a time, and every word after `begin` must be in `words`. Return the number of words in the shortest ladder, counting `begin` and `end`, or 0 if there is no ladder. All words have the same length and use the letters `a` to `z`, and `begin` is not `end`.

From `"hit"` to `"cog"` with `["hot", "dot", "dog", "lot", "log", "cog"]`, the shortest ladder is hit, hot, dot, dog, cog, so the answer is 5.

```python starter
from collections import deque


def ladder_length(begin, end, words):
    pass
```

```tests
ladder_length("hit", "cog", ["hot", "dot", "dog", "lot", "log", "cog"]) == 5
ladder_length("hit", "cog", ["hot", "dot", "dog", "lot", "log"]) == 0
ladder_length("a", "c", ["a", "b", "c"]) == 2
ladder_length("hot", "dot", ["dot"]) == 2
ladder_length("hot", "dog", ["hot", "dog"]) == 0
ladder_length("cold", "warm", ["cord", "card", "ward", "warm", "word", "worm", "wore", "core"]) == 5
ladder_length("lead", "gold", ["load", "goad", "gold", "lead"]) == 4
ladder_length("aaaa", "iiii", [a + b + c + d for a in "abcdefghi" for b in "abcdefghi" for c in "abcdefghi" for d in "abcdefghi"]) == 5
```

```python tests
import random
from itertools import product


def slow(begin, end, words):
    pool = set(words)
    level, seen, steps = {begin}, {begin}, 1
    while level:
        if end in level:
            return steps
        nxt = set()
        for w in level:
            for u in pool - seen:
                if sum(a != b for a, b in zip(w, u)) == 1:
                    nxt.add(u)
        seen |= nxt
        level, steps = nxt, steps + 1
    return 0


all_words = ["".join(p) for p in product("abc", repeat=3)]
for _ in range(200):
    words = random.sample(all_words, random.randint(1, 12))
    begin, end = random.sample(all_words, 2)
    assert ladder_length(begin, end, words) == slow(begin, end, words), (begin, end, words)
```

```python solution
from collections import deque
from string import ascii_lowercase


def ladder_length(begin, end, words):
    words = set(words)
    if end not in words:
        return 0
    dist = {begin: 1}
    queue = deque([begin])
    while queue:
        word = queue.popleft()
        if word == end:
            return dist[word]
        for i in range(len(word)):
            for ch in ascii_lowercase:
                nxt = word[:i] + ch + word[i + 1:]
                if nxt in words and nxt not in dist:
                    dist[nxt] = dist[word] + 1
                    queue.append(nxt)
    return 0
```

## Hints

1. Each word is a node, and two words are joined when they differ in exactly one letter. The question is the fewest edges from `begin` to `end`.
2. Run BFS from `begin`. Comparing a word with every other word is slow on a big list. Instead, try each of the 26 letters at each position and keep the results that are in a set of `words`.
3. Store `dist = {begin: 1}`. For each word you take from the queue, build `word[:i] + ch + word[i + 1:]`. If it's in the set and not in `dist`, give it `dist[word] + 1` and queue it. Return the distance when you take `end` from the queue.
