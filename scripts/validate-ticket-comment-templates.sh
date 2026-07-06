#!/usr/bin/env bash
set -euo pipefail

check_heading() {
  local file="$1"
  local heading="$2"
  grep -q "^## ${heading}$" "$file"
}

check_contains() {
  local file="$1"
  local text="$2"
  grep -qF -- "$text" "$file"
}

check_count_at_least() {
  local file="$1"
  local text="$2"
  local minimum="$3"
  local count
  count="$(grep -cF -- "$text" "$file" || true)"
  if (( count < minimum )); then
    echo "${file}: expected at least ${minimum} occurrences of ${text}, found ${count}" >&2
    exit 1
  fi
}

for file in epic-assessment spec-ready ready-to-implement demotion child-pr-ready epic-pr-ready epic-signoff-request claim deploy-confirmation decision-register-entry driver-claim continuation-brief lane-checkpoint; do
  test -f "templates/ticket-comments/${file}.md"
done

check_heading templates/ticket-comments/epic-assessment.md "Child Ticket State Map"
check_heading templates/ticket-comments/epic-assessment.md "Ready Work"
check_heading templates/ticket-comments/epic-assessment.md "Maturity Work"
check_heading templates/ticket-comments/epic-assessment.md "Blockers"

check_heading templates/ticket-comments/spec-ready.md "Spec Artifact"
check_heading templates/ticket-comments/spec-ready.md "Review Evidence"
check_heading templates/ticket-comments/spec-ready.md "Human Signoff"
check_heading templates/ticket-comments/spec-ready.md "Assumptions"
check_heading templates/ticket-comments/spec-ready.md "Next Action"

check_heading templates/ticket-comments/ready-to-implement.md "Spec Artifact"
check_heading templates/ticket-comments/ready-to-implement.md "Plan Artifact"
check_heading templates/ticket-comments/ready-to-implement.md "Testing Contract"
check_heading templates/ticket-comments/ready-to-implement.md "Dependency State"
check_heading templates/ticket-comments/ready-to-implement.md "Review Evidence"
check_heading templates/ticket-comments/ready-to-implement.md "Next Action"
check_contains templates/ticket-comments/ready-to-implement.md "### Required Test Groups"
check_contains templates/ticket-comments/ready-to-implement.md "- Unit: \`<required|not-required>\`"
check_contains templates/ticket-comments/ready-to-implement.md "Scope: \`<functions/components/modules>\`"
check_contains templates/ticket-comments/ready-to-implement.md "Reason: \`<why>\`"
check_contains templates/ticket-comments/ready-to-implement.md "Minimum assertions: \`<specific behaviors>\`"
check_contains templates/ticket-comments/ready-to-implement.md "- Integration: \`<required|not-required>\`"
check_contains templates/ticket-comments/ready-to-implement.md "Scope: \`<module boundaries/APIs/db/jobs/etc>\`"
check_contains templates/ticket-comments/ready-to-implement.md "Harness: \`<existing|setup-required|not-applicable>\`"
check_contains templates/ticket-comments/ready-to-implement.md "Minimum assertions: \`<specific flows>\`"
check_contains templates/ticket-comments/ready-to-implement.md "- E2E: \`<required|not-required>\`"
check_contains templates/ticket-comments/ready-to-implement.md "Scope: \`<user/business-critical flows>\`"
check_contains templates/ticket-comments/ready-to-implement.md "### Critical Flows"
check_contains templates/ticket-comments/ready-to-implement.md "- \`<flow 1>\`"
check_contains templates/ticket-comments/ready-to-implement.md "- \`<flow 2>\`"
check_contains templates/ticket-comments/ready-to-implement.md "### Regression Surface"
check_contains templates/ticket-comments/ready-to-implement.md "- \`<adjacent module or behavior that must not break>\`"
check_contains templates/ticket-comments/ready-to-implement.md "### Commands"
check_contains templates/ticket-comments/ready-to-implement.md "- Unit: \`<command or to-be-discovered>\`"
check_contains templates/ticket-comments/ready-to-implement.md "- Integration: \`<command or to-be-discovered>\`"
check_contains templates/ticket-comments/ready-to-implement.md "- E2E: \`<command or to-be-discovered>\`"
check_contains templates/ticket-comments/ready-to-implement.md "- Broader regression: \`<command or to-be-discovered>\`"
check_contains templates/ticket-comments/ready-to-implement.md "### Harness Requirements"
check_contains templates/ticket-comments/ready-to-implement.md "- \`<required setup, service, fixture, seed data, browser, env var, mock, account, etc>\`"
check_contains templates/ticket-comments/ready-to-implement.md "### Non-Required Rationale"
check_contains templates/ticket-comments/ready-to-implement.md "- Unit: \`<only if not-required>\`"
check_contains templates/ticket-comments/ready-to-implement.md "- Integration: \`<only if not-required>\`"
check_contains templates/ticket-comments/ready-to-implement.md "- E2E: \`<only if not-required>\`"
check_contains templates/ticket-comments/ready-to-implement.md "### Verification Rules"
check_contains templates/ticket-comments/ready-to-implement.md "Missing harness is not a skip reason; set it up or report a concrete blocker."
check_contains templates/ticket-comments/ready-to-implement.md "If a test failure exposes an implementation issue, fix the implementation, not the test."
check_contains templates/ticket-comments/ready-to-implement.md "If testing exposes a spec or plan mismatch, demote the ticket to the spec lane."
check_count_at_least templates/ticket-comments/ready-to-implement.md "Reason: \`<why>\`" 3
check_count_at_least templates/ticket-comments/ready-to-implement.md "Harness: \`<existing|setup-required|not-applicable>\`" 2
check_count_at_least templates/ticket-comments/ready-to-implement.md "Minimum assertions: \`<specific flows>\`" 2

