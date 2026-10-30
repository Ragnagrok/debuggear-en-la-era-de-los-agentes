#!/usr/bin/env bash
# Rules 7 and 9: the environment runs the checks, and the work isn't done until
# they pass. Meant to run when the agent tries to finish (a Stop hook); exit 2
# and the reasons on stderr send it back to work.
#
#   9. The fix is verified both ways: the reproduction fails on the last commit
#      (without the fix) and passes on the working tree (with it).
#   9. The reproduction stays, as a regression test that the suite actually ran.
#   7. "The tests pass" is checked, not reported: the suite has to run, more
#      than zero tests, none failing.
#
# Usage, from the project's directory: lab/done-gate.sh <reproduce-command> <regression-test-name>
set -uo pipefail
reproduce=$1
regression=$2
problems=()

# With the fix (the working tree).
"$reproduce" >/dev/null 2>&1 || problems+=("the reproduction still fails with your change")

# Without the fix (a clean checkout of the last commit, in a separate worktree).
before=$(mktemp -d)
git worktree add -q --detach "$before/tree" HEAD
if (cd "$before/tree" && "$reproduce" >/dev/null 2>&1); then
  problems+=("the reproduction passes without your change too: it doesn't reproduce anything")
fi
git worktree remove --force "$before/tree"
rm -rf "$before"

# The whole suite, run here, read here.
output=$(node --test --test-reporter=tap 2>&1)
tests=$(sed -n 's/^# tests \([0-9]*\)$/\1/p' <<<"$output")
fails=$(sed -n 's/^# fail \([0-9]*\)$/\1/p' <<<"$output")
(( ${tests:-0} > 0 )) || problems+=("no tests ran")
(( ${fails:-1} == 0 )) || problems+=("${fails:-?} tests failed")
grep -qE "^ok [0-9]+ - $regression\$" <<<"$output" ||
  problems+=("no passing test named \"$regression\": keep the reproduction as a regression test")

if (( ${#problems[@]} )); then
  printf 'not done:\n' >&2
  printf '  - %s\n' "${problems[@]}" >&2
  exit 2
fi
echo "done: the reproduction fails without the change and passes with it; $tests tests ran, none failed"
