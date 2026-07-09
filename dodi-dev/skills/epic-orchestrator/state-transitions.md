# Epic Orchestration State Transitions

Authoritative transition tables for `epic-orchestrator`, `deliver-ticket` lanes, and the phase skills. Reconstruct state from durable evidence, then act.

## Child-Ticket Transitions (orchestrator-tracked)

These are the states the orchestrator routes on. The delivery pipeline between `delivering` and `ready-to-merge-child` runs inside one `deliver-ticket` lane; its internal states are checkpoints (next table), not orchestrator transitions. The mature lane's four resumable rows (`needs-spec`, `spec-reviewing`, `needs-plan`, `plan-reviewing`) carry the same resume durability the delivery checkpoints do: each is a `RESUMABLE` fallback point, its artifact pushed back to the epic branch before any park, re-dispatched from the last completed boundary. (These are resume *sources*; the completion-anchored refresh-counting *seams* are the transitions the lane effects — see the mature playbook — which is why `needs-spec`, entered at assessment, is resumable but not a refresh seam.) The state transition **is** the mature-lane marker (there is no separate `# Lane Checkpoint` token layer for it) — so both lanes are resumable, deliver by checkpoint and mature by state boundary.

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| unassessed | epic intake or resume | child ticket exists under epic | ticket classification comment or epic assessment summary | needs-spec, spec-ready, needs-plan, ready-to-implement, delivering, ready-to-merge-child, or done | blocked if ticket hierarchy cannot be read |
| needs-spec | epic has `epic-signed-off`, or child has explicit signoff | Gate 1 delegation record (or per-child signoff for `needs-human-spec` children) | draft spec artifact and assumptions comment | spec-reviewing | awaiting-human-spec if the child carries `needs-human-spec` or the drafter returns QUESTIONS_FOR_HUMAN; re-dispatch on RESUMABLE |
| awaiting-human-spec | human responds with approval, edits, or delegation | explicit human signoff or delegated assumptions | finalized spec artifact link and assumptions comment | spec-reviewing | stays awaiting-human-spec if response is ambiguous |
| spec-reviewing | spec is finalized | clean final spec review evidence (incl. scannable header check) | apply `spec-ready`; comment reviewer type and result | needs-plan | remains spec-reviewing if reviewer finds issues; re-dispatch on RESUMABLE |
| needs-plan | ticket has `spec-ready` and no clean plan | clean spec, dependency context, repo context | plan artifact link and Testing Contract | plan-reviewing | returns to awaiting-human-spec if planning exposes product ambiguity; re-dispatch on RESUMABLE |
| plan-reviewing | plan exists | clean final plan review evidence (incl. delivery-tier classification) and dependency check | apply or withhold `ready-to-implement`; apply `needs-capable-delivery` on a `capable` delivery-tier verdict; comment dependency status | ready-to-implement or blocked-dependency | returns to needs-plan if reviewer finds implementation-plan issues; re-dispatch on RESUMABLE |
| blocked-dependency | dependency ticket or branch state changes | dependency implemented or explicitly accounted for | dependency status comment | ready-to-implement | remains blocked-dependency if dependency is unresolved |
| ready-to-implement | orchestrator dispatches a deliver-ticket lane | `spec-ready`, `ready-to-implement`, clean spec, clean plan, no lane in flight (serial in both modes) | lane dispatch comment | delivering | blocked if branch/worktree cannot be created cleanly |
| delivering | lane exits | lane exit state with checkpoint trail | lane checkpoint comments (see next table) | ready-to-merge-child | demote-to-spec on judgment surprise; blocked on concrete blocker; re-dispatch on RESUMABLE |
| ready-to-merge-child | orchestrator takes the serial merge slot | own-session evidence trail (all checkpoints this run id, written this context window) or evidence-checker citations (adoption); child branch current with epic head | apply `coherence-pending` (before the merge, fail-closed), squash merge, branch deletion, child done comment | done | blocked if merge conflict requires spec or plan judgment; back to lane for sync + rerun if epic moved |
| done | child PR merged into epic | merged PR state | child ticket final status | done | no transition unless ticket is reopened |

## Lane Checkpoint Contract (deliver lane)

