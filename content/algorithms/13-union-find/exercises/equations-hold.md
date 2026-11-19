---
id: equations-hold
title: Equations that can all hold
level: core
---

Each string in `equations` is `"x==y"` or `"x!=y"`, where `x` and `y` are variable names made of lowercase letters. Return `True` if some choice of numbers for the variables makes every equation true at once.

`["a==b", "b==c", "a!=c"]` can't hold: the first two force `a` to equal `c`. `["a==b", "b!=c"]` can, for example with `a = b = 1` and `c = 2`.

```python starter
def can_all_hold(equations):
    pass
```

```tests
can_all_hold(["a==b", "b==c", "a!=c"]) == False
can_all_hold(["a==b", "b!=c"]) == True
can_all_hold([]) == True
can_all_hold(["a==a"]) == True
can_all_hold(["a!=a"]) == False
can_all_hold(["a!=b", "b!=a"]) == True
can_all_hold(["c!=a", "a==b", "b==c"]) == False
can_all_hold(["price==cost", "cost==fee", "tax!=fee", "tax==tip"]) == True
can_all_hold(["x==y", "z==w", "y==w", "x!=z"]) == False
can_all_hold([f"v{i}==v{i + 1}" for i in range(99999)] + [f"v0!=w{j}" for j in range(100000)]) == True
can_all_hold([f"v{i + 1}==v{i}" for i in range(99999)] + [f"v0!=w{j}" for j in range(100000)]) == True
```

```python tests
import random


def slow(equations):
    names = sorted({s for e in equations for s in e.replace("!=", "==").split("==")})
    for values in __import__("itertools").product(range(len(names)), repeat=len(names)):
        value = dict(zip(names, values))
        ok = True
        for e in equations:
            if "==" in e:
                x, y = e.split("==")
                ok = ok and value[x] == value[y]
            else:
                x, y = e.split("!=")
                ok = ok and value[x] != value[y]
        if ok:
            return True
    return not names


for _ in range(300):
    eqs = [random.choice("abcd") + random.choice(["==", "!="]) + random.choice("abcd")
           for _ in range(random.randint(0, 6))]
    assert can_all_hold(eqs) == slow(eqs), eqs
```

```python solution
def can_all_hold(equations):
    parent = {}

    def find(x):
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for e in equations:
        if "==" in e:
            x, y = e.split("==")
            parent[find(x)] = find(y)
    for e in equations:
        if "!=" in e:
            x, y = e.split("!=")
            if find(x) == find(y):
                return False
    return True
```

## Hints

1. Equal is contagious: `a==b` and `b==c` put `a`, `b` and `c` in one group. Unequal never forces anything by itself.
2. Merge the two sides of every `==` first. Then an equation `x!=y` fails exactly when `x` and `y` ended up in the same group.
3. Use a dict for `parent`, adding each name the first time `find` sees it. Split each string with `e.split("==")` or `e.split("!=")`. Do all the `==` before checking any `!=`.
