# Phase 3 PR Lifecycle Implementation Plan

> **For agentic workers:** Use `dodi-dev:implement` to execute this plan after Phase 2 is complete.

**Goal:** Add child-ticket and epic PR lifecycle skills in both Claude and Codex trees, then bump both runtimes to `0.8.0`.

**Architecture:** Phase 3 extends the local orchestration workflow from Phase 2 with PR-specific skills. Child ticket PRs target the epic branch and may merge into the epic branch after fresh-context review and local CI-equivalent checks. Epic PRs target main/master, are left open, and rely on existing GitHub Actions and review automation.

**Tech Stack:** Markdown skills, JSON plugin manifests, Git/GitHub CLI commands where available.

**Spec:** `docs/specs/2026-05-02-epic-orchestration-design.md`

---

## File Structure

- Modify `.claude-plugin/marketplace.json`: bump `dodi-dev` from `0.7.0` to `0.8.0`.
- Modify `dodi-dev/.claude-plugin/plugin.json`: bump `version` to `0.8.0` and update description to include PR lifecycle.
- Modify `plugins/dodi-dev/.codex-plugin/plugin.json`: bump `version` to `0.8.0` and update description to include PR lifecycle.
- Create in both `dodi-dev/skills/` and `plugins/dodi-dev/skills/`:
  - `review-child-pr/SKILL.md`
  - `submit-ticket-pr/SKILL.md`
  - `submit-epic-pr/SKILL.md`
- Modify in both trees:
  - `epic-orchestrator/SKILL.md`
  - `submit/SKILL.md`
  - `quality-gate/SKILL.md`
- Add supporting prompts in both trees where useful:
  - `review-child-pr/pr-reviewer-prompt.md`
  - `submit-ticket-pr/local-ci-runner-prompt.md`

---

### Task 1: Bump Phase 3 Metadata

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `dodi-dev/.claude-plugin/plugin.json`
- Modify: `plugins/dodi-dev/.codex-plugin/plugin.json`

- [ ] **Step 1:** Run Phase 2 prerequisite checks before editing.

Run:

```bash
python3 - <<'PY'
import json
from pathlib import Path
market = json.loads(Path('.claude-plugin/marketplace.json').read_text())
claude = json.loads(Path('dodi-dev/.claude-plugin/plugin.json').read_text())
codex = json.loads(Path('plugins/dodi-dev/.codex-plugin/plugin.json').read_text())
assert market['plugins'][0]['version'] == '0.7.0'
assert claude['version'] == '0.7.0'
assert codex['version'] == '0.7.0'
PY
for skill in write-plan review verify submit quality-gate epic-orchestrator pickup-epic assess-epic mature-ticket pickup-ticket implement-ticket review-implementation create-tests; do
  test -f "dodi-dev/skills/$skill/SKILL.md" || exit 1
  test -f "plugins/dodi-dev/skills/$skill/SKILL.md" || exit 1
done
python3 - <<'PY'
from pathlib import Path

bad = []
for path in [Path("dodi-dev/skills/submit/SKILL.md"), Path("plugins/dodi-dev/skills/submit/SKILL.md")]:
    for line_no, line in enumerate(path.read_text().splitlines(), 1):
        stripped = line.strip()
        lower = stripped.lower()
        policy = (
            lower.startswith("do not ")
            or lower.startswith("- do not ")
            or "does not create prs or merge branches" in lower
            or "not create prs or merge branches" in lower
            or "not the default" in lower
            or "disabled by default" in lower
            or "compatibility wrapper" in lower
            or "compatibility entry point" in lower
        )
        if stripped.startswith("gh pr merge") or ("--auto" in stripped and not policy) or ("auto-merge" in lower and not policy):
            bad.append(f"{path}:{line_no}: {line}")
if bad:
    raise SystemExit("\n".join(bad))
PY
```

Expected: no output and exit `0`.

- [ ] **Step 2:** Update `.claude-plugin/marketplace.json`.

Expected `plugins[0]` object:

```json
{
  "name": "dodi-dev",
  "description": "Dev workflow, local epic orchestration, and PR lifecycle skills",
  "version": "0.8.0",
  "source": "./dodi-dev"
}
```

- [ ] **Step 3:** Update `dodi-dev/.claude-plugin/plugin.json`.

