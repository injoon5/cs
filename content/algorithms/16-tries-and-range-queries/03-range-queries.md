---
id: range-queries-with-updates
title: Range sums with updates
---

Prefix sums answer the sum of `nums[l..r]` with one subtraction. That works as long as `nums` never changes. Now set `nums[1]` from -1 to 5.

```diagram
array nums [3, 5, 4, 1, 5]
highlight 1
array prefix [0, 3, 2, 6, 7, 12]
shade 2..5
```

Every running total from `prefix[2]` on includes `nums[1]`, so every one of them is now 6 too small.

---

An update has to fix each prefix after it. What does this print?

```python predict
nums = [3, -1, 4, 1, 5]
prefix = [0]
for x in nums:
    prefix.append(prefix[-1] + x)

i, x = 1, 5
delta = x - nums[i]
nums[i] = x
for j in range(i + 1, len(prefix)):
    prefix[j] += delta
print(prefix)
print(prefix[4] - prefix[1])
```

Changing `nums[0]` would touch every entry but the first. An update costs O(n).

---

So there are two plain choices for n numbers:

- Keep only `nums`. An update is one assignment, O(1). A sum adds up the range, O(n).
- Keep prefix sums. A sum is one subtraction, O(1). An update fixes the prefixes, O(n).

A program gets q requests, half updates and half sums, in random order. Which choice is faster?

- [ ] Prefix sums, since sums are O(1)
- [ ] The plain list, since updates are O(1)
- [x] Neither: each pays O(n) on half the requests, O(n × q) in total

Each choice makes one operation free and the other slow. The aim is to make both cheap.

---

A middle ground: cut `nums` into blocks of `b` numbers, and keep the sum of each block.

```diagram
array nums [3, -1, 4, 1, 5, 9, 2, 6, 5]
pointer l 1
pointer r 7
shade 3..5
array blocks [6, 15, 13]
highlight 1
```

The sum of `nums[1..7]` takes the loose numbers at each end one at a time and the whole block in the middle from `blocks`: `-1 + 4`, then `15`, then `2 + 6`, which is 26.

An update changes one number and the sum of its block, `blocks[i // b]`. Nothing else holds that number.

---

```python
nums = [3, -1, 4, 1, 5, 9, 2, 6, 5]
b = 3
blocks = [sum(nums[i:i + b]) for i in range(0, len(nums), b)]


def update(i, x):
    blocks[i // b] += x - nums[i]
    nums[i] = x


def query(l, r):
    total = 0
    while l <= r:
        if l % b == 0 and l + b - 1 <= r:
            total += blocks[l // b]
            l += b
        else:
            total += nums[l]
            l += 1
    return total


print(blocks, query(1, 7))
update(4, 0)
print(blocks, query(1, 7))
```

`l` starts a whole block when it is a multiple of `b` and the block ends by `r`. Then it jumps the whole block at once.

---

Here is the query loop on its own, for `nums[1..7]`.

```python trace stop=18
nums = [3, -1, 4, 1, 5, 9, 2, 6, 5]
b = 3
blocks = [6, 15, 13]
l, r = 1, 7
total = 0
while l <= r:
    if l % b == 0 and l + b - 1 <= r:
        total += blocks[l // b]
        l += b
    else:
        total += nums[l]
        l += 1
print(total)
```

The loop has just taken the whole block `blocks[1]`. What are `total` and `l` now?

- [ ] `total` is 18, `l` is 4
- [x] `total` is 18, `l` is 6
- [ ] `total` is 15, `l` is 6

---

With n numbers in blocks of b, a sum takes at most b - 1 loose numbers at each end and at most n / b blocks. With b = √n, a sum costs

- [ ] O(1)
- [x] O(√n), and an update still costs O(1)
- [ ] O(log n)

For a million numbers that is at most about 3,000 steps per sum instead of a million. Better, but there is more to gain.

---

Blocks of size √n are one level. Add more levels: sums of pairs, then sums of pairs of pairs, until one sum covers everything.

```diagram
tree
node a "0..7"
node b "0..3"
node c "4..7"
node d "0..1"
node e "2..3"
node f "4..5"
node g "6..7"
a -> b c
b -> d e
c -> f g
d -> 0 1
e -> 2 3
f -> 4 5
g -> 6 7
highlight 1 e f 6
```

The highlighted pieces cover `nums[1..6]`. Each level halves the piece size, so there are about log₂ n levels. As the next lesson shows, a range never needs more than two pieces from one level.

---

On each level, every number is in exactly one piece. When one number changes, an update must fix

- [ ] one piece, O(1)
- [x] one piece per level, O(log n)
- [ ] every piece, O(n)

Both operations would then cost O(log n). That tree of ranges is a segment tree.

---

[Range sums in blocks](exercises/block-range-sums.md)
