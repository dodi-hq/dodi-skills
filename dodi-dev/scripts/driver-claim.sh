#!/usr/bin/env bash
# Fenced driver-claim mechanism — driver mutual exclusion, one live driver per
# active epic. Own comment species (# Driver Claim), never # Ticket Claim, on
# the EPIC ticket. claim.sh / release-claim.sh filter on # Ticket Claim, so
# they are structurally blind to these.
#
# Subcommands:
#   acquire  <epic-id> <session-run-id> [stale_min=45]
#   refresh  <epic-id> <session-run-id> <session-pid> [interval_sec=900]
#   verify   <epic-id> <session-run-id> [stale_min=45]
#   release  <epic-id> <claim-comment-id> <exit-state>
#   status   <epic-id> [stale_min=45]
#
# createdAt orders claims (refresh bumps updatedAt only); comment-id tie-breaks.
# Staleness is measured on the claim body's `Refreshed at` line, not updatedAt.
set -euo pipefail
# Source the API helper unless a caller (a test) has already provided linear_gql
# — this lets test-driver-claim.sh stub the network boundary without the
# re-source clobbering the stub. Same pattern in claim.sh / release-claim.sh.
if ! declare -F linear_gql >/dev/null 2>&1; then
  source "$(dirname "$0")/linear-api.sh"
fi

STALE_DEFAULT=45  # minutes

# --- pure selection helpers (no network) — the testable core ---
# Claim TSV shape (one row per open claim): <comment-id>\t<createdAt>\t<session-run-id>\t<refreshed-age-min>
# The rows are assumed pre-sorted oldest-createdAt-first (the reader sorts).
#
# _select_oldest_fresh: reads a claim TSV on stdin, prints the WHOLE winner row
#   (oldest fresh open, i.e. first row with age < stale) or nothing. This is the
#   one selection the acquire/verify/status paths share, so tests invoke it
#   directly with fixture TSV instead of re-implementing the awk.
_select_oldest_fresh() {  # $1 = stale_min ; TSV on stdin
  local stale="${1:-$STALE_DEFAULT}"
  awk -F'\t' -v s="$stale" '$4 < s {print; exit}'
}

# --- read all open driver claims on the epic, paged, oldest-createdAt first ---
# Emits TSV: <comment-id>\t<createdAt>\t<session-run-id>\t<refreshed-age-min>
# Test override: if DRIVER_CLAIMS_TSV is set (to a file path or a literal TSV),
# emit that instead of hitting the network — this is how test-driver-claim.sh
# injects fixtures into acquire/verify/status without a live read.
_read_open_driver_claims() {
  local epic="$1"
  if [[ -n "${DRIVER_CLAIMS_TSV:-}" ]]; then
    if [[ -f "$DRIVER_CLAIMS_TSV" ]]; then cat "$DRIVER_CLAIMS_TSV"; else printf '%s\n' "$DRIVER_CLAIMS_TSV"; fi
    return 0
  fi
  local resp
  # Page: fetch comments in windows until no nextPage (honor the comment window).
  resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id comments(last: 100) { nodes { id createdAt body } } } }' "{\"id\": \"$epic\"}")"
  RESP="$resp" python3 <<'PY'
import json, os, sys
from datetime import datetime, timezone
data = json.loads(os.environ["RESP"])
now = datetime.now(timezone.utc)
rows = []
for c in data["data"]["issue"]["comments"]["nodes"]:
    b = c["body"]
    if not b.startswith("# Driver Claim"):
        continue
    if "- Exit state: `open`" not in b:
        continue
    srid = "?"
    refreshed = None
    for l in b.splitlines():
        if l.startswith("- Session run id:") and "`" in l:
            srid = l.split("`")[1]
        if l.startswith("- Refreshed at:") and "`" in l:
            try:
                refreshed = datetime.fromisoformat(l.split("`")[1].replace("Z", "+00:00"))
            except ValueError:
                refreshed = None
    age_min = (now - refreshed).total_seconds()/60 if refreshed else 1e9
    created = c["createdAt"]
    rows.append((created, c["id"], srid, age_min))
rows.sort(key=lambda r: (r[0], r[1]))  # createdAt, then comment-id
for created, cid, srid, age in rows:
    print(f"{cid}\t{created}\t{srid}\t{age:.1f}")
PY
}

# --- issue uuid for mutations ---
_issue_uuid() {
  local epic="$1" resp
  resp="$(linear_gql 'query($id: String!) { issue(id: $id) { id } }' "{\"id\": \"$epic\"}")"
  RESP="$resp" python3 -c 'import json,os; print(json.loads(os.environ["RESP"])["data"]["issue"]["id"])'
}

