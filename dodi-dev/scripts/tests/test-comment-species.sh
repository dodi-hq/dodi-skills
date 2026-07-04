#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../comment-species.sh"

fail=0
assert() { # $1=expected $2=body $3=label
  local got; got="$(comment_species "$2")"
  if [[ "$got" != "$1" ]]; then echo "FAIL $3: expected $1 got $got" >&2; fail=1; fi
}

assert progress    $'# Decision Register Entry\n\nChild: `X`' register-entry
assert progress    $'# Lane Checkpoint\n\nTicket: `X`'       lane-checkpoint
assert bookkeeping  $'# Ticket Claim\n\nTicket: `X`'          ticket-claim
assert bookkeeping  $'# Driver Claim\n\nEpic: `X`'            driver-claim
assert bookkeeping  '# Continuation Brief'                    continuation-brief
assert bookkeeping  'heartbeat 2026-07-04T00:00:00Z host=h driver alive' heartbeat
assert bookkeeping  '# Some Novel Header Nobody Registered'   unknown-default
assert bookkeeping  '# Epic Assessment'                       epic-assessment
assert bookkeeping  '# Deploy Confirmation'                   deploy-confirmation
# Announcement headers are bookkeeping — state/label changes come from history,
# not these comments, so they must not reset a staleness clock (B1).
assert bookkeeping  '# Spec Ready'                            spec-ready-announce
assert bookkeeping  '# Ready To Implement'                    ready-to-implement-announce
assert bookkeeping  '# Child PR Ready'                        child-pr-ready-announce
assert bookkeeping  '# Epic PR Ready'                         epic-pr-ready-announce

if (( fail )); then echo "comment-species tests FAILED" >&2; exit 1; fi
echo "comment-species tests ok"
