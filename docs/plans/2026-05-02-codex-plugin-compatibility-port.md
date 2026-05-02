# Codex Plugin Compatibility Port Implementation Plan

> **For agentic workers:** Use `dodi-dev:implement` to execute this plan.

**Goal:** Add a first-class Codex `dodi-dev` plugin tree that mirrors the currently released Claude skills, adds a baseline `quality-gate`, and bumps Phase 1 metadata to `0.6.0`.

**Architecture:** Keep Claude and Codex as separate first-class skill trees. Phase 1 is a compatibility release only: it ports existing skills and metadata, but does not add epic orchestration behavior. The Codex tree is a real plugin under `plugins/dodi-dev`, and repo-root `.agents/plugins/marketplace.json` exposes it to Codex.

**Tech Stack:** Markdown skills, JSON plugin manifests, shell verification commands.

**Spec:** `docs/specs/2026-05-02-epic-orchestration-design.md`

---

## File Structure

- Modify `AGENTS.md`: repo instructions for separate Claude/Codex skill trees and dual-runtime skill maintenance.
- Modify `.claude-plugin/marketplace.json`: bump the Claude marketplace entry version from `0.5.0` to `0.6.0`.
- Modify `dodi-dev/.claude-plugin/plugin.json`: bump the Claude plugin version from `0.5.0` to `0.6.0`.
- Create `.agents/plugins/marketplace.json`: Codex marketplace entry for `dodi-dev`.
- Create `plugins/dodi-dev/.codex-plugin/plugin.json`: Codex plugin metadata at `0.6.0`.
- Create `plugins/dodi-dev/skills/`: Codex skill tree copied from current `dodi-dev/skills/`.
- Create `dodi-dev/skills/quality-gate/SKILL.md`: baseline Claude compatibility gate required by current `submit`.
- Create `plugins/dodi-dev/skills/quality-gate/SKILL.md`: matching Codex baseline compatibility gate.

Phase 1 intentionally does not create `epic-orchestrator` or any epic phase skills.

---

### Task 1: Update Repo Instructions

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1:** Ensure `AGENTS.md` describes the two first-class skill trees and the dual-runtime rule.

Expected final content:

````markdown
# dodi-skills - Codex Instructions

## Project Shape

- This repository publishes Dodi developer workflow skills.
- The Claude plugin marketplace entry is `.claude-plugin/marketplace.json`.
- The Claude plugin metadata is `dodi-dev/.claude-plugin/plugin.json`.
- Claude skills live under `dodi-dev/skills/*/SKILL.md`.
- Codex plugin metadata and skills should live in a separate Codex plugin tree.
- New workflow skills must be added to both Claude and Codex skill trees.

## Editing Rules

- Keep Claude and Codex skills functionally equivalent, but allow runtime-native wording and mechanics.
- Do not use symlinks or generated exposure as the long-term distribution model.
- If a released skill changes, update the relevant plugin versions for every affected runtime.
- Preserve each skill's frontmatter with `name` and `description`.
- Keep workflow instructions concrete and command-oriented.
- Prefer adding supporting prompt files beside the owning skill when the prompt is too long for `SKILL.md`.

## Verification

- Validate JSON metadata after edits:

  ```bash
  python -m json.tool .claude-plugin/marketplace.json
  python -m json.tool dodi-dev/.claude-plugin/plugin.json
  python -m json.tool .agents/plugins/marketplace.json
  python -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json
  ```

- Check the published file set before release:

  ```bash
  find dodi-dev/skills plugins/dodi-dev/skills -maxdepth 2 -type f | sort
  ```
````

- [ ] **Step 2:** Verify the file is ASCII-only.

Run:

```bash
LC_ALL=C grep -n '[^ -~]' AGENTS.md
```

Expected: command exits `1` with no output.

- [ ] **Step 3:** Commit.

```bash
git add AGENTS.md
git commit -m "docs: add dual-runtime skill instructions"
```

---

### Task 2: Add Codex Marketplace and Plugin Metadata

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `dodi-dev/.claude-plugin/plugin.json`
- Create: `.agents/plugins/marketplace.json`
- Create: `plugins/dodi-dev/.codex-plugin/plugin.json`

