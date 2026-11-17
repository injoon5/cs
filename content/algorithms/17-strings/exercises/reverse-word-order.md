---
id: reverse-word-order
title: Reverse the words
level: warmup
---

Return the words of `s` in reverse order, joined by single spaces. Words are separated by one or more spaces, and there may be spaces at either end. `"  the sky  is blue "` becomes `"blue is sky the"`.

```python starter
def reverse_words(s):
    pass
```

```tests
reverse_words("  the sky  is blue ") == "blue is sky the"
reverse_words("hello world") == "world hello"
reverse_words("one") == "one"
reverse_words("") == ""
reverse_words("    ") == ""
reverse_words("a b a") == "a b a"
reverse_words(" x  y ") == "y x"
reverse_words(" ".join(map(str, range(100000)))) == " ".join(map(str, range(99999, -1, -1)))
```

```python tests
import random

for _ in range(300):
    words = ["".join(random.choice("abc") for _ in range(random.randint(1, 4))) for _ in range(random.randint(0, 6))]
    gaps = [" " * random.randint(1, 3) for _ in words]
    s = " " * random.randint(0, 2) + "".join(w + g for w, g in zip(words, gaps))
    assert reverse_words(s) == " ".join(words[::-1]), s
```

```python solution
def reverse_words(s):
    return " ".join(reversed(s.split()))
```

## Hints

1. Get the words out first, without the spaces, then put them back together.
2. `s.split()` with no argument splits on any run of spaces and drops empty pieces at the ends.
3. `" ".join(reversed(words))` puts the words back in reverse order with one space between them.
