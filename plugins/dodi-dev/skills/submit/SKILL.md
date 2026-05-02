---
name: submit
description: Use after review passes when legacy submit behavior is needed; epic workflows stop locally until PR lifecycle skills are available
---

# Submit

Compatibility submit entry point. Epic orchestration does not use this as the Phase 2 PR path.

## Process

1. **Pre-flight:**
   - Verify you're on a feature branch (not main/master)
   - Check for uncommitted changes — commit or warn
   - Ensure branch is pushed to remote
   - **Run `/quality-gate`** — this is mandatory. Invoke the quality-gate skill to run compliance checks, create tests, and run the test suite. Do NOT skip this step.
2. For local epic orchestration, stop at `ready-for-child-pr`.
3. Report the branch, commit range, review evidence, verification evidence, and quality-gate evidence.

## Key Rules

- **Never force-merge or use --admin** without explicit user approval
- Do not create PRs or merge branches from this compatibility skill in Phase 2.
- Leave PR lifecycle work to Phase 3 skills after they exist.

## Epic Workflow Compatibility

`submit` is a compatibility wrapper. Phase 2 local epic orchestration stops at `ready-for-child-pr` and does not create PRs or merge branches. Phase 3 introduces `submit-ticket-pr` and `submit-epic-pr` for epic workflows.

Auto-merge is not the default documented behavior.
Do not create PRs or merge branches from this compatibility skill in Phase 2.

## Epic Workflow Submit Policy

`submit` is a compatibility entry point. Epic workflows must use:

- `submit-ticket-pr` for child ticket branches targeting the epic branch.
- `submit-epic-pr` for the epic branch targeting main/master.

Auto-merge is disabled by default. Do not run `gh pr merge --auto` from this skill. Child PRs may still be squash-merged into the epic branch by `submit-ticket-pr` after clean fresh-context review and local CI-equivalent checks. Epic PRs are opened by `submit-epic-pr` and left open for existing GitHub Actions and review.