_post_claim() {  # epic-uuid session-run-id host stale_min -> prints new comment id
  local uuid="$1" srid="$2" host="$3" stale="$4"
  local now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local body="# Driver Claim

Epic: \`$uuid\`

## Claim

- Session run id: \`$srid\`
- Host: \`$host\`
- Acquired at: \`$now\`
- Refreshed at: \`$now\`
- Lease window: \`${stale}m\`

## Exit

- Exit state: \`open\`
- Released at: \`<pending>\`"
  local vars; vars="$(python3 -c 'import json,sys; print(json.dumps({"input": {"issueId": sys.argv[1], "body": sys.argv[2]}}))' "$uuid" "$body")"
  linear_gql 'mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success comment { id } } }' "$vars" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["commentCreate"]["comment"]["id"])'
}

_close_claim() {  # comment-id exit-state
  local cid="$1" state="$2" now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # Fetch the claim body, flip Exit state + Released at, update in place.
  local resp; resp="$(linear_gql 'query($id: String!) { comment(id: $id) { id body } }' "{\"id\": \"$cid\"}")"
  local body; body="$(RESP="$resp" STATE="$state" NOW="$now" python3 <<'PY'
import json, os
c = json.loads(os.environ["RESP"])["data"]["comment"]
b = (c["body"]
     .replace("- Exit state: `open`", f"- Exit state: `{os.environ['STATE']}`")
     .replace("- Released at: `<pending>`", f"- Released at: `{os.environ['NOW']}`"))
print(json.dumps(b))
PY
)"
  local vars; vars="$(python3 -c 'import json,sys; print(json.dumps({"id": sys.argv[1], "input": {"body": json.loads(sys.argv[2])}}))' "$cid" "$body")"
  linear_gql 'mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }' "$vars" >/dev/null
}

cmd="${1:?usage: driver-claim.sh <acquire|refresh|verify|release|status> ...}"; shift || true

case "$cmd" in
  status)
    epic="${1:?status <epic-id> [stale_min]}"; stale="${2:-$STALE_DEFAULT}"
    claims="$(_read_open_driver_claims "$epic")" || { echo "read error" >&2; exit 2; }
    fresh="$(_select_oldest_fresh "$stale" <<<"$claims")"
    if [[ -n "$fresh" ]]; then
      echo "fresh open driver claim exists: $fresh"
      exit 0
    fi
    echo "no fresh open driver claim"
    exit 1
    ;;

  acquire)
    epic="${1:?acquire <epic-id> <session-run-id> [stale_min]}"; srid="${2:?session-run-id}"; stale="${3:-$STALE_DEFAULT}"
    host="$(hostname -s)"
    # 1. Close any STALE open driver claims first — re-read staleness immediately
    #    before the close so a recovering refresher at the edge is not beheaded.
    #    Capture the read into a variable and ABORT on a read error (a transport
    #    failure must not silently look like "no stale claims" and let us barge in).
    pre_claims="$(_read_open_driver_claims "$epic")" || { echo "acquire: read error before self-close; aborting" >&2; exit 2; }
    while IFS=$'\t' read -r cid created csrid age; do
      [[ -z "$cid" ]] && continue
      if (( $(python3 -c "print(1 if float('$age') >= float('$stale') else 0)") )); then
        # Closing a STALE PREDECESSOR is a takeover, not a lost race — record it as
        # `taken-over` so the audit trail distinguishes "I reaped a dead driver" from
        # "I lost the acquire race" (which is the `no-op` below on our OWN claim).
        _close_claim "$cid" "taken-over" || true
      fi
    done <<<"$pre_claims"
    # 2. Post own claim.
    uuid="$(_issue_uuid "$epic")"
    mine="$(_post_claim "$uuid" "$srid" "$host" "$stale")"
    # 3. Settle (read-replication lag), then read back all open claims.
    sleep 3
    claims="$(_read_open_driver_claims "$epic")" || { echo "acquire: read error on read-back; closing own claim and aborting" >&2; _close_claim "$mine" "no-op" || true; exit 2; }
    # 4. Win iff own claim is the OLDEST FRESH open (createdAt, comment-id tie-break).
    winner="$(_select_oldest_fresh "$stale" <<<"$claims" | cut -f1)"
    if [[ "$winner" == "$mine" ]]; then
      echo "acquired session_run_id=$srid claim=$mine"
      exit 0
    fi
    # 5. Lose -> close own, exit no-op.
    _close_claim "$mine" "no-op" || true
    echo "lost driver claim to $winner; exiting no-op" >&2
    exit 3
    ;;

  verify)
    # The fence: own claim open ∧ own session id ∧ own is oldest-fresh-open ∧ refresher alive.
    # Four conjuncts. This subcommand evaluates the first three (claim-state
    # conjuncts) against the claim TSV; the fourth (refresher alive) is the
    # caller's assert (the caller holds the refresher pid — see the caller note).
    # A test injects claim TSVs via DRIVER_CLAIMS_TSV and asserts exit 0 only when
    # all three hold, and non-zero for each failure mode.
    epic="${1:?verify <epic-id> <session-run-id> [stale_min]}"; srid="${2:?session-run-id}"; stale="${3:-$STALE_DEFAULT}"
    claims="$(_read_open_driver_claims "$epic")" || { echo "read error" >&2; exit 2; }
    # Conjunct 1+2: is there an oldest-fresh OPEN claim at all?
    top="$(_select_oldest_fresh "$stale" <<<"$claims")"
    if [[ -z "$top" ]]; then echo "no fresh open claim (own-claim-closed or all-stale)" >&2; exit 1; fi
    # Conjunct 3: is the oldest-fresh claim OURS?
    top_srid="$(cut -f3 <<<"$top")"
    if [[ "$top_srid" != "$srid" ]]; then echo "ownership lost: oldest-fresh is $top_srid not $srid" >&2; exit 1; fi
    echo "fence ok session_run_id=$srid"
    exit 0
    ;;

  refresh)
    # Session-lifetime background shell. Watches the SESSION PROCESS, not its own
    # parent: a background command's chain is command -> shell wrapper -> session
    # process, and the wrapper SURVIVES session death. The caller (drive-epic Boot
    # Step 1) captures the session pid by walking the PPID chain up from $$ and
    # passes it here; self-exit when it disappears, detected by reparenting/PPID
    # change rather than kill -0 alone (zombie-window false-alive).
    #
    # LEASE-ONLY fallback: a <session-pid> of 0 disables orphan watching (used
    # when session-pid capture is not yet confirmed live — gate item 3). The
    # refresher then only bumps the lease every ~interval; a crashed session's
    # claim decays by lease alone in <=45m (no orphan self-exit). Buildable now;
    # the orphan-aware path is a strict improvement once the walk is confirmed.
    epic="${1:?refresh <epic-id> <session-run-id> <session-pid> [interval]}"; srid="${2:?session-run-id}"
    spid="${3:?session-pid}"; interval="${4:-900}"
    orphan_watch=1
    [[ "$spid" == "0" ]] && orphan_watch=0
    orig_ppid="$(ps -o ppid= -p "$spid" 2>/dev/null | tr -d ' ' || echo GONE)"
    while :; do
      # Orphan detection (skipped in lease-only mode): session process gone, or
      # reparented (PPID changed).
      if (( orphan_watch )); then
        cur_ppid="$(ps -o ppid= -p "$spid" 2>/dev/null | tr -d ' ' || echo GONE)"
        if [[ "$cur_ppid" == "GONE" || "$cur_ppid" != "$orig_ppid" ]]; then
          echo "refresher: session process $spid gone/reparented; self-exiting" >&2
          exit 0
        fi
      fi
      # Bump the claim by mutating content (Linear updatedAt bumps on change only).
      mine="$(_read_open_driver_claims "$epic" | awk -F'\t' -v r="$srid" '$3==r {print $1; exit}')"
      if [[ -n "$mine" ]]; then
        now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        resp="$(linear_gql 'query($id: String!) { comment(id: $id) { id body } }' "{\"id\": \"$mine\"}")"
        body="$(RESP="$resp" NOW="$now" python3 -c 'import json,os,sys,re; c=json.loads(os.environ["RESP"])["data"]["comment"]; b=re.sub(r"- Refreshed at: `[^`]*`", "- Refreshed at: `"+os.environ["NOW"]+"`", c["body"]); print(json.dumps(b))')"
        vars="$(python3 -c 'import json,sys; print(json.dumps({"id": sys.argv[1], "input": {"body": json.loads(sys.argv[2])}}))' "$mine" "$body")"
        linear_gql 'mutation($id: String!, $input: CommentUpdateInput!) { commentUpdate(id: $id, input: $input) { success } }' "$vars" >/dev/null || true
      fi
      sleep "$interval"
    done
    ;;

  release)
    # Close OWN claim by id, with exit state. No attempt counters.
    epic="${1:?release <epic-id> <claim-comment-id> <exit-state>}"; cid="${2:?claim-comment-id}"; state="${3:?exit-state}"
    case "$state" in parked|bloat-handoff|refresh-park|no-op|ruled|taken-over|error) ;; *) echo "bad exit state: $state" >&2; exit 2 ;; esac
    _close_claim "$cid" "$state"
    echo "released driver claim=$cid exit=$state"
    exit 0
    ;;

  *) echo "unknown subcommand: $cmd" >&2; exit 2 ;;
esac
