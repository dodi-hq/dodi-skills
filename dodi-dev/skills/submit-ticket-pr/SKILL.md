---
name: submit-ticket-pr
description: Open a child ticket PR against the epic branch (lane-invoked) and merge it into the epic branch (orchestrator-invoked, serial)
model: sonnet
---

# Submit Ticket PR

Two separately invoked halves. **Open** runs inside a `deliver-ticket` lane after verify; **Merge** runs in the orchestrator's serial merge slot after the lane reports `ready-to-merge-child`. Child PRs target the epic branch, never main/master.

**Under Florist neither half runs** — this skill holds no seat. The kernel opens the child PR (`pr-create`) once the implementing seat's `impl-ready` digest verifies, and merges it (`child-merge`) once the integrating seat's verdict lands; both are irreversible actions performed over an exact head SHA. The docs-sync and combined hard Frontier final steps run in the implementing seat (`implement-ticket` § Phase sequence) so its edits sit on the head the PR opens over. The Merge section's eligibility rules hold there as kernel mechanics: currency is the integrating seat's sync edge, review-clean is the pinned clean final round, the verified merge is the kernel's checkpoint read. See `epic-orchestrator/florist-worker-contract.md` § 9 and `review/florist-companion.md`; this experiment requires companion enforcement before Florist delivery can succeed.

## Inputs

- child ticket id
- child branch
- epic branch
- child worktree
- evidence summary from implementation, review, tests, and verification

## Open (lane-invoked)

1. Verify the child branch is not main/master and targets the epic branch.
2. Require the completed docs-sync, verification and combined hard Frontier final record from the lane, per `review/child-review-contract.md`. Docs-sync runs before verification/final now, not while opening the PR. If absent, return to those stages.
3. Independently refresh HEAD, target epic/base and decision context, check the full durable coverage record, and verify remote HEAD equals reviewed HEAD after the push. Stale/unknown identity returns for checks and Frontier renewal; never open on early feedback alone.
4. Open the PR from the reviewed child HEAD to the reviewed epic branch. Preserve serialized ownership and read back the created PR's head/base; detected drift invalidates approval and blocks downstream progress.
5. Write the PR body with spec/plan, test and local-CI evidence, docs-sync, combined correctness/coherence approval and identity, plus `Part of <ticket-id>` (never a closing keyword).
6. Return to the lane's child-PR coverage/freshness check. Identical covered work needs no new reviewer; do not merge from this half.

```bash
git push -u origin <child-branch>
gh pr create --base <epic-branch> --head <child-branch> --title "<ticket-id>: <title>" --body-file <pr-body-file>
```

## Merge (orchestrator-invoked, strictly serial)

This section is the **single source of merge eligibility** — consumers reference it, never restate it.

1. Require the lane's `ready-to-merge-child` report with clean child-PR review and local CI-equivalent evidence — evidence-checker citations when adopting (per the epic-orchestrator Evidence Rule); own-session evidence trail otherwise.
2. Under the serial merge slot, revalidate the full combined approval, current remote child/target identity and decision context per `review/child-review-contract.md`. Verify the child branch is current with the epic head. If the epic moved, return to the lane for a sync and rerun of relevant checks — do not merge a stale branch. The child-review experiment requires exact base identity; the former docs-only de-minimis exception cannot bypass renewal.
3. Squash merge, then **verify the merge actually happened** — `gh pr merge` can succeed silently without merging (field-confirmed: zero output, no merge). Never claim the merge from the merge command's exit; claim it from the verification script.
4. Before cleanup, transfer the staged coherence approval only after verifying the merged parent/tree match the approved base/child, per `review/child-review-contract.md`. Publish the register/canon and affected-child routing serially under the real merge SHA through the orchestrator; keep `coherence-pending` until complete. Failed/uncertain transfer requires hard Frontier audit, not another automatic pass for a proven match.
5. Clean up the child branch/worktree with the verified merge SHA via the cleanup script, then update the child ticket with merge and publication evidence. Preserve the durable proposal/report for crash recovery.

```bash
gh pr merge <child-pr-number> --squash

# Verification is mandatory; the script owns the postcondition mechanics.
merge_sha="$("${CLAUDE_PLUGIN_ROOT}/scripts/verify-merge.sh" <child-pr-number> <epic-branch>)"

# Complete the proposal transfer/publication in step 4 before cleanup.
# Cleanup (handles worktree-checked-out branches; refuses without proof):
"${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-branch.sh" <child-branch> <epic-branch> <child-worktree> . "$merge_sha"
```

Expected evidence:

- push output or remote branch URL
- the `docs-sync:` evidence line (updated paths, or an attributed no-op with its reason)
- PR URL
- combined Frontier correctness/coherence approval, full identity and explicit child-PR freshness/reuse evidence (`review/child-review-contract.md`)
- local CI-equivalent command evidence — a child-PR-stage local CI digest, or the **checkpoint-recorded** verify-stage local-CI digest when current HEAD/base and Testing Contract coverage permit reuse (`review/child-review-contract.md`; the durable record, not session memory)
- merge verification: `gh pr view` showing state MERGED plus the merge commit id (merge command output alone is not evidence)
- child ticket comment with final status

## Rules

- Do not target main/master.
- Only the orchestrator's serial merge slot may merge; lanes never do.
- Do not merge if review or local CI-equivalent checks are not clean.
- Do not merge if the child branch is stale against the epic branch.
- Demote per the orchestrator's demotion rules if review or tests expose product, architecture, scope, or spec/plan mismatch.
