---
id: eval-postfix
title: Evaluate postfix
level: core
---

`tokens` is a postfix expression: each operator comes after its two operands. Return its value. Tokens are integer strings or one of `+`, `-`, `*`, `/`. Division rounds toward zero, like `int(a / b)`. For `["3", "4", "+", "2", "*"]` the answer is `(3 + 4) * 2`, which is 14. The expression is always valid.

```python starter
def eval_postfix(tokens):
    pass
```

```tests
eval_postfix(["3", "4", "+", "2", "*"]) == 14
eval_postfix(["5"]) == 5
eval_postfix(["-5"]) == -5
eval_postfix(["10", "3", "-"]) == 7
eval_postfix(["3", "10", "-"]) == -7
eval_postfix(["7", "2", "/"]) == 3
eval_postfix(["-7", "2", "/"]) == -3
eval_postfix(["2", "3", "4", "*", "+"]) == 14
eval_postfix(["4", "13", "5", "/", "+"]) == 6
eval_postfix(["1", "1", "+"] + ["1", "+"] * 98) == 100
```

```python solution
def eval_postfix(tokens):
    stack = []
    for t in tokens:
        if t in ("+", "-", "*", "/"):
            b = stack.pop()
            a = stack.pop()
            if t == "+":
                stack.append(a + b)
            elif t == "-":
                stack.append(a - b)
            elif t == "*":
                stack.append(a * b)
            else:
                stack.append(int(a / b))
        else:
            stack.append(int(t))
    return stack.pop()
```

## Hints

1. An operator always works on the two most recent values that haven't been used yet.
2. Push numbers. At an operator, pop two values, combine them, and push the result.
3. The first pop is the right operand: `b = stack.pop()`, then `a = stack.pop()`, then push `a - b`. Use `int(a / b)` for division, since `//` rounds `-7 // 2` down to -4.
