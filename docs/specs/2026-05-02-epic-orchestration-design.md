# Epic Orchestration Design

## Goal

Define a skills-based workflow policy for moving a shaped feature epic from ticket intake through child-ticket implementation and epic PR submission, with Hive acting as the long-running runtime and `dodi-skills` acting as the workflow policy package.

## Context

`dodi-skills` currently contains Claude Code-style developer workflow skills under `dodi-dev/skills`. The intended direction is to keep this repository as the source of workflow policy and skill instructions, then have Hive consume those skills as a long-running orchestration runtime.

This design focuses on feature development for a shaped epic with child tickets. Bug fixes and hot patches are out of scope because they intentionally shortcut parts of the feature workflow and may require different deployment paths.

## Responsibility Model

The workflow separates responsibilities clearly:

- Humans own product intent, spec direction, and ambiguous PM decisions.
- The epic orchestrator owns progress across the whole epic.
- Workers own bounded implementation, review, testing, and verification tasks.
- The ticketing system owns durable state through labels, comments, and artifact links.
- Hive owns long-running execution, scheduling, tool access, persistence, and notifications.

The orchestrator must not implement product code, review code directly, or run verification as the primary actor. It dispatches bounded workers and advances state only from evidence.

## Top-Level Skill

The top-level workflow skill should be `epic-orchestrator`.

Hive agents currently have too much room to drift, so Hive should not improvise the workflow. Hive should invoke `epic-orchestrator` for a specific epic, maintain the long-running session, and provide the runtime substrate. The skill itself should define the state machine, hard gates, allowed transitions, and evidence required to move forward.

`epic-orchestrator` owns:

- overall epic state machine
- allowed next actions
- hard gates
- dispatch rules for phase skills and workers
- evidence requirements before state transitions
- ticket, branch, worktree, and PR contracts
- what must be written back to Linear or another PM system

## Hive Invocation Contract

Hive should invoke `epic-orchestrator` with a compact, explicit context object:

```json
{
  "epicRef": { "kind": "ticket", "id": "PM-123" },
  "repoPath": "/absolute/path/to/repo",
  "pmSystem": "linear",
  "baseBranch": "main",
  "mode": "start-or-resume",
  "humanContact": "slack-user-or-channel",
  "runLedgerPath": ".dodi/orchestration/PM-123.jsonl"
}
```

`epicRef` identifies the epic and its shape in the PM system. `kind` is `ticket` (a parent issue with sub-issues) or `project` (a PM project or initiative container holding issues). `id` is the ticket identifier for `ticket` epics and the project's stable slug for `project` epics. See "Epic Shapes" for how each kind is read and enumerated.

The **epic slug** is `epicRef.id` — the ticket identifier or project slug. It is the single token used for the epic branch name, the run ledger path, and the `epicId` field of progress records, so all three stay stable and resume-correlatable regardless of epic shape. The epic slug equals `epicRef.id` for both kinds; branch-safe formatting is a presentation step, not a re-derivation.

Required fields are `epicRef`, `repoPath`, `pmSystem`, and `mode`. `baseBranch` may be omitted only when the orchestrator can discover the repository default branch. `humanContact` may be omitted for manual sessions. `runLedgerPath` may be omitted when the ticketing system is the only state store; when present it should incorporate the epic slug.

`epic-orchestrator` should emit structured progress records that Hive can persist or forward:

```json
{
  "epicId": "PM-123",
  "ticketId": "PM-124",
  "state": "ready-to-implement",
  "action": "applied-label",
  "evidence": ["docs/plans/2026-05-02-pm-124-implementation.md"],
  "nextAction": "pickup-ticket",
  "needsHuman": false
}
```

The run ledger, when used, is append-only JSONL. Durable workflow truth remains in the PM system through labels, comments, artifact links, and PR links. The local ledger is only for resume speed and audit convenience.

Resume contract:

1. Read the epic and child tickets from the PM system.
2. Read open PRs and local branch/worktree state.
3. Read the local ledger if present.
4. Reconstruct the current state from durable evidence, preferring PM and GitHub state over the ledger when they differ.
5. Choose exactly one allowed next action from the state machine.

