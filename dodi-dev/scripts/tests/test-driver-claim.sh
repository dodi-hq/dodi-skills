#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DC="$HERE/../driver-claim.sh"

# status/verify are network-free once DRIVER_CLAIMS_TSV is set (no mutation), so
# we invoke the REAL subcommands as subprocesses and assert on their exit codes /
# output — this exercises the real _select_oldest_fresh selection and the real
# conjunct evaluation, not a copy. acquire mutates, so it is driven below with a
# stubbed linear_gql (the network boundary) while its real case block runs.

# Fixture: three open claims — one stale (60m), two fresh (20m, 5m).
# Oldest-fresh (by createdAt order, already sorted) is c2/sridB.
export DRIVER_CLAIMS_TSV=$'c1\t2026-07-04T00:00:00Z\tsridA\t60.0\nc2\t2026-07-04T00:05:00Z\tsridB\t20.0\nc3\t2026-07-04T00:06:00Z\tsridC\t5.0'

run() { # subcommand + args; captures rc, ignoring stderr
  set +e; out="$(bash "$DC" "$@" 2>/dev/null)"; rc=$?; set -e
}

# status: a fresh open claim exists -> exit 0, names the oldest-fresh row.
run status EPIC
[[ "$rc" -eq 0 ]] || { echo "FAIL status-fresh: expected exit 0 got $rc" >&2; exit 1; }
grep -q 'sridB' <<<"$out" || { echo "FAIL status-fresh: expected oldest-fresh sridB, got: $out" >&2; exit 1; }

# verify as sridB (the oldest-fresh owner) -> fence ok, exit 0 (own-claim-open ∧ own-session ∧ oldest-fresh).
run verify EPIC sridB
[[ "$rc" -eq 0 ]] || { echo "FAIL verify-owner: expected exit 0 for sridB got $rc ($out)" >&2; exit 1; }

# verify as sridC (fresh but NOT oldest) -> ownership lost, non-zero (not-oldest conjunct).
run verify EPIC sridC
[[ "$rc" -ne 0 ]] || { echo "FAIL verify-not-oldest: expected non-zero for sridC" >&2; exit 1; }

# verify as a foreign session with no claim at all -> non-zero (foreign-oldest / ownership lost).
run verify EPIC sridZZZ
[[ "$rc" -ne 0 ]] || { echo "FAIL verify-foreign: expected non-zero for sridZZZ" >&2; exit 1; }

# All-stale (own claim effectively closed / decayed) -> no fresh open claim.
# verify -> non-zero (own-claim-closed conjunct); status -> exit 1.
export DRIVER_CLAIMS_TSV=$'c1\t2026-07-04T00:00:00Z\tsridB\t60.0'
run verify EPIC sridB
[[ "$rc" -ne 0 ]] || { echo "FAIL verify-own-closed: expected non-zero when own claim is stale" >&2; exit 1; }

run status EPIC
[[ "$rc" -eq 1 ]] || { echo "FAIL status-none: expected exit 1 when no fresh claim, got $rc" >&2; exit 1; }

# acquire-loses: own claim posts behind an already-fresh foreign claim.
# Stub ONLY the network boundary (linear_gql) and sleep; the real acquire case
# block, the real _issue_uuid/_post_claim/_close_claim, and the real
# _select_oldest_fresh all run. driver-claim.sh source-guards linear-api.sh
# (`declare -F linear_gql`), so our stub survives the source. The stubbed
# linear_gql returns whatever the parse steps need: a uuid for _issue_uuid and a
# new comment id ("m1") for _post_claim's commentCreate parse; the read-back
# comes from DRIVER_CLAIMS_TSV (a fresh `foreign` ordered before `mine`), so
# winner=foreign != mine and acquire exits 3.
acq_rc="$(
  set +e
  bash -c '
    set -euo pipefail
    linear_gql() {
      # Respond to whatever mutation/query the acquire path issues offline.
      case "$1" in
        *issue*id*) echo "{\"data\":{\"issue\":{\"id\":\"uuid-EPIC\"}}}" ;;
        *commentCreate*) echo "{\"data\":{\"commentCreate\":{\"comment\":{\"id\":\"m1\"}}}}" ;;
        *comment*body*) echo "{\"data\":{\"comment\":{\"id\":\"m1\",\"body\":\"# Driver Claim\n- Exit state: \`open\`\n- Released at: \`<pending>\`\"}}}" ;;
        *commentUpdate*) echo "{\"data\":{\"commentUpdate\":{\"success\":true}}}" ;;
        *) echo "{\"data\":{}}" ;;
      esac
    }
    export -f linear_gql
    sleep() { :; }                 # skip the settle
    export DRIVER_CLAIMS_TSV=$'"'"'f1\t2026-07-04T00:00:00Z\tforeign\t3.0\nm1\t2026-07-04T00:10:00Z\tmine\t0.0'"'"'
    bash "'"$DC"'" acquire EPIC mine 45
  ' >/dev/null 2>&1
  echo $?
)"
[[ "$acq_rc" -eq 3 ]] || { echo "FAIL acquire-loses: expected exit 3, got $acq_rc" >&2; exit 1; }

