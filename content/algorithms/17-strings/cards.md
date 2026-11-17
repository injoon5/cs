## Why can building a string with `s += ch` in a loop be slow?
Strings can't change, so each `+` makes a new string and copies the old one into it. n appends copy about n²/2 characters: O(n²).

## How do you build a long string efficiently?
Collect the pieces in a list and call `"".join(parts)` once. It sizes the result first and copies each piece once: O(total length).

## How do you change characters of a string in place?
Convert it with `list(s)`, edit the list, then `"".join(chars)`. The two conversions are O(n) once; each edit is O(1).

## What does slicing a string cost?
`s[i:j]` copies j - i characters into a new string. Recursing on `s[1:]` turns an O(n) walk into O(n²).

## What does naive string matching cost, and what input is its worst case?
O(n·m): every one of the n - m + 1 shifts can compare up to m characters. A text of all `a` with the pattern `aa…ab` hits it.

## What does `text.count(pat)` count?
Matches that don't overlap. `"abababa".count("aba")` is 2, though `aba` starts at 0, 2 and 4.

## How does a rolling hash slide its window one place right?
`h = ((h - ord(out) * B^(m-1)) * B + ord(new)) % P`: remove the leaving character's term, shift by the base, add the new character. O(1) per step.

## Why does Rabin-Karp compare characters when the hashes match?
Different strings can have the same hash. A matching hash is only a hint; comparing the characters rules out a collision.

## What does Rabin-Karp cost?
O(n + m) expected, plus O(m) for each window whose hash matches. If the pattern really occurs at almost every shift, that's O(n·m).

## How do prefix hashes give any substring's hash in O(1)?
Store `h[i]`, the hash of `s[:i]`, and `pw[k] = B^k % P`. Then `hash(s[i:j]) = (h[j] - h[i] * pw[j - i]) % P`.

## Why use a modulus like `2**61 - 1` when substring hashes aren't checked?
Collisions grow with the number of pairs, about n²/2P. With P near 10⁹, 100,000 hashes already expect about 5 collisions; with P near 2⁶¹, almost none.

## How do you find the longest repeated substring with hashing?
If length L repeats, every shorter length does too. Binary search on L, and check each length by putting every window's hash in a set: O(n log n).

## What does the prefix function `pi[i]` hold?
The length of the longest proper prefix of `s[:i + 1]` that is also its suffix, its longest border.

## Why does computing the prefix function take O(n) time?
`k` rises by at most 1 per character, and each fallback `k = pi[k - 1]` lowers it. So there are at most n - 1 fallbacks in total.

## How does KMP search a text, and what does it cost?
It keeps `k`, how many pattern characters match so far. On a mismatch it falls back with `k = pi[k - 1]` instead of moving back in the text. O(n + m) time, O(m) space.

## How do you get the smallest period of a string from its prefix function?
`p = n - pi[-1]`. The string is a shorter string repeated when p < n and n % p == 0.
