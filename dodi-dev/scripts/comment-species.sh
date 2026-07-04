#!/usr/bin/env bash
# Canonical tagged progress/bookkeeping partition for ticket-comment species.
# Sourced by claim.sh, release-claim.sh, watchdog-scan.sh; consumed by the
# guard probe and the janitor through the species-aware watchdog scan.
#
# One partition, one home. Repo-root templates/ is a validation mirror the
# target-repo worktree never sees, so this table lives inside the plugin.
#
# progress   = the ONLY two comment species that count as real work for the
#              wedged-driver probe and liveness tests: lane checkpoints and
#              decision-register entries (incl. the RULING variant, same header).
#              State/label transitions are NOT announced here — they are read
#              from issue HISTORY — so ready-to-implement / spec-ready / PR-ready
#              announcement comments are bookkeeping, not progress.
# bookkeeping = everything else — timer/bureaucratic/announcement writes that
#              must NOT reset a staleness clock: claims (both species),
#              heartbeats, takeover/janitor notes, continuation briefs,
#              assessments, deploy confirmations, and all the state-announcement
#              headers (spec-ready, ready-to-implement, child/epic-PR-ready).
#
# Usage (as a library):  source comment-species.sh; comment_species "<body-or-first-line>"
# Usage (as a CLI, for tests): comment-species.sh <<<"<body>"   -> prints the species
#
# Classification is header-based: the comment's first non-empty line. A raw
# heartbeat line (no markdown header) is carved out explicitly. Any header not
# in the table defaults to bookkeeping — never progress — so a novel comment
# species can mask neither a wedge nor a claim theft.
set -euo pipefail

comment_species() {
  # $1 = the comment body (or its first line). Returns via stdout.
  local body="$1"
  local first
  # First non-empty line.
  first="$(printf '%s\n' "$body" | sed -n '/[^[:space:]]/{p;q;}')"

  # Heartbeat carve-out: the heartbeat.sh line is not a markdown header.
  case "$first" in
    heartbeat\ *) echo bookkeeping; return 0 ;;
  esac

  case "$first" in
    # --- progress species (real work advances) ---
    # ONLY lane checkpoints and decision-register entries (incl. the RULING
    # variant, same header). State/label changes are detected from issue
    # HISTORY, not from announcement comments — so spec-ready / ready-to-implement
    # / child-pr-ready / epic-pr-ready are announcements, not progress: they fall
    # to bookkeeping below (listed explicitly for auditability).
    '# Decision Register Entry'*) echo progress ;;
    '# Lane Checkpoint'*)         echo progress ;;
    # --- bookkeeping species (timers / bureaucracy / announcements) ---
    '# Ticket Claim'*)            echo bookkeeping ;;
    '# Driver Claim'*)            echo bookkeeping ;;
    '# Continuation Brief'*)      echo bookkeeping ;;
    '# Epic Assessment'*)         echo bookkeeping ;;
    '# Deploy Confirmation'*)     echo bookkeeping ;;
    '# Workflow Demotion'*)       echo bookkeeping ;;
    '# Spec Ready'*)              echo bookkeeping ;;
    '# Ready To Implement'*)      echo bookkeeping ;;
    '# Child PR Ready'*)          echo bookkeeping ;;
    '# Epic PR Ready'*)           echo bookkeeping ;;
    '# Epic Signoff Request'*)    echo bookkeeping ;;
    # --- default: unknown header -> bookkeeping (never progress) ---
    *)                            echo bookkeeping ;;
  esac
}

# CLI mode for tests: read a body on stdin, print the species.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  comment_species "$(cat)"
fi
