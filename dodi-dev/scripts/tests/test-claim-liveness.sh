#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CLAIM="$HERE/../claim.sh"
RELEASE="$HERE/../release-claim.sh"
bash -n "$CLAIM"; bash -n "$RELEASE"

lease=2
# classify args: <cstate> <csrid> <srid> <cage_h> <lease_h> <tier1> <tier2>
cl() { bash "$CLAIM" classify "$@"; }

# Tier-1: foreign claim whose session matches a fresh driver claim -> alive.
[[ "$(cl open sridF sridMe 9.9 $lease yes no)" == alive ]] || { echo "FAIL tier-1" >&2; exit 1; }
# Tier-2: foreign, no driver match, fresh progress checkpoint -> alive.
[[ "$(cl open sridF sridMe 9.9 $lease no yes)" == alive ]] || { echo "FAIL tier-2" >&2; exit 1; }
# Tier-3 alive: foreign, no tier-1/tier-2, age < lease -> alive.
[[ "$(cl open sridF sridMe 1.0 $lease no no)" == alive ]] || { echo "FAIL tier-3-alive" >&2; exit 1; }
# Tier-3 claimable: foreign, no tier-1/tier-2, age >= lease -> claimable.
[[ "$(cl open sridF sridMe 3.0 $lease no no)" == claimable ]] || { echo "FAIL tier-3-claimable" >&2; exit 1; }
# Legacy (no srid) fresh -> tier-3 only -> alive (must NOT be silently claimable).
[[ "$(cl open '' sridMe 1.0 $lease no no)" == alive ]] || { echo "FAIL legacy-fresh" >&2; exit 1; }
# Legacy (no srid) stale -> claimable.
[[ "$(cl open '' sridMe 3.0 $lease no no)" == claimable ]] || { echo "FAIL legacy-stale" >&2; exit 1; }
# Own-session open claim -> claimable (never refused; main flow no-ops it).
[[ "$(cl open sridMe sridMe 1.0 $lease no no)" == claimable ]] || { echo "FAIL own-session" >&2; exit 1; }
# Closed claim -> claimable regardless.
[[ "$(cl closed sridF sridMe 0.1 $lease no no)" == claimable ]] || { echo "FAIL closed" >&2; exit 1; }

# --- Full-flow guard assertions with the network + driver-status stubbed. ---
# The ticket.json is built in the OUTER shell with python3 (real newlines from the
# literal \n in $BODY — NOT a nested `bash -c` heredoc, which mangled the newline
# conversion and made every case collapse to an empty csrid, the RB3 defect). A shim
# dir holds a copy of claim.sh + comment-species.sh + a stub linear-api.sh + a stub
# driver-claim.sh so claim.sh's $(dirname "$0")-relative resolution picks up all four
# — the REAL claim.sh guard runs against a controlled read. run_guard returns
# claim.sh's exit code and prints its combined stdout+stderr for discrimination checks.
run_guard() {  # $1 = claim body (with literal \n for line breaks); the session is sridMe
  local body="$1"
  local shim; shim="$(mktemp -d)"
  printf '%s\n' '#!/usr/bin/env bash' 'echo "no fresh open driver claim"; exit 1' >"$shim/driver-claim.sh"
  chmod +x "$shim/driver-claim.sh"
  cp "$CLAIM" "$shim/claim.sh"
  cp "$HERE/../comment-species.sh" "$shim/comment-species.sh"
  cat >"$shim/linear-api.sh" <<EOF
linear_gql() {
  case "\$1" in
    *comments*) cat "$shim/ticket.json" ;;   # the main read (has \`comments\`) — before *parent*
    *parent*)   echo '{"data":{"issue":{"parent":null}}}' ;;
    *commentCreate*) echo '{"data":{"commentCreate":{"comment":{"id":"new"}}}}' ;;
    *) echo '{"data":{}}' ;;
  esac
}
EOF
  BODY="$body" NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)" TJSON="$shim/ticket.json" python3 <<'PY'
import json, os
body = os.environ["BODY"].replace("\\n", "\n")   # turn literal \n into real newlines
doc = {"data": {"issue": {"id": "uuid-T", "parent": None, "comments": {"nodes": [
    {"id": "cc1", "createdAt": "2026-07-04T00:00:00Z",
     "updatedAt": os.environ["NOW"], "body": body}]}}}}
open(os.environ["TJSON"], "w").write(json.dumps(doc))
PY
  local out rc
  set +e
  out="$(bash "$shim/claim.sh" T-1 deliver-ticket sridMe 2 2>&1)"; rc=$?
  set -e
  rm -rf "$shim"
  printf '%s\n' "$out"
  return "$rc"
}

