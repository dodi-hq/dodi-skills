# Clean park before a resumable exit

Use this procedure at every claimed-lane `RESUMABLE` exit, including manual verify-to-PR exits, emergency exits, mid-lane operator waits, and driver capacity/refresh parks. Resource cleanup does not clear, compact, or reset the conversation. An invocation-time stop before any claim or work exists needs no park. Florist workers keep their kernel-owned digest/lease contract and must not run this helper.

## Commands and request

The helper requires Python 3, git and the existing Linear API environment (`LINEAR_API_KEY`, used by `linear-api.sh`). Put the JSON request outside the lane's worktree. Retain the `claim_id=` printed by `claim.sh` and use it as `ticket_claim_id`. Both a new acquisition and an own-session no-op print that ID. A foreign-claim refusal is an ownership blocker, not permission to select another claim. A manual request has this shape:

```json
{
  "session_id": "workflow-run-id",
  "worktree": "/absolute/lane-worktree",
  "branch": "declared-lane-branch",
  "remote": "origin",
  "manifest": "/absolute/dispatch-manifest-workflow-run-id.jsonl",
  "ticket_id": "DOD-123",
  "ticket_claim_id": "owned-claim-comment-id",
  "seam": "ready-for-child-pr",
  "brief": "Current state and evidence; next action and why; concerns; interrupted work; completed review records and ledger tally."
}
```

An existing empty manifest explicitly represents a session with no dispatched workers; a missing manifest is not evidence that workers are settled. `branch` names the durable push destination. Optional `source_branch` names the checked-out local branch and defaults to `branch`; an ephemeral mature worktree must set it to its local mature branch while keeping `branch` set to the epic branch. The helper pushes the saved commit without checking out or changing the epic worktree. `brief` is the narrative text, not a filename. The helper adds the pinned header, SHA and seam metadata. A driver adds `"mode": "driver"` and a `driver` object with `epic_id`, `claim_id`, `refresher_pid` (the actual integer PID captured at boot) and `exit_state` (`parked`, `refresh-park`, or `bloat-handoff`). `native_session_id` is optional and defaults to `CLAUDE_CODE_SESSION_ID` where available; never substitute the workflow run id for an unknown native id.

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/clean-park.sh" begin /absolute/park-request.json
# Use the absolute `record` path returned by begin in subsequent commands.
"${CLAUDE_PLUGIN_ROOT}/scripts/clean-park.sh" run /absolute/returned-record.json
"${CLAUDE_PLUGIN_ROOT}/scripts/clean-park.sh" status /absolute/returned-record.json
# Driver only, after confirming process AND in-flight request quiescence:
"${CLAUDE_PLUGIN_ROOT}/scripts/clean-park.sh" finish /absolute/returned-record.json --refresher-stopped
```

The helper keeps atomic owner-local records under `~/.dodi/clean-park` (mode 0700 directory, 0600 files), independently of cwd. `DODI_CLEAN_PARK_HOME` may select another absolute owner-local directory, but the helper and native hook must share that environment. Retry the returned record with its original workflow identity and anchor. Only a `completed` status proves a clean park: an exit code of zero for `begin`, `status`, or a driver awaiting shutdown is not completion.

## Prepare

1. A driver verifies its claim fence and running refresher **before shared preparation writes**, including commits on the epic branch and capacity labels/register entries. Ownership loss stops durable writes. Capacity-specific state and the reason for the park remain the caller's responsibility.
2. Finish the current worker, or stop it with the runtime's agent primitive and confirm termination. Run `${CLAUDE_PLUGIN_ROOT}/scripts/reap-workers.sh` on the manifest, settle stragglers and append reap records. A reap classification alone does not stop a worker. Prepare the final continuation narrative after these results are known: current state/evidence, next action and reason, concerns, interrupted work that must not be repeated, and completed `review-executor:` records with the running gate-ledger tally.
3. Explicitly arm the exit through `${CLAUDE_PLUGIN_ROOT}/scripts/clean-park.sh begin` using that prepared request, **before the exit's push, brief post or claim release**. The request is immutable, including its narrative; the helper adds the actual commit SHA when `run` locks the anchor. Bind the workflow session, ticket and exact owned claim, absolute worktree, declared remote/branch, last completed seam and absolute manifest. A driver also supplies its epic and exact driver claim. Bind the native Claude id separately when available; never infer a park from transcript words.
4. Commit the intended in-progress artifacts in the declared source worktree on `source_branch` (or `branch` when they are the same). Deliver pushes that source commit to its child branch; mature pushes it to the epic destination branch, without switching an ephemeral mature worktree onto the epic branch. Keep request/receipt scratch files outside the worktree or in its existing ignored runtime directory; do not commit them as implementation work. Do not release claims while a worker may still write.

## Persist and release

Run the helper against the armed record. It owns the deterministic checks, explicit non-force push, remote-SHA verification, continuation-brief persistence and exact ticket-claim close-out. The brief records the commit and last seam as the successor's resume anchor. Follow the helper's concrete failure result; never improvise a replacement PM or claim mechanism after it fails.

A manual lane completes when the helper reports a verified clean park. A driver first reaches `awaiting-refresher-stop`: stop its owned refresher through the runtime process handle and confirm both the process **and any in-flight refresh request** have finished. Then invoke the helper's `finish` operation with that confirmation. It rechecks the three claim-state fence conjuncts before releasing the recorded driver claim. Refresher quiescence replaces the fourth, refresher-alive conjunct only during this controlled final shutdown; preparation still requires the live refresher. This ordering prevents a delayed refresh from reopening a released claim. Never use a generic hook to kill an unverified PID.

Keep the existing exit meanings: the ticket claim closes as `RESUMABLE`; the driver claim uses `parked`, `refresh-park`, or `bloat-handoff` as applicable. Manual resource cleanup does not set driver park labels or start a capacity probe. The helper does not change retry ceilings, eligibility, scheduling, or context.

## Failure and retry

A superseding ticket claim stops the older session before another push or PM write; closing the successor's claim does not restore the older session's authority. An incomplete park remains recorded with the failed step. Fix the concrete cause and retry the same record; never choose a new claim, move the saved anchor to newer work, or call a partial park successful. A completed record is safe to check again without external mutations.

If cleanup cannot complete, settle owned workers and stop/quiesce the owned refresher first, including lease-only mode. Use the explicit `interrupt` operation with the reason and confirmations; report **cleanup incomplete**, the saved anchor/evidence, and the next recovery action. This releases no claims and leaves the unreleased lease to expire naturally. A crash, forced stop or unconfirmed worker termination remains recovery territory, never a clean park.

## Native Stop backstop

The Claude command Stop hook checks only an explicitly armed native-session record. Unarmed turns are unaffected. A pending record blocks normal Stop, including a repeated Stop, with a concrete cleanup instruction. After a Stop block, finish cleanup or explicitly record an incomplete exit after settling workers and the refresher; do not repeatedly retry unchanged failing operations. Only a clean or explicitly interrupted record permits normal stopping. A user interrupt or forced harness stop remains recovery territory and leaves incomplete evidence; it never produces a successful park receipt. This backstop neither creates a park nor clears context, and cannot handle a user interrupt or API failure that does not fire a Stop event.

The explicit helper/procedure is required on every runtime. Native Stop enforcement is declared only for Claude Code; do not assume Grok or Codex support. Claude automatically loads the conventional `hooks/hooks.json` command configuration; the manifest registers only the additional function module configuration. Do not also list the conventional file in the manifest, which would duplicate loading. Configuration validation and fixture tests do not prove live event activation.
