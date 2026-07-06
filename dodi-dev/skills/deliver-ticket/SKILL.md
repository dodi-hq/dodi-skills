---
name: deliver-ticket
description: Execute one ready child ticket end to end in a single lane session — pickup through open child PR and child-PR review — ending at ready-to-merge-child
model: sonnet
---

# Deliver Ticket

One lane session per child ticket. The lane runs the full local delivery sequence in the child's worktree, posting checkpoint comments as it crosses each state boundary. The lane never merges and never touches the epic branch.

**Executed inline by the top-level session** — the resident driver (`drive-epic`) or an interactive session — walking this sequence itself and dispatching each phase worker as its own leaf. **Never dispatched as a nested subagent lane** (0.14.1 interim; see Execution Model below). May also be invoked directly for a single ticket from an interactive session.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child has `spec-ready` and `ready-to-implement` | ticket id, clean spec, clean plan (with Testing Contract), register canon summary, epic branch, repo path | `ready-to-merge-child` with full evidence trail, or an exit state | checkpoint comments per state boundary, child PR, notes entries | implementer workers, reviewers, test runners, fix workers | demotion surprise, concrete blocker, resumable context exit |

## Internal Sequence

Each step is the named phase skill's process, executed inside this lane with the same worker dispatch discipline (implementers `model: sonnet` per task — the default pinned in `implement/implementer-prompt.md`, with per-task adjustments per `implement/SKILL.md`; **on a ticket carrying `needs-capable-delivery`, every implementer and fix worker pins `model: opus` instead, no per-task demotion**; fresh-context reviewers — pre-PR: `opus` rounds with a `fable` final; child-PR: one `opus` integration round + a `fable` integration final; `haiku` test runners):

1. `pickup-ticket` — create the child branch and worktree from the current epic branch.
2. `implement-ticket` — implementation workers, exact plan adherence.
3. `review` (pre-PR context) — loop capped at 5 rounds plus the Frontier final round.
4. `create-tests` — satisfy the Testing Contract.
5. `verify` — one test-runner worker per group plus the local-CI runner dispatch (repo-local gates + broader checks, discovery mandate intact); claim results only from digests; every runner digest records the head SHA it ran against; a product-code fix here triggers the focused re-review (`review` § Epic Lane Rules) before the seam.
6. **Context reset seam (verify→PR)** — see Context Hygiene below.
7. `submit-ticket-pr` (Open only) — push the child branch, open the PR against the epic branch, write the PR body.
8. `review` (child-PR context) — the delta-scoped integration pair (one `opus` integration round + a `fable` integration final per `review/child-pr-integration-prompt.md`) ∥ conditional local CI (dispatched in parallel unless the skip predicate holds — per `review`, child-PR context).
9. Report `ready-to-merge-child` with the evidence trail. Do not merge.

## Checkpoints

Post a **Lane Checkpoint** comment (pinned `# Lane Checkpoint` header, carrying the session run id — repo mirror `lane-checkpoint.md` for validation) at each boundary as it is crossed: `implementing`, `implementation-reviewing`, `testing`, `verifying`, `ready-for-child-pr`, `child-pr-reviewing`. The pinned header is load-bearing: under the comment-species partition's unknown⇒bookkeeping default, a headerless checkpoint is invisible to every liveness consumer. These are the audit trail and the resume contract — never batch them at the end.

## Exit States

- **ready-to-merge-child** — success; the orchestrator owns the merge.
- **demote-to-spec** — any product, architecture, scope, or spec/plan mismatch surprise at any step: comment per the demotion rules in `epic-orchestrator/state-transitions.md` and exit. Never redesign mid-flight.
- **blocked** — concrete blocker (auth, tooling, a harness that cannot be set up): comment the blocker and exit.
- **RESUMABLE** — deliberate context exit (see below): write the continuation brief and exit for re-dispatch.

## Resume

A re-dispatched lane reconstructs its position from durable state before doing anything else: checkpoint comments, commits on the child branch, PR state, and the continuation brief. Continue from the last completed boundary. Never redo completed work — an open PR, an existing commit, or a posted checkpoint means that step is done.

## Context Hygiene

- **Mandatory reset at the verify→PR seam:** after `verify` is green (Contract groups + the local-CI runner scope; focused re-review clean if fixes occurred), write the continuation brief and exit `RESUMABLE`. The orchestrator re-dispatches a fresh lane that opens the PR and runs child-PR review. This is the lane's biggest natural boundary; a fresh context reviews the PR without implementation bias.
- **Emergency reset:** if the harness warns context is low mid-lane, finish the current step — never abandon a review round or a dispatched worker — write the continuation brief, and exit `RESUMABLE`. If a step cannot complete, post an explicit "interrupted at" comment so the resume does not double-execute.
- **Continuation brief** (posted as a ticket comment): current state per the checkpoint contract with evidence links, the next action and one line of why, live concerns from notes, and anything in flight that must not be redone.
- **Notes discipline:** append soft observations to the ticket's notes as they occur — flaky tests, retried workers, fragile modules. When unsure whether an observation is worth persisting: write it.

## Execution Model (0.14.1 interim)

**Never run this sequence as a dispatched subagent lane.** Verified harness limitation (2026-07-05): a subagent that dispatches its own worker and ends its turn is never woken — the completion notification routes to the top-level session instead, and no blocking dispatch mode exists (field failure rate 5/5). The top-level session executes this sequence **inline**: it dispatches each phase worker (implementer, reviewer, test runner) as its own **leaf** — every worker prompt carries the leaf rule (work directly; never dispatch sub-agents; the final message is the result) — awaits via dual-wake (native notification primary, `await-worker.sh` backstop), and posts the Lane Checkpoint comments itself. The RESUMABLE/continuation-brief mechanics in Context Hygiene apply when this sequence runs as its own top-level session; when the driver walks it inline, the driver's park/bloat machinery is the pressure valve. The 0.15.0 flatten redesign owns the durable architecture.

## Rules

- Never merge; never push to or rebase the epic branch.
- Never run two implementer workers in parallel within the lane.
- Evidence discipline is unchanged: claim results only from worker digests with commands and exit codes.
- If the epic branch moves while the lane is at the PR stage, update the child branch from the epic branch and rerun relevant checks before reporting `ready-to-merge-child`.