Worker evidence contract:

- Every dispatched worker must report status, files or artifacts changed, commands run, exit status, and links or paths to evidence.
- The orchestrator may not advance state from a worker success claim alone. It must verify durable evidence exists.
- If a worker reports `BLOCKED`, `NEEDS_CONTEXT`, or an implementation surprise, the orchestrator records the blocker and follows the state machine rather than improvising.

Notification contract:

- Notify the human only for spec signoff, explicit blockers, auth/tool failures that automation cannot resolve, or final epic PR submission.
- Routine progress should be written to the PM system and optional run ledger without interrupting the human.

## Supporting Phase Skills

The orchestration layer should be built from smaller phase skills:

- `epic-orchestrator`
- `pickup-epic`
- `assess-epic`
- `mature-ticket`
- `write-plan`
- `pickup-ticket`
- `implement-ticket`
- `review-implementation`
- `create-tests`
- `verify`
- `review-child-pr`
- `submit-ticket-pr`
- `submit-epic-pr`
- `quality-gate`

These skills should exist in both the Claude and Codex skill trees. They should be functionally equivalent but may use agent-native wording and mechanisms.

Phase skill contracts:

| Skill | Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- | --- |
| `epic-orchestrator` | Hive starts or resumes work on an epic | epic reference, repo path, PM system context | next state decision, dispatched phase work, epic progress summary | epic comments, child ticket comments, labels, PR links | phase skills, workers, reviewers, test runners | needs human spec input, blocked dependency, tool/auth failure |
| `pickup-epic` | epic accepted for orchestration | epic reference, repo path, base branch | epic branch and worktree named from the epic slug | epic comment with branch/worktree | none by default | dirty worktree, missing base branch, branch conflict, unresolvable epic slug |
| `assess-epic` | epic worktree exists or orchestration resumes | epic reference, child tickets enumerated per epic shape, artifact links, repo state | ticket maturity map, dependency map, ready work queue | epic summary comment or run ledger entry | reviewer/explorer workers for codebase dependency checks | missing ticket access, child enumeration fails for the epic shape |
| `mature-ticket` | child ticket lacks `spec-ready` or `ready-to-implement` | ticket id, current artifacts, dependency context | clean spec, clean plan when allowed, readiness labels | artifact links, reviewer evidence, labels, assumptions | spec drafter, spec reviewer, plan writer, plan reviewer | needs human spec input, unresolved dependency, reviewer findings not yet fixed |
| `write-plan` | a ticket has `spec-ready` but no clean plan | clean spec, ticket id, dependency context, repo context | implementation plan with Testing Contract | plan artifact link, plan review evidence | plan writer and implementation-plan reviewer | product ambiguity, architecture ambiguity, dependency unavailable |
| `pickup-ticket` | child ticket has `ready-to-implement` | ticket id, epic branch/worktree, repo path | child branch and worktree based on epic branch | ticket comment with branch/worktree | none by default | stale epic branch, branch conflict, dirty worktree |
| `implement-ticket` | child worktree exists | ticket id, clean spec, clean plan, child worktree | implementation commits or explicit escalation | ticket comment with status, commit ids, surprise notes | implementation workers only | spec/plan mismatch, product decision needed, worker blocked |
| `review-implementation` | implementation completes before PR creation | ticket id, clean spec, clean plan, child worktree, diff | clean pre-PR code review or findings to fix | ticket comment with review evidence | fresh-context code reviewers and fix workers | review findings, spec/plan mismatch, production changes needing re-review |
| `create-tests` | implementation review is clean or plan requires tests | Testing Contract, changed files, child worktree | tests satisfying the Testing Contract | ticket comment with test files and rationale | test implementation workers | invalid Testing Contract, missing harness requiring setup, spec/plan mismatch |
| `verify` | tests exist or completion/PR claims are about to be made | Testing Contract, repo command set, child worktree, changed files | fresh verification evidence for required test groups and broader checks | ticket comment with commands, outputs, failure classification | verifier/test runner, harness setup worker, fix worker when classification warrants | missing harness, test bug, implementation bug, environment issue, spec/plan mismatch |
| `review-child-pr` | child PR is opened against epic branch | PR id, ticket id, spec, plan, diff | clean fresh-context review and local CI-equivalent evidence | PR comments, ticket comment, review/test evidence | code reviewers, fix workers, test runners | review findings, test failure, stale epic branch |
| `submit-ticket-pr` | local implementation checks pass | child branch, epic branch, ticket id, evidence summary | child PR targeting epic branch; later merge when clean | PR body, ticket comment, final child status | PR reviewer, test runner, merge worker | PR creation failure, review/test failure, merge conflict |
| `submit-epic-pr` | all child tickets are merged into epic branch | epic branch, base branch, child PR list, epic evidence | epic PR targeting main or master, left open | epic PR body, epic summary | none after PR creation by default | incomplete child ticket, local quality gate failure, PR creation failure |
| `quality-gate` | before child PR, before child merge when needed, before epic PR | repo instructions, changed files, test evidence, risk context | horizontal pass/fail evidence | ticket or PR comment with command evidence | security/review/test specialists | compliance issue, security concern, hygiene issue, missing verification |

