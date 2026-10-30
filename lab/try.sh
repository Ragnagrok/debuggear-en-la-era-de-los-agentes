#!/usr/bin/env bash
# Rule 5, one change at a time: each hypothesis gets its own worktree and
# branch, so two ideas never share a working copy.
#
# Usage, from the project's directory: lab/try.sh <hypothesis-name>
set -euo pipefail
name=$1
root=$(git rev-parse --show-toplevel)
dir="$root/../$(basename "$root")-try-$name"
git worktree add -q -b "try/$name" "$dir"
echo "$dir"
