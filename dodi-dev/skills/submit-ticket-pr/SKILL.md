---
name: submit-ticket-pr
description: Open a child ticket PR against the epic branch (lane-invoked) and merge it into the epic branch (orchestrator-invoked, serial)
model: sonnet
---

# Submit Ticket PR

Two separately invoked halves. **Open** runs inside a `deliver-ticket` lane after verify; **Merge** runs in the orchestrator's serial merge slot after the lane reports `ready-to-merge-child`. Child PRs target the epic branch, never main/master.

## Inputs

- child ticket id
- child branch
- epic branch
- child worktree
- evidence summary from implementation, review, tests, and verification

## Open (lane-invoked)

1. Verify the child branch is not main/master and targets the epic branch.
2. Push the child branch.
3. Open a PR from child branch to epic branch.
4. Write a PR body with spec, plan, test evidence, verification evidence (incl. repo-local + broader checks), and ticket link. Reference the ticket with the **non-closing** form `Part of <ticket-id>` — never `Closes`/`Fixes` on a child PR: children reach their terminal state when the epic merges to main/master, not when the child merges to the epic branch.
5. Return to the lane — the lane runs `review` (child-PR context) next. Do not merge from this half.

```bash
git push -u origin <child-branch>
gh pr create --base <epic-branch> --head <child-branch> --title "<ticket-id>: <title>" --body-file <pr-body-file>
```

## Merge (orchestrator-invoked, strictly serial)

1. Require the lane's `ready-to-merge-child` report with clean child-PR review and local CI-equivalent evidence, verified by an evidence checker.
2. Verify the child branch is current with the epic head. If the epic moved, return to the lane for a sync and rerun of relevant checks — do not merge a stale branch. **De-minimis exception:** if everything the epic gained since the child branched is demonstrably disjoint from the child's file surface *and* touches no code (docs-only housekeeping), the merge slot may proceed — record the divergence assessment and the deviation in the done comment. Any code, config, schema, or generated-file movement means sync, no exceptions.
3. Squash merge, then **verify the merge actually happened** — `gh pr merge` can succeed silently without merging (field-confirmed: zero output, no merge). Never claim the merge from the merge command's exit; claim it from the verification script.
4. Clean up the child branch and worktree via the cleanup script, threading the verified merge SHA through — squash merges rewrite the SHA, so the script's content-match proof requires it.
5. Update the child ticket with PR link, merge evidence (including the verified merge commit), and final status.

```bash
gh pr merge <child-pr-number> --squash

# Verification is mandatory; the script owns the postcondition mechanics.
merge_sha="$("${CLAUDE_PLUGIN_ROOT}/scripts/verify-merge.sh" <child-pr-number> <epic-branch>)"

# Cleanup (handles worktree-checked-out branches; refuses without proof):
"${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-branch.sh" <child-branch> <epic-branch> <child-worktree> . "$merge_sha"
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