`quality-gate` should be a standalone skill. It may invoke or require evidence from `verify`, review, and test-related skills, but it owns the horizontal compliance/security/hygiene/regression checklist and produces its own pass/fail evidence.

## Existing Skill Migration

The implementation should migrate the current Claude skills into this workflow explicitly:

| Existing skill | Migration |
| --- | --- |
| `brainstorm` | Keep as the interactive spec-shaping entry point. It may remain a wrapper around a stronger external brainstorming skill when available. |
| `write-plan` | Keep and tighten. It must require the Testing Contract and clean plan review evidence before `ready-to-implement` can be applied. |
| `pickup` | Split for epic work into `pickup-epic` and `pickup-ticket`. Keep `pickup` only as a compatibility dispatcher or legacy convenience wrapper. |
| `implement` | Replace in epic workflows with `implement-ticket`. The new skill must enforce plan adherence and escalate spec/plan surprises instead of redesigning during implementation. |
| `review` | Keep as the base review behavior, but expose the epic pre-PR review loop as `review-implementation` and the opened-child-PR loop as `review-child-pr`. |
| `verify` | Keep and tighten. It must set up missing required harnesses where feasible, classify failures, and fix implementation code when tests expose implementation defects. |
| `submit` | Replace for epic workflows with `submit-ticket-pr` and `submit-epic-pr`. The old auto-merge behavior must not be used for epic PRs and must not be the default submit path. |

For non-epic legacy workflows, existing skill names may remain as compatibility wrappers, but `epic-orchestrator` must use the explicit epic skills above.

## Implementation Sequencing

This design should be implemented as a phased plan, not one unbounded change.

Phase 1 acceptance criteria:

- Treat Phase 1 as a Codex-port and compatibility release. It should not add epic orchestration behavior.
- Create the Codex plugin scaffold:
  - `.agents/plugins/marketplace.json`
  - `plugins/dodi-dev/.codex-plugin/plugin.json`
  - `plugins/dodi-dev/skills/`
- Port the existing released Claude skills into the Codex tree:
  - `brainstorm`
  - `file-ticket`
  - `implement`
  - `pickup`
  - `review`
  - `submit`
  - `verify`
  - `write-plan`
- Add a baseline `quality-gate` skill to both trees because the current released `submit` skill already requires it. In Phase 1 this skill is a compatibility gate that validates plugin JSON metadata, checks the expected published file set, and reports gaps. Phase 2 tightens this existing baseline skill into the full horizontal gate.
- Update repo instructions so future skills must be created in both trees.
- Bump both Claude metadata files from `0.5.0` to `0.6.0`:
  - `.claude-plugin/marketplace.json`
  - `dodi-dev/.claude-plugin/plugin.json`
