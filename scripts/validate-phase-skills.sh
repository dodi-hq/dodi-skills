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
  epic-orchestrator/florist-worker-contract.md
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
  # The trailing `(#.*)?` catches a YAML-legal end-of-line comment
  # (`model: fable # needs Frontier`), which is still a live pin. Widening
  # here is the safe direction: it can only make the check trigger more
  # often, never less.
  if grep -qE "^model:[[:space:]]*[\"']?fable[\"']?[[:space:]]*(#.*)?$" <<< "$fm"; then
    if ! grep -q "^[[:space:]]*|.*\`${skill}\`" AGENTS.md; then
      echo "frontmatter fable pin without a Fable Availability Policy row: ${skill}" >&2
      exit 1
    fi
  fi
done

# Multi-tier seat registry: every worker prompt template must name every tier
# it is dispatched at (AGENTS.md Dispatch Discipline — the second half of the
# tier self-declaration invariant; the loop above checks only the first half).
# A prompt file with no row here fails: registering the seats is part of
# adding or re-seating a template.
required_tiers_for() {
  case "$1" in
    brainstorm/spec-reviewer-prompt.md)                  echo "Frontier Capable" ;;
    implement/implementer-prompt.md)                     echo "Standard Capable" ;;
    review/review-prompt.md)                             echo "Capable Frontier" ;;
    review/child-pr-integration-prompt.md)               echo "Capable Frontier" ;;
    write-plan/plan-reviewer-prompt.md)                  echo "Frontier Capable" ;;
    write-plan/plan-writer-prompt.md)                    echo "Frontier Capable" ;;
    epic-orchestrator/state-reader-prompt.md)            echo "Fast" ;;
    epic-orchestrator/evidence-checker-prompt.md)        echo "Fast" ;;
    epic-orchestrator/gate1-package-prompt.md)           echo "Frontier" ;;
    epic-orchestrator/coherence-reviewer-prompt.md)      echo "Frontier" ;;
    mature-ticket/spec-drafter-prompt.md)                echo "Frontier Capable" ;;
    verify/test-runner-prompt.md)                        echo "Fast" ;;
    submit-ticket-pr/local-ci-runner-prompt.md)          echo "Fast" ;;
    submit-ticket-pr/docs-sync-prompt.md)                echo "Frontier" ;;
    submit-epic-pr/epic-integration-reviewer-prompt.md)  echo "Capable Frontier" ;;
    *)                                                   echo "" ;;
  esac
}

for prompt in "${prompt_files[@]}"; do
  case "$prompt" in
    *-prompt.md) ;;
    *) continue ;;
  esac
  path="dodi-dev/skills/${prompt}"
  tiers="$(required_tiers_for "$prompt")"
  if [[ -z "$tiers" ]]; then
    echo "worker prompt has no seat-registry row: ${prompt}" >&2
    exit 1
  fi
  for tier in $tiers; do
    if ! grep -q "${tier} tier" "$path"; then
      echo "worker prompt does not name a tier it is dispatched at (${tier}): ${prompt}" >&2
      exit 1
    fi
  done
  if [[ "$tiers" == *" "* ]]; then
    # Flatten into a variable rather than grep -qF on the raw file: the
    # phrase can wrap across a line break in multi-seat templates (e.g.
    # review/review-prompt.md's "match this\n    dispatch's pin"), which a
    # per-line grep never matches even though the content satisfies the
    # requirement. Squeeze (tr -s), not just translate, all whitespace to a
    # single space: the wrapped continuation line's leading indentation
    # would otherwise survive a plain newline-to-space swap as a run of
    # spaces between "this" and "dispatch's", which the literal grep -qF
    # phrase (single space) would still miss. Piping tr into grep -q
    # directly risks the same SIGPIPE hazard noted above (set -o pipefail,
    # tr killed once grep -q exits early on its first match), so capture
    # first.
    flattened_prompt="$(tr -s '[:space:]' ' ' < "$path")"
    if ! grep -qF "match this dispatch's pin" <<< "$flattened_prompt"; then
      echo "multi-tier worker prompt missing 'match this dispatch's pin': ${prompt}" >&2
      exit 1
    fi
  fi
