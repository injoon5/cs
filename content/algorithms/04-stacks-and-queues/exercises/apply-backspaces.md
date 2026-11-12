---
id: apply-backspaces
title: Apply backspaces
level: warmup
---

In `typed`, each `#` is a backspace: it deletes the character before it, if there is one. Return the text that is left. `"ab#c"` gives `"ac"`, and `"a##b"` gives `"b"`.

```python starter
def apply_backspaces(typed):
    pass
```

```tests
apply_backspaces("ab#c") == "ac"
apply_backspaces("a##b") == "b"
apply_backspaces("abc") == "abc"
apply_backspaces("") == ""
apply_backspaces("#") == ""
apply_backspaces("###a") == "a"
apply_backspaces("ab##") == ""
apply_backspaces("aa#a") == "aa"
apply_backspaces("x" * 1000 + "#" * 999) == "x"
```

```python solution
def apply_backspaces(typed):
    stack = []
    for ch in typed:
        if ch != "#":
            stack.append(ch)
        elif stack:
            stack.pop()
    return "".join(stack)
```

## Hints

1. A backspace always removes the most recent character that is still there.
2. Push each character onto a stack. On `#`, pop the top.
3. Skip the pop when the stack is empty. At the end, `"".join(stack)` is the answer.
