# Clean park implementation plan

## TL;DR

Implement the approved clean-park sequence as one explicit helper plus a runtime-shipped procedure, with a Claude Stop verifier for an explicitly armed exit. Context clearing is excluded.

## Key Points

- One sequential implementation task owns the helper, its integration and behavior tests.
- Caller judgment stays in worker termination, selecting committed artifacts, and writing the continuation narrative.
- The helper owns deterministic validation, explicit push, brief persistence and exact claim close-out.
- Tests use temporary git repositories and a fake Linear transport, never live tracker writes.
- Existing exit routing and Florist behavior are preserved.
- Release metadata advances together to 0.22.1; publication is outside this change.

> For agentic workers: use dodi-dev:implement to execute this plan.

**Goal:** Make every claimed-lane RESUMABLE exit run verified resource cleanup without resetting the conversation.

**Architecture:** A Bash entrypoint invokes a Python standard-library implementation for structured input, atomic receipts and sequential orchestration. A small command hook checks the explicit session record. The helper reuses existing script mechanisms where they are safe, checking GraphQL mutation success and exact claim identity rather than trusting successful shell exit alone.

**Tech Stack:** Bash, Python 3 standard library, git, existing Linear GraphQL helper, Claude command hooks.

## Testing Contract

### Required Test Groups

- Unit: required. Scope: input/state validation, exact claim ownership, manifest checks, hook decisions. Minimum assertions: invalid/stale/foreign state cannot become a successful park; unarmed turns and Florist remain unaffected by the hook, helper rejects Florist.
- Integration: required. Scope: helper lifecycle with real temporary git remotes and fake Linear responses. Existing Python unittest/shell fixture harness is sufficient. Minimum assertions: correct remote branch/SHA, manual deliver/mature, driver fencing and release ordering, pending failure receipts, mutation false/error, retries and completed rechecks, native session IDs independent of cwd and workflow IDs.
- E2E: not-required. A live provider session, tracker and real process termination would impose external side effects; command-hook payload tests cover the shipped interface. Document that live hook activation is not proven by fixtures.

### Critical Flows

- Settle workers and prepare the final narrative, arm, commit, persist resume anchor and brief, close owned claims, finish cleanup, return success.
- A failed push/brief/release or lost fence leaves an explicit incomplete receipt, never a false clean park.
- Retry a partial cleanup without choosing a successor's claim or using a changed HEAD.
- Stop hook checks an armed session despite cwd changes; incomplete-exit acknowledgement permits returning with a visible incomplete state.

### Regression Surface

Existing driver/ticket claims, worker reaping, hook payloads/module, lane/manual wrappers, driver refresh-park, continuation comment classification and all plugin metadata.

### Commands

- Unit/integration: `bash dodi-dev/scripts/tests/test-clean-park.sh` (create).
- Existing regressions: `bash dodi-dev/scripts/tests/test-reap-workers.sh`, `bash dodi-dev/scripts/tests/test-driver-claim.sh`, `bash dodi-dev/scripts/tests/test-hooks-payload.sh`, `bash dodi-dev/scripts/tests/test-hooks-module.sh`, plus relevant existing claim/comment tests discovered by the runner.
- Repository gates: `bash scripts/validate-plugin-metadata.sh`, `bash scripts/validate-phase-skills.sh`, `bash scripts/validate-ticket-comment-templates.sh`.

### Harness Requirements

Use isolated temporary directories, a local bare git remote, mocked Linear transport, and injected helper state directories. No secrets or external account configuration are required. Failure tests must assert observable mutation order and durable outcomes, not mirror source text.

### Non-Required Rationale

E2E is omitted for the live-side-effect reason above; unit and integration groups are required.

### Verification Rules

Missing harness is a blocker to resolve. Fix implementation defects exposed by tests rather than weakening assertions. Report any material spec mismatch before changing the contract.

## Task 1: Helper, hook and workflow integration

Create `dodi-dev/scripts/clean-park.sh`, a Python implementation beside it if needed, `dodi-dev/scripts/hook-clean-park.sh`, `dodi-dev/scripts/tests/test-clean-park.sh` with supporting fixtures if needed, and `dodi-dev/skills/epic-orchestrator/clean-park.md`.

Expose command-oriented `begin`, `run`, `status` and `interrupt` operations over a JSON request/receipt (a separate `finish` operation confirms stopping and quiescing the owned refresher through its runtime handle before driver release). `begin` binds an immutable attempt to explicit workflow/native session IDs, absolute lane worktree, remote, source checkout branch and durable destination branch, ticket/claim, seam, continuation source and manifest; driver fields are optional. Store owner-local state independently of cwd, reject conflicting active attempts, and never infer exit intent from transcript words. Make request validation, phase boundaries, output/exit codes and retry behavior explicit in the runtime reference. Keep the helper narrowly focused; no general callback executor or process manager.