Expected final content:

```json
{
  "name": "dodi-dev",
  "description": "Dev workflow, local epic orchestration, and PR lifecycle skills",
  "version": "0.8.0",
  "author": {
    "name": "Dodi HQ",
    "email": "may@dodihome.com"
  }
}
```

- [ ] **Step 4:** Update `plugins/dodi-dev/.codex-plugin/plugin.json`.

Expected changed fields:

```json
{
  "version": "0.8.0",
  "description": "Dodi developer workflow, local epic orchestration, and PR lifecycle skills",
  "interface": {
    "shortDescription": "Developer workflow, epic orchestration, and PR lifecycle skills"
  }
}
```

Keep all other Codex plugin metadata fields unchanged.

- [ ] **Step 5:** Verify metadata parses and versions are correct.

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
assert market['plugins'][0]['version'] == '0.8.0'
assert claude['version'] == '0.8.0'
assert codex['version'] == '0.8.0'
print('phase 3 versions ok')
PY
```

Expected:

```text
phase 3 versions ok
```

- [ ] **Step 6:** Commit.

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json plugins/dodi-dev/.codex-plugin/plugin.json
git commit -m "chore: bump dodi-dev to 0.8.0"
```

---

### Task 2: Add Child PR Review Skill

**Files:**
- Create: `dodi-dev/skills/review-child-pr/SKILL.md`
- Create: `dodi-dev/skills/review-child-pr/pr-reviewer-prompt.md`
- Create matching files under `plugins/dodi-dev/skills/review-child-pr/`

- [ ] **Step 1:** Create `review-child-pr/SKILL.md` in both trees.

Required content:

```markdown
---
name: review-child-pr
description: Run fresh-context review and local CI-equivalent checks for a child PR targeting an epic branch
---

# Review Child PR

Use after `submit-ticket-pr` opens a child PR against the epic branch. This is a fresh-context gate. Do not rely on the implementation conversation.

## Inputs

- child PR id or URL
- child ticket id
- epic branch
- child branch
- spec path
- plan path
- local child worktree

## Process

1. Read the ticket, spec, plan, and PR diff.
2. Dispatch a fresh-context PR reviewer using `pr-reviewer-prompt.md`.
3. Dispatch a local CI-equivalent test runner.
4. If review or tests find issues, dispatch fix workers.
5. If production code changes, rerun focused review and affected tests.
6. If the epic branch moved, update the child branch from the epic branch and rerun relevant checks.
7. When clean, report `ready-to-merge-child`.

## Stop Conditions

- Stop on product, architecture, scope, or spec/plan mismatch and demote according to the spec.
- Stop on unresolved merge conflict requiring judgment.
- Stop on auth/tool failure and report the blocker.

## Evidence

Record PR comments, commands run, exit codes, reviewer status, test evidence, and final next action.

## Local CI Runner

Use `submit-ticket-pr/local-ci-runner-prompt.md` when dispatching the local CI-equivalent runner.
```

- [ ] **Step 2:** Create `pr-reviewer-prompt.md` in both trees.

Required content:

```markdown
# Child PR Reviewer Prompt

You are reviewing a child ticket PR targeting an epic branch. Start fresh. Read the ticket, spec, plan, and PR diff directly.

Check:

- spec and plan compliance
- unintended behavior changes
- regression risk across touched modules
- security and data handling
- error handling
- test coverage relative to the Testing Contract
- whether the branch is current with the epic branch

Output:

- **Status:** Approved or Issues Found
- **Issues:** severity, file/line when available, why it matters
- **Required follow-up:** review, tests, demotion, or blocker
```

- [ ] **Step 3:** Verify files exist in both trees.

Run:

```bash
test -f dodi-dev/skills/review-child-pr/SKILL.md
test -f dodi-dev/skills/review-child-pr/pr-reviewer-prompt.md
test -f plugins/dodi-dev/skills/review-child-pr/SKILL.md
test -f plugins/dodi-dev/skills/review-child-pr/pr-reviewer-prompt.md
```

Expected: each command exits `0`.

- [ ] **Step 4:** Commit.

```bash
git add dodi-dev/skills/review-child-pr plugins/dodi-dev/skills/review-child-pr
git commit -m "feat: add child pr review skill"
```

