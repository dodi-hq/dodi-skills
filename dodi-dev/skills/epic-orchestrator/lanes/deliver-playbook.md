# Deliver Playbook

The single statement of the deliver lane's sequence: execute one ready child ticket end to end — pickup through open child PR and child-PR review — ending at `ready-to-merge-child`. One lane per child ticket, run in the child's own worktree. **The lane never merges and never touches the epic branch.**

The executing session (the resident driver walking this lane inline, or a manual `deliver-ticket` session) runs this sequence per the dispatch mechanics in `execution-model.md` (leaf rule, tier pins, dual-wake await, STALLED handling, the `RESUMABLE`/seam/continuation-brief mechanics, manifest discipline). This file never restates those mechanics — it declares only the phase sequence, the checkpoints, the durable surface, the exit edges, and the resume key.

## Phase sequence

Each phase is the named phase skill's process, executed inside this lane with the same worker-dispatch discipline. Implementers pin `sonnet` per task (the default in `implement/implementer-prompt.md`, with per-task adjustments per `implement/SKILL.md`); **on a ticket carrying `needs-capable-delivery`, every implementer and fix worker pins `opus` instead, no per-task demotion.** Fresh-context reviewers: early feedback is Capable; the combined final is one hard Frontier review of completed code/tests and coherence before opening. Post-opening checks reuse current full coverage or renew at hard Frontier; see `review/child-review-contract.md`. Test runners pin `haiku`. The docs-sync worker uses a Frontier pin (soft policy — its edits commit on the child branch before verification and the combined final). Claude-native aliases shown in the table resolve to runtime-native pins per `execution-model.md` § 2.

| Phase (skill) | Worker prompt(s) | Tier pin + Frontier policy | Checkpoint posted | Exit / demotion edge |
| --- | --- | --- | --- | --- |
| `pickup-ticket` | — (git mechanics) | Fast (`haiku`) | `implementing` (child branch/worktree created, workers dispatched — **dispatch-anchored**) | blocked if branch/worktree cannot be created cleanly |
| `implement-ticket` | `implement/implementer-prompt.md` | Standard (`sonnet`), or Capable (`opus`) on `needs-capable-delivery` | `implementation-reviewing` (implementation commits complete) | implementation bug ⇒ back to implementing; judgment surprise ⇒ demote |
| `review` (pre-PR) | `review/review-prompt.md` | Capable early feedback | `testing` (feedback resolved) | findings ⇒ fix and necessary feedback, five-round cap |
| `create-tests` | — (Testing Contract) | Standard (`sonnet`) | `verifying` (Testing Contract tests exist) | test/harness work ⇒ back to testing |
| docs-sync → `verify` → `review` (child-final) | docs-sync, runners, `review/child-pr-integration-prompt.md` | docs-sync existing soft policy; runners Fast; final Frontier **hard on all tiers** | `ready-for-child-pr` (tests/CI and combined correctness/coherence approved; reset seam retained) | changed identity ⇒ checks and Frontier renewal |
| `submit-ticket-pr` (Open only) | — | Standard router | `child-pr-reviewing` (PR open over current approved identity) | stale/unknown coverage ⇒ return for renewal |
| `review` (child-PR) | existing approval; final prompt only on renewal | unchanged: no new reviewer; renewal: Frontier **hard** | `ready-to-merge-child` | serial merge slot repeats live freshness check |

Frontier-policy values are the per-gate policy the executing session looks up (per § 2 of `execution-model.md`) immediately before writing each dispatch's runtime-native tier pin; the AGENTS.md gate-policy table is authoritative. Under Florist the serialized field remains `FLORIST_FABLE_POLICY`.

### Under Florist

The same phases retain implementing, code-review and integrating kernel lanes. Provider seats run only when needed; an implemented kernel coverage path may complete unchanged code-review/integrating work without a provider invocation, recording explicit reuse and preserving slot/pin checks. Every dispatched provider still closes its normal digest. PR creation and merge remain kernel-owned irreversible actions:

| Florist lane | Seat | Phases | Ends at |
| --- | --- | --- | --- |
| `implementing` | `implement-ticket` | implement → Capable feedback → `create-tests` → docs-sync → `verify` → hard Frontier combined final → push | `impl-ready head=<sha>` |
| `pr-open` | — (kernel `pr-create`) | opens the child PR against `FLORIST_EPIC_BRANCH` over the validated review identity | code-review coverage transition, deterministic when supported |
| `code-review` | `review` | coverage/freshness check; changed identity → verification and hard Frontier renewal | `clean-final` (or `findings` at `attempt`+1) |
| `integrating` | `review` | currency check → sync (→ back to `code-review`), or current coverage + staged coherence verdict → `merge-ready` | kernel `child-merge` → `soak-ready` |

