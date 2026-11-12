---
id: price-span
title: Price span
level: core
---

`prices` holds one price per day. A day's span is the number of days in a row, ending with that day, whose price is at most that day's price. Return the span of every day. For `[100, 80, 60, 70, 60, 75, 85]` the answer is `[1, 1, 1, 2, 1, 4, 6]`. On the day of 75, the four days `60, 70, 60, 75` are all at most 75.

```python starter
def price_span(prices):
    pass
```

```tests
price_span([100, 80, 60, 70, 60, 75, 85]) == [1, 1, 1, 2, 1, 4, 6]
price_span([]) == []
price_span([10]) == [1]
price_span([1, 2, 3, 4]) == [1, 2, 3, 4]
price_span([4, 3, 2, 1]) == [1, 1, 1, 1]
price_span([5, 5, 5]) == [1, 2, 3]
price_span([3, 1, 3]) == [1, 1, 3]
price_span([-2, -5, -1]) == [1, 1, 3]
price_span(list(range(1000)))[-1] == 1000
```

```python solution
def price_span(prices):
    spans = []
    stack = []
    for i, p in enumerate(prices):
        while stack and prices[stack[-1]] <= p:
            stack.pop()
        start = stack[-1] if stack else -1
        spans.append(i - start)
        stack.append(i)
    return spans
```

## Hints

1. The span stops at the nearest earlier day with a higher price.
2. Look for the previous bigger price with a stack, scanning left to right. Pop every day whose price is at most today's.
3. After popping, the top of the stack is the previous higher day, or there is none (use -1). The span is `i - top`. Then push `i`.