---

### Task 3: Add Child Ticket Submit Skill

**Files:**
- Create: `dodi-dev/skills/submit-ticket-pr/SKILL.md`
- Create: `dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md`
- Create matching files under `plugins/dodi-dev/skills/submit-ticket-pr/`

- [ ] **Step 1:** Create `submit-ticket-pr/SKILL.md` in both trees.

Required content:

```markdown
---
name: submit-ticket-pr
description: Open a child ticket PR against the epic branch and coordinate local review, CI-equivalent checks, and merge into the epic branch
---

# Submit Ticket PR

Use when a child ticket reaches `ready-for-child-pr`. Child PRs target the epic branch, not main/master.

## Inputs

- child ticket id
- child branch
- epic branch
- child worktree
- evidence summary from implementation, review, tests, verification, and quality gate

## Process

1. Verify the child branch is not main/master and targets the epic branch.
2. Push the child branch.
3. Open a PR from child branch to epic branch.
4. Write a PR body with spec, plan, test evidence, quality-gate evidence, and ticket link.
5. Invoke `review-child-pr`.
6. If `review-child-pr` returns clean and the branch is current with epic, squash merge into the epic branch.
7. Delete the child branch after merge.
8. Update the child ticket with PR link, merge evidence, and final status.

## Commands

```bash
git push -u origin <child-branch>
gh pr create --base <epic-branch> --head <child-branch> --title "<ticket-id>: <title>" --body-file <pr-body-file>
gh pr merge <child-pr-number> --squash --delete-branch
```

Expected evidence:

- push output or remote branch URL
- PR URL
- clean `review-child-pr` evidence
- local CI-equivalent command evidence
- merge output
- child ticket comment with final status

## Rules

- Do not target main/master.
- Do not merge if review or local CI-equivalent checks are not clean.
- Do not merge if the child branch is stale against the epic branch.
- Demote according to the spec if review or tests expose product, architecture, scope, or spec/plan mismatch.
```

- [ ] **Step 2:** Create `local-ci-runner-prompt.md` in both trees.

Required content:

```markdown
# Local CI Runner Prompt

Run the repo's CI-equivalent checks for a child PR targeting an epic branch.

Inputs:

- repo path
- child worktree
- Testing Contract
- changed files
- repo instructions from AGENTS.md or CLAUDE.md

Responsibilities:

- discover the repo-local command set
- run required unit, integration, and e2e groups
- set up missing required harnesses where feasible
- run broader module or repository checks needed to catch cross-area regressions
- report commands, exit codes, and failure classification

Do not skip required checks because a harness is absent. Set up the harness or report a concrete blocker.
```

- [ ] **Step 3:** Verify files exist in both trees.

Run:

```bash
test -f dodi-dev/skills/submit-ticket-pr/SKILL.md
test -f dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md
test -f plugins/dodi-dev/skills/submit-ticket-pr/SKILL.md
test -f plugins/dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md
```

Expected: each command exits `0`.

- [ ] **Step 4:** Commit.

```bash
git add dodi-dev/skills/submit-ticket-pr plugins/dodi-dev/skills/submit-ticket-pr
git commit -m "feat: add child ticket pr submit skill"
```

---

### Task 4: Add Epic Submit Skill and Wire Existing Submit

**Files:**
- Create: `dodi-dev/skills/submit-epic-pr/SKILL.md`
- Create matching file under `plugins/dodi-dev/skills/submit-epic-pr/`
- Modify: `dodi-dev/skills/epic-orchestrator/SKILL.md`
- Modify: `plugins/dodi-dev/skills/epic-orchestrator/SKILL.md`
- Modify: `dodi-dev/skills/submit/SKILL.md`
- Modify: `plugins/dodi-dev/skills/submit/SKILL.md`
- Modify: `dodi-dev/skills/quality-gate/SKILL.md`
- Modify: `plugins/dodi-dev/skills/quality-gate/SKILL.md`

- [ ] **Step 1:** Create `submit-epic-pr/SKILL.md` in both trees.

Required content:

