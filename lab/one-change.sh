#!/usr/bin/env bash
# Rule 5, one change at a time: refuses a working tree whose change to the
# code under test is more than one small edit. New tests are allowed; they are
# the experiment, not the change.
#
# Usage, from the project's directory: lab/one-change.sh [max-files] [max-changed-lines]
# Environment: LAB_CODE (default src/), the part of the project that counts as code.
set -euo pipefail
max_files=${1:-1}
max_lines=${2:-4}
code=${LAB_CODE:-src/}

files=$(git diff --numstat HEAD -- . | awk -v c="$code" 'index($3, c) != 1 {print $3}')
code_files=$(git diff --numstat HEAD -- "$code" | wc -l)
code_lines=$(git diff --numstat HEAD -- "$code" | awk '{s += $1 + $2} END {print s + 0}')

problems=()
(( code_files <= max_files )) || problems+=("$code_files files changed under $code (at most $max_files)")
(( code_lines <= max_lines )) || problems+=("$code_lines lines changed under $code (at most $max_lines)")
for f in $files; do
  [[ "$f" == test/* ]] || problems+=("$f changed outside $code and test/: that's a second change")
done

if (( ${#problems[@]} )); then
  printf 'not one change:\n' >&2
  printf '  - %s\n' "${problems[@]}" >&2
  exit 1
fi
echo "one change: $code_files file, $code_lines lines under $code"
