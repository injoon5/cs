---
id: merging-intervals
title: Merging and covering
---

A calendar has busy blocks that overlap. Merge them, so each stretch of busy time shows up once. Blocks that only touch merge too: (1, 3) and (3, 4) cover 1 to 4 with no gap.

```diagram
grid busy
col-labels [0, 1, 2, 3, 4, 5, 6, 7, 8]
row-labels ["(0, 2)", "(1, 3)", "(3, 4)", "(5, 7)", "(6, 9)"]
row [■, ■, , , , , , , ]
row [, ■, ■, , , , , , ]
row [, , , ■, , , , , ]
row [, , , , , ■, ■, , ]
row [, , , , , , ■, ■, ■]

grid merged
col-labels [0, 1, 2, 3, 4, 5, 6, 7, 8]
row-labels ["(0, 4)", "(5, 9)"]
row [■, ■, ■, ■, , , , , ]
row [, , , , , ■, ■, ■, ■]
```

Sorted by start, the blocks that merge sit next to each other. So sort, then walk once: each interval either reaches the last merged block, or starts a new one.

---

`sorted` on tuples sorts by start, then by end. The merged blocks are lists, so the last one's end can grow in place.

```python trace stop=12
intervals = [(1, 3), (0, 2), (5, 7), (6, 9), (3, 4)]
merged = []
for start, end in sorted(intervals):
    if merged and start <= merged[-1][1]:
        merged[-1][1] = max(merged[-1][1], end)
    else:
        merged.append([start, end])
print(merged)
```

The loop has just handled (3, 4). What is `merged`?

- [ ] `[[0, 3], [3, 4]]`
- [x] `[[0, 4]]`
- [ ] `[[0, 2], [1, 4]]`

---

Why `max(merged[-1][1], end)` and not just `end`?

- [ ] `end` can be smaller than `start`
- [x] An interval can sit inside the last block, like (2, 3) inside (1, 6), and then its end is smaller
- [ ] `max` keeps the blocks sorted by end

---

Each interval is compared only with the last merged block. Why can't it overlap an earlier block?

- [ ] Sorting by start also sorts the intervals by end
- [x] Earlier blocks end before the last block starts, and this interval starts no earlier than the last block
- [ ] Earlier blocks are removed once a new block starts

---

Now the list is already sorted, with no overlaps, and one new interval arrives. Sorting everything again would cost O(n log n). One pass is enough: copy the intervals that end before the new one starts, merge every interval that overlaps or touches it into it, then copy the rest.

```diagram
grid
col-labels [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
row-labels ["(1, 2)", "(3, 5)", "(6, 7)", "(8, 10)", "new (4, 7)"]
row [, ■, , , , , , , , ]
row [, , , ■, ■, , , , , ]
row [, , , , , , ■, , , ]
row [, , , , , , , , ■, ■]
row [, , , , ■, ■, ■, , , ]
highlight 4,4 4,5 4,6
```

What is the list after (4, 7) goes in?

- [ ] `[(1, 2), (3, 5), (4, 7), (6, 7), (8, 10)]`
- [x] `[(1, 2), (3, 7), (8, 10)]`
- [ ] `[(1, 2), (3, 10)]`

---

A different question about intervals: cover a range with as few of them as you can. Clips of a video are `(start, end)` pairs, and you want to show all of it, from 0 to 10, with the fewest clips.

```diagram
grid
col-labels [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
row-labels ["(0, 2)", "(1, 5)", "(2, 4)", "(4, 6)", "(5, 9)", "(8, 10)"]
row [■, ■, , , , , , , , ]
row [, ■, ■, ■, ■, , , , , ]
row [, , ■, ■, , , , , , ]
row [, , , , ■, ■, , , , ]
row [, , , , , ■, ■, ■, ■, ]
row [, , , , , , , , ■, ■]
highlight 0,0 0,1 1,1 1,2 1,3 1,4 4,5 4,6 4,7 4,8 5,8 5,9
```

Keep `reach`, how far is covered so far. Of the clips that start at or before `reach`, take the one that ends furthest. Any other of those clips ends no later, and leaves at least as much to cover. A clip that starts after `reach` would leave a gap.

---

The clips are sorted by start, so one index `i` walks them once. Each round scans the clips that start at or before `reach` and keeps the furthest end.

```python trace stop=34
clips = [(0, 2), (1, 5), (2, 4), (4, 6), (5, 9), (8, 10)]
goal = 10
count = reach = i = 0
while reach < goal:
    furthest = reach
    while i < len(clips) and clips[i][0] <= reach:
        furthest = max(furthest, clips[i][1])
        i += 1
    if furthest == reach:
        break
    count += 1
    reach = furthest
print(count, reach)
```

The scan from `reach = 5` has finished. What is `furthest`?

- [ ] 6
- [x] 9
- [ ] 10

If none of those clips gets past `reach`, there is a gap, and the loop stops short of the goal.

---

The jump game is the same problem in disguise. From index `i` of `nums` you can jump forward up to `nums[i]` places. That makes index `i` a clip from `i` to `i + nums[i]`, and getting to the last index is covering the range.

```diagram
array nums [3, 2, 1, 0, 4]
pointer i 3
highlight 3
```

Every jump from indexes 0, 1 and 2 lands at index 3 or before, and index 3 can't move. The furthest you can reach is 3, so the last index is out of reach.

---

The clips needed a sort, which made them O(n log n). How long does the jump game take on n numbers?

- [ ] O(n log n), for the same sort
- [x] O(n), since clip `i` starts at `i` and the clips come already sorted by start
- [ ] O(n²), since each index can jump to many others

---

[Merge intervals](exercises/merge-overlapping-intervals.md)

[Insert an interval](exercises/insert-interval.md)

[Can you reach the end](exercises/jump-game-reach.md)

[Fewest jumps](exercises/min-jumps-to-end.md)
