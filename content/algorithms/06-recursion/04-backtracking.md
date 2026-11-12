---
id: choose-explore-unchoose
title: Choose, explore, unchoose
---

List every subset of `[1, 2, 3]`. Go through the items one at a time and make one choice for each: take it or leave it. Each path from the top to the bottom of this tree is one subset. Labels show what has been taken so far.

```diagram
tree
r -> a b
a -> c d
b -> e f
c -> g h
d -> i j
e -> k l
f -> m n
node r "[]"
node a "1"
node b "[]"
node c "12"
node d "1"
node e "2"
node f "[]"
node g "123"
node h "12"
node i "13"
node j "1"
node k "23"
node l "2"
node m "3"
node n "[]"
```

Three yes-or-no choices make 2 × 2 × 2 = 8 subsets, one per leaf.

---

The code walks the tree with one shared list, `picked`. Before going down a branch it makes the choice, and after coming back it undoes it, so the next branch starts clean.

```python
nums = [1, 2, 3]
picked = []
out = []

def explore(i):
    if i == len(nums):
        out.append(picked[:])
        return
    picked.append(nums[i])  # choose
    explore(i + 1)          # explore
    picked.pop()            # unchoose
    explore(i + 1)          # leave it out

explore(0)
print(out)
```

This is backtracking: choose, explore, unchoose.

---

```python trace stop=35
nums = [1, 2]
picked = []
out = []

def explore(i):
    if i == len(nums):
        out.append(picked[:])
        return
    picked.append(nums[i])
    explore(i + 1)
    picked.pop()
    explore(i + 1)

explore(0)
print(out)
```

The search left out 1 and took 2. A leaf is about to be saved. What is `picked`?

- [ ] `[1, 2]`
- [x] `[2]`
- [ ] `[1]`

---

The leaf saves `picked[:]`, a copy. This version saves `picked` itself. What does it print?

```python predict
picked = []
out = []

def explore(i):
    if i == 2:
        out.append(picked)
        return
    picked.append(i)
    explore(i + 1)
    picked.pop()
    explore(i + 1)

explore(0)
print(out)
```

---

All four entries are the same list. By the end, every choice has been undone, so that one list is empty. Save a copy at each leaf.

---

Permutations use the same pattern with a different choice: which unused item goes next. For `[1, 2, 3]` there are 3 options at the top, then 2, then 1.

```diagram
tree
r -> a b c
a -> a2 a3
b -> b1 b3
c -> c1 c2
a2 -> a23
a3 -> a32
b1 -> b13
b3 -> b31
c1 -> c12
c2 -> c21
node r "[]"
node a "1"
node b "2"
node c "3"
node a2 "12"
node a3 "13"
node b1 "21"
node b3 "23"
node c1 "31"
node c2 "32"
node a23 "123"
node a32 "132"
node b13 "213"
node b31 "231"
node c12 "312"
node c21 "321"
```

That makes 3 × 2 × 1 = 6 permutations. With n items there are n!.

---

Run this to watch `picked` grow and shrink. Highlighted cells in `nums` are in use.

```python
import viz

nums = [1, 2, 3]
picked = []
used = [False] * len(nums)

def explore():
    in_use = [i for i, u in enumerate(used) if u]
    with viz.frame():
        viz.array(nums, name="nums", highlight=in_use)
        viz.array(picked, name="picked")
    if len(picked) == len(nums):
        return
    for i, x in enumerate(nums):
        if not used[i]:
            used[i] = True
            picked.append(x)
            explore()
            picked.pop()
            used[i] = False

explore()
```

---

Put the lines in order so `orderings` returns every ordering of the letters in `s`. Each call picks the next letter from what is left.

```python arrange
def orderings(s):
    if len(s) <= 1:
        return [s]
    out = []
    for i in range(len(s)):
        rest = s[:i] + s[i + 1:]
        for tail in orderings(rest):
            out.append(s[i] + tail)
    return out
```

```tests
orderings("abc") == ["abc", "acb", "bac", "bca", "cab", "cba"]
orderings("ab") == ["ab", "ba"]
orderings("a") == ["a"]
orderings("") == [""]
```

---

The subset search reaches 2ⁿ leaves and copies a list of up to n items at each. It takes

- [ ] O(n²) time
- [x] O(2ⁿ · n) time
- [ ] O(n! · n) time

---

For 10 distinct items, about how many permutations are there?

- [ ] 1,024
- [ ] 100,000
- [x] 3,628,800

---

[Bit strings](exercises/bit-strings.md)

[Subsets of size k](exercises/subsets-of-size.md)

[Unique permutations](exercises/unique-permutations.md)
