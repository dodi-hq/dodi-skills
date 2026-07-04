#!/usr/bin/env bash
# Post a per-ticket claim comment before acting on a ticket (driver / lane /
# manual / 0.14.0-tick claim discipline). Refuses a LIVE foreign claim per the
# driver-claim-topped liveness hierarchy.
#
# Usage: claim.sh <ticket-id> <action> <session-run-id> [lease_hours=2]
#   <action>: mature-ticket | deliver-ticket | merge-child | submit-epic-pr | coherence-review
#   claim.sh classify <cstate> <csrid> <srid> <cage_h> <lease_h> <tier1> <tier2>
#     -> the pure liveness decision (alive|claimable), no network — for tests.
# Exit: 0 claimed (or own-session no-op); 3 live foreign claim; 2 error.
#
# Liveness hierarchy (in order), evaluated by the pure _liveness_tier:
#   1. claim's session id matches a FRESH open DRIVER claim (on the epic, found
#      by parent traversal) -> alive, full stop.
#   2. else, a progress-species checkpoint attributable to the claim's session
#      within one lease window of NOW -> alive.
#   3. else the lease-age test on the claim's own age.
# Legacy claims with no session id: tier-3 only. A LIVE legacy (id-less) foreign
# claim is refused (exit 3) just like an id-bearing one — the guard keys on
# csrid != srid, NOT on csrid being non-empty (that earlier conjunct was the
# legacy-claim theft bug). Own-session (csrid==srid) short-circuits to a no-op.
set -euo pipefail
# Source-guarded (tests may pre-stub linear_gql / driver-claim status).
if ! declare -F linear_gql >/dev/null 2>&1; then source "$(dirname "$0")/linear-api.sh"; fi
source "$(dirname "$0")/comment-species.sh"

# --- pure liveness-tier decision (no network) — the testable core ---
# _liveness_tier: given the claim facts and the tier-1/tier-2 signals already
# resolved by the caller, prints `alive` or `claimable`. This is the single
# decision point the exit-3 guard consumes; a test drives it directly with each
# tier's inputs (no PM access), and the network-bearing main flow computes the
# signals then calls it.
#
# Args (positional, all strings):
#   $1 cstate       open|closed
#   $2 csrid        claim's session run id ("" for a legacy id-less claim)
#   $3 srid         THIS session's run id
#   $4 cage_h       claim age in hours (for the tier-3 lease test)
#   $5 lease_hours  lease window in hours
#   $6 tier1        yes|no  — csrid matches a fresh open driver claim on the epic
#   $7 tier2        yes|no  — a progress-species checkpoint attributable to csrid
#                            within one lease window of now
# A closed claim is always claimable. Own-session (csrid==srid) is never foreign
# (own work in progress) — the guard below never refuses on it, so this returns
# `claimable` for it (the main flow short-circuits own-session to a no-op before
# ever refusing). Legacy (csrid=="") is judged by tier-3 alone.
_liveness_tier() {
  local cstate="$1" csrid="$2" srid="$3" cage_h="$4" lease_hours="$5" tier1="$6" tier2="$7"
  [[ "$cstate" != "open" ]] && { echo claimable; return 0; }
  # Own-session or legacy: no tier-1/tier-2 attribution to another session.
  if [[ "$csrid" == "$srid" ]]; then echo claimable; return 0; fi
  if [[ -n "$csrid" ]]; then
    # Foreign, id-bearing claim: full hierarchy.
    [[ "$tier1" == "yes" ]] && { echo alive; return 0; }
    [[ "$tier2" == "yes" ]] && { echo alive; return 0; }
  fi
  # Tier-3 (and the ONLY tier for a legacy id-less foreign claim): lease age.
  if (( $(python3 -c "print(1 if float('$cage_h') < float('$lease_hours') else 0)") )); then
    echo alive
  else
    echo claimable
  fi
}

