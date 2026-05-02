# Phase 4 Operational Polish Implementation Plan

> **For agentic workers:** Use `dodi-dev:implement` to execute this plan after Phase 3 is complete.

**Goal:** Add reusable operational templates and validation scripts for the dual Claude/Codex skill trees without changing workflow behavior unless the implementation deliberately chooses a versioned behavior change.

**Architecture:** Phase 4 turns the previous phases into easier-to-run operations by adding templates for ticket comments, run ledger records, and local CI-equivalent discovery, plus validation scripts that check metadata and skill-tree parity. These artifacts support Hive and human operators while keeping durable PM state as the source of truth.

**Tech Stack:** Markdown templates, JSONL examples, POSIX shell scripts or Node/Python-free shell validation, JSON metadata validation.

**Spec:** `docs/specs/2026-05-02-epic-orchestration-design.md`

---

## File Structure

- Create: `templates/ticket-comments/`
  - `epic-assessment.md`
  - `spec-ready.md`
  - `ready-to-implement.md`
  - `demotion.md`
  - `child-pr-ready.md`
  - `epic-pr-ready.md`
- Create: `templates/run-ledger/record.jsonl`
- Create: `templates/local-ci/discovery.md`
- Create: `scripts/validate-phase-skills.sh`
- Create: `scripts/validate-plugin-metadata.sh`
- Create: `scripts/validate-ticket-comment-templates.sh`
- Modify: `AGENTS.md` to reference the validation scripts.
- Optionally modify plugin versions only if Phase 4 changes released workflow behavior.

---

### Task 1: Add Ticket Comment Templates

**Files:**
- Create: `templates/ticket-comments/epic-assessment.md`
- Create: `templates/ticket-comments/spec-ready.md`
- Create: `templates/ticket-comments/ready-to-implement.md`
- Create: `templates/ticket-comments/demotion.md`
- Create: `templates/ticket-comments/child-pr-ready.md`
- Create: `templates/ticket-comments/epic-pr-ready.md`

- [ ] **Step 1:** Create `templates/ticket-comments/epic-assessment.md`.

Required content:

```markdown
# Epic Assessment

Epic: `<epic-id>`
Repo: `<repo-path>`
Epic branch: `<epic-branch>`
Epic worktree: `<epic-worktree>`

## Child Ticket State Map

| Ticket | State | Labels | Artifacts | Dependencies | Next Action |
| --- | --- | --- | --- | --- | --- |
| `<ticket-id>` | `<state>` | `<labels>` | `<spec/plan/pr links>` | `<dependency state>` | `<next action>` |

## Ready Work

- `<ticket-id>`: `<why ready>`

## Maturity Work

- `<ticket-id>`: `<what is missing>`

## Blockers

- `<blocker or none>`
```

- [ ] **Step 2:** Create `templates/ticket-comments/spec-ready.md`.

Expected final content:

```markdown
# Spec Ready

Ticket: `<ticket-id>`

## Spec Artifact

- Spec: `<path-or-url>`

## Review Evidence

- Reviewer type: `<product|ux|architect|security|implementation>`
- Final review status: `clean`
- Review artifact or comment: `<path-or-url>`

## Human Signoff

- Signoff: `<approved|delegated>`
- Human: `<name-or-contact>`
- Decision summary: `<what was approved or delegated>`

## Assumptions

- `<assumption or none>`

## Next Action

`write-plan`
```

- [ ] **Step 3:** Create `templates/ticket-comments/ready-to-implement.md`.

Expected final content:

```markdown
# Ready To Implement

Ticket: `<ticket-id>`

## Spec Artifact

- Spec: `<path-or-url>`

## Plan Artifact

- Plan: `<path-or-url>`

## Testing Contract

- Unit: `<required|not-required> - <reason>`
- Integration: `<required|not-required> - <reason>`
- E2E: `<required|not-required> - <reason>`
- Harness/setup: `<requirements>`
- Critical flows: `<flows>`

## Dependency State

- `<dependency status>`

## Review Evidence

- Spec review: `<clean evidence>`
- Plan review: `<clean evidence>`

## Next Action

`pickup-ticket`
```

- [ ] **Step 4:** Create `templates/ticket-comments/demotion.md`.

Expected final content:

```markdown
# Workflow Demotion

Ticket: `<ticket-id>`

## Current State

`<state>`

## Demotion Target

`<needs-spec|awaiting-human-spec|needs-plan>`

## Triggering Evidence

- `<review finding, test failure, worker report, or command output>`

## Why Automation Cannot Continue

`<reason>`

## Human Question

`<specific decision needed>`

## Artifacts To Revise

- Spec: `<path-or-url-or-none>`
- Plan: `<path-or-url-or-none>`
- PR: `<url-or-none>`
```

