---
name: submit-ticket-pr
description: Open a child ticket PR against the epic branch and coordinate local review, CI-equivalent checks, and merge into the epic branch
model: sonnet
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
