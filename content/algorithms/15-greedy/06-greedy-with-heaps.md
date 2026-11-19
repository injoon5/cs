---
id: greedy-with-heaps
title: Greedy with a heap
---

Join ropes of lengths 4, 3, 2 and 6 into one. Each join ties two ropes together and costs the sum of their lengths. What is the cheapest way?

Joining the longest first costs 6 + 4 = 10, then 10 + 3 = 13, then 13 + 2 = 15: 38 in all. The greedy rule goes the other way: always join the two shortest ropes. The joined rope goes back in the pile, so the pile keeps changing, and a heap hands over the two shortest each time. What does this print?

```python predict
import heapq

ropes = [4, 3, 2, 6]
heapq.heapify(ropes)
total = 0
while len(ropes) > 1:
    a = heapq.heappop(ropes)
    b = heapq.heappop(ropes)
    total += a + b
    heapq.heappush(ropes, a + b)
    print(a, "+", b, "costs", a + b)
print(total)
```

---

Draw the joins as a tree. Each join is a node, and its two children are the ropes it tied together.

```diagram
tree
15 -> 6 9
9 -> 4 5
5 -> 2 3
highlight 2 3
```

A rope's length is paid once for every join above it, which is its depth in the tree. The 2 and the 3 sit three joins deep: 2·3 + 3·3 + 4·2 + 6·1 = 29. The total is each length times its depth, so short ropes belong deep and long ropes near the top.

---

The exchange argument again. In some join tree, a rope of length 6 sits deeper than a rope of length 2. Swap the two. The total

- [ ] stays the same, since the same ropes are joined
- [x] goes down by 4 for each level between them
- [ ] goes up, since 6 is now joined earlier

So some best tree has the two shortest ropes side by side at the bottom, joined first. Joining them is safe, and then the joined rope is just another rope in a smaller problem.

---

Each round pops two ropes and pushes one, so n ropes take n - 1 rounds. With a heap, joining them all costs

- [ ] O(n) time
- [x] O(n log n) time
- [ ] O(n²) time

A sorted list would need O(n) to insert each joined rope in its place, O(n²) in all.

---

This is Huffman coding, which compresses text. Each letter gets a string of bits, frequent letters get short ones, and no code is the start of another, so a string of bits reads back only one way.

Build the tree with the rope rule, using how often each letter appears as its length. A letter's code is its path from the root: 0 for each step left, 1 for each step right.

```diagram
tree
9 -> a 4
4 -> b 2
2 -> c d
node a "a 5"
node b "b 2"
node c "c 1"
node d "d 1"
```

In a text with five `a`, two `b`, one `c` and one `d`, the codes are `a` 0, `b` 10, `c` 110 and `d` 111. The text takes 5·1 + 2·2 + 1·3 + 1·3 = 15 bits, the same sum the ropes give: 2 + 4 + 9.

---

Some greedy algorithms keep the best set found so far, and when a new item doesn't fit, they swap out the worst item in the set. A heap finds that item quickly.

Each course is `(days, deadline)`: it takes that many days, one course at a time from day 0, and has to be done by its deadline. Take as many courses as you can.

```diagram
array days [5, 4, 2]
array deadline [5, 6, 6]
```

Go through the courses by deadline and take each one. The 5-day course fits by day 5. The 4-day course brings the total to 9 days, past its deadline of 6.

---

One course has to go. Which one?

- [ ] The one just added, since it doesn't fit
- [x] The longest one taken so far, here the 5-day course
- [ ] The one with the earliest deadline

Dropping any one course leaves the same count. Dropping the longest frees the most days for the courses still to come, and the rest still meet their deadlines. A max-heap of the days taken finds the longest in O(log n). Here the 2-day course fits next, and the answer is 2.

---

What do the rope joins and the course drops have in common?

- [ ] Both sort once, then never look at the order again
- [x] Each step needs the smallest or largest of a set that keeps changing
- [ ] Both try every choice and keep the best, as DP does

---

[Huffman code lengths](exercises/huffman-code-lengths.md)

[Courses before their deadlines](exercises/courses-by-deadline.md)