At each run validate the recorded anchor and exact claims. Do not auto-commit or force-push. Require all dispatched workers to be confirmed reaped; reject missing/malformed/foreign manifest evidence rather than treating it as settled. Push the declared branch, verify its remote SHA, post the pinned brief header plus explicit metadata and narrative, and close only recorded own claims after persistence. Acquisition must expose and retain its exact `claim_id=`; return it on both create and own-session no-op, and reject unconfirmed create responses. Driver preparation writes (including caller commits) require the existing fence and refresher check. After ticket close-out, yield `awaiting-refresher-stop`; the caller stops and confirms the refresher and its in-flight request finished. `finish` then rechecks all three claim-state fence conjuncts with refresher quiescence replacing the alive conjunct, and performs driver release; validate the driver claim id belongs to that session and epic before release. Record/verify each successful external step so a partial retry can progress safely. Check mutation booleans and transport/GraphQL failures. A completed recheck is read-only. `interrupt` requires caller confirmation that all owned workers and the refresher have stopped and no refresh write is in flight, then explicitly records an incomplete exit and its reason without claiming cleanup success or releasing claims. Test an in-flight refresher cannot reopen a claim after final release.

Wire the command Stop hook using the verified official contract. It does nothing for an unarmed session; pending cleanup blocks with a short actionable instruction. Repeated normal Stops must still require a completed or explicitly interrupted record; stop_hook_active is not permission to bypass shutdown. The actionable instruction routes to finish or interrupt rather than blindly repeating failed operations. Forced harness stops retain incomplete evidence. Do not promise native enforcement on unsupported runtimes.

Update `epic-orchestrator/execution-model.md` §5, `epic-orchestrator/lanes/{deliver,mature}-playbook.md`, `deliver-ticket/SKILL.md`, `mature-ticket/SKILL.md` and `drive-epic/SKILL.md` to route all applicable exit edges to the one procedure. Preserve mode checks and existing state meanings. Extend `templates/ticket-comments/continuation-brief.md` to show lane/SHA/seam metadata without changing its comment species. Update AGENTS.md only as needed to describe the new mechanism and distinction between cleanup and reset. Register the shell entrypoints in `scripts/validate-phase-skills.sh` and wire the hook in `dodi-dev/hooks/hooks.json` with no matcher. Keep the Claude manifest pointing only at the additional `hooks/function-hooks.json`; the conventional `hooks/hooks.json` is automatically loaded and must not also be explicitly listed. Preserve the function module and update the validator to inspect both the conventional command config and the manifest-referenced function config. State that fixtures do not prove live loading. Use the official `CLAUDE_CODE_SESSION_ID` for the native marker binding when available, keeping workflow run id separate.

Bump the five version-bearing metadata files from 0.22.0 to 0.22.1. No runtime file may refer to this plan or the repository-only spec. Run the focused tests, self-review the diff, then return a compact evidence digest. Do not publish, tag or push this repository as part of implementation; the helper's git pushes are exercised against fixture remotes only.

## Review and verification

After implementation, run a fresh Capable review with a fix loop and a fresh Frontier final review. Use Fast test-runner workers for the required groups/repository checks. Finish with a reviewable local diff and concise user-facing result, including any limitation on live hook verification.

## Plan review evidence

Frontier plan-review round 1 approved with no findings. Delivery tier: capable, because claim ownership, concurrency and resumable state transitions are invariant-sensitive. Native executor: Astra, highest supported reasoning configuration. User approval already covers implementation of this plan.

Native hook configuration probe: Claude Code 2.1.263 accepted a temporary plugin using both hook-config paths and a Stop command (`claude plugin validate`, exit 0). Corrupting the command hook JSON made the same validation fail (exit 1), confirming that file participates in validation. This establishes schema loading only; it does not prove a Stop event fired in a live session. The subsequent wiring review found that the installed loader diagnoses explicitly naming the conventional command file as a duplicate; the implementation therefore preserves implicit command loading and the existing additional function-config registration. Probe log: `/tmp/dodi-plugin-validate-clean.log`.

## Completion evidence

Implemented locally with context clearing excluded. The final fresh Frontier review approved with no remaining findings, using an ephemeral read-only Codex session after the in-app agent-thread limit was reached: native Astra, declared Frontier/xhigh, requested native effort ultra. Verdict: `/tmp/dodi-clean-park-frontier-final3.txt`.

- `bash dodi-dev/scripts/tests/test-clean-park.sh`: exit 0, 46 offline tests passed; `/tmp/dodi-clean-park-compat-verification.log`.
- Updated claim-liveness tests (including returned IDs and unconfirmed creation): exit 0; `/tmp/dodi-clean-park-handoff-verification.log`.
- All three required repository validators, Claude plugin validation and `git diff --check`: exit 0; same verification logs.
- Existing driver-claim, worker-reaping, hook payload/module and comment-species regression groups also passed. The generic skill validator rejects unchanged canonical `model` frontmatter in three skills; repository-specific validation accepts these intentional cross-runtime declarations.
- Final review findings addressed source-versus-destination branch handling, legacy claims, exact acquisition-ID handoff, repeated Stop enforcement, successor ownership, and duplicate close-out instructions. Tests use only temporary git remotes and fake Linear responses.
- Metadata is 0.22.1. No release commit, tag, repository push, live tracker mutation or live native Stop event test was performed.