# acquire-wins: on read-back, own claim ("m1"/mine) is the oldest-fresh open with
# NO fresher foreign claim ahead of it — same stubbed network boundary as the lose
# case, but the read-back TSV names only `mine`, so winner==mine and acquire exits 0
# printing `acquired session_run_id=mine`. Testing-Contract Minimum assertion:
# "acquire on an epic with no open driver claim wins and prints the run id."
set +e
acq_win_out="$(
  bash -c '
    set -euo pipefail
    linear_gql() {
      case "$1" in
        *issue*id*) echo "{\"data\":{\"issue\":{\"id\":\"uuid-EPIC\"}}}" ;;
        *commentCreate*) echo "{\"data\":{\"commentCreate\":{\"comment\":{\"id\":\"m1\"}}}}" ;;
        *comment*body*) echo "{\"data\":{\"comment\":{\"id\":\"m1\",\"body\":\"# Driver Claim\n- Exit state: \`open\`\n- Released at: \`<pending>\`\"}}}" ;;
        *commentUpdate*) echo "{\"data\":{\"commentUpdate\":{\"success\":true}}}" ;;
        *) echo "{\"data\":{}}" ;;
      esac
    }
    export -f linear_gql
    sleep() { :; }                 # skip the settle
    # Read-back: only our own claim is open and fresh -> winner==mine.
    export DRIVER_CLAIMS_TSV=$'"'"'m1\t2026-07-04T00:10:00Z\tmine\t0.0'"'"'
    bash "'"$DC"'" acquire EPIC mine 45
  ' 2>/dev/null
)"
acq_win_rc=$?
set -e
[[ "$acq_win_rc" -eq 0 ]] || { echo "FAIL acquire-wins: expected exit 0, got $acq_win_rc" >&2; exit 1; }
grep -q 'acquired session_run_id=mine' <<<"$acq_win_out" || { echo "FAIL acquire-wins: expected 'acquired session_run_id=mine', got: $acq_win_out" >&2; exit 1; }

# release enum guard: a bogus exit state is rejected by the case block before any
# network write (network-free — the reject happens ahead of _close_claim).
run release EPIC c1 not-a-state
[[ "$rc" -eq 2 ]] || { echo "FAIL release-bad-state: expected exit 2 for a bogus exit state, got $rc" >&2; exit 1; }

# release accepts refresh-park (the planned context-refresh exit state added in
# 0.16.0) — stub the network boundary (_close_claim's comment query + commentUpdate)
# exactly as the acquire cases do, and assert the release goes through.
set +e
rel_out="$(
  bash -c '
    set -euo pipefail
    linear_gql() {
      case "$1" in
        *commentUpdate*) echo "{\"data\":{\"commentUpdate\":{\"success\":true}}}" ;;
        *comment*body*) echo "{\"data\":{\"comment\":{\"id\":\"c1\",\"body\":\"# Driver Claim\n- Exit state: \`open\`\n- Released at: \`<pending>\`\"}}}" ;;
        *) echo "{\"data\":{}}" ;;
      esac
    }
    export -f linear_gql
    bash "'"$DC"'" release EPIC c1 refresh-park
  ' 2>/dev/null
)"
rel_rc=$?
set -e
[[ "$rel_rc" -eq 0 ]] || { echo "FAIL release-refresh-park: expected exit 0, got $rel_rc" >&2; exit 1; }
grep -q 'exit=refresh-park' <<<"$rel_out" || { echo "FAIL release-refresh-park: expected 'exit=refresh-park', got: $rel_out" >&2; exit 1; }

echo "driver-claim tests ok"
