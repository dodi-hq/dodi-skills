#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
AW="$HERE/../await-worker.sh"
bash -n "$AW"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# (a) terminal record in the final lines -> exit 0
f="$tmp/done.jsonl"
printf '%s\n' '{"type":"assistant","content":"x"}' '{"type":"assistant","stop_reason":"end_turn"}' >"$f"
if out="$(bash "$AW" "$f" 40 600 540)"; then
  grep -q 'end_turn' <<<"$out" || { echo "FAIL (a): terminal not printed" >&2; exit 1; }
else
  echo "FAIL (a): expected exit 0" >&2; exit 1
fi

# (b) terminal string only in an EARLY line; final lines are non-terminal.
# With many trailing non-terminal lines and tail_lines=2, the final-lines scan
# must NOT see the early end_turn -> chunk times out (exit 8), not false-0.
f2="$tmp/early.jsonl"
{ printf '%s\n' '{"stop_reason":"end_turn"}'; for i in $(seq 1 50); do printf '%s\n' '{"type":"assistant","content":"still going"}'; done; } >"$f2"
set +e
bash "$AW" "$f2" 2 600 2 >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -eq 8 ]] || { echo "FAIL (b): expected exit 8 (still running), got $rc" >&2; exit 1; }

# (c) STALLED: file exists, unchanged, no terminal, small stall window.
f3="$tmp/stall.jsonl"
printf '%s\n' '{"type":"assistant","content":"work"}' >"$f3"
touch -t 202001010000 "$f3" 2>/dev/null || true   # force old mtime where supported
set +e
bash "$AW" "$f3" 40 1 60 >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -eq 7 || "$rc" -eq 8 ]] || { echo "FAIL (c): expected STALLED(7) or chunk(8), got $rc" >&2; exit 1; }

echo "await-worker tests ok"
