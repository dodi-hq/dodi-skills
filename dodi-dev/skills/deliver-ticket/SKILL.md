---
name: deliver-ticket
description: Execute one ready child ticket end to end in a single lane session — pickup through open child PR and child-PR review — ending at ready-to-merge-child
model: sonnet
---

# Deliver Ticket

One lane session per child ticket. The lane runs the full local delivery sequence in the child's worktree, posting checkpoint comments as it crosses each state boundary. The lane never merges and never touches the epic branch.

Dispatched by `epic-orchestrator` as a worker (Agent tool, `model: sonnet`), one lane per ticket, up to the orchestrator's `maxParallelLanes`. May also be invoked directly for a single ticket.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child has `spec-ready` and `ready-to-implement` | ticket id, clean spec, clean plan (with Testing Contract), epic branch, repo path | `ready-to-merge-child` with full evidence trail, or an exit state | checkpoint comments per state boundary, child PR, notes entries | implementer workers, reviewers, test runners, fix workers | demotion surprise, concrete blocker, resumable context exit |

## Internal Sequence

Each step is the named phase skill's process, executed inside this lane with the same worker dispatch discipline (implementers per task, fresh-context reviewers with `opus` rounds and a `fable` final round, `haiku` test runners):

1. `pickup-ticket` — create the child branch and worktree from the current epic branch.
2. `implement-ticket` — implementation workers, exact plan adherence.
3. `review` (pre-PR context) — loop capped at 5 rounds plus the Frontier final round.
4. `create-tests` — satisfy the Testing Contract.
5. `verify` — one test-runner worker per group; claim results only from digests.
6. `quality-gate` — horizontal checks with command evidence.
7. **Context reset seam** — see Context Hygiene below.
8. `submit-ticket-pr` (Open only) — push the child branch, open the PR against the epic branch, write the PR body.
9. `review` (child-PR context) — PR reviewer and local CI runner in parallel.
10. Report `ready-to-merge-child` with the evidence trail. Do not merge.

## Checkpoints

Post the standard PM comment at each boundary as it is crossed: `implementing`, `implementation-reviewing`, `testing`, `verifying`, `quality-gating`, `ready-for-child-pr`, `child-pr-reviewing`. These are the audit trail and the resume contract — never batch them at the end.

## Exit States

- **ready-to-merge-child** — success; the orchestrator owns the merge.
- **demote-to-spec** — any product, architecture, scope, or spec/plan mismatch surprise at any step: comment per the demotion rules in `epic-orchestrator/state-transitions.md` and exit. Never redesign mid-flight.
- **blocked** — concrete blocker (auth, tooling, a harness that cannot be set up): comment the blocker and exit.
- **RESUMABLE** — deliberate context exit (see below): write the continuation brief and exit for re-dispatch.

## Resume

A re-dispatched lane reconstructs its position from durable state before doing anything else: checkpoint comments, commits on the child branch, PR state, and the continuation brief. Continue from the last completed boundary. Never redo completed work — an open PR, an existing commit, or a posted checkpoint means that step is done.

## Context Hygiene

- **Mandatory reset at the quality-gate→PR seam:** after `quality-gate` passes, write the continuation brief and exit `RESUMABLE`. The orchestrator re-dispatches a fresh lane that opens the PR and runs child-PR review. This is the lane's biggest natural boundary; a fresh context reviews the PR without implementation bias.
- **Emergency reset:** if the harness warns context is low mid-lane, finish the current step — never abandon a review round or a dispatched worker — write the continuation brief, and exit `RESUMABLE`. If a step cannot complete, post an explicit "interrupted at" comment so the resume does not double-execute.
- **Continuation brief** (posted as a ticket comment): current state per the checkpoint contract with evidence links, the next action and one line of why, live concerns from notes, and anything in flight that must not be redone.
- **Notes discipline:** append soft observations to the ticket's notes as they occur — flaky tests, retried workers, fragile modules. When unsure whether an observation is worth persisting: write it.

## Awaiting Workers

The lane is itself a subagent, so completion notifications from its own workers (implementers, reviewers, test runners) do not reliably arrive — never yield the turn to "wait" for one; that is a stall, not a wait. On Claude Code: after dispatching, poll the worker's `output_file` from inside a single long-timeout Bash call until the file's mtime has been stable for more than 60 seconds, then read only the final JSONL entries for the worker's result. Never read the whole transcript file — it overflows the lane's context.

## Rules

- Never merge; never push to or rebase the epic branch.
- Never run two implementer workers in parallel within the lane.
- Evidence discipline is unchanged: claim results only from worker digests with commands and exit codes.
- If the epic branch moves while the lane is at the PR stage, update the child branch from the epic branch and rerun relevant checks before reporting `ready-to-merge-child`.
