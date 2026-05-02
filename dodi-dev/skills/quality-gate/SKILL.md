---
name: quality-gate
description: Local release gate for dodi-skills metadata, skill files, verification evidence, and workflow risk checks
---

# Quality Gate

Run before submitting or releasing skill changes. Validate plugin metadata, verify the expected published skill files exist, check implementation compliance and risk, and report gaps.

## Process

1. Validate all plugin metadata JSON:

   ```bash
   python3 -m json.tool .claude-plugin/marketplace.json
   python3 -m json.tool dodi-dev/.claude-plugin/plugin.json
   python3 -m json.tool .agents/plugins/marketplace.json
   python3 -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json
   ```

2. Verify both skill trees contain the expected Phase 2 skills:

   ```bash
   for skill in brainstorm file-ticket implement pickup quality-gate review submit verify write-plan epic-orchestrator pickup-epic assess-epic mature-ticket pickup-ticket implement-ticket review-implementation create-tests; do
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

5. Check implementation compliance, security concerns, code hygiene, regression risk, documentation, and operational concerns.

6. Require verification command evidence before passing.

7. Report the commands run and their exit codes. If any command fails, stop and report the missing file or invalid JSON path.

## Local Epic Quality Gate

- Preserve plugin metadata and skill-tree checks.
- Require verification command evidence before passing.
- Check implementation compliance, security concerns, code hygiene, regression risk, documentation, and operational concerns.
- Do not create PRs or merge branches in Phase 2.
