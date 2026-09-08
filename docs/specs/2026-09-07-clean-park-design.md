# Clean park on resumable exit

## TL;DR

Every manual or resident-driver `RESUMABLE` exit must run one shared clean-park procedure before returning. It preserves the resume anchor, settles workers, releases only the exiting session's claims, and reports incomplete cleanup; it never clears or compacts context.

## Key Points

- The user approved saving continuation state, settling workers, releasing owned claims, and reporting failures, explicitly excluding context clearing.
- One runtime-shipped procedure owns the sequence; all resumable exit sites reference it.
- The agent finishes or stops workers and commits the intended work; a helper checks evidence and performs deterministic persistence and claim close-out.
- Explicit worktree, branch, remote, session, ticket and claim identifiers prevent inference from the hook's current directory.
- Driver ownership must still hold before shared writes; a lost fence aborts mutations.
- An explicitly armed Claude Stop hook blocks a successful exit while cleanup is incomplete. Ordinary turns and Florist workers are unaffected.
- Interrupted cleanup can be retried without closing a successor's claim or treating a partial park as success.
- No native context reset, new scheduling policy, Florist lease manipulation, forced push, automatic commit, or release publication is included.

## Shared procedure

Before arming the resumable exit, finish the current worker, or stop it through the runtime agent primitive and confirm termination; append manifest reap records and prepare the final continuation narrative after these results are known. Then arm a session-scoped pending park record with explicit identifiers and that narrative, before the exit push, brief post or claim release. Never release a writer's ownership while a worker can still write. For a driver, verify its claim fence and running refresher before any shared preparation write, including committing or posting capacity state. Commit the intended artifacts on the declared source checkout, with the durable destination kept separate (deliver: child branch; mature: epic branch), use the prepared continuation text and record the last completed seam, next action and reason, concerns, interrupted work, completed review executor records and ledger tally.

Run the clean-park helper using the armed request. It validates the clean worktree and declared source checkout branch separately from the durable push destination (an ephemeral mature branch may push to the epic branch), the session's fully reaped manifest, and claim ownership before mutation. It verifies a driver's existing claim fence and running refresher when applicable; manual sessions have no driver claim. It pushes the explicit branch without force, checks the remote SHA, and posts a `# Continuation Brief` containing the SHA and seam to the ticket and, for a driver, the epic. It closes the exact owned ticket claim as `RESUMABLE`. For a driver, it then yields a pending `awaiting-refresher-stop` result. The caller stops its owned refresher through the runtime process handle and confirms that the process and any in-flight refresh request have completed; no refresh write may remain able to reopen the claim. Only then does a separate finish operation recheck the three claim-state fence conjuncts and close the exact driver claim using its existing exit state (`parked`, `refresh-park`, or `bloat-handoff`). The fourth, refresher-alive conjunct is required through the preparation stage and intentionally replaced by confirmed refresher quiescence for this final shutdown stage. Do not kill an unverified PID from a generic hook. Test the delayed-refresh/release interleaving explicitly.

Before final success, verify claim mutations succeeded. A durable receipt records the anchor, brief identifiers and completed cleanup; an incomplete operation remains pending with its concrete failure. A retry checks actual state and may finish a prefix of the sequence, but must never act under a released/lost driver's ownership, choose a new claim, repush newer work using an old anchor, or duplicate a completed brief unnecessarily. A completed park can be checked again without mutations.

The request and pending/completed record must bind to the workflow session and declared worktree; a native Stop hook additionally uses an explicit native session id, which need not equal the workflow session run id. Use an owner-local location resolvable independently of cwd so switching to a child worktree does not bypass the hook. Do not interpret the word `RESUMABLE` in conversation text as an exit declaration. An unarmed stop does nothing. Repeated normal Stop events still require a completed or explicitly interrupted record; the retry flag is not a cleanup bypass. A failed park does not make the agent immortal: preserve pending evidence and offer an explicit interrupted-exit acknowledgement that permits stopping while clearly recording cleanup as incomplete. This acknowledgement performs no claim release and cannot produce a successful park receipt. Before acknowledgement, the caller must settle all owned workers and stop/quiesce its owned refresher, including lease-only mode, so an unreleased claim can expire naturally. A crash or forced harness stop remains recovery territory: the hook retains incomplete evidence and never reports a clean park.

## Integration and compatibility

Put the procedure beside `epic-orchestrator/execution-model.md` and reference it from its shared exit contract, both lane playbooks and manual wrappers, and the driver's mid-lane exit protocol. Capacity-specific labels/register entries remain the existing caller's responsibility under its fence. Preserve retry ceilings, resume eligibility, and manual-versus-driver park semantics. Clarify that manual sessions now perform resource cleanup without entering the driver's capacity-park state. Florist retains its own digest/lease contract and must be rejected by the helper.

The command Stop hook is Claude-specific defense in depth using its documented payload and blocking contract. Do not claim Grok or Codex enforcement without verified support; the explicit helper/procedure is required on all runtimes. Runtime files must not reference this repository-only spec.

## Acceptance

Fixture tests cover manual deliver and mature parking; driver refresh/capacity-style close-out; correct push target and resume anchor; clean and dirty worktrees; active/unreaped workers; lost ownership before each mutation boundary; exact claims and successor safety; transport/GraphQL/mutation failures; partial retries and completed rechecks; Florist refusal; armed/unarmed stops, different cwd and native/workflow session ids; incomplete-exit acknowledgement; no context clearing. No live tracker writes or process termination are used for tests. All repository validators and affected existing claim/hook tests pass.

## Review evidence

User approved the design with context clearing excluded. Frontier spec review round 1 found three blocking issues: fencing before preparation writes, refresher/release synchronization, and refresher cleanup on interrupted exit. All three were applied; fresh Frontier round 2 approved with no findings.
