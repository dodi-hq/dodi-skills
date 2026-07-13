# Deliver Playbook

The single statement of the deliver lane's sequence: execute one ready child ticket end to end — pickup through open child PR and child-PR review — ending at `ready-to-merge-child`. One lane per child ticket, run in the child's own worktree. **The lane never merges and never touches the epic branch.**

The executing session (the resident driver walking this lane inline, or a manual `deliver-ticket` session) runs this sequence per the dispatch mechanics in `execution-model.md` (leaf rule, tier pins, dual-wake await, STALLED handling, the `RESUMABLE`/seam/continuation-brief mechanics, manifest discipline). This file never restates those mechanics — it declares only the phase sequence, the checkpoints, the durable surface, the exit edges, and the resume key.

## Phase sequence

Each phase is the named phase skill's process, executed inside this lane with the same worker-dispatch discipline. Implementers pin `sonnet` per task (the default in `implement/implementer-prompt.md`, with per-task adjustments per `implement/SKILL.md`); **on a ticket carrying `needs-capable-delivery`, every implementer and fix worker pins `opus` instead, no per-task demotion.** Fresh-context reviewers: pre-PR uses `opus` rounds with a `fable` final; child-PR uses one `opus` integration round plus a `fable` integration final. Test runners pin `haiku`.

| Phase (skill) | Worker prompt(s) | Tier pin + fable-policy | Checkpoint posted | Exit / demotion edge |
| --- | --- | --- | --- | --- |
| `pickup-ticket` | — (git mechanics) | Fast (`haiku`) | `implementing` (child branch/worktree created, workers dispatched — **dispatch-anchored**) | blocked if branch/worktree cannot be created cleanly |
| `implement-ticket` | `implement/implementer-prompt.md` | Standard (`sonnet`), or Capable (`opus`) on `needs-capable-delivery` | `implementation-reviewing` (implementation commits complete) | implementation bug ⇒ back to implementing; judgment surprise ⇒ demote |
| `review` (pre-PR) | `review/review-prompt.md` | Capable (`opus`) rounds + Frontier (`fable`) final; **final round deferred** | `testing` (pre-PR review clean, incl. fable final) | loop capped at 5 rounds + the Frontier final; findings ⇒ another round |
| `create-tests` | — (Testing Contract) | Standard (`sonnet`) | `verifying` (Testing Contract tests exist) | test/harness work ⇒ back to testing |
| `verify` | `verify/test-runner-prompt.md`, `submit-ticket-pr/local-ci-runner-prompt.md` | Fast (`haiku`) runners | `ready-for-child-pr` (verification green; **reset seam for a standalone lane, durable-brief anchor for the resident driver**) | a product-code fix here triggers the focused re-review before the seam |
| `submit-ticket-pr` (Open only) | — | Standard (`sonnet`) | `child-pr-reviewing` (child PR open against epic branch) | — |
| `review` (child-PR) | `review/child-pr-integration-prompt.md` | one Capable (`opus`) integration round + Frontier (`fable`) integration final; **final round deferred on standard-tier, hard on `needs-capable-delivery`** | (exit) `ready-to-merge-child` | child-PR review clean + local CI clean ⇒ report; **do not merge** |

fable-policy values are the per-gate policy the executing session looks up (per § 2 of `execution-model.md`) immediately before writing each dispatch's tier pin; the AGENTS.md gate-policy table is authoritative.

## Internal sequence

1. `pickup-ticket` — create the child branch and worktree from the current epic branch.
2. `implement-ticket` — implementation workers, exact plan adherence.
3. `review` (pre-PR context) — loop capped at 5 rounds plus the Frontier final round.
4. `create-tests` — satisfy the Testing Contract.
5. `verify` — one test-runner worker per group plus the local-CI runner dispatch (repo-local gates + broader checks, discovery mandate intact); claim results only from digests; every runner digest records the head SHA it ran against; a product-code fix here triggers the focused re-review (`review` § Epic Lane Rules) before the seam.
6. **Verify→PR seam** (a context reset for a standalone lane; a durable-brief anchor for the resident driver walking inline) — see § Context hygiene.
7. `submit-ticket-pr` (Open only) — push the child branch, open the PR against the epic branch, write the PR body.
8. `review` (child-PR context) — the delta-scoped integration pair (one `opus` integration round + a `fable` integration final per `review/child-pr-integration-prompt.md`) ∥ conditional local CI (dispatched in parallel unless the skip predicate holds — per `review`, child-PR context).
9. Report `ready-to-merge-child` with the evidence trail, including the child-PR gate's close-out `gate-ledger` line (`review` § Gate Ledger). Do not merge.

