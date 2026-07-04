# Epic Orchestration State Transitions

Authoritative transition tables for `epic-orchestrator`, `deliver-ticket` lanes, and the phase skills. Reconstruct state from durable evidence, then act.

## Child-Ticket Transitions (orchestrator-tracked)

These are the states the orchestrator routes on. The delivery pipeline between `delivering` and `ready-to-merge-child` runs inside one `deliver-ticket` lane; its internal states are checkpoints (next table), not orchestrator transitions.

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| unassessed | epic intake or resume | child ticket exists under epic | ticket classification comment or epic assessment summary | needs-spec, spec-ready, needs-plan, ready-to-implement, delivering, ready-to-merge-child, or done | blocked if ticket hierarchy cannot be read |
| needs-spec | epic has `epic-signed-off`, or child has explicit signoff | Gate 1 delegation record (or per-child signoff for `needs-human-spec` children) | draft spec artifact and assumptions comment | spec-reviewing | awaiting-human-spec if the child carries `needs-human-spec` or the drafter returns QUESTIONS_FOR_HUMAN |
| awaiting-human-spec | human responds with approval, edits, or delegation | explicit human signoff or delegated assumptions | finalized spec artifact link and assumptions comment | spec-reviewing | stays awaiting-human-spec if response is ambiguous |
| spec-reviewing | spec is finalized | clean final spec review evidence (incl. scannable header check) | apply `spec-ready`; comment reviewer type and result | needs-plan | remains spec-reviewing if reviewer finds issues |
| needs-plan | ticket has `spec-ready` and no clean plan | clean spec, dependency context, repo context | plan artifact link and Testing Contract | plan-reviewing | returns to awaiting-human-spec if planning exposes product ambiguity |
| plan-reviewing | plan exists | clean final plan review evidence and dependency check | apply or withhold `ready-to-implement`; comment dependency status | ready-to-implement or blocked-dependency | returns to needs-plan if reviewer finds implementation-plan issues |
| blocked-dependency | dependency ticket or branch state changes | dependency implemented or explicitly accounted for | dependency status comment | ready-to-implement | remains blocked-dependency if dependency is unresolved |
| ready-to-implement | orchestrator dispatches a deliver-ticket lane | `spec-ready`, `ready-to-implement`, clean spec, clean plan, lane slot free per parallelism policy | lane dispatch comment | delivering | blocked if branch/worktree cannot be created cleanly |
| delivering | lane exits | lane exit state with checkpoint trail | lane checkpoint comments (see next table) | ready-to-merge-child | demote-to-spec on judgment surprise; blocked on concrete blocker; re-dispatch on RESUMABLE |
| ready-to-merge-child | orchestrator takes the serial merge slot | evidence-checker citations; child branch current with epic head | squash merge, branch deletion, child done comment | done | blocked if merge conflict requires spec or plan judgment; back to lane for sync + rerun if epic moved |
| done | child PR merged into epic | merged PR state | child ticket final status | done | no transition unless ticket is reopened |

## Lane Checkpoint Contract (inside deliver-ticket)

The lane posts these as **Lane Checkpoint** comments (pinned `# Lane Checkpoint` header, session-run-id field; repo mirror `lane-checkpoint.md` for validation) at each boundary. They are the audit trail and the resume contract — a re-dispatched lane continues from the last completed checkpoint. The pinned header is required: the comment-species partition classifies an unknown header as bookkeeping, which would hide the checkpoint from the wedged-driver probe and the liveness hierarchy.

| Checkpoint | Reached when | Evidence in the comment |
| --- | --- | --- |
| implementing | child branch/worktree created, workers dispatched | branch, worktree, plan link |
| implementation-reviewing | implementation commits complete | commit ids, worker evidence |
| testing | pre-PR review clean (incl. fable final round) | review evidence, reviewed diff range |
| verifying | Testing Contract tests exist | test files, harness evidence |
| quality-gating | verification green | commands, exit codes, per-group digests |
| ready-for-child-pr | quality gate passed — mandatory lane context reset here | gate evidence; continuation brief |
| child-pr-reviewing | child PR open against epic branch | PR link, PR body |
| (exit) ready-to-merge-child | child-PR review + local CI clean | reviewer status, CI digests |

Failure routing inside the lane mirrors the previous per-skill rules: implementation bug → back to implementing; test bug or harness work → back to testing; judgment surprise at any checkpoint → demote-to-spec and exit.

## Epic-Level Transitions

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| epic-unassessed | orchestration starts | epic ticket and child tickets readable | epic assessment summary | awaiting-epic-signoff | blocked if PM access fails |
| awaiting-epic-signoff | Gate 1 package posted and human notified | human approval of the package | `epic-signed-off` label; delegation comment quoting what was approved | epic-active | stays awaiting-epic-signoff on ambiguous or partial response |
| epic-active | at least one child is not done | current child state map | next-action summary | epic-active | blocked only if all next actions require human/tool intervention |
| coherence-pending | a child merge completed (label applied at merge close-out) | merged child diff + spec, epic design artifact, Gate 1 package, decision register | register entry + canon summary, label changes on affected children per verdict, corrective ticket on MATERIAL_DRIFT — all keyed to the merge SHA | epic-active (verdict routed clean; label cleared) | remains coherence-pending + escalation on GATE1_AMENDMENT or GATE1_REFRESH; canon-consuming dispatches (spec, plan, lane, epic-PR drafting) blocked throughout — operator-ordered housekeeping that consumes no canon is exempt |
| epic-ready-for-pr | all children are done | child PR links, latest main/master sync, full regression suite green on integrated epic head, epic quality gate evidence | scannable epic readiness summary | epic-pr-open | returns to epic-active if a child reopens, sync introduces required fixes, or the full regression suite fails |
| epic-pr-open | epic PR created — Gate 2 | PR link targeting main or master | epic ticket PR comment; human notified | epic-pr-open | human merges (production entry); automation never does |

## Realignment (LEGITIMATE_DIVERGENCE)

When the coherence review rules that a merged child was right and the epic design was stale:

- The new decision becomes canonical in the register; the superseded design point gets a superseded-by note (never a silent edit).
- Each affected child named by the reviewer: strip `ready-to-implement`; strip `spec-ready` only when the spec itself is invalidated. The tick then re-routes the child through `mature-ticket`, whose drafter consumes the updated canon summary.
- Dependency relations are untouched unless the reviewer explicitly re-sequences.
- Realignment is judged once, at the merge seam — lanes never check-and-repair their own instructions; a perceived register conflict mid-lane remains a demote-to-spec surprise.

## Demotion Rules

When a ticket must return to an earlier lane:

- Demote from any state between `ready-to-implement` and `ready-to-merge-child` (including any lane checkpoint) to the spec lane when a product, architecture, scope, or spec/plan mismatch is discovered.
- Remove or withhold `ready-to-implement`. Keep `spec-ready` only if the spec itself remains valid and the issue is limited to the plan.
- Add a ticket comment with: current state, demotion target, triggering evidence, why automation cannot continue safely, the concrete question or decision needed from the human, and the artifacts that must be revised.
- Preserve existing artifact links for audit history; supersede them with new links after revision rather than deleting old references.
- Close or mark stale an open child PR only when continuing it would be misleading; otherwise leave it open with a blocking comment.
