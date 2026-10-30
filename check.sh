#!/usr/bin/env bash
# Builds the demo project in a temporary directory and walks a bug through the
# lab, checking at each step that the lab says what it should.
set -uo pipefail
cd "$(dirname "$0")"
here=$PWD
lab=$here/lab
reproduce=$here/demo/reproduce.sh
regression="finds a card typed in lowercase with spaces around"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

# step <description> <expected exit code> <text the output must contain> <command...>
step() {
  local what=$1 code=$2 text=$3 output status
  shift 3
  output=$("$@" 2>&1)
  status=$?
  if [[ $status == "$code" ]] && grep -qF -- "$text" <<<"$output"; then
    echo "ok   $what"
    sed 's/^/       /' <<<"$output"
  else
    echo "FAIL $what (exit $status, expected $code and \"$text\")"
    sed 's/^/       /' <<<"$output"
    failures=1
  fi
}

"$here/demo/setup.sh" "$tmp/project"
cd "$tmp/project"

echo "== rule 2: make it fail, and print what was seen (rule 3)"
step "the bug reproduces on the last commit" 1 'found: null' "$reproduce"
step "...while the existing suite is green: \"the tests pass\" says nothing about it" 0 "# fail 0" \
  bash -c "node --test --test-reporter=tap | grep -E '^# (tests|fail) '"

echo "== rule 4: divide and conquer"
step "bisect finds the commit that broke it" 0 "tidy: extract normalizeCode()" \
  "$lab/bisect.sh" v0.1 "$reproduce"
step "...and leaves the repository where it was" 0 "Release 0.2.0" git log -1 --format=%s

echo "== rule 6: keep an audit trail"
step "an attempt goes in the log" 0 "" "$lab/log.sh" "the tidy-up dropped toUpperCase" \
  "bisect from v0.1" "first bad commit: tidy: extract normalizeCode()"
step "the log is what a new session reads first" 0 "the tidy-up dropped toUpperCase" "$lab/log.sh" --show

echo "== rule 9: if you didn't fix it, it isn't fixed"
step "the gate won't let the work end with nothing changed" 2 "the reproduction still fails" \
  "$lab/done-gate.sh" "$reproduce" "$regression"

echo "== rule 5: one change at a time"
mixed=$("$lab/try.sh" mixed)
git -C "$mixed" apply "$here/demo/mixed.patch"
step "the \"while I was at it\" change does make the bug go away..." 0 "found: {" \
  bash -c "cd '$mixed' && '$reproduce'"
step "...but it isn't one change, so it says nothing about the cause" 1 "not one change" \
  bash -c "cd '$mixed' && '$lab/one-change.sh'"

fix=$("$lab/try.sh" upper-case)
git -C "$fix" apply "$here/demo/fix.patch"
step "the one-line fix is one change" 0 "one change: 1 file, 2 lines" \
  bash -c "cd '$fix' && '$lab/one-change.sh'"
"$lab/log.sh" "normalizeCode must upper-case" "one-line fix in its own worktree" "reproduction passes" >/dev/null

echo "== rules 7 and 9, at the end"
step "the gate wants the reproduction kept as a test" 2 "no passing test named" \
  bash -c "cd '$fix' && '$lab/done-gate.sh' '$reproduce' '$regression'"
cp "$here/demo/regression.test.js" "$fix/test/"
step "with the test, the gate lets the work end" 0 "done: the reproduction fails without the change and passes with it" \
  bash -c "cd '$fix' && '$lab/done-gate.sh' '$reproduce' '$regression'"

git -C "$fix" add -A && git -C "$fix" commit -q -m "Upper-case typed codes again"
step "after the commit, the same gate with no change left refuses: nothing reproduces anything" 2 \
  "the reproduction passes without your change too" \
  bash -c "cd '$fix' && '$lab/done-gate.sh' '$reproduce' '$regression'"

echo "== rule 6: the log is designed, not just appended to"
for i in $(seq 1 12); do
  LAB_LOG_KEEP=10 "$lab/log.sh" "hypothesis $i" "tried $i" "saw $i" >/dev/null
done
step "it keeps the last ten entries" 0 "10" grep -c '^## ' LAB_LOG.md
step "and moves the older ones to the archive" 0 "the tidy-up dropped toUpperCase" grep '^## ' LAB_LOG.archive.md

exit $failures
