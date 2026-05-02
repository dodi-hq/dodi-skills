# Phase 2 Local Epic Orchestration Implementation Plan

> **For agentic workers:** Use `dodi-dev:implement` to execute this plan.

**Goal:** Add the local epic orchestration skill layer in both Claude and Codex trees without adding PR creation or merge behavior.

**Architecture:** Phase 2 introduces `epic-orchestrator` as the anti-drift top-level workflow skill and adds the local phase skills needed for epic assessment, ticket maturity, ticket pickup, implementation dispatch, pre-PR review, test creation, verification, and quality gate. Existing skills are tightened where their behavior becomes part of the local orchestration state machine. PR lifecycle skills remain out of scope until Phase 3.

**Tech Stack:** Markdown skills, JSON plugin manifests, shell verification commands.

**Spec:** `docs/specs/2026-05-02-epic-orchestration-design.md`

---

## File Structure

- Modify `.claude-plugin/marketplace.json`: bump `dodi-dev` from `0.6.0` to `0.7.0`.
- Modify `dodi-dev/.claude-plugin/plugin.json`: bump `version` to `0.7.0` and update description to local epic orchestration.
- Modify `plugins/dodi-dev/.codex-plugin/plugin.json`: bump `version` to `0.7.0` and update description to local epic orchestration.
- Create in both `dodi-dev/skills/` and `plugins/dodi-dev/skills/`:
  - `epic-orchestrator/SKILL.md`
  - `pickup-epic/SKILL.md`
  - `assess-epic/SKILL.md`
  - `mature-ticket/SKILL.md`
  - `pickup-ticket/SKILL.md`
  - `implement-ticket/SKILL.md`
  - `review-implementation/SKILL.md`
  - `create-tests/SKILL.md`
- Modify in both skill trees:
  - `write-plan/SKILL.md`
  - `review/SKILL.md`
  - `verify/SKILL.md`
  - `submit/SKILL.md`
  - `quality-gate/SKILL.md`

Phase 2 must not create `review-child-pr`, `submit-ticket-pr`, or `submit-epic-pr`.

---

### Task 1: Bump Phase 2 Metadata

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `dodi-dev/.claude-plugin/plugin.json`
- Modify: `plugins/dodi-dev/.codex-plugin/plugin.json`

- [ ] **Step 1:** Update `.claude-plugin/marketplace.json`.

Expected `plugins[0]` object:

```json
{
  "name": "dodi-dev",
  "description": "Dev workflow and local epic orchestration skills",
  "version": "0.7.0",
  "source": "./dodi-dev"
}
```

- [ ] **Step 2:** Update `dodi-dev/.claude-plugin/plugin.json`.

Expected final content:

```json
{
  "name": "dodi-dev",
  "description": "Dev workflow and local epic orchestration skills",
  "version": "0.7.0",
  "author": {
    "name": "Dodi HQ",
    "email": "may@dodihome.com"
  }
}
```

- [ ] **Step 3:** Update `plugins/dodi-dev/.codex-plugin/plugin.json`.

Expected changed fields:

```json
{
  "version": "0.7.0",
  "description": "Dodi developer workflow and local epic orchestration skills",
  "interface": {
    "shortDescription": "Developer workflow and local epic orchestration skills"
  }
}
```

Keep all other existing Codex plugin metadata fields unchanged.

- [ ] **Step 4:** Verify metadata parses and versions are correct.

Run:

```bash
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -m json.tool dodi-dev/.claude-plugin/plugin.json >/dev/null
python3 -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json >/dev/null
python3 - <<'PY'
import json
from pathlib import Path
market = json.loads(Path('.claude-plugin/marketplace.json').read_text())
claude = json.loads(Path('dodi-dev/.claude-plugin/plugin.json').read_text())
codex = json.loads(Path('plugins/dodi-dev/.codex-plugin/plugin.json').read_text())
assert market['plugins'][0]['version'] == '0.7.0'
assert claude['version'] == '0.7.0'
assert codex['version'] == '0.7.0'
print('phase 2 versions ok')
PY
```

Expected:

```text
phase 2 versions ok
```

