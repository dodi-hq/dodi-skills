#!/usr/bin/env bash
# The dispatch-eligibility query for a child ticket:
#   readiness labels present ∧ no open blocking issues ∧ epic not coherence-pending
#   ∧ epic carries epic-signed-off.
#
# Usage: dispatch-eligible.sh <ticket-id>
# Exit: 0 eligible; 1 not eligible (reasons on stdout, one per line); 2 error.
set -euo pipefail
source "$(dirname "$0")/linear-api.sh"

ticket="${1:?usage: dispatch-eligible.sh <ticket-id>}"

resp="$(linear_gql 'query($id: String!) {
  issue(id: $id) {
    identifier
    labels { nodes { name } }
    inverseRelations { nodes { type issue { identifier state { type } } } }
    parent { identifier labels { nodes { name } } }
  }
}' "{\"id\": \"$ticket\"}")"

RESP="$resp" python3 <<'PY'
import json, os, sys
issue = json.loads(os.environ["RESP"])["data"]["issue"]
reasons = []
labels = {l["name"] for l in issue["labels"]["nodes"]}
for required in ("spec-ready", "ready-to-implement"):
    if required not in labels:
        reasons.append(f"missing label: {required}")
blockers = [r["issue"]["identifier"] for r in issue["inverseRelations"]["nodes"]
            if r["type"] == "blocks" and r["issue"]["state"]["type"] not in ("completed", "canceled")]
for b in blockers:
    reasons.append(f"open blocker: {b}")
parent = issue.get("parent")
if not parent:
    reasons.append("no parent epic")
else:
    epic_labels = {l["name"] for l in parent["labels"]["nodes"]}
    if "epic-signed-off" not in epic_labels:
        reasons.append(f"epic {parent['identifier']} lacks epic-signed-off")
    if "coherence-pending" in epic_labels:
        reasons.append(f"epic {parent['identifier']} is coherence-pending")
if reasons:
    print("\n".join(reasons))
    sys.exit(1)
print(f"eligible: {issue['identifier']}")
PY