The deliver lane posts these as **Lane Checkpoint** comments (pinned `# Lane Checkpoint` header, session-run-id field; repo mirror `lane-checkpoint.md` for validation) at each boundary. They are the audit trail and the resume contract — a re-dispatched lane continues from the last completed checkpoint. The pinned header is required: the comment-species partition classifies an unknown header as bookkeeping, which would hide the checkpoint from the wedged-driver probe and the liveness hierarchy. The **mature lane has no `# Lane Checkpoint` token layer** — its equivalent resume/refresh seams are the four state transitions in the table above (the state boundary *is* the marker), carrying the same `RESUMABLE`/push-back-to-epic-branch durability; the checkpoint table below is deliver-specific.

| Checkpoint | Reached when | Evidence in the comment |
| --- | --- | --- |
| implementing | child branch/worktree created, workers dispatched | branch, worktree, plan link |
| implementation-reviewing | implementation commits complete | commit ids, worker evidence |
| testing | pre-PR review clean (incl. fable final round) | review evidence, reviewed diff range |
| verifying | Testing Contract tests exist | test files, harness evidence |
| ready-for-child-pr | verification green (Contract groups + local-CI runner scope; focused re-review clean if fixes occurred) — reset seam for a standalone/manual lane, a durable-brief anchor for the resident driver walking inline (per `deliver-playbook.md` § Context hygiene / `AGENTS.md` § Context Hygiene) | verification evidence, including each runner digest's recorded head SHA with the local-CI runner's named explicitly; continuation brief |
| child-pr-reviewing | child PR open against epic branch | PR link, PR body |
| (exit) ready-to-merge-child | child-PR review clean + local CI clean *or* verify-stage local-CI digest under the conditional-CI predicate (per `submit-ticket-pr` § Merge) | reviewer status, CI digests |

Failure routing inside the lane mirrors the previous per-skill rules: implementation bug → back to implementing; test bug or harness work → back to testing; judgment surprise at any checkpoint → demote-to-spec and exit.

**Resume mapping (pre-0.15.0 checkpoints):** a previously posted `quality-gating` checkpoint reads as `verifying` complete; the next boundary is `ready-for-child-pr`. A pre-0.15.0 lane resuming past `verifying` never ran the verify-stage local-CI runner: run it before posting `ready-for-child-pr`, or post that boundary noting the runner's absence (the no-digest⇒dispatch backstop then forces the child-PR CI run).

## Epic-Level Transitions

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| epic-unassessed | orchestration starts | epic ticket and child tickets readable | epic assessment summary | awaiting-epic-signoff | blocked if PM access fails |
| awaiting-epic-signoff | Gate 1 package posted and human notified | human approval of the package | `epic-signed-off` label; delegation comment quoting what was approved | epic-active | stays awaiting-epic-signoff on ambiguous or partial response |
| epic-active | at least one child is not done | current child state map | next-action summary | epic-active | blocked only if all next actions require human/tool intervention |
| coherence-pending | label applied at the merge close-out **before** the merge command (fail-closed), or by the set-difference boot audit finding a merged-but-unregistered SHA | merged child diff + spec, epic design artifact, Gate 1 package, decision register | register entry + canon summary, label changes on affected children per verdict, corrective ticket on MATERIAL_DRIFT — all keyed to the per-entry merge SHA | epic-active when the register-wide clear predicate holds — the set-difference is empty (every merged child PR holds a **coherence-verdict** register entry — one with no `Kind:` field; `MODE`/`CAPACITY_PARK`/`FABLE_MAKEUP` entries are not verdicts and never satisfy the audit) ∧ no register entry over the epic's merged SHAs is unresolved (a pending-human GATE1_AMENDMENT/GATE1_REFRESH entry with no later `RULING` for its SHA) | remains coherence-pending on an unresolved pending-human entry — the human resolves it via `rule-coherence`; the driver/guard no-op on the park; the merge slot and all canon-consuming dispatches (spec, plan, lane, epic-PR drafting) blocked throughout — except a `RESUMABLE` **deliver** lane resume, whose canon was consumed before it started (a `RESUMABLE` **mature** lane is not exempt — its next action is a fresh canon-consuming dispatch); operator-ordered housekeeping that consumes no canon is exempt |
| epic-ready-for-pr | all children are done | child PR links, latest main/master sync, full regression suite green on integrated epic head, integrated-head review evidence **current with the epic head** (reviewed SHA = regression SHA = PR head), zero unconsumed `FABLE_MAKEUP` obligations (else `pending-capacity`) | scannable epic readiness summary | epic-pr-open | returns to epic-active if a child reopens, sync introduces required fixes, the full regression suite fails, or an integrated-head **judgment** finding files a corrective child ticket (epic-active via the not-done child); integrated-head loop-cap exhaustion ⇒ blocked + escalation |
| epic-pr-open | epic PR created — Gate 2 | PR link targeting main or master | epic ticket PR comment; human notified | epic-pr-open | human merges (production entry); automation never does |