- [ ] **Step 5:** Commit.

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json plugins/dodi-dev/.codex-plugin/plugin.json
git commit -m "chore: bump dodi-dev to 0.7.0"
```

---

### Task 2: Add Local Orchestration Skills to Both Trees

**Files:**
- Create: `dodi-dev/skills/epic-orchestrator/SKILL.md`
- Create: `dodi-dev/skills/pickup-epic/SKILL.md`
- Create: `dodi-dev/skills/assess-epic/SKILL.md`
- Create: `dodi-dev/skills/mature-ticket/SKILL.md`
- Create: `dodi-dev/skills/pickup-ticket/SKILL.md`
- Create: `dodi-dev/skills/implement-ticket/SKILL.md`
- Create: `dodi-dev/skills/review-implementation/SKILL.md`
- Create: `dodi-dev/skills/create-tests/SKILL.md`
- Create matching files under `plugins/dodi-dev/skills/`

- [ ] **Step 1:** Create `epic-orchestrator/SKILL.md` in both trees.

Required content:

```markdown
---
name: epic-orchestrator
description: Top-level local epic workflow orchestrator; dispatches phase skills and workers without implementing, reviewing, or testing directly
---

# Epic Orchestrator

Orchestrate one feature epic from intake through local readiness for child PR creation. Do not implement product code, review code directly, or run tests as the primary actor. Dispatch bounded workers and advance state only from durable evidence.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| Hive starts or resumes work on an epic | epic id, repo path, PM system context | next state decision, dispatched phase work, epic progress summary | epic comments, child ticket comments, labels, artifact links | phase skills, workers, reviewers, test runners | needs human spec input, blocked dependency, tool/auth failure |

## Inputs

- `epicId`
- `repoPath`
- `pmSystem`
- `mode`: `start` or `start-or-resume`
- optional `baseBranch`
- optional `humanContact`
- optional `runLedgerPath`

## Hard Gates

- No ticket enters planning without human spec signoff or explicit delegation.
- No ticket enters implementation without `spec-ready` and `ready-to-implement`.
- Any implementation surprise requiring product, architecture, scope, or plan judgment returns the ticket to the spec lane.
- Phase 2 stops before PR creation. If a ticket reaches local PR readiness, report `ready-for-child-pr` and stop.

## State Reconstruction

1. Read the epic and child tickets from the PM system.
2. Read branch and worktree state.
3. Read the local ledger if present.
4. Prefer PM labels, PM comments, artifact links, and Git state over local ledger entries when they disagree.
5. Choose exactly one allowed next action.

## Process

1. Reconstruct epic and child ticket state from durable evidence.
2. Pick exactly one allowed next action.
3. Dispatch the owning phase skill or worker.
4. Verify evidence before advancing state.
5. Stop at `ready-for-child-pr` in Phase 2.

## Allowed Next Actions

- Run `pickup-epic`.
- Run `assess-epic`.
- Run `mature-ticket`.
- Run `pickup-ticket`.
- Run `implement-ticket`.
- Run `review-implementation`.
- Run `create-tests`.
- Run `verify`.
- Run `quality-gate`.
- Stop for human spec input.
- Stop for a concrete blocker.
- Stop with `ready-for-child-pr`.

## State Transitions

Use only the Phase 2 subset of the child-ticket and epic-level transition tables in `docs/specs/2026-05-02-epic-orchestration-design.md`. Phase 2 ends at `ready-for-child-pr`. Do not execute or encode `child-pr-reviewing`, `ready-to-merge-child`, `done`, `epic-ready-for-pr`, or `epic-pr-open` as active transitions in this release.

## Evidence Rule

Never advance from a worker success claim alone. Verify labels, comments, artifacts, branch/worktree state, commits, or command output first.

The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.

Durable PM state is the source of truth.

## Evidence

- PM labels and comments
- artifact links
- branch and worktree state
- commit ids
- command output
- optional run ledger records

## Stop Conditions

- human spec input required
- tool or auth failure
- blocked dependency
- implementation surprise requiring spec or plan revision
- `ready-for-child-pr`

## Progress Record

Emit progress records with `epicId`, optional `ticketId`, `state`, `action`, `evidence`, `nextAction`, and `needsHuman`.
```

- [ ] **Step 2:** Create the seven local phase skills in both trees with these required contracts.

Each skill must include a `## Contract` table with the exact fields below, followed by `## Inputs`, `## Process`, `## Evidence`, and `## Stop Conditions`.

