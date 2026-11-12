---
id: pruning
title: Pruning the search
---

Which numbers from `[2, 3, 4]` add up to 6, each used at most once? Backtracking can try every subset. But once the picked numbers already pass 6, nothing below that branch can work. Cutting a branch off early is called pruning.

```diagram
tree
r -> a b c
a -> ab ac
b -> bc
node r "6 left"
node a "2: 4 left"
node b "3: 3 left"
node c "4: 2 left"
node ab "3: 1 left"
node ac "4: 0 left"
node bc "4: too big"
highlight ac
dim bc
```

---

Sort the numbers first. Then, as soon as one number is bigger than what is left, every number after it is too, and the loop can stop.

```python
nums = [2, 3, 4]
picked = []

def explore(start, left):
    if left == 0:
        print(picked)
        return
    for i in range(start, len(nums)):
        if nums[i] > left:
            break
        picked.append(nums[i])
        explore(i + 1, left - nums[i])
        picked.pop()

explore(0, 6)
```

`left` is how much of the target is still missing. Each number goes in, the search goes deeper with less left, and the number comes back out.

---

```python trace stop=20
nums = [2, 3, 4]
picked = []

def explore(start, left):
    if left == 0:
        print(picked)
        return
    for i in range(start, len(nums)):
        if nums[i] > left:
            break
        picked.append(nums[i])
        explore(i + 1, left - nums[i])
        picked.pop()

explore(0, 6)
```

`picked` is `[2, 3]`, `left` is 1, and the next number is 4. What does this call do?

- [ ] Takes 4 and goes one level deeper
- [ ] Skips 4 and tries the next number
- [x] Stops its loop, because every later number is at least 4

---

How much does the `break` save? This counts calls with and without it, for the numbers 1 to 12 and a target of 6.

```python predict
def count_calls(nums, target, prune):
    calls = 0

    def explore(start, left):
        nonlocal calls
        calls += 1
        if left == 0:
            return
        for i in range(start, len(nums)):
            if prune and nums[i] > left:
                break
            explore(i + 1, left - nums[i])

    explore(0, target)
    return calls

nums = list(range(1, 13))
print(count_calls(nums, 6, prune=False))
print(count_calls(nums, 6, prune=True))
```

---

Run this to watch the search. Each frame shows what is picked so far.

```python
import viz

nums = [1, 2, 3, 4, 5]
target = 7
picked = []

def explore(start, left):
    if left == 0:
        viz.array(picked, name="picked", note="found")
        return
    for i in range(start, len(nums)):
        if nums[i] > left:
            viz.array(picked, name="picked", note=f"{nums[i]} > {left}, stop")
            break
        picked.append(nums[i])
        viz.array(picked, name="picked", highlight=len(picked) - 1, note=f"{left - nums[i]} left")
        explore(i + 1, left - nums[i])
        picked.pop()

explore(0, target)
```

---

The worst case doesn't change: some inputs still force the search to look at every subset. Pruning helps when a partial choice can already be ruled out, and it often turns a hopeless search into a fast one.

---

The classic pruning puzzle: place n queens on an n × n board so that no two share a row, a column or a diagonal. One answer for n = 4:

```diagram
grid board
row [, Q, , ]
row [, , , Q]
row [Q, , , ]
row [, , Q, ]
highlight 0,1 1,3 2,0 3,2
```

Place one queen per row, top to bottom. In each row, try each column, skip squares an earlier queen attacks, and take the queen back when the rows below run out of options.

---

Keep sets of the columns and diagonals already taken, so checking a square is O(1). Two squares `(r1, c1)` and `(r2, c2)` are on the same down-right diagonal when

- [ ] `r1 + c1 == r2 + c2`
- [x] `r1 - c1 == r2 - c2`
- [ ] `r1 * c1 == r2 * c2`

---

Grids work the same way. To find a word in a grid of letters, start at a cell with the first letter, then step to a neighbor with the next one. Mark a cell as used before going deeper and unmark it when you come back, so a path never reuses a cell.

```diagram
grid letters
row [c, a, t]
row [x, r, s]
row [o, d, e]
highlight 0,0 0,1 1,1 2,1
```

The highlighted path spells `card`.

---

[Combinations that hit a target](exercises/combination-target.md)

[Count n-queens solutions](exercises/n-queens-count.md)

[Word search](exercises/grid-word-search.md)