## Checkpoints

Post a **Lane Checkpoint** comment (pinned `# Lane Checkpoint` header, carrying the session run id — repo mirror `lane-checkpoint.md` for validation) at each boundary as it is crossed: `implementing`, `implementation-reviewing`, `testing`, `verifying`, `ready-for-child-pr`, `child-pr-reviewing`. The pinned header is load-bearing: under the comment-species partition's unknown⇒bookkeeping default, a headerless checkpoint is invisible to every liveness consumer. These are the audit trail and the resume contract — never batch them at the end.

## Durable surface and resumability

The deliver lane's **declared durable surface is commits on its own child branch/worktree** — the lane never touches the epic branch. Its six internal checkpoints are its progress markers; **five are completion-anchored countable refresh seams**. The `implementing` checkpoint is **dispatch-anchored** — it is posted when workers are dispatched, before any commit exists — so it is a resume checkpoint but **never** a refresh seam. Before any `RESUMABLE`, hard capacity-park, or `refresh-park` exit, the session commits its in-progress work on the child branch and posts/updates the continuation brief keyed to that SHA plus the last checkpoint. The `RESUMABLE`/continuation-brief/push-and-record mechanics themselves are the shared, lane-neutral contract in `execution-model.md` § 5.

## Resume

A re-dispatched lane reconstructs its position from durable state before doing anything else: checkpoint comments, commits on the child branch, PR state, and the continuation brief. Continue from the last completed boundary. Never redo completed work — an open PR, an existing commit, or a posted checkpoint means that step is done.

## Context hygiene

- **Verify→PR seam:** after `verify` is green (Contract groups + the local-CI runner scope; focused re-review clean if fixes occurred), write/refresh the continuation brief keyed to the head SHA. **For a standalone/manual lane session this is a mandatory context reset** — exit `RESUMABLE`; the re-dispatched fresh lane opens the PR and runs child-PR review, so a fresh context reviews the PR without implementation bias. **For the resident driver walking inline it is a durable-brief anchor, not a reset** (per `AGENTS.md` § Context Hygiene — the driver's only resets are park, refresh-park, and bloat): keep the brief current and continue to `submit-ticket-pr` and child-PR review in the same session, unless the refresh-park seam budget trips at this seam. Either way it is the lane's biggest natural boundary.
- **Emergency reset:** if the harness warns context is low mid-lane, finish the current step — never abandon a review round or a dispatched worker — write the continuation brief, and exit `RESUMABLE`. If a step cannot complete, post an explicit "interrupted at" comment so the resume does not double-execute.
- **Continuation brief** (posted as a ticket comment): current state per the checkpoint contract with evidence links, the next action and one line of why, live concerns from notes, and anything in flight that must not be redone.
- **Notes discipline:** append soft observations to the ticket's notes as they occur — flaky tests, retried workers, fragile modules. When unsure whether an observation is worth persisting: write it.

## Exit states

- **ready-to-merge-child** — success; the orchestrator owns the merge.
- **demote-to-spec** — any product, architecture, scope, or spec/plan mismatch surprise at any step: comment per the demotion rules in `state-transitions.md` and exit. Never redesign mid-flight.
- **blocked** — concrete blocker (auth, tooling, a harness that cannot be set up): comment the blocker and exit.
- **RESUMABLE** — a deliberate context exit (the verify→PR seam for a standalone/manual lane only, an emergency reset for either executor, or — driver-only — a capacity-park or refresh-park; see § Context hygiene for the executor split): commit on the child branch, write the continuation brief, and exit for re-dispatch.

## Rules

- Never merge; never push to or rebase the epic branch.
- Never run two implementer workers in parallel within the lane.
- Evidence discipline: claim results only from worker digests with commands and exit codes.
- If the epic branch moves while the lane is at the PR stage, update the child branch from the epic branch and rerun relevant checks before reporting `ready-to-merge-child`.
