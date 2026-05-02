#!/usr/bin/env bash
set -euo pipefail

check_heading() {
  local file="$1"
  local heading="$2"
  rg -n "^## ${heading}$" "$file" >/dev/null
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
