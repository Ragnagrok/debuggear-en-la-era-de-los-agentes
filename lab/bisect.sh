#!/usr/bin/env bash
# Rule 4, divide and conquer: binary search over the history, with the
# reproduction as the yes-or-no oracle. Prints the first bad commit and puts
# the repository back where it was.
#
# Usage, from the project's directory: lab/bisect.sh <known-good-ref> <reproduce-script>
# The script is copied out of the repository first: old commits may not have
# it, and checking them out must not change the question being asked.
set -euo pipefail
good=$1
oracle=$(mktemp)
cp "$2" "$oracle"
chmod +x "$oracle"
trap 'git bisect reset >/dev/null 2>&1; rm -f "$oracle"' EXIT

git bisect start HEAD "$good" >/dev/null
git bisect run "$oracle" >/dev/null 2>&1 || true
echo "first bad commit: $(git log -1 --format='%h %s' refs/bisect/bad)"
