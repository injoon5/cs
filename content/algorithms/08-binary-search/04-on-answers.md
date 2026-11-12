---
id: on-answers
title: Searching for the answer
---

What is the whole-number square root of 30, rounded down?

```diagram
array k [0, 1, 2, 3, 4, 5, 6, 7]
pointer answer 5
shade 6..7
```

There is no list to search, but there is a range of candidates, and a yes-or-no test: "is `k * k` bigger than 30?" It says no for 0 through 5 and yes from 6 on. Once a square is too big, every bigger square is too.

The answer is one before the first yes: 5.

---

That shape is all binary search needs. A test that flips from no to yes once, and stays yes, is called monotone. With one, you can search a range of possible answers instead of a list.

```python
def int_sqrt(n):
    lo, hi = 0, n + 1      # (n + 1) ** 2 > n
    while lo < hi:
        mid = (lo + hi) // 2
        if mid * mid > n:
            hi = mid
        else:
            lo = mid + 1
    return lo - 1

print(int_sqrt(30), int_sqrt(36), int_sqrt(10**12))
```

For `10**12` that is a trillion candidates, settled in about 40 tests.

---

```python trace stop=20
n = 20
lo, hi = 0, n + 1
while lo < hi:
    mid = (lo + hi) // 2
    if mid * mid > n:
        hi = mid
    else:
        lo = mid + 1
print(lo - 1)
```

The loop has just ended. What is `lo`?

- [ ] 4
- [x] 5
- [ ] 10

---

A harder one. Packages with these weights must ship in order within 3 days. Each day the ship carries packages from the front of the line until the next one would go over its capacity. What is the smallest capacity that works?

```diagram
array weights [3, 2, 2, 4, 1, 4]
shade 0..1 4..5
```

With capacity 6, day one takes 3 and 2. The next 2 would make 7, so it waits. Day two takes 2 and 4, day three takes 1 and 4. Three days, shown as the three runs above, so 6 works.

---

Checking one capacity is a simple pass over the weights. What does this print?

```python predict
def days_needed(weights, cap):
    days, load = 1, 0
    for w in weights:
        if load + w > cap:
            days += 1
            load = 0
        load += w
    return days

weights = [3, 2, 2, 4, 1, 4]
for cap in [5, 6, 16]:
    print(cap, days_needed(weights, cap))
```

---

A bigger ship never needs more days, so "does it fit in 3 days?" is monotone in the capacity. The capacity is at least the heaviest package, 4, and at most the total, 16, which ships everything in one day.

Run this to watch the search over capacities 4 to 16.

```python
import viz

weights = [3, 2, 2, 4, 1, 4]
caps = list(range(4, 17))

def days_needed(cap):
    days, load = 1, 0
    for w in weights:
        if load + w > cap:
            days, load = days + 1, 0
        load += w
    return days

lo, hi = 4, 16
while lo < hi:
    mid = (lo + hi) // 2
    d = days_needed(mid)
    p = {"lo": lo - 4, "mid": mid - 4, "hi": hi - 4}
    ok = "fits" if d <= 3 else "too slow"
    msg = f"capacity {mid}: {d} days, {ok}"
    viz.array(caps, pointers=p, range=(lo - 4, hi - 4), note=msg)
    if d <= 3:
        hi = mid
    else:
        lo = mid + 1
viz.array(caps, pointers={"answer": lo - 4}, highlight=lo - 4, note=f"smallest capacity: {lo}")
```

---

Which of these tests is monotone over `k`, so you can binary search for the smallest `k` that passes?

- [x] Eating `k` bananas an hour finishes every pile within 8 hours
- [ ] `k` is a prime number
- [ ] `k` is the closest number to the average of a list

---

`n` packages, total weight `S`. The search tries about log S capacities and checks each with one pass over the packages. The whole search takes

- [ ] O(n + log S)
- [x] O(n log S)
- [ ] O(S · n)

---

[Integer square root](exercises/int-sqrt.md)

[Ship within days](exercises/ship-capacity.md)

[Eating speed](exercises/eating-speed.md)

[Kth in a multiplication table](exercises/kth-in-table.md)
