#!/usr/bin/env bash
# Await an async Agent-tool worker by polling its output_file until the file's
# mtime has been stable for STABLE_SECS, then print only the final JSONL
# entries. Never read the whole transcript — it overflows the caller's context.
#
# Usage: await-worker.sh <output_file> [stable_secs=60] [timeout_secs=7200] [tail_entries=15]
# Exit: 0 result printed; 1 timeout; 2 usage/environment error.
set -euo pipefail

file="${1:?usage: await-worker.sh <output_file> [stable_secs] [timeout_secs] [tail_entries]}"
stable_secs="${2:-60}"
timeout_secs="${3:-7200}"
tail_entries="${4:-15}"

mtime_of() {
  # macOS (BSD stat) then GNU stat
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null
}

start="$(date +%s)"
while :; do
  now="$(date +%s)"
  if (( now - start > timeout_secs )); then
    echo "await-worker: timed out after ${timeout_secs}s waiting on ${file}" >&2
    exit 1
  fi
  if [[ -f "$file" ]]; then
    mtime="$(mtime_of "$file")"
    if [[ -n "$mtime" ]] && (( now - mtime > stable_secs )); then
      break
    fi
  fi
  sleep 15
done

tail -n "$tail_entries" "$file"
