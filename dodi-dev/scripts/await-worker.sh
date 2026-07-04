#!/usr/bin/env bash
# Await an async Agent-tool worker by CONTENT, not by silence. Poll the
# transcript's FINAL LINES for the terminal record ("stop_reason":"end_turn")
# every few seconds; raise an mtime stall alarm in the same loop; STALLED is a
# distinct exit. Chunk-bounded (<=9 min per call, well under the 600s Bash
# harness cap and the 120s foreground default per the tool contract) so it
# never depends on timeout(1). (Live-test gate item 5's real question is
# multi-hour *scheduled-session* longevity, not these per-call caps.)
#
# Never whole-file grep (one escaping accident from a false completion, and
# additive harness drift would be silent) — final-lines keeps drift loud.
#
# Usage: await-worker.sh <output_file> [tail_lines=40] [stall_secs=600] [chunk_secs=540]
# Exit: 0 terminal record found (final lines printed);
#       7 STALLED (mtime unchanged > stall_secs, no terminal record);
#       8 chunk timeout — STILL RUNNING, caller re-invokes (never "done");
#       2 usage/environment error.
set -euo pipefail

file="${1:?usage: await-worker.sh <output_file> [tail_lines] [stall_secs] [chunk_secs]}"
tail_lines="${2:-40}"
stall_secs="${3:-600}"
chunk_secs="${4:-540}"

mtime_of() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }

start="$(date +%s)"
last_mtime=""
last_change="$start"

while :; do
  now="$(date +%s)"
  # Self-bound the chunk: report STILL RUNNING so the caller re-invokes.
  if (( now - start >= chunk_secs )); then
    echo "await-worker: chunk elapsed (${chunk_secs}s), worker still running on ${file}" >&2
    exit 8
  fi

  if [[ -f "$file" ]]; then
    mtime="$(mtime_of "$file")"
    if [[ "$mtime" != "$last_mtime" ]]; then
      last_mtime="$mtime"; last_change="$now"
    fi
    # Content check on the FINAL LINES only.
    if tail -n "$tail_lines" "$file" | grep -q '"stop_reason"[[:space:]]*:[[:space:]]*"end_turn"'; then
      # Truncation guard: a large final record flushes in multiple writes. Confirm
      # completeness — a trailing newline — before extracting, RE-CHECKING after
      # each short sleep (up to a few tries) rather than extracting after a single
      # unconditional sleep. `tail -c1` is empty iff the last byte is a newline
      # (command substitution strips it), so non-empty = still mid-flush.
      guard=0
      while [[ -n "$(tail -c1 "$file")" ]] && (( guard < 5 )); do
        sleep 2
        guard=$((guard + 1))
      done
      # Only extract once the record is complete (trailing newline) or the guard
      # bound is hit (extract best-effort rather than hang).
      tail -n "$tail_lines" "$file"
      exit 0
    fi
    # mtime stall alarm: file exists, unchanged beyond stall window, no terminal.
    if (( now - last_change > stall_secs )); then
      echo "await-worker: STALLED — ${file} mtime unchanged for >${stall_secs}s with no terminal record" >&2
      exit 7
    fi
  fi
  sleep 3
done
