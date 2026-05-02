#!/usr/bin/env bash
set -euo pipefail

skills=(
  brainstorm
  file-ticket
  implement
  pickup
  quality-gate
  review
  submit
  verify
  write-plan
  epic-orchestrator
  pickup-epic
  assess-epic
  mature-ticket
  pickup-ticket
  implement-ticket
  review-implementation
  create-tests
  review-child-pr
  submit-ticket-pr
  submit-epic-pr
)

for skill in "${skills[@]}"; do
  test -f "dodi-dev/skills/${skill}/SKILL.md"
  test -f "plugins/dodi-dev/skills/${skill}/SKILL.md"
done

testing_contract_checks=(
  "### Required Test Groups"
  "- Unit: \`<required|not-required>\`"
  "Scope: \`<functions/components/modules>\`"
  "Reason: \`<why>\`"
  "Minimum assertions: \`<specific behaviors>\`"
  "- Integration: \`<required|not-required>\`"
  "Scope: \`<module boundaries/APIs/db/jobs/etc>\`"
  "Harness: \`<existing|setup-required|not-applicable>\`"
  "Minimum assertions: \`<specific flows>\`"
  "- E2E: \`<required|not-required>\`"
  "Scope: \`<user/business-critical flows>\`"
  "### Critical Flows"
  "- \`<flow 1>\`"
  "- \`<flow 2>\`"
  "### Regression Surface"
  "- \`<adjacent module or behavior that must not break>\`"
  "### Commands"
  "- Unit: \`<command or to-be-discovered>\`"
  "- Integration: \`<command or to-be-discovered>\`"
  "- E2E: \`<command or to-be-discovered>\`"
  "- Broader regression: \`<command or to-be-discovered>\`"
  "### Harness Requirements"
  "- \`<required setup, service, fixture, seed data, browser, env var, mock, account, etc>\`"
  "### Non-Required Rationale"
  "- Unit: \`<only if not-required>\`"
  "- Integration: \`<only if not-required>\`"
  "- E2E: \`<only if not-required>\`"
  "### Verification Rules"
  "Missing harness is not a skip reason; set it up or report a concrete blocker."
  "If a test failure exposes an implementation issue, fix the implementation, not the test."
  "If testing exposes a spec or plan mismatch, demote the ticket to the spec lane."
)

check_count_at_least() {
  local file="$1"
  local text="$2"
  local minimum="$3"
  local count
  count="$(rg --fixed-strings --count -- "$text" "$file" || true)"
  if (( count < minimum )); then
    echo "${file}: expected at least ${minimum} occurrences of ${text}, found ${count}" >&2
    exit 1
  fi
}

for file in dodi-dev/skills/write-plan/SKILL.md plugins/dodi-dev/skills/write-plan/SKILL.md; do
  rg -n "^## Testing Contract$" "$file" >/dev/null
  for expected in "${testing_contract_checks[@]}"; do
    rg -n --fixed-strings -- "$expected" "$file" >/dev/null
  done
  check_count_at_least "$file" "Reason: \`<why>\`" 3
  check_count_at_least "$file" "Harness: \`<existing|setup-required|not-applicable>\`" 2
  check_count_at_least "$file" "Minimum assertions: \`<specific flows>\`" 2
done

find plugins/dodi-dev/skills -type l -print | while read -r link; do
  echo "unexpected symlink: ${link}" >&2
  exit 1
done
find dodi-dev/skills -type l -print | while read -r link; do
  echo "unexpected symlink: ${link}" >&2
  exit 1
done
find dodi-dev/skills plugins/dodi-dev/skills -maxdepth 2 -type f | sort

echo "phase skills ok"