- [ ] **Step 1:** Update `.claude-plugin/marketplace.json` to bump the `dodi-dev` plugin entry to `0.6.0`.

Expected final content:

```json
{
  "name": "dodi-skills",
  "description": "Dodi skills plugins for Claude Code",
  "owner": {
    "name": "Dodi HQ",
    "email": "may@dodihome.com"
  },
  "plugins": [
    {
      "name": "dodi-dev",
      "description": "Dev workflow skills: brainstorm, plan, implement, review, submit",
      "version": "0.6.0",
      "source": "./dodi-dev"
    }
  ]
}
```

- [ ] **Step 2:** Update `dodi-dev/.claude-plugin/plugin.json` to `0.6.0`.

Expected final content:

```json
{
  "name": "dodi-dev",
  "description": "Dev workflow skills: brainstorm, plan, implement, review, submit",
  "version": "0.6.0",
  "author": {
    "name": "Dodi HQ",
    "email": "may@dodihome.com"
  }
}
```

- [ ] **Step 3:** Create `.agents/plugins/marketplace.json`.

Expected final content:

```json
{
  "name": "dodi-skills",
  "interface": {
    "displayName": "Dodi Skills"
  },
  "plugins": [
    {
      "name": "dodi-dev",
      "source": {
        "source": "local",
        "path": "./plugins/dodi-dev"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

- [ ] **Step 4:** Create `plugins/dodi-dev/.codex-plugin/plugin.json`.

Expected final content:

```json
{
  "name": "dodi-dev",
  "version": "0.6.0",
  "description": "Dodi developer workflow skills",
  "author": {
    "name": "Dodi HQ",
    "email": "may@dodihome.com"
  },
  "repository": "https://github.com/dodi-hq/dodi-skills",
  "skills": "./skills/",
  "interface": {
    "displayName": "Dodi Dev",
    "shortDescription": "Developer workflow skills",
    "developerName": "Dodi HQ",
    "category": "Productivity",
    "capabilities": ["Write", "Review"]
  }
}
```

- [ ] **Step 5:** Verify JSON metadata parses.

Run:

```bash
python -m json.tool .claude-plugin/marketplace.json
python -m json.tool dodi-dev/.claude-plugin/plugin.json
python -m json.tool .agents/plugins/marketplace.json
python -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json
```

Expected: each command prints formatted JSON and exits `0`.

- [ ] **Step 6:** Commit.

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json .agents/plugins/marketplace.json plugins/dodi-dev/.codex-plugin/plugin.json
git commit -m "chore: add codex plugin metadata"
```

---

### Task 3: Port Existing Skills to Codex Tree

**Files:**
- Create: `plugins/dodi-dev/skills/brainstorm/SKILL.md`
- Create: `plugins/dodi-dev/skills/brainstorm/spec-reviewer-prompt.md`
- Create: `plugins/dodi-dev/skills/file-ticket/SKILL.md`
- Create: `plugins/dodi-dev/skills/implement/SKILL.md`
- Create: `plugins/dodi-dev/skills/implement/implementer-prompt.md`
- Create: `plugins/dodi-dev/skills/pickup/SKILL.md`
- Create: `plugins/dodi-dev/skills/review/SKILL.md`
- Create: `plugins/dodi-dev/skills/review/review-prompt.md`
- Create: `plugins/dodi-dev/skills/submit/SKILL.md`
- Create: `plugins/dodi-dev/skills/verify/SKILL.md`
- Create: `plugins/dodi-dev/skills/write-plan/SKILL.md`
- Create: `plugins/dodi-dev/skills/write-plan/plan-reviewer-prompt.md`

- [ ] **Step 1:** Copy the released Claude skill tree into the Codex plugin tree as real files, not symlinks.

Run:

```bash
mkdir -p plugins/dodi-dev
cp -R dodi-dev/skills plugins/dodi-dev/skills
```

Expected: `plugins/dodi-dev/skills` exists and contains the same current files as `dodi-dev/skills`.

- [ ] **Step 2:** Verify the copied tree has no symlinks.

Run:

```bash
find plugins/dodi-dev/skills -type l -print
```

Expected: no output.

- [ ] **Step 3:** Verify every current released skill file exists in the Codex tree.

Run:

```bash
test -f plugins/dodi-dev/skills/brainstorm/SKILL.md
test -f plugins/dodi-dev/skills/brainstorm/spec-reviewer-prompt.md
test -f plugins/dodi-dev/skills/file-ticket/SKILL.md
test -f plugins/dodi-dev/skills/implement/SKILL.md
test -f plugins/dodi-dev/skills/implement/implementer-prompt.md
test -f plugins/dodi-dev/skills/pickup/SKILL.md
test -f plugins/dodi-dev/skills/review/SKILL.md
test -f plugins/dodi-dev/skills/review/review-prompt.md
test -f plugins/dodi-dev/skills/submit/SKILL.md
test -f plugins/dodi-dev/skills/verify/SKILL.md
test -f plugins/dodi-dev/skills/write-plan/SKILL.md
test -f plugins/dodi-dev/skills/write-plan/plan-reviewer-prompt.md
```

Expected: each `test -f` exits `0`.

- [ ] **Step 4:** Verify copied files match the source tree before `quality-gate` is added.

Run:

```bash
diff -ru dodi-dev/skills plugins/dodi-dev/skills
```

Expected: no output and exit `0`.

- [ ] **Step 5:** Commit.

```bash
git add plugins/dodi-dev/skills
git commit -m "chore: port released skills to codex tree"
```

---

### Task 4: Add Baseline Quality Gate to Both Trees

**Files:**
- Create: `dodi-dev/skills/quality-gate/SKILL.md`
- Create: `plugins/dodi-dev/skills/quality-gate/SKILL.md`

- [ ] **Step 1:** Create `dodi-dev/skills/quality-gate/SKILL.md`.

Expected final content:

````markdown
---
name: quality-gate
description: Baseline release gate for dodi-skills plugin metadata and published skill files
---

# Quality Gate

Run before submitting or releasing skill changes. Phase 1 is a compatibility gate: validate plugin metadata, verify the expected published skill files exist, and report gaps. Later phases will expand this into a broader horizontal gate for implementation compliance, security, hygiene, and regression risk.

## Process

1. Validate all plugin metadata JSON:

   ```bash
   python -m json.tool .claude-plugin/marketplace.json
   python -m json.tool dodi-dev/.claude-plugin/plugin.json
   python -m json.tool .agents/plugins/marketplace.json
   python -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json
   ```

2. Verify both skill trees contain the expected Phase 1 skills:

   ```bash
   for skill in brainstorm file-ticket implement pickup quality-gate review submit verify write-plan; do
     test -f "dodi-dev/skills/$skill/SKILL.md" || exit 1
     test -f "plugins/dodi-dev/skills/$skill/SKILL.md" || exit 1
   done
   ```

3. Verify supporting prompt files exist in both trees:

   ```bash
   test -f dodi-dev/skills/brainstorm/spec-reviewer-prompt.md
   test -f dodi-dev/skills/implement/implementer-prompt.md
   test -f dodi-dev/skills/review/review-prompt.md
   test -f dodi-dev/skills/write-plan/plan-reviewer-prompt.md
   test -f plugins/dodi-dev/skills/brainstorm/spec-reviewer-prompt.md
   test -f plugins/dodi-dev/skills/implement/implementer-prompt.md
   test -f plugins/dodi-dev/skills/review/review-prompt.md
   test -f plugins/dodi-dev/skills/write-plan/plan-reviewer-prompt.md
   ```

4. Verify the Codex skill tree does not use symlinks:

   ```bash
   find plugins/dodi-dev/skills -type l -print
   ```

   Expected: no output.

5. Report the commands run and their exit codes. If any command fails, stop and report the missing file or invalid JSON path.
````

- [ ] **Step 2:** Copy the same file to `plugins/dodi-dev/skills/quality-gate/SKILL.md`.

Run:

```bash
mkdir -p plugins/dodi-dev/skills/quality-gate
cp dodi-dev/skills/quality-gate/SKILL.md plugins/dodi-dev/skills/quality-gate/SKILL.md
```

Expected: both files exist and are identical.

- [ ] **Step 3:** Verify both quality-gate files match.

Run:

```bash
diff -u dodi-dev/skills/quality-gate/SKILL.md plugins/dodi-dev/skills/quality-gate/SKILL.md
```

Expected: no output and exit `0`.

