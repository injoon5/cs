---
id: merge-accounts
title: Merge accounts
level: stretch
---

Each account is a list: a name, then one or more emails. Two accounts belong to the same person when they share an email, and so do accounts linked through a chain of shared emails. Two different people can have the same name.

Merge the accounts of each person into one list: the name, then all of that person's emails sorted, each once. Return the merged accounts sorted.

In `[["Ana", "a@x", "a@y"], ["Bo", "b@x"], ["Ana", "a@z", "a@y"], ["Ana", "ana@q"]]`, the first and third accounts share `a@y`. The last Ana shares nothing, so she is someone else. The answer is `[["Ana", "a@x", "a@y", "a@z"], ["Ana", "ana@q"], ["Bo", "b@x"]]`.

```python starter
def merge_accounts(accounts):
    pass
```

```tests
merge_accounts([["Ana", "a@x", "a@y"], ["Bo", "b@x"], ["Ana", "a@z", "a@y"], ["Ana", "ana@q"]]) == [["Ana", "a@x", "a@y", "a@z"], ["Ana", "ana@q"], ["Bo", "b@x"]]
merge_accounts([]) == []
merge_accounts([["Cy", "c@x"]]) == [["Cy", "c@x"]]
merge_accounts([["Cy", "c@x", "c@x"]]) == [["Cy", "c@x"]]
merge_accounts([["Cy", "c@x"], ["Cy", "c@x"]]) == [["Cy", "c@x"]]
merge_accounts([["A", "1"], ["A", "2"], ["A", "3"], ["A", "3", "1"]]) == [["A", "1", "3"], ["A", "2"]]
merge_accounts([["D", "d1", "d2"], ["D", "d3", "d4"], ["D", "d5", "d1"], ["D", "d4", "d5"]]) == [["D", "d1", "d2", "d3", "d4", "d5"]]
len(merge_accounts([["P", f"e{i}", f"e{i + 1}"] for i in range(20000)])[0]) == 20002
len(merge_accounts([["P", f"e{i * 7 % 20000 + 1}", f"e{i * 7 % 20000}"] for i in range(20000)])[0]) == 20002
len(merge_accounts([["P", f"e{i}"] for i in range(20000)])) == 20000
```

```python tests
import random


def slow(accounts):
    groups = [[a[0], set(a[1:])] for a in accounts]
    merged = True
    while merged:
        merged = False
        for i in range(len(groups)):
            for j in range(i + 1, len(groups)):
                if groups[i][1] & groups[j][1]:
                    groups[i][1] |= groups[j][1]
                    del groups[j]
                    merged = True
                    break
            if merged:
                break
    return sorted([name] + sorted(emails) for name, emails in groups)


for _ in range(300):
    accounts = []
    for _ in range(random.randint(0, 6)):
        owner = random.choice("AB")
        emails = random.sample([f"{owner}{k}" for k in range(5)], random.randint(1, 3))
        accounts.append([owner] + emails)
    assert merge_accounts(accounts) == slow(accounts), accounts
```

```python solution
def merge_accounts(accounts):
    parent = list(range(len(accounts)))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    owner = {}
    for i, account in enumerate(accounts):
        for email in account[1:]:
            if email in owner:
                parent[find(i)] = find(owner[email])
            else:
                owner[email] = i

    emails = {}
    for email, i in owner.items():
        emails.setdefault(find(i), []).append(email)
    return sorted([accounts[root][0]] + sorted(group) for root, group in emails.items())
```

## Hints

1. The items to group are the accounts. An email that shows up in two accounts joins them.
2. Keep a dict from each email to the first account that had it. When a later account has the same email, union the two accounts.
3. Afterwards, file every email under `find` of its first account. Each group gives one merged account: the name of its root account, then the emails sorted. Sort the list of merged accounts at the end.
