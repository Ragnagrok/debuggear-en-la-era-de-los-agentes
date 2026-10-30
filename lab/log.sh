#!/usr/bin/env bash
# Rule 6, keep an audit trail: one entry per attempt, in LAB_LOG.md at the
# project's root. The log is designed, not just appended to: it keeps the last
# $LAB_LOG_KEEP entries and moves older ones to LAB_LOG.archive.md, so whoever
# reads it at the start of a session reads the present, not two days ago.
#
# Usage: lab/log.sh "<hypothesis>" "<what was done>" "<what happened>"
#        lab/log.sh --show        (prints the log; meant for a session-start hook)
set -euo pipefail
log=LAB_LOG.md
archive=LAB_LOG.archive.md
keep=${LAB_LOG_KEEP:-10}

if [[ "${1:-}" == "--show" ]]; then
  [[ -f "$log" ]] && cat "$log" || echo "(no attempts logged yet)"
  exit 0
fi

(( $# == 3 )) || { echo "usage: lab/log.sh <hypothesis> <action> <result>" >&2; exit 64; }
{
  echo "## $(date -u +%Y-%m-%dT%H:%MZ) · $1"
  echo "- did: $2"
  echo "- saw: $3"
  echo
} >> "$log"

entries=$(grep -c '^## ' "$log")
if (( entries > keep )); then
  # Split at the first entry that stays; everything before it goes to the archive.
  cut=$(grep -n '^## ' "$log" | sed -n "$(( entries - keep + 1 ))p" | cut -d: -f1)
  head -n $(( cut - 1 )) "$log" >> "$archive"
  tail -n +"$cut" "$log" > "$log.tmp" && mv "$log.tmp" "$log"
fi