```markdown
---
name: submit-epic-pr
description: Open an epic PR from the epic branch to main/master and leave it open for existing GitHub Actions and review
---

# Submit Epic PR

Use when all child tickets under an epic are done and merged into the epic branch.

## Inputs

- epic id
- epic branch
- base branch: main or master
- child ticket list
- child PR links
- epic readiness evidence

## Process

1. Confirm all child tickets are done.
2. Update the epic branch with the latest main/master.
3. Run epic-level `quality-gate`.
4. Prepare an epic readiness summary with child tickets, child PRs, test evidence, known risks, migrations, release notes, and coverage summary.
5. Push the epic branch.
6. Open a PR from epic branch to main/master.
7. Leave the PR open.
8. Update the epic ticket with the PR link and readiness summary.

## Commands

```bash
git checkout <epic-branch>
git fetch origin <base-branch>
git merge --no-ff origin/<base-branch>
git push -u origin <epic-branch>
gh pr create --base <base-branch> --head <epic-branch> --title "<epic-id>: <title>" --body-file <pr-body-file>
```

Expected evidence:

- latest base sync output
- epic quality-gate evidence
- push output or remote branch URL
- epic PR URL
- epic ticket comment with readiness summary

## Rules

- Never auto-merge epic PRs by default.
- Existing GitHub Actions and main-target review automation take over after PR creation.
- Stop if any child ticket is incomplete or reopened.
- Stop if epic-level `quality-gate` fails.
- Stop if syncing latest main/master introduces conflicts or required fixes; return the epic to `epic-active`.
- Stop if PR creation fails; report the blocker with command output.
```

- [ ] **Step 2:** Update both `epic-orchestrator/SKILL.md` files to allow Phase 3 PR lifecycle transitions.

Required additive content:

```markdown
## Phase 3 PR Lifecycle

When a child ticket reaches `ready-for-child-pr`, invoke `submit-ticket-pr` instead of stopping.

Allowed Phase 3 next actions:

- Run `submit-ticket-pr`.
- Run `review-child-pr`.
- Run `submit-epic-pr`.

When every child ticket is `done`, transition the epic to `epic-ready-for-pr` and invoke `submit-epic-pr` after the epic readiness evidence is present.

Child PR transitions:

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| ready-for-child-pr | local checks pass | branch, commits, review, verification, quality-gate evidence | child PR link and PR body | child-pr-reviewing | blocked if PR cannot be created |
| child-pr-reviewing | child PR is open | clean PR review and local CI-equivalent evidence | PR comments and ticket evidence | ready-to-merge-child | returns to implementation-reviewing or verifying based on finding type |
| ready-to-merge-child | child branch is current with epic | clean review/test evidence after latest epic sync | merge commit or squash merge link; child ticket done comment | done | blocked if merge conflict requires spec or plan judgment |
| done | child PR merged into epic | merged PR state | child ticket final status | done | no transition unless ticket is reopened |

Epic PR transitions:

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| epic-ready-for-pr | all children are done | child PR links, latest main/master sync, epic quality gate evidence | epic readiness summary | epic-pr-open | returns to epic-active if a child reopens or sync introduces required fixes |
| epic-pr-open | epic PR created | PR link targeting main or master | epic ticket PR comment | epic-pr-open | existing GitHub Actions and review workflows take over |

Do not auto-merge epic PRs. Existing GitHub Actions and review workflows take over after `epic-pr-open`.
```

- [ ] **Step 3:** Update both `submit/SKILL.md` files.

Required additive content:

```markdown
## Epic Workflow Submit Policy

`submit` is a compatibility entry point. Epic workflows must use:

- `submit-ticket-pr` for child ticket branches targeting the epic branch.
- `submit-epic-pr` for the epic branch targeting main/master.

Auto-merge is disabled by default. Do not run `gh pr merge --auto` from this skill. Child PRs may still be squash-merged into the epic branch by `submit-ticket-pr` after clean fresh-context review and local CI-equivalent checks. Epic PRs are opened by `submit-epic-pr` and left open for existing GitHub Actions and review.
```

- [ ] **Step 4:** Update both `quality-gate/SKILL.md` files.

Required additive content:

```markdown
## PR Lifecycle Contexts

Child PR gate:

- Require clean `review-child-pr` evidence.
- Require local CI-equivalent command evidence.
- Require proof that the child branch is current with the epic branch.
- Do not pass if merge conflicts require product, architecture, scope, or spec/plan judgment.

Epic PR gate:

- Require all child tickets to be done.
- Require child PR links.
- Require latest main/master sync evidence.
- Require an epic readiness summary.
- Do not merge or auto-merge the epic PR.
```

