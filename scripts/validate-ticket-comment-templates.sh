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

for file in epic-assessment spec-ready ready-to-implement demotion child-pr-ready epic-pr-ready; do
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

check_heading templates/ticket-comments/epic-pr-ready.md "Completed Children"
check_heading templates/ticket-comments/epic-pr-ready.md "Child PR Links"
check_heading templates/ticket-comments/epic-pr-ready.md "Quality Gate Evidence"
check_heading templates/ticket-comments/epic-pr-ready.md "Known Risks"
check_heading templates/ticket-comments/epic-pr-ready.md "Migrations Or Release Notes"
check_heading templates/ticket-comments/epic-pr-ready.md "Test Coverage Summary"

echo "ticket comment templates ok"
