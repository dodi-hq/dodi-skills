#!/usr/bin/env bash
# Close out a per-ticket claim comment with an exit state.
#
# Usage:
#   release-claim.sh <ticket-id> <exit-state> [evidence]                  # own-session: newest open own claim
#   release-claim.sh <ticket-id> <exit-state> [evidence] --foreign <claim-id>   # foreign: EXACTLY this claim id
#   release-claim.sh <ticket-id> <exit-state> [evidence] --session <run-id>     # own-session disambiguation
#
#   <exit-state>: completed | RESUMABLE | demoted | blocked | released-no-op
#
# Foreign release requires BOTH the flag AND the target claim id — never
# most-recent-open selection (a post-crash ticket normally holds a dead claim
# AND a live successor claim; close the one judged, not the newest). The janitor
# re-reads staleness immediately before the close mutation.
# Exit: 0 released; 1 no matching open claim; 2 error.
set -euo pipefail
source "$(dirname "$0")/linear-api.sh"

ticket="${1:?usage: release-claim.sh <ticket-id> <exit-state> [evidence] [--foreign <id> | --session <run-id>]}"
exit_state="${2:?usage: release-claim.sh <ticket-id> <exit-state> [evidence]}"
shift 2
# Remaining args (any order): an OPTIONAL leading non-`--` token is the evidence;
# --foreign <id> and --session <run-id> are flags. The only concrete foreign
# caller is `release-claim.sh <ticket> released-no-op --foreign <id>` — no
# evidence — so evidence MUST be optional here, not positional-$3 (the old
# `evidence=$3; shift 3` swallowed `--foreign` as evidence and broke takeover).
evidence="none recorded"
foreign_id=""; own_srid=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --foreign) foreign_id="${2:?--foreign needs a claim id}"; shift 2 ;;
    --session) own_srid="${2:?--session needs a run id}"; shift 2 ;;
    --*) echo "release-claim: unknown flag $1" >&2; exit 2 ;;
    *) evidence="$1"; shift ;;   # leading non-`--` token: the optional evidence
  esac
done
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

resp="$(linear_gql 'query($id: String!) { issue(id: $id) { comments(last: 100) { nodes { id body } } } }' "{\"id\": \"$ticket\"}")"

update="$(RESP="$resp" EXIT_STATE="$exit_state" EVIDENCE="$evidence" NOW="$now_iso" FOREIGN="$foreign_id" OWN="$own_srid" python3 <<'PY'
import json, os
data = json.loads(os.environ["RESP"])
foreign, own = os.environ["FOREIGN"], os.environ["OWN"]
opens = [c for c in data["data"]["issue"]["comments"]["nodes"]
         if c["body"].startswith("# Ticket Claim") and "- Exit state: `<open>`" in c["body"]]
target = None
if foreign:
    target = next((c for c in opens if c["id"] == foreign), None)
elif own:
    target = next((c for c in reversed(opens)
                   if f"- Session run id: `{own}`" in c["body"]), None)
else:
    target = opens[-1] if opens else None
if target is None:
    print("NONE"); raise SystemExit
b = (target["body"]
     .replace("- Exit state: `<open>`", f"- Exit state: `{os.environ['EXIT_STATE']}`")
     .replace("- Evidence: `<pending>`", f"- Evidence: {os.environ['EVIDENCE']}")
     .replace("- Exited at: `<pending>`", f"- Exited at: `{os.environ['NOW']}`"))
print(json.dumps({"id": target["id"], "body": b}))
PY
)"

if [[ "$update" == "NONE" ]]; then
  echo "release-claim: no matching open claim on $ticket" >&2
  exit 1
fi

vars="$(UPDATE="$update" python3 -c 'import json,os; u=json.loads(os.environ["UPDATE"]); print(json.dumps({"id": u["id"], "input": {"body": u["body"]}}))')"
linear_gql 'mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }' "$vars" >/dev/null
echo "released $ticket exit=$exit_state${foreign_id:+ foreign=$foreign_id}"
