#!/usr/bin/env bash
# Post a claim comment on a ticket before acting on it (pickup-next / manual
# orchestrator claim discipline). Detects a live foreign claim and refuses.
#
# Usage: claim.sh <ticket-id> <action> [lease_hours=2]
#   <action>: mature-ticket | deliver-ticket | merge-child | submit-epic-pr | coherence-review
# Exit: 0 claimed (prints attempt number); 3 live foreign claim (details on
#       stdout — caller decides whether checkpoint progress overrides); 2 error.
#
# Liveness is progress-based at the caller level: this script only refuses a
# foreign claim comment updated within the lease window. A claim older than the
# lease, or one from this host, is claimable; the caller must first apply the
# progress test (fresh checkpoints since the claim's last update = alive).
set -euo pipefail
source "$(dirname "$0")/linear-api.sh"

ticket="${1:?usage: claim.sh <ticket-id> <action> [lease_hours]}"
action="${2:?usage: claim.sh <ticket-id> <action> [lease_hours]}"
lease_hours="${3:-2}"
host="$(hostname -s)"
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id comments(last: 50) { nodes { id body updatedAt } } } }' "{\"id\": \"$ticket\"}")"

issue_uuid="$(RESP="$resp" python3 -c 'import json,os; print(json.loads(os.environ["RESP"])["data"]["issue"]["id"])')"

# Inspect the most recent claim comment, if any.
claim_info="$(RESP="$resp" CLAIM_HOST="$host" LEASE_H="$lease_hours" python3 <<'PY'
import json, os
from datetime import datetime, timezone
host, lease_hours = os.environ["CLAIM_HOST"], float(os.environ["LEASE_H"])
data = json.loads(os.environ["RESP"])
claims = [c for c in data["data"]["issue"]["comments"]["nodes"] if c["body"].startswith("# Ticket Claim")]
if not claims:
    print("none\t-\t-\t0")
    raise SystemExit
c = claims[-1]
body = c["body"]
open_claim = "- Exit state: `<open>`" in body
holder = next((l.split("`")[1] for l in body.splitlines() if l.startswith("- Host:") and "`" in l), "?")
attempts = 0
for l in body.splitlines():
    if "Consecutive attempt:" in l and "`" in l:
        try:
            attempts = int(l.split("`")[1])
        except ValueError:
            pass
updated = datetime.fromisoformat(c["updatedAt"].replace("Z", "+00:00"))
age_h = (datetime.now(timezone.utc) - updated).total_seconds() / 3600
state = "foreign" if (open_claim and holder != host and age_h < lease_hours) else "claimable"
print(f"{state}\t{holder}\t{age_h:.2f}\t{attempts}")
PY
)"

state="$(cut -f1 <<<"$claim_info")"
if [[ "$state" == "foreign" ]]; then
  echo "live foreign claim: $claim_info"
  exit 3
fi
prev_attempts="$(cut -f4 <<<"$claim_info")"
attempt=$((prev_attempts + 1))

body="# Ticket Claim

Ticket: \`$ticket\`

## Claim

- Host: \`$host\`
- Claimed at: \`$now_iso\`
- Action: \`$action\`
- Lease window: \`${lease_hours}h\`

## Attempt

- Consecutive attempt: \`$attempt\` of \`3\`
- Prior checkpoint: \`<caller updates on close-out>\`

## Exit

- Exit state: \`<open>\`
- Evidence: \`<pending>\`
- Exited at: \`<pending>\`"

vars="$(python3 -c 'import json,sys; print(json.dumps({"input": {"issueId": sys.argv[1], "body": sys.argv[2]}}))' "$issue_uuid" "$body")"
linear_gql 'mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success comment { id } } }' "$vars" >/dev/null
echo "claimed attempt=$attempt host=$host action=$action"
