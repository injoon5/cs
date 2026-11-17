## How do you write a number in binary by hand?
Divide by 2 over and over. Each `n % 2` is the next bit from the right, and `n //= 2` drops it. Reverse the bits at the end. O(log n).

## How many bits does a positive integer n need?
`n.bit_length()`, which is about log₂ n: exactly ⌊log₂ n⌋ + 1. k bits hold 2ᵏ values, 0 to 2ᵏ - 1.

## What do `x << k` and `x >> k` compute?
`x * 2**k` and `x // 2**k`. On negative numbers `>>` rounds down, so `-7 >> 1` is -4.

## How do you read, set, clear and toggle bit k of x?
Read `x >> k & 1`, set `x | (1 << k)`, clear `x & ~(1 << k)`, toggle `x ^ (1 << k)`.

## How does 8-bit two's complement store a negative number?
The top bit is worth -128 instead of +128, so a byte holds -128 to 127. To negate, flip every bit and add 1: -5 is `1111 1011`.

## How do bit operations treat negative Python ints?
As if the sign bit repeated forever to the left. So `~x` is `-x - 1`, and `x & 0xFF` shows the low byte: `-5 & 0xFF` is 251, `1111 1011`. `bin(-5)` only prints `-0b101`.

## What does `x & (x - 1)` do?
Clears the lowest 1 bit of `x`. Subtracting 1 turns that bit to 0 and the zeros below it to 1, and the `&` drops them all.

## What does `x & -x` give?
Only the lowest 1 bit of `x`, for example 4 for 12 (`1100`).

## How do you test whether n is a power of two?
`n > 0 and n & (n - 1) == 0`. A power of two has exactly one 1 bit.

## How does Kernighan's method count the 1 bits of x, and what does it cost?
Repeat `x &= x - 1` until `x` is 0 and count the passes. One pass per 1 bit, not per bit. Python has `x.bit_count()`.

## Which xor facts find the one value that appears an odd number of times?
`x ^ x == 0`, `x ^ 0 == x`, and order doesn't matter. Xor everything; the pairs cancel and the odd one is left. O(n) time, O(1) space.

## How do you loop over every subset of n items with bitmasks?
`for mask in range(1 << n)`, where bit i set means item i is in. 2ⁿ subsets, O(2ⁿ · n) to list them all.

## How do you loop over every subset of a mask?
Start at `sub = mask` and step with `sub = (sub - 1) & mask` until after `sub` is 0. Each step gives the next smaller subset.

## Why is `0.1 + 0.2 != 0.3`, and how should you compare floats?
0.1 has no exact binary form, so each float is rounded to 53 significant bits. Compare with `math.isclose`, adding `abs_tol` near zero.

## Above what size do floats lose whole numbers?
2⁵³. A float has 53 significant bits, so `float(2**53 + 1)` is `2**53`. Use `//` on big ints, not `/`.

## When do you use `Decimal` or `Fraction` instead of floats?
When the answer must be exact. `Decimal` for money, built from strings like `Decimal("0.10")`. `Fraction` for exact ratios. Or keep money as whole cents in ints.
