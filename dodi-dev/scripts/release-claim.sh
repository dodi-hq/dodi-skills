#!/usr/bin/env bash
# Close out the most recent open claim comment on a ticket with an exit state.
#
# Usage: release-claim.sh <ticket-id> <exit-state> [evidence]
#   <exit-state>: completed | RESUMABLE | demoted | blocked | released-no-op
# Exit: 0 released; 1 no open claim found; 2 error.
set -euo pipefail
source "$(dirname "$0")/linear-api.sh"

ticket="${1:?usage: release-claim.sh <ticket-id> <exit-state> [evidence]}"
exit_state="${2:?usage: release-claim.sh <ticket-id> <exit-state> [evidence]}"
evidence="${3:-none recorded}"
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

resp="$(linear_gql 'query($id: String!) { issue(id: $id) { comments(last: 50) { nodes { id body } } } }' "{\"id\": \"$ticket\"}")"

update="$(RESP="$resp" EXIT_STATE="$exit_state" EVIDENCE="$evidence" NOW="$now_iso" python3 <<'PY'
import json, os
data = json.loads(os.environ["RESP"])
claims = [c for c in data["data"]["issue"]["comments"]["nodes"]
          if c["body"].startswith("# Ticket Claim") and "- Exit state: `<open>`" in c["body"]]
if not claims:
    print("NONE")
    raise SystemExit
c = claims[-1]
body = (c["body"]
        .replace("- Exit state: `<open>`", f"- Exit state: `{os.environ['EXIT_STATE']}`")
        .replace("- Evidence: `<pending>`", f"- Evidence: {os.environ['EVIDENCE']}")
        .replace("- Exited at: `<pending>`", f"- Exited at: `{os.environ['NOW']}`"))
print(json.dumps({"id": c["id"], "body": body}))
PY
)"

if [[ "$update" == "NONE" ]]; then
  echo "release-claim: no open claim on $ticket" >&2
  exit 1
fi

vars="$(UPDATE="$update" python3 -c 'import json,os; u=json.loads(os.environ["UPDATE"]); print(json.dumps({"id": u["id"], "input": {"body": u["body"]}}))')"
linear_gql 'mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }' "$vars" >/dev/null
echo "released $ticket exit=$exit_state"
