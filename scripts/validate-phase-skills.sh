#!/usr/bin/env bash
set -euo pipefail

skills=(
  brainstorm
  file-ticket
  implement
  pickup
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
  create-tests
  submit-ticket-pr
  deliver-ticket
  submit-epic-pr
  reconcile-tickets
  drive-epic
)

for skill in "${skills[@]}"; do
  test -f "dodi-dev/skills/${skill}/SKILL.md"
done

prompt_files=(
  brainstorm/spec-reviewer-prompt.md
  implement/implementer-prompt.md
  review/review-prompt.md
  review/child-pr-integration-prompt.md
  write-plan/plan-reviewer-prompt.md
  write-plan/plan-writer-prompt.md
  epic-orchestrator/state-reader-prompt.md
  epic-orchestrator/evidence-checker-prompt.md
  epic-orchestrator/state-transitions.md
  epic-orchestrator/execution-model.md
  epic-orchestrator/lanes/mature-playbook.md
  epic-orchestrator/lanes/deliver-playbook.md
  epic-orchestrator/gate1-package-prompt.md
  epic-orchestrator/coherence-reviewer-prompt.md
  mature-ticket/spec-drafter-prompt.md
  verify/test-runner-prompt.md
  submit-ticket-pr/local-ci-runner-prompt.md
  submit-ticket-pr/docs-sync-prompt.md
  submit-epic-pr/epic-integration-reviewer-prompt.md
)

for prompt in "${prompt_files[@]}"; do
  test -f "dodi-dev/skills/${prompt}"
done

# Deterministic skeleton: plugin scripts exist, are executable, and parse.
plugin_scripts=(
  linear-api.sh
  await-worker.sh
  claim.sh
  release-claim.sh
  dispatch-eligible.sh
  verify-merge.sh
  cleanup-branch.sh
  check-deploy.sh
  watchdog-scan.sh
  heartbeat.sh
  driver-claim.sh
  reap-workers.sh
  comment-species.sh
  hook-gate2-guard.sh
  hook-require-model-pin.sh
)

for script in "${plugin_scripts[@]}"; do
  path="dodi-dev/scripts/${script}"
  test -f "$path"
  test -x "$path"
  bash -n "$path"
done

# Hooks configuration parses.
python3 -c 'import json; json.load(open("dodi-dev/hooks/hooks.json"))'

# Every plugin script referenced by a skill must exist.
grep -rhoE 'scripts/[a-z-]+\.sh' dodi-dev/skills | sort -u | while read -r ref; do
  test -f "dodi-dev/${ref}" || { echo "skill references missing script: ${ref}" >&2; exit 1; }
done

# Skills must not reference documents that only exist in this repository.
if grep -rn -E "docs/specs/2026|docs/plans/2026|templates/ticket-comments" dodi-dev/skills; then
  echo "skill references a repo-only document; ship policy inside the skill directory" >&2
  exit 1
fi

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
  count="$(grep -cF -- "$text" "$file" || true)"
  if (( count < minimum )); then
    echo "${file}: expected at least ${minimum} occurrences of ${text}, found ${count}" >&2
    exit 1
  fi
}

file=dodi-dev/skills/write-plan/SKILL.md
grep -q "^## Testing Contract$" "$file"
for expected in "${testing_contract_checks[@]}"; do
  grep -qF -- "$expected" "$file"
done
check_count_at_least "$file" "Reason: \`<why>\`" 3
check_count_at_least "$file" "Harness: \`<existing|setup-required|not-applicable>\`" 2
check_count_at_least "$file" "Minimum assertions: \`<specific flows>\`" 2

find dodi-dev/skills -type l -print | while read -r link; do
  echo "unexpected symlink: ${link}" >&2
  exit 1
done
find dodi-dev/skills -maxdepth 2 -type f | sort

echo "phase skills ok"
