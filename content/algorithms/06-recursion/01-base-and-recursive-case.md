---
id: base-and-recursive-case
title: Base case and recursive case
---

What is the total of `[4, 1, 3]`? It is 4 plus the total of `[1, 3]`. And the total of `[1, 3]` is 1 plus the total of `[3]`.

```diagram
array nums [4, 1, 3]
highlight 0
shade 1..2
```

The question keeps shrinking until it is one you can answer without thinking: the total of an empty list is 0.

---

That idea, written as a function that calls itself:

```python
def total(nums):
    if not nums:
        return 0
    return nums[0] + total(nums[1:])

print(total([4, 1, 3]))
```

The `if` is the base case. It answers the smallest question directly. The last line is the recursive case. It handles one item and hands the rest to a smaller call.

---

When you write the recursive case, don't follow the calls down in your head. Assume `total(nums[1:])` already returns the right answer for the rest of the list. Your only job is to combine it with `nums[0]`.

If the base case is right, and every call gets a smaller input, the whole thing is right. It is the same argument as a proof by induction.

---

```python predict
def countdown(n):
    if n == 0:
        print("go")
        return
    print(n)
    countdown(n - 1)

countdown(3)
```

---

Now the `print` comes after the call. What does this print?

```python predict
def show(n):
    if n == 0:
        return
    show(n - 1)
    print(n)

show(3)
```

---

Code after the recursive call runs on the way back up. `show(3)` can't print 3 until `show(2)` has finished, and `show(2)` waits for `show(1)`. So the smallest call prints first.

---

Someone writes `return nums[0] + total(nums)` by mistake. What happens on `total([4, 1, 3])`?

- [ ] It returns 4
- [ ] It returns 8, the same as before
- [x] It never reaches the base case, because the list never gets shorter

---

Put the lines in order so `reverse_text` returns its string backwards.

```python arrange
def reverse_text(s):
    if len(s) <= 1:
        return s
    return reverse_text(s[1:]) + s[0]
```

```tests
reverse_text("abc") == "cba"
reverse_text("ab") == "ba"
reverse_text("a") == "a"
reverse_text("") == ""
```

---

`total(nums)` makes one call per item. But `nums[1:]` copies the rest of the list each time. On a list of n numbers, `total` takes

- [ ] O(n) time
- [x] O(n²) time
- [ ] O(2ⁿ) time

---

Passing an index instead of a slice avoids the copies, so this version is O(n).

```python
def total(nums, i=0):
    if i == len(nums):
        return 0
    return nums[i] + total(nums, i + 1)

print(total([4, 1, 3]))
```

---

[Digit sum](exercises/digit-sum.md)

[Flatten a nested list](exercises/flatten-nested.md)
