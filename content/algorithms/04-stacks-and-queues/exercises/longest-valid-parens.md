---
id: longest-valid-parens
title: Longest valid parentheses
level: stretch
---

`s` holds only `(` and `)`. Return the length of the longest run of characters in a row that is balanced. In `")()())"` the answer is 4, for `()()`.

```python starter
def longest_valid_parens(s):
    pass
```

```tests
longest_valid_parens(")()())") == 4
longest_valid_parens("(()") == 2
longest_valid_parens("") == 0
longest_valid_parens("(") == 0
longest_valid_parens(")(") == 0
longest_valid_parens("()(())") == 6
longest_valid_parens("()(()") == 2
longest_valid_parens("(()())") == 6
longest_valid_parens("())(())") == 4
longest_valid_parens("()" * 500) == 1000
```

```python solution
def longest_valid_parens(s):
    stack = [-1]
    best = 0
    for i, ch in enumerate(s):
        if ch == "(":
            stack.append(i)
        else:
            stack.pop()
            if not stack:
                stack.append(i)
            else:
                best = max(best, i - stack[-1])
    return best
```

## Hints

1. Push indexes instead of characters. The distance between two indexes is a length.
2. Keep the index just before the current valid run at the bottom of the stack. Start with `-1` there.
3. On `(`, push `i`. On `)`, pop. If the stack is now empty, push `i` as the new floor. Otherwise the run ending here has length `i - stack[-1]`.
