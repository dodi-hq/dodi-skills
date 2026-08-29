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

# Tier and effort self-declaration: every worker prompt template names the
# tier and declared effort it is dispatched at (AGENTS.md Dispatch
# Discipline). The pin is what the hook enforces; these lines are what make
# a wrong tier or effort visible in the transcript.
for prompt in "${prompt_files[@]}"; do
  case "$prompt" in
    *-prompt.md) ;;
    *) continue ;;
  esac
  path="dodi-dev/skills/${prompt}"
  if ! grep -qE '\((Frontier|Capable|Standard|Fast) tier' "$path"; then
    echo "worker prompt does not name its tier: ${prompt}" >&2
    exit 1
  fi
  # Effort check is tolerant of parentheticals that wrap across lines
  # (multi-seat templates); the {0,200} bound keeps a stray unclosed
  # parenthesis from matching across the whole file. Flatten into a
  # variable rather than piping into grep -q: under set -o pipefail, a
  # large file could make tr die of SIGPIPE once grep -q exits early on
  # its first match, turning a real pass into a spurious failure.
  flattened="$(tr '\n' ' ' < "$path")"
  if ! grep -qE '\((Frontier|Capable|Standard|Fast) tier[^)]{0,200}effort' <<< "$flattened"; then
    echo "worker prompt does not name its effort: ${prompt}" >&2
    exit 1
  fi
done

# Fable Availability Policy: every frontmatter `model: fable` pin has a policy
# row naming its skill (AGENTS.md "a fable seat without a row is a defect").
# Scoped to the frontmatter block only (a `model: fable` in prose never
# matches). The AGENTS.md side is deliberately loose: it matches ANY markdown
# table row naming the skill in backticks, not policy-table rows specifically
# — a skill named in some other table's cell (e.g. a dispatch-gate mention)
# also satisfies it. A tighter predicate would risk missing legitimate policy
# rows, since seat mentions and dispatch-gate mentions share the same tables;
# this keeps prose-only mentions from counting and survives bucket renames.
# Iterates the skill directories on disk rather than the hardcoded `skills`
# array above, so a future skill that ships a frontmatter fable pin is covered
# by this guard from the moment its directory exists — before anyone remembers
# to add it to the array.
for f in dodi-dev/skills/*/SKILL.md; do
  skill="$(basename "$(dirname "$f")")"
  # Capture the frontmatter block into a variable rather than piping awk into
  # grep -q: under set -o pipefail, grep -q exiting early on its first match
  # can kill awk with SIGPIPE, turning a real pass into a spurious failure.
  fm="$(awk 'NR==1 && /^---$/ {inf=1; next} inf && /^---$/ {exit} inf' "$f")"
  if grep -qE '^model:[[:space:]]*"?fable"?[[:space:]]*$' <<< "$fm"; then
    if ! grep -q "^[[:space:]]*|.*\`${skill}\`" AGENTS.md; then
      echo "frontmatter fable pin without a Fable Availability Policy row: ${skill}" >&2
      exit 1
    fi
  fi
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