- [ ] **Step 5:** Verify files exist in both trees.

Run:

```bash
test -f dodi-dev/skills/submit-epic-pr/SKILL.md
test -f plugins/dodi-dev/skills/submit-epic-pr/SKILL.md
```

Expected: each command exits `0`.

- [ ] **Step 6:** Commit.

```bash
git add dodi-dev/skills plugins/dodi-dev/skills
git commit -m "feat: add epic pr submit workflow"
```

---

### Task 5: Phase 3 Verification

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
assert market['plugins'][0]['version'] == '0.8.0'
assert claude['version'] == '0.8.0'
assert codex['version'] == '0.8.0'
print('phase 3 versions ok')
PY
```

Expected:

```text
phase 3 versions ok
```

- [ ] **Step 2:** Verify PR lifecycle skill files exist in both trees.

Run:

```bash
for skill in review-child-pr submit-ticket-pr submit-epic-pr; do
  test -f "dodi-dev/skills/$skill/SKILL.md" || exit 1
  test -f "plugins/dodi-dev/skills/$skill/SKILL.md" || exit 1
done
```

Expected: no output and exit `0`.

- [ ] **Step 3:** Verify supporting prompts exist.

Run:

```bash
test -f dodi-dev/skills/review-child-pr/pr-reviewer-prompt.md
test -f dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md
test -f plugins/dodi-dev/skills/review-child-pr/pr-reviewer-prompt.md
test -f plugins/dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md
```

Expected: each command exits `0`.

- [ ] **Step 4:** Verify no symlinks exist in the Codex tree.

Run:

```bash
find plugins/dodi-dev/skills -type l -print
```

Expected: no output.

- [ ] **Step 5:** Verify Phase 3 rewiring content exists.

Run:

```bash
for file in dodi-dev/skills/epic-orchestrator/SKILL.md plugins/dodi-dev/skills/epic-orchestrator/SKILL.md; do
  rg -n "## Phase 3 PR Lifecycle" "$file" >/dev/null
  rg -n 'When a child ticket reaches `ready-for-child-pr`, invoke `submit-ticket-pr` instead of stopping.' "$file" >/dev/null
  rg -n "child-pr-reviewing" "$file" >/dev/null
  rg -n "ready-to-merge-child" "$file" >/dev/null
  rg -n "epic-ready-for-pr" "$file" >/dev/null
  rg -n "epic-pr-open" "$file" >/dev/null
  rg -n "Do not auto-merge epic PRs" "$file" >/dev/null
done
for file in dodi-dev/skills/submit/SKILL.md plugins/dodi-dev/skills/submit/SKILL.md; do
  rg -n "## Epic Workflow Submit Policy" "$file" >/dev/null
  rg -n "submit-ticket-pr" "$file" >/dev/null
  rg -n "submit-epic-pr" "$file" >/dev/null
  rg -n "Auto-merge is disabled by default" "$file" >/dev/null
  rg -n 'Do not run `gh pr merge --auto` from this skill' "$file" >/dev/null
done
python3 - <<'PY'
from pathlib import Path

bad = []
for path in [Path("dodi-dev/skills/submit/SKILL.md"), Path("plugins/dodi-dev/skills/submit/SKILL.md")]:
    for line_no, line in enumerate(path.read_text().splitlines(), 1):
        stripped = line.strip()
        lower = stripped.lower()
        policy = (
            lower.startswith("do not ")
            or lower.startswith("- do not ")
            or "disabled by default" in lower
            or "compatibility entry point" in lower
        )
        if stripped.startswith("gh pr merge") or ("--auto" in stripped and not policy) or ("auto-merge" in lower and not policy):
            bad.append(f"{path}:{line_no}: {line}")
if bad:
    raise SystemExit("\n".join(bad))
PY
for file in dodi-dev/skills/quality-gate/SKILL.md plugins/dodi-dev/skills/quality-gate/SKILL.md; do
  rg -n "## PR Lifecycle Contexts" "$file" >/dev/null
  rg -n "Child PR gate" "$file" >/dev/null
  rg -n "Epic PR gate" "$file" >/dev/null
  rg -n "local CI-equivalent command evidence" "$file" >/dev/null
  rg -n "Do not merge or auto-merge the epic PR" "$file" >/dev/null