- [ ] **Step 4:** Verify Phase 1 skill names exist in both trees.

Run:

```bash
for skill in brainstorm file-ticket implement pickup quality-gate review submit verify write-plan; do
  test -f "dodi-dev/skills/$skill/SKILL.md" || exit 1
  test -f "plugins/dodi-dev/skills/$skill/SKILL.md" || exit 1
done
```

Expected: no output and exit `0`.

- [ ] **Step 5:** Commit.

```bash
git add dodi-dev/skills/quality-gate/SKILL.md plugins/dodi-dev/skills/quality-gate/SKILL.md
git commit -m "feat: add baseline quality gate skill"
```

---

### Task 5: Final Phase 1 Verification

**Files:**
- Verify: `AGENTS.md`
- Verify: `.claude-plugin/marketplace.json`
- Verify: `dodi-dev/.claude-plugin/plugin.json`
- Verify: `.agents/plugins/marketplace.json`
- Verify: `plugins/dodi-dev/.codex-plugin/plugin.json`
- Verify: `dodi-dev/skills/`
- Verify: `plugins/dodi-dev/skills/`

- [ ] **Step 1:** Run metadata validation.

Run:

```bash
python -m json.tool .claude-plugin/marketplace.json
python -m json.tool dodi-dev/.claude-plugin/plugin.json
python -m json.tool .agents/plugins/marketplace.json
python -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json
```

Expected: each command prints formatted JSON and exits `0`.

- [ ] **Step 2:** Confirm all Phase 1 skill directories exist in both runtime trees.

Run:

```bash
for skill in brainstorm file-ticket implement pickup quality-gate review submit verify write-plan; do
  test -d "dodi-dev/skills/$skill" || exit 1
  test -d "plugins/dodi-dev/skills/$skill" || exit 1
done
```

Expected: no output and exit `0`.

- [ ] **Step 3:** Confirm required supporting prompts exist in both runtime trees.

Run:

```bash
test -f dodi-dev/skills/brainstorm/spec-reviewer-prompt.md
test -f dodi-dev/skills/implement/implementer-prompt.md
test -f dodi-dev/skills/review/review-prompt.md
test -f dodi-dev/skills/write-plan/plan-reviewer-prompt.md
test -f plugins/dodi-dev/skills/brainstorm/spec-reviewer-prompt.md
test -f plugins/dodi-dev/skills/implement/implementer-prompt.md
test -f plugins/dodi-dev/skills/review/review-prompt.md
test -f plugins/dodi-dev/skills/write-plan/plan-reviewer-prompt.md
```

Expected: each `test -f` exits `0`.

- [ ] **Step 4:** Confirm the Codex tree has no symlinks.

Run:

```bash
find plugins/dodi-dev/skills -type l -print
```

Expected: no output.

- [ ] **Step 5:** Confirm Phase 1 metadata versions.

Run:

```bash
python - <<'PY'
import json
from pathlib import Path

market = json.loads(Path('.claude-plugin/marketplace.json').read_text())
claude = json.loads(Path('dodi-dev/.claude-plugin/plugin.json').read_text())
codex = json.loads(Path('plugins/dodi-dev/.codex-plugin/plugin.json').read_text())

assert market['plugins'][0]['version'] == '0.6.0'
assert claude['version'] == '0.6.0'
assert codex['version'] == '0.6.0'
print('versions ok')
PY
```

Expected:

```text
versions ok
```

- [ ] **Step 6:** Confirm the working tree state is expected for the chosen commit cadence.

Run:

```bash
git status --short
```

Expected if the per-task commits above were created: output includes only uncommitted planning docs, if any:

```text
?? docs/specs/2026-05-02-epic-orchestration-design.md
?? docs/plans/2026-05-02-codex-plugin-compatibility-port.md
```

Expected if the implementer intentionally batches commits instead: output includes only intended Phase 1 files from this plan plus the spec and plan docs, with normal `git status --short` prefixes such as `M`, `A`, or `??`.

- [ ] **Step 7:** Commit final verification or remaining docs if not already committed.

```bash
git add AGENTS.md docs/specs/2026-05-02-epic-orchestration-design.md docs/plans/2026-05-02-codex-plugin-compatibility-port.md
git commit -m "docs: plan codex compatibility port"
```