- Create Codex metadata at `0.6.0`.
- Validate Claude and Codex plugin JSON metadata.
- Do not add epic orchestration behavior yet.

Phase 2 acceptance criteria:

- Treat Phase 2 as the local epic orchestration release. It supports epic assessment, ticket maturity, ticket pickup, implementation, local review, tests, verification, and quality gate. It does not create or merge PRs.
- Add `epic-orchestrator` to both Claude and Codex skill trees.
- Add the core phase skills required for the maturity and implementation lanes:
  - `pickup-epic`
  - `assess-epic`
  - `mature-ticket`
  - `pickup-ticket`
  - `implement-ticket`
  - `review-implementation`
  - `create-tests`
  - `quality-gate` as a tightened version of the Phase 1 baseline, not a second new skill
- Tighten `write-plan`, `review`, and `verify` behavior according to this spec.
- Keep `submit` as a compatibility wrapper, but remove auto-merge from the default documented path.
- Bump both Claude and Codex plugin metadata from `0.6.0` to `0.7.0`.

Phase 3 acceptance criteria:

- Treat Phase 3 as the PR lifecycle release. It adds child-ticket PR handling and epic PR submission.
- Add child and epic PR skills:
  - `review-child-pr`
  - `submit-ticket-pr`
  - `submit-epic-pr`
- Encode child PR local review/test/merge behavior.
- Encode epic PR creation behavior targeting main or master and leaving the PR open.
- Add prompt templates for implementation, review, test, and verification workers where needed.
- Bump both Claude and Codex plugin metadata from `0.7.0` to `0.8.0`.

Phase 4 acceptance criteria:

- Add or refine ticket comment templates, run ledger templates, and local CI-equivalent discovery instructions.
- Add validation commands or scripts that check both skill trees contain the required skill names.
- Bump plugin versions only if Phase 4 changes released workflow behavior; otherwise keep existing versions and update docs or scripts only.

Phase 5 acceptance criteria:

- Treat Phase 5 as the epic-reference contract release. It adds explicit support for `project`-shaped epics alongside `ticket`-shaped epics.
- Replace the opaque `epicId` input with `epicRef` (`{ kind, id }`) in the Hive invocation contract, and thread the derived epic slug through branch naming, the run ledger path, and progress records.
- Add the "Epic Shapes" contract and update `epic-orchestrator`, `pickup-epic`, and `assess-epic` in both the Claude and Codex skill trees to read and enumerate both epic shapes.
- Narrow the epic-shaping Non-Goal so it no longer covers the consumption contract.
- Bump both Claude and Codex `dodi-dev` plugin metadata to `0.9.0`. Patch releases (`0.8.1`, `0.8.2`) shipped between Phase 3 and Phase 5; the phase-plan numbers are minor-version milestones, and Phase 5 lands on `0.9.0` regardless of intervening patch releases.

Each phase should have its own implementation plan, should be independently reviewable, and should leave the repo in a usable state.

## Ticket Readiness Labels

Two durable labels are required:

- `spec-ready`: a clean reviewed spec exists, and product/system intent is sufficiently resolved.
- `ready-to-implement`: a clean reviewed plan exists, implementation dependencies are satisfied or explicitly accounted for, and a worker can start without reopening product or design questions.

`ready-to-implement` implies `spec-ready`, but `spec-ready` does not imply `ready-to-implement`.

Other workflow states may exist as comments, branch/worktree state, or orchestrator memory. Candidate states include `needs-spec`, `spec-reviewing`, `planning`, `plan-reviewing`, `implementing`, `in-pr`, and `done`, but these do not need to be durable labels unless the PM system benefits from them.

## Orchestrator State Transitions