done
rg -n "local-ci-runner-prompt.md" dodi-dev/skills/review-child-pr/SKILL.md plugins/dodi-dev/skills/review-child-pr/SKILL.md >/dev/null
cat > /tmp/expected-phase3-files <<'EOF'
dodi-dev/skills/assess-epic/SKILL.md
dodi-dev/skills/brainstorm/SKILL.md
dodi-dev/skills/brainstorm/spec-reviewer-prompt.md
dodi-dev/skills/create-tests/SKILL.md
dodi-dev/skills/epic-orchestrator/SKILL.md
dodi-dev/skills/file-ticket/SKILL.md
dodi-dev/skills/implement-ticket/SKILL.md
dodi-dev/skills/implement/SKILL.md
dodi-dev/skills/implement/implementer-prompt.md
dodi-dev/skills/mature-ticket/SKILL.md
dodi-dev/skills/pickup-epic/SKILL.md
dodi-dev/skills/pickup-ticket/SKILL.md
dodi-dev/skills/pickup/SKILL.md
dodi-dev/skills/quality-gate/SKILL.md
dodi-dev/skills/review-child-pr/SKILL.md
dodi-dev/skills/review-child-pr/pr-reviewer-prompt.md
dodi-dev/skills/review-implementation/SKILL.md
dodi-dev/skills/review/SKILL.md
dodi-dev/skills/review/review-prompt.md
dodi-dev/skills/submit-epic-pr/SKILL.md
dodi-dev/skills/submit-ticket-pr/SKILL.md
dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md
dodi-dev/skills/submit/SKILL.md
dodi-dev/skills/verify/SKILL.md
dodi-dev/skills/write-plan/SKILL.md
dodi-dev/skills/write-plan/plan-reviewer-prompt.md
plugins/dodi-dev/skills/assess-epic/SKILL.md
plugins/dodi-dev/skills/brainstorm/SKILL.md
plugins/dodi-dev/skills/brainstorm/spec-reviewer-prompt.md
plugins/dodi-dev/skills/create-tests/SKILL.md
plugins/dodi-dev/skills/epic-orchestrator/SKILL.md
plugins/dodi-dev/skills/file-ticket/SKILL.md
plugins/dodi-dev/skills/implement-ticket/SKILL.md
plugins/dodi-dev/skills/implement/SKILL.md
plugins/dodi-dev/skills/implement/implementer-prompt.md
plugins/dodi-dev/skills/mature-ticket/SKILL.md
plugins/dodi-dev/skills/pickup-epic/SKILL.md
plugins/dodi-dev/skills/pickup-ticket/SKILL.md
plugins/dodi-dev/skills/pickup/SKILL.md
plugins/dodi-dev/skills/quality-gate/SKILL.md
plugins/dodi-dev/skills/review-child-pr/SKILL.md
plugins/dodi-dev/skills/review-child-pr/pr-reviewer-prompt.md
plugins/dodi-dev/skills/review-implementation/SKILL.md
plugins/dodi-dev/skills/review/SKILL.md
plugins/dodi-dev/skills/review/review-prompt.md
plugins/dodi-dev/skills/submit-epic-pr/SKILL.md
plugins/dodi-dev/skills/submit-ticket-pr/SKILL.md
plugins/dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md
plugins/dodi-dev/skills/submit/SKILL.md
plugins/dodi-dev/skills/verify/SKILL.md
plugins/dodi-dev/skills/write-plan/SKILL.md
plugins/dodi-dev/skills/write-plan/plan-reviewer-prompt.md
EOF
find dodi-dev/skills plugins/dodi-dev/skills -maxdepth 2 -type f | sort > /tmp/actual-phase3-files
diff -u /tmp/expected-phase3-files /tmp/actual-phase3-files
```

Expected: no output and exit `0`.

- [ ] **Step 6:** Commit the Phase 3 plan.

```bash
git add docs/plans/2026-05-02-phase-3-pr-lifecycle.md
git commit -m "docs: plan phase 3 pr lifecycle"
```
