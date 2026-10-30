# The lab

Read this before touching a bug. It's the part of the system you can't see from the repository.

## What the system is for

<!-- What it should do, not what the code does. Specs, invariants, links. -->

## What you can look at

<!-- Rule 3: logs, a read-only copy of the database, a browser, real volumes. How to reach each. -->

## How to make it fail

<!-- Rule 2: the reproduction command for the bug at hand, and how to get test data in one line. -->

## How this lab works

- Before any fix, a reproduction that fails: `lab/reproduce.sh` (yours to write, one per bug).
- To find the commit that broke it: `lab/bisect.sh <known-good-ref> lab/reproduce.sh`.
- One hypothesis per worktree: `lab/try.sh <name>`. One change per hypothesis: `lab/one-change.sh`.
- Every attempt goes in the log: `lab/log.sh "<hypothesis>" "<what you did>" "<what you saw>"`.
- You're done when `lab/done-gate.sh` says so, not before.
