---
name: submit-ticket-pr
description: Open a child ticket PR against the epic branch (lane-invoked) and merge it into the epic branch (orchestrator-invoked, serial)
model: sonnet
---

# Submit Ticket PR

Two separately invoked halves. **Open** runs inside a `deliver-ticket` lane after the quality gate; **Merge** runs in the orchestrator's serial merge slot after the lane reports `ready-to-merge-child`. Child PRs target the epic branch, never main/master.

## Inputs

- child ticket id
- child branch
- epic branch
- child worktree
- evidence summary from implementation, review, tests, verification, and quality gate

## Open (lane-invoked)

1. Verify the child branch is not main/master and targets the epic branch.
2. Push the child branch.
3. Open a PR from child branch to epic branch.
4. Write a PR body with spec, plan, test evidence, quality-gate evidence, and ticket link. Reference the ticket with the **non-closing** form `Part of <ticket-id>` — never `Closes`/`Fixes` on a child PR: children reach their terminal state when the epic merges to main/master, not when the child merges to the epic branch.
5. Return to the lane — the lane runs `review` (child-PR context) next. Do not merge from this half.

```bash
git push -u origin <child-branch>
gh pr create --base <epic-branch> --head <child-branch> --title "<ticket-id>: <title>" --body-file <pr-body-file>
```

## Merge (orchestrator-invoked, strictly serial)

1. Require the lane's `ready-to-merge-child` report with clean child-PR review and local CI-equivalent evidence, verified by an evidence checker.
2. Verify the child branch is current with the epic head. If the epic moved, return to the lane for a sync and rerun of relevant checks — do not merge a stale branch.
3. Squash merge, then **verify the merge actually happened** — `gh pr merge` can succeed silently without merging. Confirm state and merge commit before claiming success.
4. Delete the child branch. If the child branch is checked out in a worktree, `--delete-branch` fails or misbehaves — skip it and use the explicit sequence: delete the remote branch, remove the worktree, then delete the local branch.
5. Update the child ticket with PR link, merge evidence (including the verified merge commit), and final status.

```bash
gh pr merge <child-pr-number> --squash

# Verification is mandatory — do not claim the merge from the merge command's exit alone.
gh pr view <child-pr-number> --json state,mergeCommit   # expect state MERGED + a commit id
git fetch origin <epic-branch>                          # merge commit reachable on the epic branch

# Branch cleanup when the child branch is checked out in a worktree
# (skip `--delete-branch` in that case):
git push origin --delete <child-branch>
git worktree remove <child-worktree>
git branch -D <child-branch>
```

Expected evidence:

- push output or remote branch URL
- PR URL
- clean child-PR review evidence (`review`, child-PR context)
- local CI-equivalent command evidence
- merge verification: `gh pr view` showing state MERGED plus the merge commit id (merge command output alone is not evidence)
- child ticket comment with final status

## Rules

- Do not target main/master.
- Only the orchestrator's serial merge slot may merge; lanes never do.
- Do not merge if review or local CI-equivalent checks are not clean.
- Do not merge if the child branch is stale against the epic branch.
- Demote per the orchestrator's demotion rules if review or tests expose product, architecture, scope, or spec/plan mismatch.
