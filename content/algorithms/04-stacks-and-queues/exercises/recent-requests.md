---
id: recent-requests
title: Recent requests
level: warmup
---

`times` lists request times in milliseconds, in increasing order. For each request, count the requests in the last 3000 ms, itself included: those with a time in `[t - 3000, t]`. Return the counts as a list. For `[1, 100, 3001, 3002]` the answer is `[1, 2, 3, 3]`. At 3002, the request at 1 is too old.

```python starter
def recent_requests(times):
    pass
```

```tests
recent_requests([1, 100, 3001, 3002]) == [1, 2, 3, 3]
recent_requests([]) == []
recent_requests([5]) == [1]
recent_requests([0, 3000]) == [1, 2]
recent_requests([0, 3001]) == [1, 1]
recent_requests([7, 7, 7]) == [1, 2, 3]
recent_requests([0, 1000, 2000, 3000, 4000, 5000]) == [1, 2, 3, 4, 4, 4]
recent_requests([0, 10000, 20000]) == [1, 1, 1]
recent_requests(list(range(0, 100000, 1000)))[-1] == 4
```

```python solution
from collections import deque

def recent_requests(times):
    window = deque()
    counts = []
    for t in times:
        window.append(t)
        while window[0] < t - 3000:
            window.popleft()
        counts.append(len(window))
    return counts
```

## Hints

1. Requests that are too old for one time are too old for every later time.
2. Keep the recent times in a queue. Add each new time at the back and drop old ones from the front.
3. After `window.append(t)`, `popleft` while `window[0] < t - 3000`. Then `len(window)` is the count.
