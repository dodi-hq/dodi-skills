#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
HB="$HERE/../heartbeat.sh"
bash -n "$HB"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
hb="$tmp/heartbeat.log"   # under mktemp -d: path contains a slash -> file-target branch
today="$(date -u +%Y-%m-%d)"
yesterday="$(date -u -d 'yesterday' +%Y-%m-%d 2>/dev/null || date -u -v-1d +%Y-%m-%d)"

# Seed a PRIOR day's heartbeat line that must SURVIVE the in-place update.
printf 'heartbeat %sT12:00:00Z host=h driver alive\n' "$yesterday" >"$hb"

# Two runs on the SAME day against the file target -> update-in-place, not append.
bash "$HB" "$hb" "run one" >/dev/null
bash "$HB" "$hb" "run two" >/dev/null

# Assertion 1: exactly ONE line for today remains (dedupe / update-in-place).
today_count="$(grep -c "^heartbeat ${today}T" "$hb" || true)"
[[ "$today_count" -eq 1 ]] || { echo "FAIL dedupe: expected 1 today line, got $today_count" >&2; cat "$hb" >&2; exit 1; }

# Assertion 2: the prior day's line survived (date-scoped, not whole-file wipe).
grep -q "^heartbeat ${yesterday}T" "$hb" || { echo "FAIL prior-day: yesterday's heartbeat was clobbered" >&2; cat "$hb" >&2; exit 1; }

# The surviving today line reflects the LATEST run (in-place replace, not stale-first).
grep -q "^heartbeat ${today}T.*run two" "$hb" || { echo "FAIL freshness: today line must carry the latest note" >&2; cat "$hb" >&2; exit 1; }

echo "heartbeat tests ok"
