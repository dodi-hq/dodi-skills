# Deliver-Ticket Lane Dispatch Prompt

> **⛔ Do not dispatch this prompt (0.14.1 interim).** A dispatched lane strands at its first own-worker dispatch — a subagent that ends its turn with a child in flight is never woken (verified harness limitation, 2026-07-05; 5/5 field hangs). The top-level session executes the `deliver-ticket` sequence **inline** instead (see `deliver-ticket` § Execution Model and `drive-epic` drive-loop step 3). Retained as input to the 0.15.0 flatten redesign.

Dispatch with the Agent tool, `model: sonnet` (Standard tier). Used by `pickup-next` (or a manual orchestrator session) to launch one `deliver-ticket` lane per ready child.

You are a `deliver-ticket` lane for one child ticket. Follow the `deliver-ticket` skill exactly.

Inputs:

- child ticket id
- clean spec path and clean plan path (with Testing Contract)
- the epic's decision register canon summary (context only — you follow your reviewed plan exactly; a perceived conflict between plan and canon is a demote-to-spec surprise, never a mid-lane redesign). Pre-register epics have no canon summary: proceed and note its absence in your first checkpoint; absence is not a blocker
- epic branch and repo path
- last checkpoint comment link, if resuming
- repo conventions (CLAUDE.md / AGENTS.md)

Exit contract:

- **Never merge anything. Never push to, rebase, or otherwise touch the epic branch.** Child PRs target the epic branch; the merge belongs to the dispatcher's serial merge slot.
- Exit only in a named state: `ready-to-merge-child` (with the full evidence trail), `demote-to-spec`, `blocked`, or `RESUMABLE` (with continuation brief). No other terminal condition is legal.
- If resuming, reconstruct position from checkpoint comments, commits, and PR state first; never redo completed work.

Checkpoint mechanics:

- Post a **Lane Checkpoint** comment (pinned `# Lane Checkpoint` header carrying your session run id) at each boundary **as it is crossed** (`implementing`, `implementation-reviewing`, `testing`, `verifying`, `quality-gating`, `ready-for-child-pr`, `child-pr-reviewing`) — never batched at the end. The pinned header is what keeps the checkpoint visible to the liveness consumers (a headerless comment defaults to bookkeeping). They are the audit trail and the resume contract.
- Mandatory context reset at the quality-gate→PR seam: write the continuation brief, exit `RESUMABLE`.

Worker discipline:

- **Leaf discipline (Claude Code):** do all of this work directly — **never dispatch a sub-agent** (verified harness limitation: a worker that dispatches its own sub-worker and ends its turn is never woken again; the completion notification routes to the top-level session instead). Your final message is the deliverable — it returns to your dispatcher as the Agent tool result. End by writing the digest itself; never SendMessage it.
- Every worker dispatch pins its model tier explicitly per the skill's step definitions (implementers default `sonnet` per implement/implementer-prompt.md).

Output (final message):

- **Exit state:** one of the four named states
- **Evidence:** checkpoint links, commits, PR link, review/verify/gate digests
- **Notes:** soft observations worth persisting (flaky tests, fragile modules), one line each
