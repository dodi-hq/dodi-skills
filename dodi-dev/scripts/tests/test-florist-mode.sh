#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
FM="$HERE/../florist-mode.sh"
bash -n "$FM"

# manual: no FLORIST_UNIT -> mode=manual, exit 0, never mentions a digest to emit
out="$(env -u FLORIST_UNIT -u FLORIST_LANE bash "$FM")"
[[ "$(head -1 <<<"$out")" == "mode=manual" ]] || { echo "FAIL manual: $out" >&2; exit 1; }

# autonomous: the machine line carries unit + lane; the instruction names the contract and the digest script
out="$(FLORIST_UNIT=DOD-1 FLORIST_LANE=code-review FLORIST_ATTEMPT=0 FLORIST_TIER='Standard@session-default' FLORIST_FABLE_POLICY=none FLORIST_EPIC_BRANCH=epic/x LINEAR_API_KEY=k bash "$FM")"
grep -q '^mode=autonomous unit=DOD-1 lane=code-review attempt=0 ' <<<"$out" || { echo "FAIL autonomous line: $out" >&2; exit 1; }
grep -q 'florist-worker-contract.md' <<<"$out" || { echo "FAIL: must point at the contract" >&2; exit 1; }
grep -q 'florist-digest.sh' <<<"$out" || { echo "FAIL: must name the digest script" >&2; exit 1; }
grep -q 'linear_key=present' <<<"$out" || { echo "FAIL: linear key presence" >&2; exit 1; }

# misdispatch: FLORIST_UNIT set but the kernel companions missing -> exit 3, told to block
set +e
err="$(FLORIST_UNIT=DOD-1 env -u FLORIST_LANE bash "$FM" 2>&1 >/dev/null)"; rc=$?
set -e
[[ $rc -eq 3 ]] || { echo "FAIL misdispatch rc=$rc" >&2; exit 1; }
grep -q 'worker-blocked' <<<"$err" || { echo "FAIL misdispatch message: $err" >&2; exit 1; }

echo "florist-mode tests ok"