# Test/inspection subcommand: `claim.sh classify <cstate> <csrid> <srid> <cage_h> <lease_h> <tier1> <tier2>`
# Prints alive|claimable and exits — the pure decision, no network.
if [[ "${1:-}" == "classify" ]]; then
  shift
  _liveness_tier "$@"
  exit 0
fi

ticket="${1:?usage: claim.sh <ticket-id> <action> <session-run-id> [lease_hours]}"
action="${2:?usage: claim.sh <ticket-id> <action> <session-run-id> [lease_hours]}"
srid="${3:?usage: claim.sh <ticket-id> <action> <session-run-id> [lease_hours]}"
lease_hours="${4:-2}"
host="$(hostname -s)"
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Read the ticket: id, parent chain (for tier-1 epic resolution), comments (paged).
resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id parent { id } comments(last: 100) { nodes { id body createdAt updatedAt } } } }' "{\"id\": \"$ticket\"}")"
issue_uuid="$(RESP="$resp" python3 -c 'import json,os; print(json.loads(os.environ["RESP"])["data"]["issue"]["id"])')"

# Resolve the epic (parentless root) for tier-1.
epic_id="$ticket"
cur="$ticket"
while :; do
  p="$(linear_gql 'query($id: String!) { issue(id: $id) { parent { id } } }' "{\"id\": \"$cur\"}" \
       | python3 -c 'import json,sys; d=json.load(sys.stdin)["data"]["issue"]["parent"]; print(d["id"] if d else "")')"
  [[ -z "$p" ]] && break
  epic_id="$p"; cur="$p"
done

# Inspect the most recent per-ticket claim comment (# Ticket Claim only).
# NOTE: heredocs live inside functions, not inside $(...) — bash 3.2 (macOS
# /bin/bash) cannot parse heredocs within command substitution when the body
# contains backticks or odd apostrophes. Same reason the python builds
# backticks via chr(96).
_read_claim_info() {
  RESP="$resp" LEASE_H="$lease_hours" python3 <<'PY'
import json, os
from datetime import datetime, timezone
lease_hours = float(os.environ["LEASE_H"])
data = json.loads(os.environ["RESP"])
now = datetime.now(timezone.utc)
comments = data["data"]["issue"]["comments"]["nodes"]
claims = [c for c in comments if c["body"].startswith("# Ticket Claim")]
if not claims:
    print("none\t-\t-\t0\t-")
    raise SystemExit
c = claims[-1]
body = c["body"]
# BT: literal backticks inside a heredoc inside $(...) break bash 3.2's parser
# (macOS /bin/bash) — build them via chr(96) instead.
BT = chr(96)
open_claim = f"- Exit state: {BT}<open>{BT}" in body
csrid = next((l.split(BT)[1] for l in body.splitlines() if l.startswith("- Session run id:") and BT in l), "")
updated = datetime.fromisoformat(c["updatedAt"].replace("Z","+00:00"))
age_h = (now - updated).total_seconds()/3600
# tier-2 pre-compute: latest progress-species comment attributable to csrid, in hours-ago.
# (Species classification is applied in bash; here we just export the claim facts.)
print(f"{'open' if open_claim else 'closed'}\t{csrid}\t{age_h:.3f}\t{c['id']}\t{c['updatedAt']}")
PY
}
claim_info="$(_read_claim_info)"

cstate="$(cut -f1 <<<"$claim_info")"
csrid="$(cut -f2 <<<"$claim_info")"
cage_h="$(cut -f3 <<<"$claim_info")"
cclaim_id="$(cut -f4 <<<"$claim_info")"

# Own-session short-circuit: the newest open claim is already ours. Do not append
# a duplicate # Ticket Claim — no-op and echo. (A caller re-running claim.sh in
# the same session must not stack claims.)
if [[ "$cstate" == "open" && -n "$csrid" && "$csrid" == "$srid" ]]; then
  echo "already claimed by this session (claim=$cclaim_id action=$action); no-op"
  exit 0
fi