What does not run: `pickup-ticket` (the kernel creates the unit worktree on `unit/<FLORIST_UNIT>` from `FLORIST_EPIC_BRANCH` at the `implementing` dispatch), and both halves of `submit-ticket-pr` (its docs-sync and combined-final steps run in the implementing seat; its Merge eligibility rules are the kernel's — currency is the integrating seat's sync edge, review-clean is the pinned clean final round, the verified merge is the kernel's checkpoint read). The verify→PR seam has no counterpart: the seat boundary between `implementing` and `code-review` **is** the fresh-context reset, by construction. No `# Lane Checkpoint` comments are posted — the checkpoints collapse into digest evidence plus each seat's Seat Record — and resume is from the commits on the unit branch plus that record. The result contract — digest grammar, evidence rows, decline vocabulary, gate tiers by `FLORIST_EPIC_TIER` — is each seat skill's § autonomous mode over `epic-orchestrator/florist-worker-contract.md` (§ 9 for the per-seat table). Nothing else in this file changes: digest vocabulary and irreversible-action ownership stay the same; the companion must enforce the new review record and post-merge publication.

## Internal sequence

1. `pickup-ticket` — create the child branch and worktree from the current epic branch.
2. `implement-ticket` — implementation workers satisfy the approved plan outcomes and constraints, owning routine coding choices within them.
3. `review` (pre-PR context) — early Capable feedback and necessary fixes, five-round cap.
4. `create-tests` — satisfy the Testing Contract.
5. Run child docs-sync (existing soft policy), commit any edits, then `verify` — one test-runner worker per group plus the local-CI runner dispatch (repo-local gates + broader checks, discovery mandate intact); claim results only from digests; every runner digest records the head SHA it ran against; a product-code fix here triggers the focused re-review (`review` § Epic Lane Rules) before the seam.
6. `review` (child-final context) — one fresh hard Frontier review of completed code/tests plus coherence per `review/child-review-contract.md`. Record both scopes and full approval identity. Then **Verify→PR seam** (a context reset for a standalone lane; a durable-brief anchor for the resident driver walking inline) — see § Context hygiene.
7. `submit-ticket-pr` (Open only) — revalidate coverage, push and open at the approved identity; carry docs-sync and final correctness/coherence evidence in the PR body.
8. `review` (child-PR context) — explicit freshness/coverage check. Reuse identical full approval; changed identity requires necessary sync/checks and a Frontier renewal. Do not repeat an automatic review pair.
9. Report `ready-to-merge-child` with the evidence trail, including each review round's `review-executor:` record and the child-PR gate's close-out `gate-ledger` line (`review` §§ Native Executor Evidence, Gate Ledger). Do not merge.

## Checkpoints

Post a **Lane Checkpoint** comment (pinned `# Lane Checkpoint` header, carrying the session run id — repo mirror `lane-checkpoint.md` for validation) at each boundary as it is crossed: `implementing`, `implementation-reviewing`, `testing`, `verifying`, `ready-for-child-pr`, `child-pr-reviewing`. The pinned header is load-bearing: under the comment-species partition's unknown⇒bookkeeping default, a headerless checkpoint is invisible to every liveness consumer. These are the audit trail and the resume contract — never batch them at the end.

## Durable surface and resumability

The deliver lane's **declared durable surface is commits on its own child branch/worktree** — the lane never touches the epic branch. Its six internal checkpoints are its progress markers; **five are completion-anchored countable refresh seams**. The `implementing` checkpoint is **dispatch-anchored** — it is posted when workers are dispatched, before any commit exists — so it is a resume checkpoint but **never** a refresh seam. Before any claimed-lane `RESUMABLE`, hard capacity-park, or `refresh-park` exit, run [Clean park](../clean-park.md). It owns persistence and claim close-out for the exit, keyed to the child SHA and last checkpoint; do not separately post an exit brief or release a claim. This includes the emergency and manual exit edges below and does not clear context. The `RESUMABLE`/continuation-brief/push-and-record mechanics themselves are the shared, lane-neutral contract in `execution-model.md` § 5.

## Resume

A re-dispatched lane reconstructs its position from durable state before doing anything else: checkpoint comments, commits on the child branch, PR state, and the continuation brief. Continue from the last completed boundary. A pending prior coherence publication/ruling permits only already-scoped work that consumes no new canon; final/renewal and action freshness checks wait for that barrier to clear. Never redo completed work — an open PR, an existing commit, or a posted checkpoint means that step is done.

## Context hygiene

- **Verify→PR seam:** after verification and the combined Frontier final are green, with full child/base/context approval recorded, **a standalone/manual lane takes its mandatory context exit through [Clean park](../clean-park.md)** and returns `RESUMABLE`; the re-dispatched fresh lane opens the PR and runs child-PR review. The clean-park procedure owns the exit brief and preserves the head SHA. **For the resident driver walking inline this seam is a durable-brief anchor, not a reset**: if the refresh-park budget trips, go directly through clean park; otherwise write/refresh the continuation brief keyed to the head SHA and continue to `submit-ticket-pr` in this session. Either way it is the lane's biggest natural boundary.
- **Emergency reset:** if the harness warns context is low mid-lane, finish the current step — never abandon a review round or a dispatched worker — then exit `RESUMABLE` through [Clean park](../clean-park.md). If a step cannot complete, include explicit "interrupted at" evidence in the continuation narrative so the resume does not double-execute.

## Exit states

"Judgment surprise" and "spec/plan mismatch" below and in the phase table mean a defect in the approved contract or a required change to product behavior, architecture, shared contracts, or scope. Routine implementation choices within the approved task boundaries do not demote the ticket; implementation bugs are fixed in-lane (see `state-transitions.md` § Demotion Rules).

- **ready-to-merge-child** — success; the orchestrator owns the merge.
- **demote-to-spec** — any product, architecture, scope, or spec/plan mismatch surprise at any step: comment per the demotion rules in `state-transitions.md` and exit. Never redesign mid-flight.
- **blocked** — concrete blocker (auth, tooling, a harness that cannot be set up): comment the blocker and exit.
- **RESUMABLE** — a deliberate context exit (the verify→PR seam for a standalone/manual lane only, an emergency reset for either executor, or — driver-only — a capacity-park or refresh-park; see § Context hygiene for the executor split): exit through [Clean park](../clean-park.md), which preserves the child-branch resume anchor and releases owned claims before re-dispatch.

## Rules

- Never merge; never push to or rebase the epic branch.
- Never run two implementer workers in parallel within the lane.
- Evidence discipline: claim results only from worker digests with commands and exit codes.
- If the epic branch moves while the lane is at the PR stage, update the child branch from the epic branch and rerun relevant checks before reporting `ready-to-merge-child`.
