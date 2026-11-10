---
id: best-worst-average
title: Best, worst and average case
---

Linear search checks each item in turn until it finds the target.

```python
def find(nums, target):
    for i in range(len(nums)):
        if nums[i] == target:
            return i
    return -1

print(find([7, 2, 9, 4, 5], 7))
print(find([7, 2, 9, 4, 5], 8))
```

The same function, on the same list, did very different amounts of work.

---

Looking for 7 takes one check. It's at the front.

```diagram
array [7, 2, 9, 4, 5]
pointer i 0
highlight 0
```

That's the best case: O(1), whatever the length.

---

```python trace stop=11
nums = [7, 2, 9, 4, 5]
target = 4
for i in range(len(nums)):
    if nums[i] == target:
        break
```

The loop is about to stop. What is `i`?

- [ ] 2
- [x] 3
- [ ] 4

---

Looking for 8 in a list of `n` numbers that has no 8. How many items get checked?

- [ ] 1
- [ ] About `n / 2`
- [x] All `n`

---

If the target is equally likely to be at any spot, how many checks happen on average? Here's the count for 10 items.

```python predict
n = 10
total = 0
for spot in range(n):
    total += spot + 1
print(total / n)
```

---

On average it's about `n / 2` checks. Halving a count doesn't change its growth, so the average case is still O(n).

Best case is the luckiest input, worst case the unluckiest, average case the typical one. When people give one Big-O without saying which, they almost always mean the worst case. It's a promise that holds for every input.

---

Linear search finds the first item in one step. Why isn't it called O(1)?

- [ ] Big-O ignores the first step
- [x] That only happens for lucky inputs, and Big-O usually describes the worst case
- [ ] Lists can't be searched in constant time

---

[First index](exercises/first-index.md)
