# Epic Orchestration State Transitions

Authoritative transition tables for `epic-orchestrator` and its phase skills. Reconstruct state from durable evidence, then choose exactly one allowed transition.

## Child-Ticket Transitions

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| unassessed | epic intake or resume | child ticket exists under epic | ticket classification comment or epic assessment summary | needs-spec, spec-ready, needs-plan, ready-to-implement, implementing, in-pr, or done | blocked if ticket hierarchy cannot be read |
| needs-spec | ticket lacks `spec-ready` | ticket description and any prior artifacts | draft spec/questions comment; `needs-human-spec` status if human input is required | awaiting-human-spec | blocked if product context is missing and no human contact exists |
| awaiting-human-spec | human responds with approval, edits, or delegation | explicit human signoff or delegated assumptions | finalized spec artifact link and assumptions comment | spec-reviewing | stays awaiting-human-spec if response is ambiguous |
| spec-reviewing | spec is finalized | clean final spec review evidence | apply `spec-ready`; comment reviewer type and result | needs-plan | remains spec-reviewing if reviewer finds issues |
| needs-plan | ticket has `spec-ready` and no clean plan | clean spec, dependency context, repo context | plan artifact link and Testing Contract | plan-reviewing | returns to awaiting-human-spec if planning exposes product ambiguity |
| plan-reviewing | plan exists | clean final plan review evidence and dependency check | apply or withhold `ready-to-implement`; comment dependency status | ready-to-implement or blocked-dependency | returns to needs-plan if reviewer finds implementation-plan issues |
| blocked-dependency | dependency ticket or branch state changes | dependency implemented or explicitly accounted for | dependency status comment | ready-to-implement | remains blocked-dependency if dependency is unresolved |
| ready-to-implement | orchestrator selects ticket for execution | `spec-ready`, `ready-to-implement`, clean spec, clean plan, epic branch current | child branch/worktree comment | implementing | blocked if branch/worktree cannot be created cleanly |
| implementing | worker completes plan | implementation commits and worker evidence | implementation status comment with commit ids | implementation-reviewing | demote-to-spec if worker reports product, architecture, scope, or plan mismatch surprise |
| implementation-reviewing | implementation diff is ready | clean pre-PR review evidence | pre-PR review evidence comment | testing | remains implementation-reviewing while review findings are being fixed |
| testing | implementation review is clean | Testing Contract and test creation evidence | test files/rationale comment | verifying | demote-to-spec if Testing Contract is invalid or exposes spec/plan mismatch |
| verifying | tests exist and commands are known | verification command output and failure classification if any | verification evidence comment | quality-gating | demote-to-spec for spec/plan mismatch; returns to implementing for implementation bug; returns to testing for test bug or harness work |
| quality-gating | verification is clean | quality-gate pass evidence | quality-gate evidence comment | ready-for-child-pr | returns to implementation-reviewing or verifying based on finding type |
| ready-for-child-pr | local checks pass | branch, commits, review, verification, quality-gate evidence | child PR link and PR body | child-pr-reviewing | blocked if PR cannot be created |
| child-pr-reviewing | child PR is open | clean PR review and local CI-equivalent evidence | PR comments and ticket evidence | ready-to-merge-child | returns to implementation-reviewing or verifying based on finding type |
| ready-to-merge-child | child branch is current with epic | clean review/test evidence after latest epic sync | merge commit or squash merge link; child ticket done comment | done | blocked if merge conflict requires spec or plan judgment |
| done | child PR merged into epic | merged PR state | child ticket final status | done | no transition unless ticket is reopened |

## Epic-Level Transitions

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| epic-unassessed | orchestration starts | epic ticket and child tickets readable | epic assessment summary | epic-active | blocked if PM access fails |
| epic-active | at least one child is not done | current child state map | next-action summary | epic-active | blocked only if all next actions require human/tool intervention |
| epic-ready-for-pr | all children are done | child PR links, latest main/master sync, full regression suite green on integrated epic head, epic quality gate evidence | epic readiness summary | epic-pr-open | returns to epic-active if a child reopens, sync introduces required fixes, or the full regression suite fails |
| epic-pr-open | epic PR created | PR link targeting main or master | epic ticket PR comment | epic-pr-open | existing GitHub Actions and review workflows take over |

## Demotion Rules

When a ticket must return to an earlier lane:

- Demote from any state between `ready-to-implement` and `child-pr-reviewing` to the spec lane when a product, architecture, scope, or spec/plan mismatch is discovered.
- Remove or withhold `ready-to-implement`. Keep `spec-ready` only if the spec itself remains valid and the issue is limited to the plan.
- Add a ticket comment with: current state, demotion target, triggering evidence, why automation cannot continue safely, the concrete question or decision needed from the human, and the artifacts that must be revised.
- Preserve existing artifact links for audit history; supersede them with new links after revision rather than deleting old references.
- Close or mark stale an open child PR only when continuing it would be misleading; otherwise leave it open with a blocking comment.
