---
id: courses-by-deadline
title: Courses before their deadlines
level: stretch
---

Each course is a `(days, deadline)` pair of positive whole numbers. You take courses one at a time, starting on day 0, and a course that takes `days` days must be finished by day `deadline`. Return the most courses you can finish on time.

For `[(5, 5), (4, 6), (2, 6)]` the answer is 2: take the 4-day course and then the 2-day one, finishing on day 6.

```python starter
import heapq


def most_courses(courses):
    pass
```

```tests
most_courses([(5, 5), (4, 6), (2, 6)]) == 2
most_courses([]) == 0
most_courses([(3, 2)]) == 0
most_courses([(2, 2)]) == 1
most_courses([(1, 2), (2, 3)]) == 2
most_courses([(2, 2), (2, 3)]) == 1
most_courses([(1, 1), (1, 2), (1, 3)]) == 3
most_courses([(100, 200), (200, 1300), (1000, 1250), (2000, 3200)]) == 3
most_courses([(5, 5), (2, 6), (2, 7), (2, 8)]) == 3
most_courses([(7, 17), (3, 12), (10, 20), (9, 10), (5, 20), (10, 19), (4, 18)]) == 4
most_courses([(1, i) for i in range(1, 100001)]) == 100000
most_courses([(i % 7 + 1, 100000) for i in range(100000)]) == 46429
```

```python tests
import random
from itertools import combinations


def fits(chosen):
    t = 0
    for days, deadline in sorted(chosen, key=lambda c: c[1]):
        t += days
        if t > deadline:
            return False
    return True


def slow(courses):
    for k in range(len(courses), -1, -1):
        if any(fits(chosen) for chosen in combinations(courses, k)):
            return k


for _ in range(300):
    courses = [(random.randint(1, 6), random.randint(1, 15)) for _ in range(random.randint(0, 7))]
    assert most_courses(courses) == slow(courses), courses
```

```python solution
import heapq


def most_courses(courses):
    taken = []  # negated days, so the root is the longest course
    total = 0
    for days, deadline in sorted(courses, key=lambda c: c[1]):
        heapq.heappush(taken, -days)
        total += days
        if total > deadline:
            total += heapq.heappop(taken)
    return len(taken)
```

## Hints

1. A set of courses can be done on time exactly when doing them in order of deadline works. So go through the courses by deadline.
2. Take each course. If the total days now pass its deadline, one course has to go, and the count drops back to what it was.
3. Drop the longest course taken so far: it frees the most days for later. Keep a max-heap of days (push `-days`), and when `total > deadline`, pop it and subtract its days.