# --- Resolve the tier-1 and tier-2 signals for a FOREIGN, id-bearing claim,
#     then delegate the decision to the pure _liveness_tier. Legacy (csrid="")
#     and closed claims skip signal resolution — _liveness_tier judges them by
#     tier-3 / closed directly. ---
tier1="no"; tier2="no"
if [[ "$cstate" == "open" && -n "$csrid" && "$csrid" != "$srid" ]]; then
  # Tier 1: does csrid match a FRESH open driver claim on the epic?
  if "$(dirname "$0")/driver-claim.sh" status "$epic_id" 2>/dev/null | grep -q "$csrid"; then
    tier1="yes"
  fi
  # Tier 2: a progress-species checkpoint attributable to csrid within one lease window of now?
  if [[ "$tier1" != "yes" ]]; then
    _tier2_signal() {
      RESP="$resp" CSRID="$csrid" LEASE_H="$lease_hours" python3 <<'PY'
import json, os
from datetime import datetime, timezone
lease_hours = float(os.environ["LEASE_H"]); csrid = os.environ["CSRID"]
data = json.loads(os.environ["RESP"]); now = datetime.now(timezone.utc)
alive = "no"
for c in data["data"]["issue"]["comments"]["nodes"]:
    b = c["body"]
    BT = chr(96)  # no literal backticks in a $()-heredoc — bash 3.2 parser bug
    if f"Run id: {BT}{csrid}{BT}" not in b and f"Run id: {csrid}" not in b:
        continue
    # Species check: only the two progress headers a session posts under its run
    # id (Lane Checkpoint, Decision Register Entry) carry a run-id field, so an
    # inline first-header match is exactly comment-species.sh's progress set for
    # this population. (unknown⇒bookkeeping semantics preserved: a non-matching
    # header is skipped, i.e. treated as non-progress.)
    first = next((l for l in b.splitlines() if l.strip()), "")
    progress = first.startswith("# Lane Checkpoint") or first.startswith("# Decision Register Entry")
    if not progress:
        continue
    ts = datetime.fromisoformat(c["updatedAt"].replace("Z","+00:00"))
    if (now - ts).total_seconds()/3600 <= lease_hours:
        alive = "yes"; break
print(alive)
PY
    }
    tier2="$(_tier2_signal)"
  fi
fi

# The decision: pure tier evaluation (also covers legacy tier-3 and closed).
alive="$(_liveness_tier "$cstate" "$csrid" "$srid" "$cage_h" "$lease_hours" "$tier1" "$tier2")"

# Exit-3 guard (B5 theft fix): refuse ANY live claim that is not this session's
# own. The old guard also required `-n "$csrid"`, which was FALSE for a legacy
# id-less claim — so a LIVE legacy foreign claim was silently stolen. Dropping
# that conjunct closes the theft; own-session (csrid==srid) already short-circuited
# to a no-op above, so it never reaches here to self-refuse.
if [[ "$alive" == "alive" && "$csrid" != "$srid" ]]; then
  echo "live foreign claim: session=${csrid:-<legacy/no-id>} age_h=$cage_h"
  exit 3
fi

body="# Ticket Claim

Ticket: \`$ticket\`

## Claim

- Session run id: \`$srid\`
- Host: \`$host\`
- Claimed at: \`$now_iso\`
- Action: \`$action\`
- Lease window: \`${lease_hours}h\`

## Attempt

- Consecutive attempt: \`1\` of \`3\`
- Prior checkpoint: \`<caller updates on close-out>\`

## Exit

- Exit state: \`<open>\`
- Evidence: \`<pending>\`
- Exited at: \`<pending>\`"

vars="$(python3 -c 'import json,sys; print(json.dumps({"input": {"issueId": sys.argv[1], "body": sys.argv[2]}}))' "$issue_uuid" "$body")"
linear_gql 'mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success comment { id } } }' "$vars" >/dev/null
echo "claimed session_run_id=$srid host=$host action=$action"