The orchestrator should reconstruct each child ticket's state from durable PM labels, ticket comments, artifact links, PR state, and branch/worktree state. It then chooses exactly one allowed transition.

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
| implementation-reviewing | implementation diff is ready | clean `review-implementation` evidence | pre-PR review evidence comment | testing | remains implementation-reviewing while review findings are being fixed |
| testing | implementation review is clean | Testing Contract and test creation evidence | test files/rationale comment | verifying | demote-to-spec if Testing Contract is invalid or exposes spec/plan mismatch |
| verifying | tests exist and commands are known | verification command output and failure classification if any | verification evidence comment | quality-gating | demote-to-spec for spec/plan mismatch; returns to implementing for implementation bug; returns to testing for test bug or harness work |
| quality-gating | verification is clean | quality-gate pass evidence | quality-gate evidence comment | ready-for-child-pr | returns to implementation-reviewing or verifying based on finding type |
| ready-for-child-pr | local checks pass | branch, commits, review, verification, quality-gate evidence | child PR link and PR body | child-pr-reviewing | blocked if PR cannot be created |
| child-pr-reviewing | child PR is open | clean PR review and local CI-equivalent evidence | PR comments and ticket evidence | ready-to-merge-child | returns to implementation-reviewing or verifying based on finding type |
| ready-to-merge-child | child branch is current with epic | clean review/test evidence after latest epic sync | merge commit or squash merge link; child ticket done comment | done | blocked if merge conflict requires spec or plan judgment |
| done | child PR merged into epic | merged PR state | child ticket final status | done | no transition unless ticket is reopened |

On a cold resume the `unassessed` row classifies each child ticket from durable evidence alone, in this precedence order:

- `done` — child PR merged into the epic branch.
- `in-pr` — an open child PR exists for the ticket branch.
- `implementing` — a child branch or worktree exists with commits but no open PR.
- `ready-to-implement` — the `ready-to-implement` label is present and no child branch exists yet.
- `needs-plan` — `spec-ready` is present, `ready-to-implement` is absent, and no clean plan artifact is linked, or a plan artifact exists but `ready-to-implement` was withheld pending the dependency check.
- `spec-ready` — `spec-ready` is present with a clean spec artifact linked.
- `needs-spec` — no `spec-ready` label.

Labels and artifact links are the primary signal; branch, worktree, and PR state disambiguate the implementation lane. The classification comment the orchestrator writes is the output of this step, not its input.

Epic-level transitions:

| Source state | Trigger | Required evidence | Durable writes | Next state | Fallback or error transition |
| --- | --- | --- | --- | --- | --- |
| epic-unassessed | orchestration starts | epic (ticket or project, per `epicRef`) and its child tickets readable | epic assessment summary | epic-active | blocked if PM access fails |
| epic-active | at least one child is not done | current child state map | next-action summary | epic-active | blocked only if all next actions require human/tool intervention |
| epic-ready-for-pr | all children are done | child PR links, latest main/master sync, epic quality gate evidence | epic readiness summary | epic-pr-open | returns to epic-active if a child reopens or sync introduces required fixes |
| epic-pr-open | epic PR created | PR link targeting main or master | epic PR comment | epic-pr-open | existing GitHub Actions and review workflows take over |

## Demotion Rules

When a ticket must return to an earlier lane, the orchestrator must mutate durable state consistently:

- Demote from `ready-to-implement`, `implementing`, `implementation-reviewing`, `testing`, `verifying`, `quality-gating`, `ready-for-child-pr`, or `child-pr-reviewing` to the spec lane when a product, architecture, scope, or spec/plan mismatch is discovered.
- Remove or withhold `ready-to-implement`.
- Keep `spec-ready` only if the spec itself remains valid and the issue is limited to the plan. Remove or withhold `spec-ready` when product intent, user behavior, architecture, or acceptance criteria need human revision.
- Add a ticket comment with:
  - current state
  - demotion target
  - triggering evidence
  - why automation cannot continue safely
  - concrete question or decision needed from the human
  - affected artifacts that must be revised
- Preserve existing artifact links for audit history. Supersede them with new artifact links after revision rather than deleting old references.
- Close or mark stale any open child PR only when continuing it would be misleading. Otherwise leave it open with a blocking comment until the revised spec or plan determines the next action.

## Epic Shapes

`epicRef.kind` determines how the orchestrator reads the epic and enumerates its children. Both shapes are first-class; the orchestrator must support both.