| Skill | Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- | --- |
| `pickup-epic` | epic accepted for orchestration | epic id, repo path, optional base branch | epic branch and epic worktree | epic comment with branch/worktree paths and base branch | none by default | dirty worktree, missing base branch, branch conflict, pull failure |
| `assess-epic` | epic worktree exists or orchestration resumes | epic id, child ticket list, repo state, artifact links | ticket maturity map, dependency map, ready work queue, maturity work queue | epic assessment comment or run ledger entry | explorer/reviewer workers for dependency checks only | ticket access failure, inconsistent child hierarchy, missing repo |
| `mature-ticket` | child lacks `spec-ready` or `ready-to-implement` | ticket id, current artifacts, dependency context, human contact | clean spec, clean plan when allowed, readiness label decision | artifact links, reviewer evidence, assumptions, labels | spec drafter, spec reviewer, plan writer, plan reviewer | needs human spec input, unresolved dependency, review findings, spec/plan mismatch |
| `pickup-ticket` | child has `ready-to-implement` | ticket id, epic branch/worktree, repo path, clean spec, clean plan | child branch and child worktree based on epic branch | ticket comment with child branch/worktree | none by default | stale epic branch, branch conflict, dirty worktree, missing readiness labels |
| `implement-ticket` | child worktree exists | ticket id, clean spec, clean plan, child worktree | implementation commits or explicit escalation | ticket comment with commit ids, worker evidence, surprise notes | implementation workers only | product decision needed, architecture decision needed, scope surprise, plan mismatch, worker blocked |
| `review-implementation` | implementation completes before PR creation | ticket id, clean spec, clean plan, child worktree, diff | clean pre-PR review or findings to fix | ticket comment with reviewer status and fixed findings | fresh-context code reviewers and fix workers | review findings, spec/plan mismatch, production changes requiring focused re-review |
| `create-tests` | implementation review is clean or plan requires tests | Testing Contract, changed files, child worktree, repo instructions | tests satisfying Testing Contract or concrete escalation | ticket comment with test files, rationale, harness setup evidence | test implementation workers and harness setup workers | invalid Testing Contract, missing harness blocker, spec/plan mismatch |

Each skill must include:

- frontmatter with `name` and `description`
- `# <Title>`
- `## Inputs`
- `## Process`
- `## Evidence`
- `## Stop Conditions`
- a rule that durable PM state is the source of truth
- a rule that Phase 2 stops at `ready-for-child-pr` and must not create PRs, merge branches, or invoke Phase 3 PR lifecycle skills

Each skill must include this exact common evidence rule:

```markdown
The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.
```

Each new local phase skill must include these exact process, evidence, and stop-condition bullets in addition to its contract:

| Skill | Required process bullets | Required evidence bullets | Required stop-condition bullets |
| --- | --- | --- | --- |
| `pickup-epic` | `Verify the current repository worktree is clean before changing branches.`<br>`Discover the base branch from input or origin default branch.`<br>`Pull the latest base branch before creating or refreshing the epic branch.`<br>`Create or switch to the epic branch and epic worktree.` | `Record epic id, repo path, base branch, epic branch, and epic worktree.` | `Stop on dirty worktree, missing base branch, branch conflict, or pull failure.` |
| `assess-epic` | `Read the epic and child tickets from the PM system.`<br>`Inspect labels, comments, artifact links, branches, and worktrees.`<br>`Classify each child using the state transition table through ready-for-child-pr only.`<br>`Build ready work and maturity work queues.` | `Record child state map, dependency map, ready work queue, maturity work queue, and blockers.` | `Stop on ticket access failure, inconsistent child hierarchy, or missing repository context.` |
| `mature-ticket` | `Draft spec questions or a proposed spec for tickets without spec-ready.`<br>`Require human signoff or explicit delegation before write-plan.`<br>`Run spec review until the final round is clean.`<br>`Run write-plan only after spec signoff.`<br>`Run plan review until the final round is clean.` | `Record spec artifact, plan artifact, reviewer type, review status, assumptions, dependency state, and labels applied or withheld.` | `Stop for human spec input, unresolved dependency, review findings, or spec/plan mismatch.` |
| `pickup-ticket` | `Verify spec-ready and ready-to-implement are present.`<br>`Refresh the epic branch before branching.`<br>`Create the child branch and child worktree from the epic branch.` | `Record ticket id, epic branch, child branch, child worktree, spec artifact, and plan artifact.` | `Stop on missing readiness labels, stale epic branch, branch conflict, or dirty worktree.` |
| `implement-ticket` | `Read the clean plan and dispatch bounded implementation workers.`<br>`Require exact plan adherence.`<br>`Demote to the spec lane on product, architecture, scope, or plan mismatch surprises.` | `Record worker status, commit ids, files changed, commands run, and surprise notes.` | `Stop on product decision, architecture decision, scope surprise, plan mismatch, or worker blocker.` |
| `review-implementation` | `Read the spec, plan, and diff directly.`<br>`Dispatch a fresh-context reviewer.`<br>`Dispatch fix workers for findings.`<br>`Repeat until the final review round is clean.` | `Record reviewer status, findings, fixes, reviewed diff range, and final clean review evidence.` | `Stop on spec/plan mismatch or unresolved review findings.` |
| `create-tests` | `Read the Testing Contract from the plan.`<br>`Dispatch test workers for required unit, integration, and e2e groups.`<br>`Set up missing required harnesses where feasible.`<br>`Escalate when the Testing Contract is invalid.` | `Record test files, required groups, harness setup evidence, and rationale for any not-required group.` | `Stop on invalid Testing Contract, missing harness blocker, or spec/plan mismatch.` |