check_heading templates/ticket-comments/demotion.md "Current State"
check_heading templates/ticket-comments/demotion.md "Demotion Target"
check_heading templates/ticket-comments/demotion.md "Triggering Evidence"
check_heading templates/ticket-comments/demotion.md "Why Automation Cannot Continue"
check_heading templates/ticket-comments/demotion.md "Human Question"
check_heading templates/ticket-comments/demotion.md "Artifacts To Revise"

check_heading templates/ticket-comments/child-pr-ready.md "Branches"
check_heading templates/ticket-comments/child-pr-ready.md "Evidence"
check_heading templates/ticket-comments/child-pr-ready.md "Local Checks"
check_heading templates/ticket-comments/child-pr-ready.md "Next Action"

check_heading templates/ticket-comments/epic-pr-ready.md "TL;DR"
check_heading templates/ticket-comments/epic-pr-ready.md "Key Points"
check_heading templates/ticket-comments/epic-pr-ready.md "Completed Children"
check_heading templates/ticket-comments/epic-pr-ready.md "Child PR Links"
check_heading templates/ticket-comments/epic-pr-ready.md "Integrated-Head Review Evidence"
check_heading templates/ticket-comments/epic-pr-ready.md "Known Risks"
check_heading templates/ticket-comments/epic-pr-ready.md "Migrations Or Release Notes"
check_heading templates/ticket-comments/epic-pr-ready.md "Test Coverage Summary"

check_heading templates/ticket-comments/epic-signoff-request.md "TL;DR"
check_heading templates/ticket-comments/epic-signoff-request.md "Key Points"
check_heading templates/ticket-comments/epic-signoff-request.md "Children"
check_heading templates/ticket-comments/epic-signoff-request.md "Needs Human Input"
check_heading templates/ticket-comments/epic-signoff-request.md "On Approval"

check_heading templates/ticket-comments/claim.md "Claim"
check_heading templates/ticket-comments/claim.md "Attempt"
check_heading templates/ticket-comments/claim.md "Exit"
check_contains templates/ticket-comments/claim.md "Consecutive attempt:"
check_contains templates/ticket-comments/claim.md "Lease window:"

check_heading templates/ticket-comments/deploy-confirmation.md "Deployment"
check_heading templates/ticket-comments/deploy-confirmation.md "Tickets Updated"
check_heading templates/ticket-comments/deploy-confirmation.md "Cleanup"
check_contains templates/ticket-comments/deploy-confirmation.md "verified merged by SHA reachability"

check_heading templates/ticket-comments/epic-pr-ready.md "What Changed Since Signoff"

check_heading templates/ticket-comments/decision-register-entry.md "Verdict"
check_heading templates/ticket-comments/decision-register-entry.md "Decisions Recorded"
check_heading templates/ticket-comments/decision-register-entry.md "Affected Children"
check_heading templates/ticket-comments/decision-register-entry.md "Supersedes"
check_heading templates/ticket-comments/decision-register-entry.md "Canon Summary"
check_contains templates/ticket-comments/decision-register-entry.md "Merge SHA:"

check_heading templates/ticket-comments/driver-claim.md "Claim"
check_heading templates/ticket-comments/driver-claim.md "Exit"
check_contains templates/ticket-comments/driver-claim.md "Session run id:"

check_heading templates/ticket-comments/continuation-brief.md "State Map Reference"
check_heading templates/ticket-comments/continuation-brief.md "Chosen Next Action"
check_heading templates/ticket-comments/continuation-brief.md "In Flight (must not be redone)"

check_heading templates/ticket-comments/lane-checkpoint.md "Session"
check_heading templates/ticket-comments/lane-checkpoint.md "Evidence"
check_contains templates/ticket-comments/lane-checkpoint.md "Run id:"

# claim.md session-id + coherence-review enum
check_contains templates/ticket-comments/claim.md "Session run id:"
check_contains templates/ticket-comments/claim.md "coherence-review"

# decision-register-entry.md new fields + RULING variant
check_contains templates/ticket-comments/decision-register-entry.md "Run id:"
check_heading templates/ticket-comments/decision-register-entry.md "Held Route (GATE1_AMENDMENT only — the not-yet-performed writes the approve branch executes)"
check_heading templates/ticket-comments/decision-register-entry.md "Per-Decision Affected Children (GATE1_REFRESH only — which children's specs consumed EACH superseded decision)"
check_heading templates/ticket-comments/decision-register-entry.md "Ruling (RULING variant only — the durable resolution record for a pending-human entry)"
check_contains templates/ticket-comments/decision-register-entry.md "RULING"

echo "ticket comment templates ok"