| `kind` | Epic body | Child enumeration | Epic slug (branch id) |
| --- | --- | --- | --- |
| `ticket` | The epic ticket's description and comments | Sub-issues of the epic ticket | `epicRef.id` — the epic ticket identifier, e.g. `PM-123` |
| `project` | The PM project's description and overview content | Issues belonging to the project | `epicRef.id` — the project's stable slug |

For a `project` epic there is no parent ticket to "read" — the project description is the epic body, and the project's issue list is the child set. A `project` epic has no `PM-###` ticket id; its epic slug is the project slug, and that slug produces the deterministic, resume-stable `epic/<slug>` branch name.

The orchestrator does not require a single canonical epic-authoring convention. It only requires that `epicRef.kind` correctly classifies the supplied epic so the right read and enumeration paths are used.

## Epic Intake

The orchestrator starts by picking up an epic.

Process:

1. Resolve `epicRef` and derive the epic slug (see Epic Shapes).
2. Run `pickup-epic` to create or switch to the epic branch and worktree from the base branch. Epic Intake does not re-implement branch or worktree creation; `pickup-epic` owns it.
3. Treat the epic worktree as the homebase for this orchestration run.
4. Read the epic body and enumerate child tickets per the epic's shape (see Epic Shapes).
5. Classify each child ticket by maturity:
   - one-line concept or weak description
   - needs spec
   - spec-ready
   - needs plan
   - ready-to-implement
   - already implementing
   - in PR
   - done
6. Decide which ready tickets can be implemented now.
7. Decide which unready tickets can be matured now.

The orchestrator may decide whether ready implementation work should be sequential or parallel. This decision should be based on the plans, dependency graph, expected file overlap, and codebase knowledge.

## Spec Maturity Lane

Tickets without `spec-ready` remain in the spec maturity lane.

Process:

1. Inspect the ticket and any existing artifacts.
2. Draft a proposed spec, decision options, or focused questions.
3. Require human signoff before entering the plan phase.
4. Acceptable human responses include explicit approval or explicit delegation such as "good" or "don't care". A response is ambiguous when it neither approves a direction nor delegates the open choices; on an ambiguous response, re-ask with the specific decision needed rather than guessing.
5. If the human delegates a choice, record the resulting assumption in the spec or ticket.
6. Finalize the spec.
7. Run a fresh-context spec review loop until the final round is clean.
8. Apply `spec-ready` and write a ticket comment with artifact links and review evidence.

The orchestrator may choose the reviewer type for the spec. Product-heavy specs may need a product or UX reviewer. System, API, data, security, or architecture-heavy specs may need an architect or security-aware reviewer. The chosen reviewer and reason should be recorded.

A ticket may not enter `write-plan` unless a human has accepted the spec direction or explicitly delegated the open choices.

## Plan Maturity Lane

Tickets with `spec-ready` but without `ready-to-implement` remain in the plan maturity lane.

Process:

1. Write an implementation plan from the clean spec.
2. Include a required Testing Contract:
   - unit tests: required or not required, with reason
   - integration tests: required or not required, with reason
   - end-to-end tests: required or not required, with reason
   - harness and setup requirements
   - critical user or system flows to prove
3. Run a fresh-context plan review loop until the final round is clean.
4. Verify implementation dependencies are satisfied or explicitly represented.
5. Apply `ready-to-implement` only when dependencies allow implementation.
6. Write a ticket comment with artifact links, review evidence, dependency status, and testing requirements.

The default plan reviewer should be an implementation-plan reviewer or code-review-style reviewer. The reviewer should check file responsibilities, task sequencing, dependency and conflict risks, test and verification instructions, fit with existing code patterns, and whether the plan is complete enough for a fresh worker.

If plan review reveals product or architecture ambiguity, the ticket returns to the spec lane.

## Branch and Worktree Model

Every child ticket gets its own branch and worktree by default.

Branch model:

```text
main/master
-> epic branch + epic worktree
   -> child ticket branch + child worktree
   -> child ticket branch + child worktree
   -> child ticket branch + child worktree
```

PR targets:

```text
child ticket branch -> epic branch
epic branch -> main/master
```

The default invariant is one child branch per child ticket. A human may explicitly override this for rare cases, such as bundling tickets or merging directly into the epic branch.

`pickup-epic` should branch from main or master, naming the epic branch `epic/<epic-slug>` where the epic slug is derived from `epicRef` — the ticket identifier for `ticket` epics, the project slug for `project` epics (see Epic Shapes). `pickup-ticket` should branch from the epic branch. Before `pickup-ticket`, the epic branch should be current with already-merged child PRs.

## Implementation Lane

Only tickets with `ready-to-implement` may enter implementation.

Process:

1. Refresh the epic branch.
2. Run `pickup-ticket` from the epic branch.
3. Dispatch an implementation worker against the clean plan.
4. Require the worker to implement exactly the plan.
5. If the worker encounters a surprise requiring product, architecture, or scope judgment:
   - stop implementation
   - comment on the ticket with the surprise and why the plan cannot continue
   - withhold or remove `ready-to-implement`
   - return the ticket to the spec lane
6. If implementation completes without surprise, proceed to code review.

Small mechanical discoveries may be handled by the worker when they do not change product behavior, architecture, scope, risk, or the Testing Contract. Meaningful plan mismatch is a workflow event, not permission to redesign during implementation.

## Local Review, Test, and Verification

After implementation completes:

1. Run `review-implementation` as a fresh-context pre-PR code review loop until the final review round is clean.
2. Run `create-tests` to satisfy the Testing Contract.
3. Run `verify` to prove required tests and harnesses pass.
4. If verification changes production code, run a focused `review-implementation` loop on the verification-era changes.
5. Run `quality-gate` for horizontal checks.

`create-tests` may add more tests than the Testing Contract requires, but it must satisfy the contract or escalate.

`verify` must not skip required test groups because a harness is missing. If a required harness is absent, the verifier must attempt to set up the repo-appropriate harness or escalate with a concrete blocker. If tests fail, the verifier must classify the failure as one of:

- test bug
- implementation bug
- environment or harness issue
- spec or plan mismatch

The verifier must fix the right thing. It must not default to editing tests. If the failure reveals a spec or plan mismatch, the ticket returns to the spec lane.

`quality-gate` should check horizontal concerns after the vertical ticket work is believed to pass, including implementation compliance, security concerns, code hygiene, regression risk, documentation, and operational concerns.

## Child PR Flow

After local implementation checks pass, `submit-ticket-pr` opens a PR from the child ticket branch to the epic branch and leaves it open for review.

After the child PR opens:

1. Kick off another fresh-context code review loop.
2. Kick off a test runner agent to run local CI-equivalent tests.
3. If review or tests require code or test changes, apply fixes through workers.
4. Rerun focused fresh-context review and affected tests when production code changes.
5. Merge the child PR into the epic branch only when review and local CI-equivalent checks are clean.
6. Update the child ticket with PR links, evidence, and final status.

The local CI-equivalent runner should prove both the ticket Testing Contract and enough broader repo or module checks to catch cross-area regressions.

The initial implementation should not require GitHub Actions for child PRs targeting epic branches. Longer term, local CI-equivalent commands should be shared with GitHub Actions so the local runner and main-branch CI execute the same command graph where possible.

If the epic branch moves while child PR review or tests are running, the child branch must be updated from the epic branch and relevant checks rerun before merge.

## Epic PR Flow

When all child tickets under the epic are complete and merged into the epic branch:

1. Confirm all required child ticket statuses are done.
2. Update the epic branch with the latest main or master.
3. Run an epic-level local quality gate.
4. Prepare an epic readiness summary:
   - child tickets completed
   - child PR links
   - local quality gate evidence
   - known risks
   - migrations or release notes
   - test coverage summary
5. Run `submit-epic-pr` from the epic branch to main or master.
6. Leave the epic PR open.

For epic PRs targeting main or master, the existing GitHub Actions flow should run fresh-context code review and CI. The skills should not auto-merge epic PRs.

## Submit Policy

