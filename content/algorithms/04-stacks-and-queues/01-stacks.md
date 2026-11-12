---
id: stacks
title: Stacks
---

An editor keeps your changes in a pile. Each new change goes on top. Undo takes the top one off.

```diagram
stack history ["type a", "type b", bold]
highlight 2
```

That pile is a stack: the last thing in is the first thing out. A Python list is already one. `append` puts an item on top, and `pop()` takes the top item off and returns it.

```python
history = []
history.append("type a")
history.append("type b")
history.append("bold")
print(history.pop())
print(history)
```

---

Why is the top at the end of the list and not the start?

A list keeps its items in one row of slots. Adding or removing at the end touches one slot. Removing at the front leaves a gap, so every other item shifts left by one.

```diagram
array [a, b, c, d, e]
highlight 0
```

Taking `a` from this list moves `b`, `c`, `d` and `e`. With n items that is n - 1 moves.

---

With `top` at the end of a list of n items, `append` and `pop()` take

- [x] O(1) time each, amortized for `append`
- [ ] O(1) for `append`, O(n) for `pop()`
- [ ] O(n) time each, because the list may grow

---

What does this print?

```python predict
st = []
for x in [1, 2, 3]:
    st.append(x)
st.pop()
st.append(4)
print(st, st[-1])
```

---

Is `([]{})` balanced? Every closing bracket has to match the most recent opening bracket that is still open. "Most recent" is the top of a stack.

Read left to right. Push each opener. At each closer, pop the top and check that it is the matching opener. At the end the stack must be empty.

```diagram
array s ["(", "[", "]", "{", "}", ")"]
pointer ch 3
stack ["(", "{"]
highlight 1
```

At `{` the stack holds `(` and the new `{`. The `[` already met its `]` and left.

---

```python trace stop=14
s = "([]{})"
pairs = {")": "(", "]": "[", "}": "{"}
stack = []
ok = True
for ch in s:
    if ch in pairs:
        if not stack or stack.pop() != pairs[ch]:
            ok = False
            break
    else:
        stack.append(ch)
print(ok and not stack)
```

`ch` is `]`, and its check has just finished. What is in `stack`?

- [x] `['(']`
- [ ] `['(', '[']`
- [ ] `[]`

---

Run this to watch the stack on a string that goes wrong.

```python
import viz

s = "{[(])}"
pairs = {")": "(", "]": "[", "}": "{"}
stack = []
for i, ch in enumerate(s):
    with viz.frame():
        viz.array(list(s), pointers={"ch": i})
        viz.stack(stack)
    if ch not in pairs:
        stack.append(ch)
    elif stack.pop() != pairs[ch]:
        viz.note(f"{ch} does not match the top")
        break
```

---

Put the lines in order so `is_balanced` returns whether every bracket is matched.

```python arrange
def is_balanced(s):
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    for ch in s:
        if ch in pairs:
            if not stack or stack.pop() != pairs[ch]:
                return False
        else:
            stack.append(ch)
    return not stack
```

```tests
is_balanced("([]{})") == True
is_balanced("([)]") == False
is_balanced("((") == False
is_balanced("))") == False
is_balanced("") == True
```

---

Why does `is_balanced` check `not stack` before it pops?

- [ ] Popping an empty list returns `None`, which breaks the comparison
- [x] A closer with nothing open is unbalanced, and popping an empty list raises an error
- [ ] To make the loop O(1) per character

---

Stacks also evaluate postfix expressions, where the operator comes after its two numbers. `3 4 + 2 *` means `(3 + 4) * 2`.

Push each number. At an operator, pop two numbers, apply it, and push the result. After `3 4 +` the stack holds one number:

```diagram
stack [7]
highlight 0
```

Then `2` goes on top, and `*` pops 2 and 7 and pushes 14. No parentheses and no precedence rules are needed.

---

[Apply backspaces](exercises/apply-backspaces.md)

[Evaluate postfix](exercises/eval-postfix.md)

[Longest valid parentheses](exercises/longest-valid-parens.md)
