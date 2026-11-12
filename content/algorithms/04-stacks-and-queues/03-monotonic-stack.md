---
id: monotonic-stack
title: Monotonic stacks
---

For each number, find the next number to its right that is bigger. Write -1 if there is none.

```diagram
array nums [5, 3, 1, 4, 6, 2]
array next [6, 4, 4, 6, -1, -1]
```

Scanning right from every number works, but a falling list like `[6, 5, 4, 3, 2, 1]` makes each scan run to the end. That is about n²/2 comparisons.

---

Read left to right and keep the numbers still waiting for an answer on a stack. After 5, 3 and 1 the stack is `5, 3, 1`. Nothing bigger has come yet.

```diagram
array nums [5, 3, 1, 4, 6, 2]
pointer i 3
highlight 0 1 2
stack waiting [5, 3, 1]
highlight 2
```

Then 4 arrives. It is the answer for 1, so pop 1. It is the answer for 3, so pop 3. It is not bigger than 5, so stop and push 4. The stack is now `5, 4`.

---

The stack always runs from big at the bottom to small at the top. That order is why the scan can stop at the first number that is not smaller: everything under it is bigger still.

Such a stack is called monotonic. It holds indexes, so the answer can be written to the right slot.

```python
nums = [5, 3, 1, 4, 6, 2]
ans = [-1] * len(nums)
stack = []
for i, x in enumerate(nums):
    while stack and nums[stack[-1]] < x:
        ans[stack.pop()] = x
    stack.append(i)
print(ans)
```

---

Run this to watch numbers wait on the stack and leave when a bigger one arrives.

```python
import viz

nums = [5, 3, 1, 4, 6, 2]
ans = [-1] * len(nums)
stack = []
for i, x in enumerate(nums):
    while stack and nums[stack[-1]] < x:
        j = stack.pop()
        ans[j] = x
        viz.note(f"{x} answers {nums[j]}")
    stack.append(i)
    with viz.frame():
        viz.array(nums, pointers={"i": i}, highlight=stack)
        viz.stack([nums[j] for j in stack], name="waiting")
print(ans)
```

---

```python trace stop=20
nums = [5, 3, 1, 4, 6, 2]
ans = [-1] * len(nums)
stack = []
for i, x in enumerate(nums):
    while stack and nums[stack[-1]] < x:
        ans[stack.pop()] = x
    stack.append(i)
print(ans)
```

4 has just been pushed. What is `stack`?

- [ ] `[0, 1, 2, 3]`
- [x] `[0, 3]`
- [ ] `[3]`

---

Equal numbers are not bigger. What does this print?

```python predict
nums = [2, 2, 1, 3]
ans = [-1] * len(nums)
stack = []
for i, x in enumerate(nums):
    while stack and nums[stack[-1]] < x:
        ans[stack.pop()] = x
    stack.append(i)
print(ans)
```

---

The `while` inside the `for` can pop many items at once. On n numbers, the whole scan takes

- [ ] O(n²) time, when the list is falling
- [x] O(n) time, because each index is pushed once and popped at most once
- [ ] O(n log n) time, like sorting

---

Put the lines in order so `next_smaller` finds the next smaller number to the right of each one, or -1.

```python arrange
def next_smaller(nums):
    ans = [-1] * len(nums)
    stack = []
    for i, x in enumerate(nums):
        while stack and nums[stack[-1]] > x:
            ans[stack.pop()] = x
        stack.append(i)
    return ans
```

```tests
next_smaller([4, 6, 5, 1]) == [1, 5, 1, -1]
next_smaller([1, 2, 3]) == [-1, -1, -1]
next_smaller([3, 3, 1]) == [1, 1, -1]
next_smaller([]) == []
```

---

Once a number is popped, why is it never needed again?

- [x] It has its answer, and every number still waiting to its left is at least as big, so it can't answer them
- [ ] Every number after it is bigger than it
- [ ] The stack has to stay sorted, so it must go

---

[Days until warmer](exercises/days-until-warmer.md)

[Price span](exercises/price-span.md)

[Largest rectangle](exercises/largest-rectangle.md)