The existing submit behavior must change materially.

Child ticket submit:

- source: child ticket branch
- target: epic branch
- opens a PR
- runs `review-child-pr` and local CI-equivalent checks
- may merge into the epic branch after all required local checks are clean

Epic submit:

- source: epic branch
- target: main or master
- opens a PR
- relies on existing GitHub Actions review and CI
- leaves the PR open
- never auto-merges by default

## Codex and Claude Skill Trees

The repository should maintain separate first-class skill trees for Claude and Codex.

Existing Claude tree:

```text
.claude-plugin/marketplace.json
dodi-dev/
  .claude-plugin/plugin.json
  skills/
```

Target Codex tree:

```text
.agents/
  plugins/
    marketplace.json
plugins/
  dodi-dev/
    .codex-plugin/plugin.json
    skills/
```

Every new skill should be created in both trees in the same change. The two versions should be functionally equivalent, but they may be idiomatically different for each agent runtime. The goal is not byte-for-byte identity; the goal is equivalent workflow policy.

The first implementation must port the existing released Claude skills into the Codex tree before or alongside the new orchestration skills, so Codex can consume a complete `dodi-dev` plugin directly.

Codex marketplace metadata should be:

```json
{
  "name": "dodi-skills",
  "interface": {
    "displayName": "Dodi Skills"
  },
  "plugins": [
    {
      "name": "dodi-dev",
      "source": {
        "source": "local",
        "path": "./plugins/dodi-dev"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

Codex plugin metadata should include:

```json
{
  "name": "dodi-dev",
  "version": "0.6.0",
  "description": "Dodi developer workflow skills",
  "author": {
    "name": "Dodi HQ",
    "email": "may@dodihome.com"
  },
  "repository": "https://github.com/dodi-hq/dodi-skills",
  "skills": "./skills/",
  "interface": {
    "displayName": "Dodi Dev",
    "shortDescription": "Developer workflow skills",
    "developerName": "Dodi HQ",
    "category": "Productivity",
    "capabilities": ["Write", "Review"]
  }
}
```

Versioning rule: Phase 1 creates the Codex plugin at `0.6.0` and bumps the Claude `dodi-dev` plugin metadata from `0.5.0` to `0.6.0`. Phase 2 bumps both runtimes to `0.7.0`. Phase 3 bumps both runtimes to `0.8.0`. Phase 5 bumps both runtimes to `0.9.0`. Later workflow behavior changes should bump both Claude and Codex `dodi-dev` plugin versions in the same change unless the change is explicitly runtime-specific and does not affect shared workflow policy.

## Non-Goals

- Define bugfix or hot patch workflows.
- Define or enforce a single canonical epic-authoring convention in the PM tool. The orchestrator's *consumption* contract for each supported epic shape — `ticket` and `project` — is defined; see Epic Shapes.
- Implement the Hive runtime state machine.
- Configure GitHub Actions for every epic branch.
- Auto-merge epic PRs into main or master.

## Implementation Defaults

Use these defaults unless a repository-specific instruction overrides them:

- Linear labels: `spec-ready` and `ready-to-implement`.
- Epic slug: the ticket identifier for `ticket` epics, the project slug for `project` epics. Used for the epic branch name, run ledger path, and progress record `epicId`.
- Spec artifacts: `docs/specs/YYYY-MM-DD-<ticket-or-epic-slug>-design.md`.
- Plan artifacts: `docs/plans/YYYY-MM-DD-<ticket-or-epic-slug>-implementation.md`.
- Ticket comments: include artifact links, reviewer type and result, verification evidence, dependency state, PR links, and current next action.
- Child PR merge into epic: squash merge by default, then delete the child branch after the merge is complete.
- Local CI-equivalent discovery: prefer an explicit repo instruction in `AGENTS.md` or `CLAUDE.md`; otherwise inspect package scripts, CI workflow files, and project docs, then record the chosen command set before running it.
- Orchestration state: durable state lives in the ticketing system; the epic worktree may also keep a local run ledger for convenience, but the ticketing system is the source of truth.