- [ ] **Step 5:** Create `templates/ticket-comments/child-pr-ready.md`.

Expected final content:

```markdown
# Child PR Ready

Ticket: `<ticket-id>`

## Branches

- Child branch: `<child-branch>`
- Epic branch: `<epic-branch>`

## Evidence

- Implementation commits: `<commits>`
- Pre-PR review: `<clean evidence>`
- Verification: `<commands and status>`
- Quality gate: `<pass evidence>`

## Local Checks

- Unit: `<status>`
- Integration: `<status>`
- E2E: `<status>`
- Broader regression checks: `<status>`

## Next Action

`submit-ticket-pr`
```

- [ ] **Step 6:** Create `templates/ticket-comments/epic-pr-ready.md`.

Expected final content:

```markdown
# Epic PR Ready

Epic: `<epic-id>`

## Completed Children

- `<ticket-id>`: `<summary>`

## Child PR Links

- `<ticket-id>`: `<pr-url>`

## Quality Gate Evidence

- `<command or evidence link>`

## Known Risks

- `<risk or none>`

## Migrations Or Release Notes

- `<migration/release note or none>`

## Test Coverage Summary

- Unit: `<summary>`
- Integration: `<summary>`
- E2E: `<summary>`
- Local CI-equivalent: `<summary>`
```

- [ ] **Step 7:** Verify templates exist and contain required evidence fields.

Run:

```bash
for file in epic-assessment spec-ready ready-to-implement demotion child-pr-ready epic-pr-ready; do
  test -f "templates/ticket-comments/$file.md" || exit 1
done
rg -n "^## Child Ticket State Map$" templates/ticket-comments/epic-assessment.md >/dev/null
rg -n "^## Ready Work$" templates/ticket-comments/epic-assessment.md >/dev/null
rg -n "^## Maturity Work$" templates/ticket-comments/epic-assessment.md >/dev/null
rg -n "^## Blockers$" templates/ticket-comments/epic-assessment.md >/dev/null
rg -n "^## Spec Artifact$" templates/ticket-comments/spec-ready.md >/dev/null
rg -n "^## Review Evidence$" templates/ticket-comments/spec-ready.md >/dev/null
rg -n "^## Human Signoff$" templates/ticket-comments/spec-ready.md >/dev/null
rg -n "^## Testing Contract$" templates/ticket-comments/ready-to-implement.md >/dev/null
rg -n "^## Dependency State$" templates/ticket-comments/ready-to-implement.md >/dev/null
rg -n "^## Demotion Target$" templates/ticket-comments/demotion.md >/dev/null
rg -n "^## Triggering Evidence$" templates/ticket-comments/demotion.md >/dev/null
rg -n "^## Branches$" templates/ticket-comments/child-pr-ready.md >/dev/null
rg -n "^## Evidence$" templates/ticket-comments/child-pr-ready.md >/dev/null
rg -n "^## Local Checks$" templates/ticket-comments/child-pr-ready.md >/dev/null
rg -n "^## Next Action$" templates/ticket-comments/child-pr-ready.md >/dev/null
rg -n "^## Completed Children$" templates/ticket-comments/epic-pr-ready.md >/dev/null
rg -n "^## Child PR Links$" templates/ticket-comments/epic-pr-ready.md >/dev/null
rg -n "^## Quality Gate Evidence$" templates/ticket-comments/epic-pr-ready.md >/dev/null
rg -n "^## Known Risks$" templates/ticket-comments/epic-pr-ready.md >/dev/null
rg -n "^## Migrations Or Release Notes$" templates/ticket-comments/epic-pr-ready.md >/dev/null
rg -n "^## Test Coverage Summary$" templates/ticket-comments/epic-pr-ready.md >/dev/null
```

Expected: no output and exit `0`.

- [ ] **Step 8:** Commit.

```bash
git add templates/ticket-comments
git commit -m "docs: add orchestration ticket comment templates"
```

---

### Task 2: Add Run Ledger and Local CI Discovery Templates

**Files:**
- Create: `templates/run-ledger/record.jsonl`
- Create: `templates/local-ci/discovery.md`

- [ ] **Step 1:** Create `templates/run-ledger/record.jsonl`.

Expected final content:

```jsonl
{"epicId":"PM-123","ticketId":"PM-124","state":"ready-to-implement","action":"applied-label","evidence":["docs/plans/2026-05-02-pm-124-implementation.md"],"nextAction":"pickup-ticket","needsHuman":false,"timestamp":"2026-05-02T00:00:00Z"}
```

- [ ] **Step 2:** Create `templates/local-ci/discovery.md`.

Required content:

```markdown
# Local CI-Equivalent Discovery

Use this checklist when a repo does not already declare a local CI-equivalent command set.

1. Read `AGENTS.md` and `CLAUDE.md`.
2. Inspect package scripts, Makefiles, CI workflow files, and project docs.
3. Identify commands for:
   - dependency install/check
   - format check
   - lint
   - typecheck or build
   - unit tests
   - integration tests
   - e2e tests
4. Compare commands against the ticket Testing Contract.
5. Set up missing required harnesses when feasible.
6. Record the chosen command set before running it.
7. Report commands, exit codes, and failure classification.

Do not skip a required test group solely because a harness is missing. Set up the harness or report a concrete blocker.
```

- [ ] **Step 3:** Validate the JSONL template.

Run:

```bash
python3 - <<'PY'
import json
from pathlib import Path
for line in Path('templates/run-ledger/record.jsonl').read_text().splitlines():
    json.loads(line)
print('jsonl ok')
PY
```

Expected:

```text
jsonl ok
```

- [ ] **Step 4:** Commit.

```bash
git add templates/run-ledger templates/local-ci
git commit -m "docs: add orchestration runtime templates"
```

---

### Task 3: Add Validation Scripts

**Files:**
- Create: `scripts/validate-phase-skills.sh`
- Create: `scripts/validate-plugin-metadata.sh`
- Create: `scripts/validate-ticket-comment-templates.sh`

- [ ] **Step 1:** Create `scripts/validate-phase-skills.sh`.

Expected final content:

```bash
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
```

- [ ] **Step 2:** Create `scripts/validate-plugin-metadata.sh`.

Expected final content:

```bash
#!/usr/bin/env bash
set -euo pipefail

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

market_version = market['plugins'][0]['version']
assert market_version == claude['version'], (market_version, claude['version'])
assert claude['version'] == codex['version'], (claude['version'], codex['version'])
assert claude['version'] == '0.8.0', claude['version']

print(f"plugin metadata ok: {claude['version']}")
PY
```

- [ ] **Step 3:** Create `scripts/validate-ticket-comment-templates.sh`.

Expected final content:

```bash
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
```

- [ ] **Step 4:** Mark scripts executable.

Run:

```bash
chmod +x scripts/validate-phase-skills.sh scripts/validate-plugin-metadata.sh scripts/validate-ticket-comment-templates.sh
```

Expected: no output and exit `0`.

- [ ] **Step 5:** Run the scripts.

Note: the expected metadata version assumes Phase 3 is complete and Phase 4 does not change released workflow behavior. If Phase 4 intentionally changes released workflow behavior, update the expected version to the new release version in the same change.

Run:

```bash
scripts/validate-plugin-metadata.sh
scripts/validate-phase-skills.sh
scripts/validate-ticket-comment-templates.sh
```

Expected:

```text
plugin metadata ok: 0.8.0
<published file list from dodi-dev/skills and plugins/dodi-dev/skills>
phase skills ok
ticket comment templates ok
```

- [ ] **Step 6:** Commit.

```bash
git add scripts/validate-phase-skills.sh scripts/validate-plugin-metadata.sh scripts/validate-ticket-comment-templates.sh
git commit -m "chore: add skill tree validation scripts"
```

---

### Task 4: Update Repo Instructions and Final Verification

**Files:**
- Modify: `AGENTS.md`
- Verify: metadata files
- Verify: both skill trees
- Verify: templates
- Verify: scripts

- [ ] **Step 1:** Update `AGENTS.md` verification commands to prefer the new scripts.

Required content in the `Verification` section:

````markdown
- Run repository validation scripts:

  ```bash
  scripts/validate-plugin-metadata.sh
  scripts/validate-phase-skills.sh
  scripts/validate-ticket-comment-templates.sh
  ```

- Validate runtime templates when they change:

  ```bash
  python3 - <<'PY'
  import json
  from pathlib import Path
  for line in Path('templates/run-ledger/record.jsonl').read_text().splitlines():
      json.loads(line)
  print('jsonl ok')
  PY
  ```
````

- [ ] **Step 2:** Run all Phase 4 verification.

Run:

```bash
scripts/validate-plugin-metadata.sh
scripts/validate-phase-skills.sh
scripts/validate-ticket-comment-templates.sh
python3 - <<'PY'
import json
from pathlib import Path
for line in Path('templates/run-ledger/record.jsonl').read_text().splitlines():
    json.loads(line)
print('jsonl ok')
PY
```

Expected:

```text
plugin metadata ok: 0.8.0
<published file list from dodi-dev/skills and plugins/dodi-dev/skills>
phase skills ok
ticket comment templates ok
```

The JSONL command also prints `jsonl ok` and exits `0`.

- [ ] **Step 3:** Decide whether a version bump is required.

Expected: no version bump if Phase 4 only adds docs/templates/scripts and does not change released workflow behavior.

- [ ] **Step 4:** Commit.

```bash
git add AGENTS.md
git commit -m "docs: update validation instructions"
```
