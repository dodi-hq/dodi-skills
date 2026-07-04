#!/usr/bin/env bash
# Classify and report the unreaped workers in a dispatch manifest. Does NOT
# stop anything — stopping is the calling agent's step via the agent-layer
# primitive (nested availability is gated; where absent, orphaned grandchildren
# run to completion — the caller notes and escalates).
#
# Manifest: .dodi/dispatch-manifest-<session-run-id>.jsonl at an ABSOLUTE path.
# Each line: {session_id, worker_id, output_file, purpose, tier, ts}
# Reap records appended: {reaped, verdict, ts} keyed to worker_id.
#
# Usage: reap-workers.sh <manifest-path>
# Exit: 0 report printed; 2 error.
set -euo pipefail

manifest="${1:?usage: reap-workers.sh <manifest-path>}"
[[ -f "$manifest" ]] || { echo "reap-workers: no manifest at $manifest" >&2; exit 0; }

mtime_of() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }
now="$(date +%s)"

MANIFEST="$manifest" NOW="$now" python3 <<'PY'
import json, os, subprocess
from pathlib import Path
mpath = os.environ["MANIFEST"]; now = int(os.environ["NOW"])
lines = [json.loads(l) for l in Path(mpath).read_text().splitlines() if l.strip()]
dispatched = {r["worker_id"]: r for r in lines if "worker_id" in r and "reaped" not in r}
reaped = {r["worker_id"] for r in lines if r.get("reaped")}
for wid, rec in dispatched.items():
    if wid in reaped:
        continue
    of = rec.get("output_file", "")
    verdict = "live"
    if of and Path(of).exists():
        tail = "".join(Path(of).read_text(errors="replace").splitlines(keepends=True)[-40:])
        if '"stop_reason"' in tail and '"end_turn"' in tail:
            verdict = "terminal"
        else:
            try:
                st = Path(of).stat().st_mtime
                if now - st > 600:
                    verdict = "STALLED"
            except OSError:
                verdict = "live"
    print(f"{wid}\t{verdict}\t{of}")
PY
echo "reap-workers: classified $manifest" >&2
