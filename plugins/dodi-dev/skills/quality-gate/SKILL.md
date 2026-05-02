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
