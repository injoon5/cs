---
id: largest-rectangle
title: Largest rectangle
level: stretch
---

`heights` are the heights of bars of width 1, side by side. Return the area of the largest rectangle that fits inside the bars. For `[2, 1, 5, 6, 2, 3]` the answer is 10: height 5 across the bars `5, 6`.

```diagram
array heights [2, 1, 5, 6, 2, 3]
shade 2..3
```

```python starter
def largest_rectangle(heights):
    pass
```

```tests
largest_rectangle([2, 1, 5, 6, 2, 3]) == 10
largest_rectangle([]) == 0
largest_rectangle([7]) == 7
largest_rectangle([0, 0]) == 0
largest_rectangle([2, 4]) == 4
largest_rectangle([3, 3, 3]) == 9
largest_rectangle([1, 2, 3, 4, 5]) == 9
largest_rectangle([5, 4, 3, 2, 1]) == 9
largest_rectangle([2, 1, 2]) == 3
largest_rectangle([6, 2, 5, 4, 5, 1, 6]) == 12
largest_rectangle([1] * 1000) == 1000
```

```python solution
def largest_rectangle(heights):
    best = 0
    stack = []
    bars = heights + [0]
    for i, h in enumerate(bars):
        while stack and bars[stack[-1]] >= h:
            height = bars[stack.pop()]
            left = stack[-1] if stack else -1
            best = max(best, height * (i - left - 1))
        stack.append(i)
    return best
```

## Hints

1. The best rectangle is as tall as one of the bars. For each bar, stretch it left and right until a shorter bar stops it.
2. Keep a stack of bar indexes with rising heights. A shorter bar ends every taller bar on top: that is its right edge. The bar under it on the stack is its left edge.
3. Add a 0 at the end so every bar gets popped. When bar `j` is popped at `i`, its width is `i - stack[-1] - 1`, or `i` if the stack is now empty.
