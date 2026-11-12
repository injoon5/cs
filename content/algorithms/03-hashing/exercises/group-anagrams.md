---
id: group-anagrams
title: Group anagrams
level: core
---

Group the words that are anagrams of each other. Return a list of groups. Groups come in the order their first word appears, and words in a group keep their input order. For `["eat", "tea", "tan", "ate", "nat", "bat"]` the answer is `[["eat", "tea", "ate"], ["tan", "nat"], ["bat"]]`.

```python starter
def group_anagrams(words):
    pass
```

```tests
group_anagrams(["eat", "tea", "tan", "ate", "nat", "bat"]) == [["eat", "tea", "ate"], ["tan", "nat"], ["bat"]]
group_anagrams([]) == []
group_anagrams(["a"]) == [["a"]]
group_anagrams(["", ""]) == [["", ""]]
group_anagrams(["ab", "ba", "ab"]) == [["ab", "ba", "ab"]]
group_anagrams(["abc", "def", "ghi"]) == [["abc"], ["def"], ["ghi"]]
group_anagrams(["aab", "abb", "bab"]) == [["aab"], ["abb", "bab"]]
group_anagrams(["listen", "silent", "enlist", "tinsel", "list"]) == [["listen", "silent", "enlist", "tinsel"], ["list"]]
```

```python tests
from itertools import permutations

words = ["".join(p) for p in permutations("abcdefg")]
groups = group_anagrams(words * 3)
assert len(groups) == 1 and len(groups[0]) == len(words) * 3
```

```python solution
def group_anagrams(words):
    groups = {}
    for w in words:
        key = "".join(sorted(w))
        groups.setdefault(key, []).append(w)
    return list(groups.values())
```

## Hints

1. Find a key that every anagram of a word shares and nothing else does.
2. Sort each word's letters to get its key, and keep a dict from key to a list of words.
3. `groups.setdefault("".join(sorted(w)), []).append(w)`, then `return list(groups.values())`. A dict keeps keys in the order they were added.