## Workflow Mode and Driver Priority Table

The driver Selects the next action each loop pass by this priority table — single canon. `drive-epic` step 1 references it and never restates the ordering.

**Workflow mode** is durable per-epic state, two-valued — `sprint | waterfall` — scheduling policies over the same lane primitives (same playbooks, different dispatch order):

- **Storage:** epic label `mode-sprint` / `mode-waterfall` (the cheap cache the driver re-reads every loop pass, piggybacking the per-iteration re-scan) **plus** a `# Decision Register Entry` with `Kind: MODE` (keyed by epic id + seam timestamp) carrying the coupling rationale — the register entry is truth, the label caches it. Every mode flip lands a new `MODE` entry; the janitor (`reconcile-tickets`) flags a label-vs-latest-`MODE`-entry mismatch.
- **Decision home:** `assess-epic` decides the mode from the inter-child coupling graph unless the Gate 1 delegation pre-declares it; mid-epic flips are first-class and expected (re-evaluated at each lane close-out and the boot audit — coupling that looked loose tightens once real diffs exist). No third human gate.

**Priority table** (higher rows win; the top four slots are identical in both modes):

| Priority | Action | Eligibility |
| --- | --- | --- |
| 1 | Merge a `ready-to-merge-child` | serial merge slot; **no merge eligible while `coherence-pending`** |
| 2 | Coherence review | a merged SHA holds no coherence-verdict register entry (no `Kind:` field — a `Kind:`-tagged entry never counts) |
| 3 | Epic PR (`submit-epic-pr`) | all children done |
| 4 | Resume a `RESUMABLE` lane | a parked lane exists — **deliver or mature** (both carry `RESUMABLE`). A `RESUMABLE` **deliver** resume is eligible even while `coherence-pending` (its canon was consumed before it started); a `RESUMABLE` **mature** resume is **not** — its next action is a fresh canon-consuming dispatch, so it waits out `coherence-pending` |
| 5 · sprint | `deliver-ticket`, then `mature-ticket` | interleave per child (today's order) |
| 5 · waterfall | `mature-ticket`, then `deliver-ticket` | mature-all-then-deliver-all: `deliver-ticket` is ineligible until every unblocked child carries `ready-to-implement` |

A `hotfix`-labeled ticket is **never selected** by this table — it routes outside the epic machinery (see `file-ticket` hotfix declaration). A `hotfix` label on an epic child is an escalation, not a selectable action.

`coherence-pending` blocking scope and the demotion rules are mode-independent and unchanged: the block covers the merge slot and every canon-consuming dispatch (spec, plan, lane, epic-PR drafting); only a `RESUMABLE` deliver resume, which consumes no canon, is exempt.

## Realignment (LEGITIMATE_DIVERGENCE)

When the coherence review rules that a merged child was right and the epic design was stale:

- The new decision becomes canonical in the register; the superseded design point gets a superseded-by note (never a silent edit).
- Each affected child named by the reviewer: strip `ready-to-implement`; strip `spec-ready` only when the spec itself is invalidated. The driver then re-routes the child through `mature-ticket`, whose drafter consumes the updated canon summary.
- Dependency relations are untouched unless the reviewer explicitly re-sequences.
- Realignment is judged once, at the merge seam — lanes never check-and-repair their own instructions; a perceived register conflict mid-lane remains a demote-to-spec surprise.

## Demotion Rules

When a ticket must return to an earlier lane:

- Demote from any state between `ready-to-implement` and `ready-to-merge-child` (including any lane checkpoint) to the spec lane when a product, architecture, scope, or spec/plan mismatch is discovered.
- Remove or withhold `ready-to-implement`. Keep `spec-ready` only if the spec itself remains valid and the issue is limited to the plan.
- Add a ticket comment with: current state, demotion target, triggering evidence, why automation cannot continue safely, the concrete question or decision needed from the human, and the artifacts that must be revised.
- Preserve existing artifact links for audit history; supersede them with new links after revision rather than deleting old references.
- Close or mark stale an open child PR only when continuing it would be misleading; otherwise leave it open with a blocking comment.
