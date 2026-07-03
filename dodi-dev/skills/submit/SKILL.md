---
name: submit
description: Use after review passes when a compatibility entry point is needed; epic workflows route to dedicated PR lifecycle skills
model: sonnet
---

# Submit

Compatibility submit entry point. Epic orchestration uses dedicated PR lifecycle skills.

## Process

1. **Pre-flight:**
   - Verify you're on a feature branch (not main/master)
   - Check for uncommitted changes — commit or warn
   - Ensure branch is pushed to remote
   - **Run `/quality-gate`** — this is mandatory. Invoke the quality-gate skill to run compliance checks, create tests, and run the test suite. Do NOT skip this step.
2. For epic workflows, route child ticket branches to `submit-ticket-pr` and epic branches to `submit-epic-pr`.
3. Report the branch, commit range, review evidence, verification evidence, and quality-gate evidence.

## Key Rules

- **Never force-merge or use --admin** without explicit user approval
- Do not create PRs or merge branches from this compatibility skill.
- Leave PR lifecycle work to dedicated epic workflow skills.

## Epic Workflow Submit Policy

`submit` is a compatibility entry point. Epic workflows must use:

- `submit-ticket-pr` for child ticket branches targeting the epic branch.
- `submit-epic-pr` for the epic branch targeting main/master.

Auto-merge is disabled by default. Do not run `gh pr merge --auto` from this skill. Child PRs may still be squash-merged into the epic branch by `submit-ticket-pr` after clean fresh-context review and local CI-equivalent checks. Epic PRs are opened by `submit-epic-pr` and left open for existing GitHub Actions and review.
