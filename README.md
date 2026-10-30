# Debugging in the Age of Agents

Proof of concept for the article *Debugging in the Age of Agents*
([English](https://blog.ragnagrok.com/en/2026-10-28-debuggear-en-la-era-de-los-agentes) ·
[español](https://blog.ragnagrok.com/es/2026-10-28-debuggear-en-la-era-de-los-agentes)):
David Agans' nine debugging rules, read not as advice for the person debugging but as the
blueprint of the lab an agent works in. Here the lab is a handful of scripts, and a demo walks a
real bug through them.

The article's question in one line: not "do I follow the rules?", but **"how do I set up the
environment so that the agent follows them, even when it forgets?"**

## The demo

`demo/setup.sh` builds a small gift card library with a git history of twelve commits. At `v0.1`,
codes typed in lowercase with spaces around them were found. Five commits later, a commit titled
`tidy: extract normalizeCode()` also dropped the `toUpperCase()`. The two existing tests don't
notice: the suite is green and the bug is there.

`check.sh` walks that bug through the lab and checks what each step says:

```
== rule 2: make it fail, and print what was seen (rule 3)
ok   the bug reproduces on the last commit
       typed " abc-123 ", found: null
ok   ...while the existing suite is green: "the tests pass" says nothing about it
== rule 4: divide and conquer
ok   bisect finds the commit that broke it
       first bad commit: 5d854e7 tidy: extract normalizeCode()
== rule 9: if you didn't fix it, it isn't fixed
ok   the gate won't let the work end with nothing changed
== rule 5: one change at a time
ok   the "while I was at it" change does make the bug go away...
ok   ...but it isn't one change, so it says nothing about the cause
       not one change:
         - 11 lines changed under src/ (at most 4)
         - README.md changed outside src/ and test/: that's a second change
ok   the one-line fix is one change
== rules 7 and 9, at the end
ok   the gate wants the reproduction kept as a test
ok   with the test, the gate lets the work end
       done: the reproduction fails without the change and passes with it; 3 tests ran, none failed
ok   after the commit, the same gate with no change left refuses: nothing reproduces anything
== rule 6: the log is designed, not just appended to
ok   it keeps the last ten entries
ok   and moves the older ones to the archive
```

(Abridged; commit hashes change on every run.)

## The nine rules, in this lab

The article sorts each rule by how it reaches the agent: you **ask** for it (instructions), you
**give** it (a tool that makes the right path easy), or you **enforce** it (the environment does it,
whatever the agent decides). Only the last two can live in a repository.

| Rule | Here | How |
|---|---|---|
| 1. Understand the system | `lab/LAB.md`, a template for what the agent can't see from the code | Given. Not mechanical: someone has to write it. |
| 2. Make it fail | `demo/reproduce.sh`: the bug report as a yes-or-no question, one per bug | Given; `done-gate.sh` refuses to finish without one that actually reproduces |
| 3. Quit thinking and look | The reproduction prints what it saw (`found: null`), not just pass or fail | Given, partly. Logs, a read-only database and a browser are outside a repository. |
| 4. Divide and conquer | `lab/bisect.sh`: `git bisect run` with the reproduction as the oracle, copied outside the history first | Given |
| 5. Change one thing at a time | `lab/try.sh` (a worktree and a branch per hypothesis) and `lab/one-change.sh` (refuses a diff with more than one small change to the code) | Given; can be enforced |
| 6. Keep an audit trail | `lab/log.sh`: one entry per attempt, and a cap that moves old entries to an archive | Enforced with a session-start hook that prints it (`lab/claude-settings.example.json`) |
| 7. Check the plug | `lab/done-gate.sh` runs the suite itself and reads the result: zero tests or any failure is not "the tests pass" | Enforced |
| 8. Get a fresh view | Not here. A read-only reviewer is a matter of the agent tool's permissions, not of scripts. | — |
| 9. If you didn't fix it, it ain't fixed | `lab/done-gate.sh`: the reproduction must fail on the last commit and pass on the working tree, and stay as a passing regression test | Enforced with a stop hook (`lab/claude-settings.example.json`): exit 2 sends the agent back to work |

The demo's bug is also the article's point about rule 4: the culprit is a commit that mixed a
tidy-up with a change of behaviour, which is exactly what Kent Beck's *Tidy First?* asks you not
to do.

## What's here

| Path | What it is |
|---|---|
| `lab/` | The reusable part: `bisect.sh`, `try.sh`, `one-change.sh`, `log.sh`, `done-gate.sh`, `LAB.md` and an example of Claude Code hooks. |
| `demo/setup.sh` | Builds the demo project and its history. |
| `demo/reproduce.sh` | The reproduction for the demo's bug. |
| `demo/fix.patch`, `demo/mixed.patch` | The one-line fix, and a "while I was at it" change that also fixes it. |
| `demo/regression.test.js` | The reproduction, kept as a test. |
| `check.sh` | The whole walk-through. |

## Running it

With Node 24 and git:

```sh
./check.sh
```

To use the lab in a project, copy `lab/` into it, write `lab/reproduce.sh` for the bug at hand, and
merge `lab/claude-settings.example.json` into `.claude/settings.json`. The scripts expect a Node
project with tests under `test/` and code under `src/` (`LAB_CODE` changes the latter); the gate
runs `node --test`, which is the line to change for another stack.

## What this proof of concept doesn't cover

- **No agent runs here.** The walk-through plays the agent's moves by hand. The hooks file is an
  example of how the gate and the log would be wired into Claude Code, not something this
  repository tests against a live agent.
- **A stop hook that always blocks can loop.** If the agent can't make the gate pass, a hook that
  refuses every time never lets it stop. A real setup needs a way out, and someone reading why.
- **`one-change.sh` counts lines, not ideas.** It catches a fix that drags a rename and a README
  along; it can't tell two ideas packed into three lines.
- **Rules 1, 3 and 8 mostly live outside a repository:** documentation, real data, a browser,
  and a second reviewer with read-only permissions.
- **Every enforced rule will eventually fire when it shouldn't**, as the article says, and someone
  has to maintain it. The ones worth keeping come from a concrete stumble.

## Further reading

- Agans (2002), *Debugging: The 9 Indispensable Rules for Finding Even the Most Elusive Software and Hardware Problems*. [debuggingrules.com](https://debuggingrules.com/)
- Zeller (2005), *Why Programs Fail*, and its open continuation, [*The Debugging Book*](https://www.debuggingbook.org/).
- Anthropic (2025), [*Effective harnesses for long-running agents*](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).
- Anthropic, [*Best practices for Claude Code*](https://code.claude.com/docs/en/best-practices).
- Git, [git-bisect](https://git-scm.com/docs/git-bisect).