- [ ] **Step 3:** Copy each newly created Claude skill file to the matching Codex path, then adjust only runtime-specific wording if needed. For Phase 2, no runtime-specific wording is required.

Run:

```bash
for skill in epic-orchestrator pickup-epic assess-epic mature-ticket pickup-ticket implement-ticket review-implementation create-tests; do
  mkdir -p "plugins/dodi-dev/skills/$skill"
  cp "dodi-dev/skills/$skill/SKILL.md" "plugins/dodi-dev/skills/$skill/SKILL.md"
done
```

- [ ] **Step 4:** Verify all new skill files exist in both trees.

Run:

```bash
for skill in epic-orchestrator pickup-epic assess-epic mature-ticket pickup-ticket implement-ticket review-implementation create-tests; do
  test -f "dodi-dev/skills/$skill/SKILL.md" || exit 1
  test -f "plugins/dodi-dev/skills/$skill/SKILL.md" || exit 1
done
```

Also rerun the exact Python required-snippet verification block from Task 2 Step 6. Do not substitute a broad `rg` alternation for the required contract, process, evidence, and stop-condition snippets.

Expected: no output and exit `0`.

- [ ] **Step 5:** Verify no PR lifecycle skills were added in Phase 2.

Run:

```bash
test ! -e dodi-dev/skills/review-child-pr
test ! -e dodi-dev/skills/submit-ticket-pr
test ! -e dodi-dev/skills/submit-epic-pr
test ! -e plugins/dodi-dev/skills/review-child-pr
test ! -e plugins/dodi-dev/skills/submit-ticket-pr
test ! -e plugins/dodi-dev/skills/submit-epic-pr
```

Expected: each command exits `0`.

- [ ] **Step 6:** Verify required skill structure and contracts are present.

Run:

```bash
for tree in dodi-dev/skills plugins/dodi-dev/skills; do
  for skill in epic-orchestrator pickup-epic assess-epic mature-ticket pickup-ticket implement-ticket review-implementation create-tests; do
    file="$tree/$skill/SKILL.md"
    rg -n "^name: $skill$" "$file" >/dev/null
    rg -n "^description:" "$file" >/dev/null
    rg -n "^## Contract$" "$file" >/dev/null
    rg -n "^## Inputs$" "$file" >/dev/null
    rg -n "^## Process$" "$file" >/dev/null
    rg -n "^## Evidence$" "$file" >/dev/null
    rg -n "^## Stop Conditions$" "$file" >/dev/null
    rg -n "The orchestrator may not advance state from a worker success claim alone" "$file" >/dev/null
    rg -n "ready-for-child-pr" "$file" >/dev/null
  done
done
python3 - <<'PY'
from pathlib import Path

required = {
    "epic-orchestrator": [
        "Hive starts or resumes work on an epic",
        "epic id, repo path, PM system context",
        "next state decision, dispatched phase work, epic progress summary",
        "epic comments, child ticket comments, labels, artifact links",
        "phase skills, workers, reviewers, test runners",
        "needs human spec input, blocked dependency, tool/auth failure",
        "No ticket enters planning without human spec signoff or explicit delegation.",
        "No ticket enters implementation without `spec-ready` and `ready-to-implement`.",
        "Phase 2 stops before PR creation.",
    ],
    "pickup-epic": [
        "epic accepted for orchestration",
        "epic id, repo path, optional base branch",
        "epic branch and epic worktree",
        "epic comment with branch/worktree paths and base branch",
        "none by default",
        "dirty worktree, missing base branch, branch conflict, pull failure",
        "Verify the current repository worktree is clean before changing branches.",
        "Discover the base branch from input or origin default branch.",
        "Pull the latest base branch before creating or refreshing the epic branch.",
        "Create or switch to the epic branch and epic worktree.",
        "Record epic id, repo path, base branch, epic branch, and epic worktree.",
        "Stop on dirty worktree, missing base branch, branch conflict, or pull failure.",
    ],
    "assess-epic": [
        "epic worktree exists or orchestration resumes",
        "epic id, child ticket list, repo state, artifact links",
        "ticket maturity map, dependency map, ready work queue, maturity work queue",
        "epic assessment comment or run ledger entry",
        "explorer/reviewer workers for dependency checks only",
        "ticket access failure, inconsistent child hierarchy, missing repo",
        "Read the epic and child tickets from the PM system.",
        "Inspect labels, comments, artifact links, branches, and worktrees.",
        "Classify each child using the state transition table through ready-for-child-pr only.",
        "Build ready work and maturity work queues.",
        "Record child state map, dependency map, ready work queue, maturity work queue, and blockers.",
        "Stop on ticket access failure, inconsistent child hierarchy, or missing repository context.",
    ],
    "mature-ticket": [
        "child lacks `spec-ready` or `ready-to-implement`",
        "ticket id, current artifacts, dependency context, human contact",
        "clean spec, clean plan when allowed, readiness label decision",
        "artifact links, reviewer evidence, assumptions, labels",
        "spec drafter, spec reviewer, plan writer, plan reviewer",
        "needs human spec input, unresolved dependency, review findings, spec/plan mismatch",
        "Draft spec questions or a proposed spec for tickets without spec-ready.",
        "Require human signoff or explicit delegation before write-plan.",
        "Run spec review until the final round is clean.",
        "Run write-plan only after spec signoff.",
        "Run plan review until the final round is clean.",
        "Record spec artifact, plan artifact, reviewer type, review status, assumptions, dependency state, and labels applied or withheld.",
        "Stop for human spec input, unresolved dependency, review findings, or spec/plan mismatch.",
    ],
    "pickup-ticket": [
        "child has `ready-to-implement`",
        "ticket id, epic branch/worktree, repo path, clean spec, clean plan",
        "child branch and child worktree based on epic branch",
        "ticket comment with child branch/worktree",
        "none by default",
        "stale epic branch, branch conflict, dirty worktree, missing readiness labels",
        "Verify spec-ready and ready-to-implement are present.",
        "Refresh the epic branch before branching.",
        "Create the child branch and child worktree from the epic branch.",
        "Record ticket id, epic branch, child branch, child worktree, spec artifact, and plan artifact.",
        "Stop on missing readiness labels, stale epic branch, branch conflict, or dirty worktree.",
    ],
    "implement-ticket": [
        "child worktree exists",
        "ticket id, clean spec, clean plan, child worktree",
        "implementation commits or explicit escalation",
        "ticket comment with commit ids, worker evidence, surprise notes",
        "implementation workers only",
        "product decision needed, architecture decision needed, scope surprise, plan mismatch, worker blocked",
        "Read the clean plan and dispatch bounded implementation workers.",
        "Require exact plan adherence.",
        "Demote to the spec lane on product, architecture, scope, or plan mismatch surprises.",
        "Record worker status, commit ids, files changed, commands run, and surprise notes.",
        "Stop on product decision, architecture decision, scope surprise, plan mismatch, or worker blocker.",
    ],
    "review-implementation": [
        "implementation completes before PR creation",
        "ticket id, clean spec, clean plan, child worktree, diff",
        "clean pre-PR review or findings to fix",
        "ticket comment with reviewer status and fixed findings",
        "fresh-context code reviewers and fix workers",
        "review findings, spec/plan mismatch, production changes requiring focused re-review",
        "Read the spec, plan, and diff directly.",
        "Dispatch a fresh-context reviewer.",
        "Dispatch fix workers for findings.",
        "Repeat until the final review round is clean.",
        "Record reviewer status, findings, fixes, reviewed diff range, and final clean review evidence.",
        "Stop on spec/plan mismatch or unresolved review findings.",
    ],
    "create-tests": [
        "implementation review is clean or plan requires tests",
        "Testing Contract, changed files, child worktree, repo instructions",
        "tests satisfying Testing Contract or concrete escalation",
        "ticket comment with test files, rationale, harness setup evidence",
        "test implementation workers and harness setup workers",
        "invalid Testing Contract, missing harness blocker, spec/plan mismatch",
        "Read the Testing Contract from the plan.",
        "Dispatch test workers for required unit, integration, and e2e groups.",
        "Set up missing required harnesses where feasible.",
        "Escalate when the Testing Contract is invalid.",
        "Record test files, required groups, harness setup evidence, and rationale for any not-required group.",
        "Stop on invalid Testing Contract, missing harness blocker, or spec/plan mismatch.",
    ],
}

for tree in ["dodi-dev/skills", "plugins/dodi-dev/skills"]:
    for skill, snippets in required.items():
        text = Path(tree, skill, "SKILL.md").read_text()
        missing = [snippet for snippet in snippets if snippet not in text]
        if missing:
            raise SystemExit(f"{tree}/{skill}/SKILL.md missing: {missing}")
PY
```

Expected: no output and exit `0`.

- [ ] **Step 7:** Verify Phase 2 skills do not contain PR creation or merge instructions.

Run:

```bash
rg -n "gh pr create|gh pr merge|--auto|auto-merge|squash merge|target main|target master" dodi-dev/skills/epic-orchestrator dodi-dev/skills/pickup-epic dodi-dev/skills/assess-epic dodi-dev/skills/mature-ticket dodi-dev/skills/pickup-ticket dodi-dev/skills/implement-ticket dodi-dev/skills/review-implementation dodi-dev/skills/create-tests plugins/dodi-dev/skills/epic-orchestrator plugins/dodi-dev/skills/pickup-epic plugins/dodi-dev/skills/assess-epic plugins/dodi-dev/skills/mature-ticket plugins/dodi-dev/skills/pickup-ticket plugins/dodi-dev/skills/implement-ticket plugins/dodi-dev/skills/review-implementation plugins/dodi-dev/skills/create-tests && exit 1 || exit 0
```

Expected: no output and exit `0`.

- [ ] **Step 8:** Commit.

```bash
git add dodi-dev/skills plugins/dodi-dev/skills
git commit -m "feat: add local epic orchestration skills"
```

---

### Task 3: Tighten Existing Local Workflow Skills

**Files:**
- Modify: `dodi-dev/skills/write-plan/SKILL.md`
- Modify: `plugins/dodi-dev/skills/write-plan/SKILL.md`
- Modify: `dodi-dev/skills/review/SKILL.md`
- Modify: `plugins/dodi-dev/skills/review/SKILL.md`
- Modify: `dodi-dev/skills/verify/SKILL.md`
- Modify: `plugins/dodi-dev/skills/verify/SKILL.md`
- Modify: `dodi-dev/skills/submit/SKILL.md`
- Modify: `plugins/dodi-dev/skills/submit/SKILL.md`
- Modify: `dodi-dev/skills/quality-gate/SKILL.md`
- Modify: `plugins/dodi-dev/skills/quality-gate/SKILL.md`

- [ ] **Step 1:** Update both `write-plan/SKILL.md` files.

Required changes:

- Add a hard gate: planning requires a clean spec and human spec signoff or explicit delegation.
- Add a required `Testing Contract` section to the plan template with unit, integration, e2e, harness/setup, and critical flow fields.
- Add a rule that `ready-to-implement` may only be applied after clean plan review and dependency check.
- Add a rule that product or architecture ambiguity returns the ticket to the spec lane.

Required additive content:

```markdown
## Epic Orchestration Planning Gates

- A ticket may enter planning only after human spec signoff or explicit delegation.
- Every implementation plan must include a Testing Contract with unit, integration, e2e, harness/setup, and critical-flow fields.
- Apply `ready-to-implement` only after clean plan review and dependency check.
- Product or architecture ambiguity returns the ticket to the spec lane.
```

- [ ] **Step 2:** Update both `review/SKILL.md` files.

Required changes:

- Identify it as the base review behavior used by `review-implementation`.
- Require fresh context: read spec, plan, and diff directly.
- Require focused re-review when production code changes during verification.
- Require findings to distinguish spec mismatch, implementation issue, test issue, and hygiene/security issue.

Required additive content:

```markdown
## Epic Orchestration Review Rules

- Read the spec, plan, and diff directly.
- Treat this as fresh-context review.
- Focused re-review is required when production code changes during verification.
- Classify findings as spec mismatch, implementation issue, test issue, security issue, hygiene issue, or regression risk.
```

- [ ] **Step 3:** Update both `verify/SKILL.md` files.

Required changes:

- Require reading the Testing Contract.
- Require setting up missing required harnesses when feasible.
- Forbid skipping required unit, integration, or e2e groups solely because a harness is absent.
- Require failure classification: test bug, implementation bug, environment/harness issue, spec/plan mismatch.
- Require fixing the right thing rather than defaulting to test edits.
- Require returning to the spec lane when verification exposes spec/plan mismatch.

Required additive content:

```markdown
## Epic Orchestration Verification Rules

- Read the Testing Contract before choosing commands.
- Do not skip required unit, integration, or e2e groups because a harness is absent.
- Set up missing required harnesses when feasible.
- Classify failures as test bug, implementation bug, environment/harness issue, or spec/plan mismatch.
- Fix the right thing; do not default to editing tests.
- Return to the spec lane when verification exposes a spec/plan mismatch.
```

- [ ] **Step 4:** Update both `submit/SKILL.md` files.

Required changes:

- Keep it as a compatibility wrapper, not the epic workflow submit path.
- Remove automatic merge as the default documented behavior.
- Remove the existing GitHub PR creation and merge command blocks from the default path.
- State that epic workflows must use Phase 3 `submit-ticket-pr` and `submit-epic-pr` once those skills exist.
- For Phase 2, state that local orchestration stops at `ready-for-child-pr`.