done

# Florist seats (DOD-1255, DOD-1302): every seat-holding skill defers to the
# worker contract and carries NO frontmatter `model:` pin — the kernel seats
# the session per worker-dispatch.json (a capable unit runs its router at
# Capable), and frontmatter cannot branch by mode, so a pin would override the
# seat at skill load. The contract's per-seat table must name every digest
# outcome the kernel's parser accepts (dodi-florist src/worker/digest.ts).
florist_seat_skills=(mature-ticket implement-ticket review)
for skill in "${florist_seat_skills[@]}"; do
  path="dodi-dev/skills/${skill}/SKILL.md"
  if ! grep -qF 'florist-worker-contract.md' "$path"; then
    echo "Florist seat skill does not reference the worker contract: ${skill}" >&2
    exit 1
  fi
  fm="$(awk 'NR==1 && /^---$/ {inf=1; next} inf && /^---$/ {exit} inf' "$path")"
  if grep -qE '^model:' <<< "$fm"; then
    echo "Florist seat skill carries a frontmatter model pin (cannot branch by mode): ${skill}" >&2
    exit 1
  fi
done
florist_outcomes=(artifact-ready findings clean-final impl-ready synced merge-ready demote blocked declined)
contract=dodi-dev/skills/epic-orchestrator/florist-worker-contract.md
for outcome in "${florist_outcomes[@]}"; do
  if ! grep -qE "^\| \`${outcome}\` \|" "$contract"; then
    echo "florist-worker-contract.md per-seat table missing kernel outcome: ${outcome}" >&2
    exit 1
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
  capacity-park-scan.sh
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

# DR-025 (DOD-1218): tier-conditional focused re-round wording pins. The
# ruled doctrine is prose; these literals keep it from drifting silently.
# (a) review/SKILL.md :47 hard + standard clauses; (b) the unchanged :55
# verify-stage clause — the resolved asymmetry's stationary half; (c) the
# AGENTS.md doctrine sentence's core; (d) the hard-row re-round cell;
# (e) the :48 fix-loop closure clause — the gate-clean rule's two-path shape.
dr025_pins_review=(
  "on a \`needs-capable-delivery\` ticket it runs at the gate's **hard** fable seat (\`model: fable\` on Claude Code"
  "on a standard-tier ticket it runs at Capable tier (\`model: opus\` on Claude Code"
  "a fresh reviewer at Capable tier (\`model: opus\` on Claude Code) reads the fix delta"
  "it is the **focused re-round** at its tier-conditional seat"
)
for pin in "${dr025_pins_review[@]}"; do
  if ! grep -qF -- "$pin" dodi-dev/skills/review/SKILL.md; then
    echo "review/SKILL.md missing DR-025 wording pin: ${pin}" >&2
    exit 1
  fi
done
dr025_pins_agents=(
  "Post-fix focused re-rounds run at Capable tier (\`opus@high\`) by default"
  "and its post-fix focused re-round"
)
for pin in "${dr025_pins_agents[@]}"; do
  if ! grep -qF -- "$pin" AGENTS.md; then
    echo "AGENTS.md missing DR-025 wording pin: ${pin}" >&2
    exit 1
  fi
done
# Negative assertions: the retired pre-DR-025 shapes must not reappear.
# Combined with the positive pins, the asymmetry cannot silently return:
# re-adding either retired phrase fails here, and deleting the new doctrine
# text fails the positive pins instead.
if grep -qF -- "focused re-round at the gate's fable seat" dodi-dev/skills/review/SKILL.md; then
  echo "retired pre-DR-025 wording (unconditional re-round fable seat) reappeared: dodi-dev/skills/review/SKILL.md" >&2
  exit 1
fi
if grep -qF -- "inherit their gate's policy" AGENTS.md; then
  echo "retired pre-DR-025 inherit rule reappeared: AGENTS.md" >&2
  exit 1
fi

find dodi-dev/skills -type l -print | while read -r link; do
  echo "unexpected symlink: ${link}" >&2
  exit 1
done
find dodi-dev/skills -maxdepth 2 -type f | sort

echo "phase skills ok"
