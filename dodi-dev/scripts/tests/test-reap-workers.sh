#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RW="$HERE/../reap-workers.sh"
bash -n "$RW"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
manifest="$tmp/dispatch-manifest-test.jsonl"

# Mixed-schema manifest: manifests accrete across sessions in one worktree, so
# legacy "worker"-keyed records (pre-0.16.x) sit beside "worker_id" records.
# The field-confirmed crash: an unguarded r["worker_id"] on a legacy reap
# record threw KeyError and the script died before printing anything.
cat >"$manifest" <<'JSONL'
{"worker":"legacy-merge","phase":"merge","tier":"haiku","dispatched":"2026-08-14T03:00:00Z"}
{"worker":"legacy-merge","reaped":true,"verdict":"merged","ts":"2026-08-14T03:30:00Z"}
{"session_id":"s1","worker_id":"current-reaped","output_file":"","purpose":"x","tier":"haiku","ts":"t"}
{"worker_id":"current-reaped","reaped":true,"verdict":"done","ts":"t2"}
{"session_id":"s1","worker_id":"current-unreaped","output_file":"","purpose":"y","tier":"haiku","ts":"t3"}
JSONL

# Assertion 1: mixed schemas must not crash (the KeyError regression).
out="$(bash "$RW" "$manifest" 2>/dev/null)" || { echo "FAIL crash: non-zero exit on mixed-schema manifest" >&2; exit 1; }

# Assertion 2: the unreaped current-schema worker is reported.
grep -q "^current-unreaped	" <<<"$out" || { echo "FAIL report: current-unreaped missing from output" >&2; printf '%s\n' "$out" >&2; exit 1; }

# Assertion 3: reaped workers (either schema) are NOT reported.
grep -q "^legacy-merge	" <<<"$out" && { echo "FAIL legacy dedup: reaped legacy worker reported as unreaped" >&2; printf '%s\n' "$out" >&2; exit 1; }
grep -q "^current-reaped	" <<<"$out" && { echo "FAIL current dedup: reaped worker reported as unreaped" >&2; printf '%s\n' "$out" >&2; exit 1; }

# Assertion 4: a legacy-schema DISPATCH with no reap record is still visible.
cat >"$manifest" <<'JSONL'
{"worker":"legacy-unreaped","phase":"verify","tier":"haiku","dispatched":"2026-08-14T04:00:00Z"}
JSONL
out="$(bash "$RW" "$manifest" 2>/dev/null)"
grep -q "^legacy-unreaped	" <<<"$out" || { echo "FAIL legacy visibility: unreaped legacy worker missing from output" >&2; printf '%s\n' "$out" >&2; exit 1; }

echo "reap-workers tests ok"