Required additive content:

```markdown
## Epic Workflow Compatibility

`submit` is a compatibility wrapper. Phase 2 local epic orchestration stops at `ready-for-child-pr` and does not create PRs or merge branches. Phase 3 introduces `submit-ticket-pr` and `submit-epic-pr` for epic workflows.

Auto-merge is not the default documented behavior.
Do not create PRs or merge branches from this compatibility skill in Phase 2.
```

- [ ] **Step 5:** Tighten both `quality-gate/SKILL.md` files.

Required changes:

- Expand from Phase 1 compatibility checks into a local horizontal gate.
- Keep the Phase 1 metadata and skill-tree checks.
- Add checks for implementation compliance, security concerns, code hygiene, regression risk, documentation, and operational concerns.
- Require command evidence from `verify` before passing.
- State that Phase 2 `quality-gate` does not create or merge PRs.

Required additive content:

```markdown
## Local Epic Quality Gate

- Preserve plugin metadata and skill-tree checks.
- Require verification command evidence before passing.
- Check implementation compliance, security concerns, code hygiene, regression risk, documentation, and operational concerns.
- Do not create PRs or merge branches in Phase 2.
```

- [ ] **Step 6:** Verify matching skill names still exist in both trees.

Run:

```bash
for skill in write-plan review verify submit quality-gate; do
  test -f "dodi-dev/skills/$skill/SKILL.md" || exit 1
  test -f "plugins/dodi-dev/skills/$skill/SKILL.md" || exit 1
done
for file in dodi-dev/skills/write-plan/SKILL.md plugins/dodi-dev/skills/write-plan/SKILL.md; do
  rg -n "## Epic Orchestration Planning Gates" "$file" >/dev/null
  rg -n "Testing Contract" "$file" >/dev/null
  rg -n "ready-to-implement" "$file" >/dev/null
done
for file in dodi-dev/skills/review/SKILL.md plugins/dodi-dev/skills/review/SKILL.md; do
  rg -n "## Epic Orchestration Review Rules" "$file" >/dev/null
  rg -n "Focused re-review" "$file" >/dev/null
  rg -n "Classify findings" "$file" >/dev/null
done
for file in dodi-dev/skills/verify/SKILL.md plugins/dodi-dev/skills/verify/SKILL.md; do
  rg -n "## Epic Orchestration Verification Rules" "$file" >/dev/null
  rg -n "Classify failures" "$file" >/dev/null
  rg -n "Set up missing required harnesses" "$file" >/dev/null
done
for file in dodi-dev/skills/submit/SKILL.md plugins/dodi-dev/skills/submit/SKILL.md; do
  rg -n "## Epic Workflow Compatibility" "$file" >/dev/null
  rg -n "ready-for-child-pr" "$file" >/dev/null
  rg -n "does not create PRs or merge branches" "$file" >/dev/null
done
for file in dodi-dev/skills/quality-gate/SKILL.md plugins/dodi-dev/skills/quality-gate/SKILL.md; do
  rg -n "## Local Epic Quality Gate" "$file" >/dev/null
  rg -n "verification command evidence" "$file" >/dev/null
  rg -n "Do not create PRs" "$file" >/dev/null
done
```

Expected: no output and exit `0`.

- [ ] **Step 7:** Commit.

```bash
git add dodi-dev/skills plugins/dodi-dev/skills
git commit -m "feat: tighten local orchestration workflow skills"
```

---

### Task 4: Phase 2 Verification

**Files:**
- Verify: metadata files
- Verify: both skill trees

- [ ] **Step 1:** Validate metadata and versions.

Run:

```bash
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -m json.tool dodi-dev/.claude-plugin/plugin.json >/dev/null
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json >/dev/null
python3 - <<'PY'
import json
from pathlib import Path
market = json.loads(Path('.claude-plugin/marketplace.json').read_text())
claude = json.loads(Path('dodi-dev/.claude-plugin/plugin.json').read_text())
codex = json.loads(Path('plugins/dodi-dev/.codex-plugin/plugin.json').read_text())
assert market['plugins'][0]['version'] == '0.7.0'
assert claude['version'] == '0.7.0'
assert codex['version'] == '0.7.0'
print('phase 2 versions ok')
PY
```

Expected:

```text
phase 2 versions ok
```

- [ ] **Step 2:** Verify required Phase 2 skill files exist in both trees.

Run:

```bash
for skill in brainstorm file-ticket implement pickup quality-gate review submit verify write-plan epic-orchestrator pickup-epic assess-epic mature-ticket pickup-ticket implement-ticket review-implementation create-tests; do
  test -f "dodi-dev/skills/$skill/SKILL.md" || exit 1
  test -f "plugins/dodi-dev/skills/$skill/SKILL.md" || exit 1
done
```

Expected: no output and exit `0`.

- [ ] **Step 3:** Verify required sections and contracts are present in Phase 2 skills.

Run:

```bash
for tree in dodi-dev/skills plugins/dodi-dev/skills; do
  for skill in epic-orchestrator pickup-epic assess-epic mature-ticket pickup-ticket implement-ticket review-implementation create-tests; do
    file="$tree/$skill/SKILL.md"
    rg -n "^## Contract$" "$file" >/dev/null
    rg -n "^## Inputs$" "$file" >/dev/null
    rg -n "^## Process$" "$file" >/dev/null
    rg -n "^## Evidence$" "$file" >/dev/null
    rg -n "^## Stop Conditions$" "$file" >/dev/null
    rg -n "durable PM state is the source of truth|Durable PM state is the source of truth" "$file" >/dev/null
    rg -n "The orchestrator may not advance state from a worker success claim alone" "$file" >/dev/null
    rg -n "ready-for-child-pr" "$file" >/dev/null
  done
done
```

Also rerun the exact Python required-snippet verification block from Task 2 Step 6. Do not substitute a broad `rg` alternation for the required contract, process, evidence, and stop-condition snippets.

Expected: no output and exit `0`.

- [ ] **Step 4:** Verify Phase 3 PR lifecycle skills are absent.

Run:

```bash
test ! -e dodi-dev/skills/review-child-pr
test ! -e dodi-dev/skills/submit-ticket-pr
test ! -e dodi-dev/skills/submit-epic-pr
test ! -e plugins/dodi-dev/skills/review-child-pr
test ! -e plugins/dodi-dev/skills/submit-ticket-pr
test ! -e plugins/dodi-dev/skills/submit-epic-pr
```

Expected: each command exits `0`.

- [ ] **Step 5:** Verify no symlinks exist in either skill tree.

Run:

```bash
find dodi-dev/skills -type l -print
find plugins/dodi-dev/skills -type l -print
```

Expected: no output.

- [ ] **Step 6:** Verify plan and spec references are present in the new top-level orchestration skill.

Run:

```bash
rg -n "docs/specs/2026-05-02-epic-orchestration-design.md|ready-for-child-pr|No ticket enters implementation" dodi-dev/skills/epic-orchestrator/SKILL.md plugins/dodi-dev/skills/epic-orchestrator/SKILL.md
```

Expected: matches in both files.

- [ ] **Step 7:** Print the published Phase 2 file set.

Run:

```bash
find dodi-dev/skills plugins/dodi-dev/skills -maxdepth 2 -type f | sort
```

Expected: prints the published file set for both skill trees and exits `0`.

- [ ] **Step 8:** Verify Phase 2 skills do not contain PR creation or merge instructions.

Run:

```bash
python3 - <<'PY'
from pathlib import Path

paths = []
for tree in ["dodi-dev/skills", "plugins/dodi-dev/skills"]:
    for skill in [
        "epic-orchestrator",
        "pickup-epic",
        "assess-epic",
        "mature-ticket",
        "pickup-ticket",
        "implement-ticket",
        "review-implementation",
        "create-tests",
        "submit",
        "quality-gate",
    ]:
        paths.append(Path(tree, skill, "SKILL.md"))

bad = []
for path in paths:
    for line_no, line in enumerate(path.read_text().splitlines(), 1):
        stripped = line.strip()
        lower = stripped.lower()
        policy = (
            lower.startswith("do not ")
            or lower.startswith("- do not ")
            or "does not create prs or merge branches" in lower
            or "not create prs or merge branches" in lower
            or "not the default" in lower
            or "phase 3 introduces" in lower
            or "compatibility wrapper" in lower
        )
        active = (
            stripped.startswith("gh pr create")
            or stripped.startswith("gh pr merge")
            or ("--auto" in stripped and not policy)
            or ("auto-merge" in lower and not policy)
            or ("squash merge" in lower and not policy)
            or ("target main" in lower and not policy)
            or ("target master" in lower and not policy)
        )
        if active:
            bad.append(f"{path}:{line_no}: {line}")
if bad:
    raise SystemExit("\n".join(bad))
PY
```

Expected: no output and exit `0`.

- [ ] **Step 9:** Commit the Phase 2 plan.

```bash
git add docs/plans/2026-05-02-phase-2-local-epic-orchestration.md
git commit -m "docs: plan phase 2 local epic orchestration"
```
