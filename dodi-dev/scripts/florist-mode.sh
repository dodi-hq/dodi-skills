#!/usr/bin/env bash
# Mechanical Florist mode detection (epic-orchestrator/florist-worker-contract.md § 1).
# Every seat-holding skill (mature-ticket, implement-ticket, review) runs this as
# its FIRST Bash step, in both modes. It prints one machine line, then the
# instruction the session must follow. It never guesses: the environment
# variable IS the mode.
#
#   mode=manual                          -> a human invoked the skill; manual process
#   mode=autonomous unit=… lane=… …      -> the Florist kernel dispatched this session
#
# Exit 0 in both modes. Exit 3 only when FLORIST_UNIT is set but the kernel's
# required companions are missing — a misdispatch, which the session must
# report as `blocked reason=worker-blocked` through florist-digest.sh.
set -euo pipefail

if [[ -z "${FLORIST_UNIT:-}" ]]; then
  echo "mode=manual"
  echo "FLORIST_UNIT is unset: a human invoked this skill and is present to answer it. The manual process applies. Never emit a FLORIST-STATUS or FLORIST-EVIDENCE line in this mode."
  exit 0
fi

missing=()
for v in FLORIST_LANE FLORIST_ATTEMPT FLORIST_TIER FLORIST_FABLE_POLICY FLORIST_EPIC_BRANCH; do
  [[ -n "${!v:-}" ]] || missing+=("$v")
done
linear_key="present"
[[ -n "${LINEAR_API_KEY:-}" ]] || linear_key="ABSENT"

printf 'mode=autonomous unit=%s lane=%s attempt=%s tier=%s fable_policy=%s epic_tier=%s delivery_tier=%s needs_human_spec=%s epic_branch=%s linear_key=%s\n' \
  "$FLORIST_UNIT" "${FLORIST_LANE:-?}" "${FLORIST_ATTEMPT:-?}" "${FLORIST_TIER:-?}" \
  "${FLORIST_FABLE_POLICY:-?}" "${FLORIST_EPIC_TIER:-unset}" "${FLORIST_DELIVERY_TIER:-unset}" \
  "${FLORIST_NEEDS_HUMAN_SPEC:-0}" "${FLORIST_EPIC_BRANCH:-?}" "$linear_key"

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cat <<MSG
AUTONOMOUS MODE — the Florist kernel dispatched this session for lane '${FLORIST_LANE:-?}' of unit ${FLORIST_UNIT}. There is no human to answer you.
1. Read ${root}/skills/epic-orchestrator/florist-worker-contract.md NOW, before any other step.
2. Only this skill's Florist seat section for FLORIST_LANE='${FLORIST_LANE:-?}' applies. The manual process tables, checkpoints, and close-out vocabulary (e.g. 'ready-to-merge-child', 'Review Summary') do NOT apply and must not be your last output.
3. Close by running ${root}/scripts/florist-digest.sh — its output must be the LAST thing this session prints. A wall is 'blocked reason=<id>' or 'declined reason=<id>' through the same script. Never exit without a digest.
MSG

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "MISDISPATCH: FLORIST_UNIT is set but the kernel's required variables are missing: ${missing[*]}. Report it: florist-digest.sh blocked reason=worker-blocked" >&2
  exit 3
fi
if [[ "$linear_key" == "ABSENT" ]]; then
  echo "LINEAR_API_KEY is absent: the deployment issued no worker tracker credential. Per the contract § 2 this is a concrete blocker — florist-digest.sh blocked reason=worker-blocked — never an improvised read path." >&2
fi