# (1) id-bearing fresh foreign claim -> exit 3, and the log line NAMES the foreign
#     session id — proves the body parsed (csrid resolved, not empty). If the body
#     never converted to real newlines (RB3 bug), csrid would be empty and the log
#     would read <legacy/no-id>, failing this assertion.
set +e
out="$(run_guard '# Ticket Claim\n\nTicket: `T-1`\n\n## Claim\n- Session run id: `sridOTHER`\n\n## Exit\n- Exit state: `<open>`')"
rc=$?; set -e
[[ "$rc" -eq 3 ]] || { echo "FAIL foreign-id exit3: got $rc :: $out" >&2; exit 1; }
grep -q 'session=sridOTHER' <<<"$out" || { echo "FAIL foreign-id discrimination: log must name sridOTHER, got: $out" >&2; exit 1; }

# (2) id-LESS (legacy) fresh foreign claim -> exit 3 (the theft-bug regression guard, B5),
#     distinguished from the id-bearing case by the <legacy/no-id> log token.
set +e
out="$(run_guard '# Ticket Claim\n\nTicket: `T-1`\n\n## Claim\n- Host: `h`\n\n## Exit\n- Exit state: `<open>`')"
rc=$?; set -e
[[ "$rc" -eq 3 ]] || { echo "FAIL legacy foreign exit3 (theft bug): got $rc :: $out" >&2; exit 1; }
grep -q 'session=<legacy/no-id>' <<<"$out" || { echo "FAIL legacy discrimination: got: $out" >&2; exit 1; }

# (3) POSITIVE DISCRIMINATION (RB3): own-session fresh open claim (csrid == srid) -> exit 0
#     no-op, NOT exit 3. If body-parse->csrid is broken (empty), this claim looks
#     legacy-foreign and wrongly exits 3 — this assertion catches that collapse, and
#     also catches a regression that makes the guard refuse its own session.
set +e
out="$(run_guard '# Ticket Claim\n\nTicket: `T-1`\n\n## Claim\n- Session run id: `sridMe`\n\n## Exit\n- Exit state: `<open>`')"
rc=$?; set -e
[[ "$rc" -eq 0 ]] || { echo "FAIL own-session-no-op: expected exit 0, got $rc :: $out" >&2; exit 1; }
grep -q 'already claimed by this session' <<<"$out" || { echo "FAIL own-session-no-op msg: got: $out" >&2; exit 1; }

# --- RB1: release-claim.sh foreign release reaches the mutation (never exit 2) and
#         targets EXACTLY the given claim id. The concrete caller is
#         `release-claim.sh <ticket> released-no-op --foreign <id>` — NO evidence arg;
#         the old `evidence=$3; shift 3` parse swallowed `--foreign` and exited 2 on
#         every takeover. Two open claims (a dead predecessor + a live successor) prove
#         the foreign release closes the id given, not the newest. ---
rel_shim="$(mktemp -d)"
cp "$RELEASE" "$rel_shim/release-claim.sh"
cat >"$rel_shim/ticket.json" <<'EOF'
{"data":{"issue":{"comments":{"nodes":[
  {"id":"cc-dead","body":"# Ticket Claim\n\n## Exit\n- Exit state: `<open>`\n- Evidence: `<pending>`\n- Exited at: `<pending>`"},
  {"id":"cc-live","body":"# Ticket Claim\n\n## Exit\n- Exit state: `<open>`\n- Evidence: `<pending>`\n- Exited at: `<pending>`"}
]}}}}
EOF
python3 - "$rel_shim/ticket.json" <<'PY'
import json, sys
p = sys.argv[1]; doc = json.load(open(p))
for n in doc["data"]["issue"]["comments"]["nodes"]:
    n["body"] = n["body"].replace("\\n", "\n")
json.dump(doc, open(p, "w"))
PY
cat >"$rel_shim/linear-api.sh" <<EOF
UPDATED_TARGET_LOG="$rel_shim/updated-id.log"
linear_gql() {
  case "\$1" in
    *commentUpdate*) echo "\$2" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' >>"\$UPDATED_TARGET_LOG"; echo '{"data":{"commentUpdate":{"success":true}}}' ;;
    *comments*) cat "$rel_shim/ticket.json" ;;
    *) echo '{"data":{}}' ;;
  esac
}
EOF
set +e
rel_out="$(bash "$rel_shim/release-claim.sh" T-1 released-no-op --foreign cc-dead 2>&1)"; rel_rc=$?
set -e
[[ "$rel_rc" -eq 0 ]] || { echo "FAIL foreign-release: expected exit 0 (reaches mutation, not exit 2), got $rel_rc :: $rel_out" >&2; exit 1; }
targeted="$(cat "$rel_shim/updated-id.log" 2>/dev/null || true)"
[[ "$targeted" == "cc-dead" ]] || { echo "FAIL foreign-release target: mutation must target cc-dead, targeted: '$targeted'" >&2; exit 1; }
rm -rf "$rel_shim"

echo "claim liveness tests ok"
