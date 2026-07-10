# DOD-813 - Codex Worker Lifecycle Adapter

## TL;DR

DOD-813 implements the Codex-native worker lifecycle behind DOD-811's shared adapter contract: durable pre-spawn intent, native spawn/wait/close normalization, atomic result evidence, manifest transitions, recovery, reaping, quarantine, and safe takeover. A worker result is never consumed and a successor never touches a possibly-writing worktree until durable terminal, attestation, close, reap, baseline, and conflict checks establish the required postconditions.

The adapter preserves the v0.16 top-level-only, leaf-worker, single-driver-writer workflow and leaves setup, scheduling, Gate 2, escalation delivery, and release validation to C4/C5; Codex scheduled delivery remains blocked until a live current-runtime gate proves cross-session worker addressability, runtime-owned parent termination, or the approved fail-closed quarantine path.

## Key Points

- Implement DOD-811's `prepare-intent`, `spawn`, `await`, `persist-result`, `close`, and `reap/recover` operations without Claude transcript or `output_file` assumptions.
- Use one deterministic `codex-worker-adapter.sh` for durable state and normalization; the top-level session alone performs native Codex spawn/wait/close tool calls and feeds their exact observations back to the script.
- Persist a mode-`0600`, content-addressed normalized result artifact before appending any terminal manifest record; terminal evidence, attestation, close, and reap must all pass before a digest is consumed.
- Treat authoritative spawn rejection differently from unknown acceptance, expected wait expiry differently from transport/query failure, and equivalent duplicate evidence differently from conflicting evidence.
- Bind every mutable dispatch to a clean pre-spawn HEAD and exact porcelain-status hash. Invalid attestation or uncertain ownership triggers baseline comparison and quarantine; untrusted output is never promoted in place.
- Add an append-only quarantine ledger for activation/release evidence while preserving DOD-811's manifest path, v1 envelope, state vocabulary, nonce/worker keys, profile-generation fields, and legacy-Claude boundary.
- Consume DOD-812's `resolve-tier` and `verify-attestation` outputs exactly; do not duplicate model mapping, capacity signatures, hook enforcement, or effective-tier comparison.
- Preserve one lane in flight, one driver writer, top-level-only dispatch, leaf workers, no silence-as-success, and the absolute prohibition on automated Gate 2 merge.
- ⚠ The exact native Codex worker ids, status payloads, enumeration/query surface, and cross-session behavior are runtime-observed mechanics. Deterministic fixtures pin the observed shape, and the live gate blocks C3 completion if no approved safe takeover path can be proved.

## Decision Context

The DOD-810 parent design was approved at `baf219a`. DOD-811's runtime-foundation spec and plan are canonical at epic commit `978cad7`; DOD-812's tier-map spec and plan are canonical at the current DOD-810 epic head. Workflow mode is `waterfall`, so C3 designs against those approved contracts and does not assume their implementation has already landed in this maturity worktree.

DOD-811 owns:

- the manifest location `<epic-worktree-abs>/.dodi/dispatch-manifest-<session-run-id>.jsonl`;
- the v1 envelope, state vocabulary, pre/post-binding logical keys, baseline fields, profile-generation fields, and append-only ordering;
- the semantic adapter operations and fail-closed postconditions;
- the runtime-profile/root policy and `verify-state-generation` ownership boundary;
- the rule that unversioned v0.16 records are Claude-only and v1 records declare `runtime` explicitly.

DOD-812 owns:

- `resolve-tier` and the exact requested model/reasoning pair;
- `verify-attestation` and the `WORKER_TIER_VERIFIED`, `TIER_UNVERIFIED`, and `SETUP_REQUIRED` outcomes;
- effective model/reasoning/context and context-inheritance verification;
- Frontier capacity classification, Fable policy routing inputs, and model-pin hook enforcement.

C3 consumes those contracts. If landed C1/C2 code differs materially from the approved interfaces, implementation returns through the DOD-810 decision process instead of introducing a second manifest grammar, tier verifier, or profile authority.

## Problem

The v0.16 worker mechanics are Claude-shaped. `await-worker.sh` searches transcript final lines for `stop_reason:end_turn`, and `reap-workers.sh` classifies `output_file` mtime and transcript content. Codex exposes native worker ids, wait/status results, completion notifications, and explicit close operations instead. Treating those surfaces as equivalent would create unsafe ambiguity at every crash boundary.

The critical failures are not only ordinary worker errors:

1. A spawn transport failure can occur after the runtime accepted the worker but before the caller received or durably bound its id.
2. A task can crash after writing intent, after receiving an id, after receiving terminal output, or after closing the worker, leaving a different durable seam at each point.
3. A completion notification and an explicit wait can duplicate or contradict each other.
4. A terminal result can exist while its artifact or manifest record cannot be persisted.
5. A worker can finish on the wrong model/context, leaving mutable output that must not be trusted.
6. A close call can fail or an id can become unqueryable while the worker may still write.
7. A successor session may be unable to address a predecessor's worker even when it can read the predecessor's manifest.

Without a native adapter, silence can look like success, unknown acceptance can cause a duplicate writer, invalid-tier output can be consumed, and takeover can place two writers in one worktree.

## Goals

1. Implement all C3-owned Codex worker-adapter operations using native runtime observations and DOD-811's durable seams.
2. Make every spawn attempt recoverable from a flushed pre-spawn intent, including failure before worker-id binding.
3. Normalize native queued/running/terminal/error/close observations without inferring success from timeout, absence, or free-form text.
4. Persist complete normalized result/error evidence atomically and hash-bind it to the terminal manifest record.
5. Consume DOD-812 tier verification only after result persistence and before digest consumption.
6. Reconcile duplicate/conflicting terminal evidence and guarantee exactly-once digest consumption.
7. Close and reap every accepted worker, including valid, invalid-tier, errored, interrupted, shutdown, and missing-digest outcomes.
8. Quarantine unresolved or contaminated worktrees and define proof-based release/takeover rules.
9. Prove the selected cross-session addressability/termination/quarantine behavior on the supported Codex runtime before C3 is implementation-complete.
10. Preserve Claude behavior and all v0.16 workflow, lane, Gate 2, and concurrency semantics.

## Non-Goals

- No model map, model candidate, reasoning default, capacity signature, Fable bucket, hook matcher, hook enforcement, main-loop preflight, or attestation-comparison implementation. Those are C2.
- No `setup-dodi-dev`, production runtime-profile/register writer, health replay, auth bridge, task creation, scheduler wake configuration, Gate 2 expansion/live-fire, Slack escalation adapter, `runtime-preflight.sh verify-profile` implementation, setup quiescence, or rollback engine. Those are C4.
- No isolated install/release validator, install guide, marketplace or plugin metadata bump, final release matrix, or `0.17.0` release evidence. Those are C5.
- No second skill tree, Codex-specific lane playbook, copied tier/Fable policy, or change to review-round counts and delivery-tier routing.
- No nested workers, worker-created subagents, parallel mutable lanes, multi-driver writes, or general-purpose worker scheduler.
- No consumption, cherry-pick, reset, cleanup, or promotion of output from an invalid-attestation or uncertain worker. C3 records and fences; later lane logic or C4-owned rollback/quiescence handles disposition.
- No assumption that elapsed time, a missing completion notification, an unknown-worker response, process absence, or an operator assertion proves a worker cannot write.
- No change to Gate 2: no scheduled run merges, auto-merges, or enables auto-merge on an epic PR.

## Binding Contracts

### Installed runtime and workflow semantics

`dodi-dev/skills/epic-orchestrator/runtime-policy.md` remains the installed policy authority. C3 links native mechanics from that canon and `execution-model.md`; it does not restate semantic tiers, Fable policy, lane transitions, review gates, or Gate 2 rules.

Only the top-level resident driver, scheduled guard/janitor, or interactive main loop may invoke the adapter and native worker tools. Every spawned worker is a leaf and returns the existing compact `STATUS` + `EVIDENCE` digest. One lane is in flight, implementers are serial, PM/git/register writes are serialized in the driver, and the epic worktree has one writing session.

### Manifest and identity

C3 writes DOD-811 v1 records to the existing absolute manifest path. It does not add a competing manifest or state vocabulary.

- Before id binding, identity is `(runtime, session_id, dispatch_nonce)`.
- After id binding, identity is `(runtime, worker_id)` while every record retains the original session/context/nonce envelope.
- `worker_id` is absent from ordinary `dispatch-intent` records.
- Every manifest append is schema-validated, serialized under a manifest-local exclusive lock, appended as one complete JSON line, flushed, and `fsync`ed before the operation reports success.
- Unknown schema versions, runtimes, states, broken identity chains, non-absolute paths, malformed hashes, and profile-generation mismatches are blockers.

C3 may clarify state-specific Codex `data` branches in the shared schema/docs during implementation, but it must preserve the approved envelope, paths, state names, keys, and meanings. In particular, absent attestation is represented as absent/unattested observed evidence under `attestation-invalid`; requested values are never copied into effective fields to satisfy schema shape.

### Tier and generation handoff

The dispatcher invokes DOD-812's `resolve-tier` before calling C3 `prepare-intent`. C3 accepts only the resulting `TIER_READY` evidence object and verifies that its tier, requested pair, profile generation, profile hash, repo, operation nonce, and verifier binding are internally current per the DOD-812 output shape. Ticket, gate, worktree, session, and prompt identity are C3-owned request-evidence fields that bind the dispatch to that already-verified tier result; C3 does not require C2 to echo those C3 lifecycle fields. C3 never performs model selection itself. Until C4 provides production `verify-profile`, production C3 operations return `SETUP_REQUIRED`; deterministic tests use only the C2 fixture verifier, and the C3 live gate uses an explicitly trusted development installation without writing production setup state.

The adapter passes the native pin and explicit `context_inheritance` request to spawn. After terminal artifact persistence, it invokes DOD-812's `verify-attestation`; it neither compares effective tier itself nor interprets capacity failures.

### Claude boundary

Unversioned v0.16 manifest records are always legacy Claude records. V1 `runtime: claude` records continue through the Claude adapter, `await-worker.sh`, transcript evidence, and Claude reaping rules. Codex records never require or infer `output_file`, transcript mtime, `stop_reason:end_turn`, or a Claude alias. C3 changes shared classification only enough to route v1 Codex records to the Codex adapter while preserving both Claude branches byte-for-byte in regression fixtures.

## Design

### 1. Composite adapter boundary

Create `dodi-dev/scripts/codex-worker-adapter.sh` as the deterministic state, persistence, and normalization surface. The script does not pretend shell can call harness-native agent tools. Instead, each lifecycle operation has two explicit sides:

1. The script validates durable prerequisites and returns one compact JSON action naming the exact native operation and request evidence.
2. The top-level session performs that native Codex tool call.
3. The session writes the exact returned observation to a mode-`0600` temporary JSON input and immediately feeds it to the script for validation, normalization, and durable transition.

The script exposes these semantic commands:

```text
codex-worker-adapter.sh prepare-intent ...
codex-worker-adapter.sh spawn --phase request|observe ...
codex-worker-adapter.sh await --phase request|observe ...
codex-worker-adapter.sh persist-result ...
codex-worker-adapter.sh close --phase request|observe ...
codex-worker-adapter.sh reap-recover ...
codex-worker-adapter.sh digest --phase ready|claim|ack ...
```

`spawn`, `await`, and `close` request phases perform no runtime mutation; they emit a redacted action object only after proving the preceding durable state. Observe phases accept only runtime-versioned fixture shapes captured from the supported Codex runtime. Unknown fields may be retained in the private normalized artifact where safe, but an unknown status, identity field, or acceptance/terminal/close meaning fails closed rather than being guessed.

Successful stdout is one JSON object. Diagnostics go to stderr, are concise, and never print prompt text, digest bodies, credentials, arbitrary environment values, or raw runtime payloads. Stable exit classes align with C1/C2: `0` successful named outcome, `2` malformed input/dependency, `3` `SETUP_REQUIRED`, `4` unresolved/unsafe lifecycle state, and `5` safe-output/persistence failure.

All manifest and lifecycle-ledger updates use the same lock discipline: acquire the manifest-local exclusive lock, read and validate the complete manifest plus `worker-quarantine.jsonl`, evaluate the transition predicate against that locked state, append exactly one complete JSON line, flush and `fsync` the file, `fsync` the directory when a new file may appear, then release. Digest claim/ack uses this locked compare-and-append contract; no caller may read an unclaimed digest and append a claim outside the adapter.

### 2. Durable request and pre-spawn intent

For each attempt, the adapter generates a cryptographically random dispatch nonce and creates this deterministic request-evidence path before the manifest intent:

```text
<epic-worktree>/.dodi/workers/<session-id>/requests/<dispatch-nonce>.json
```

The request evidence is mode `0600`, written through a same-directory temporary file, parsed, flushed, atomically renamed, and directory-`fsync`ed. It contains no raw prompt; it records the prompt SHA-256, purpose, absolute worktree, declared write scope, C2 `TIER_READY` evidence hash, semantic tier, requested model/reasoning, profile generation/hash, owning session/context, gate context needed by C2, and `context_inheritance` (`fresh-required`, `may-inherit`, or `same-context-required`). DOD-811's intent `prompt_sha256` is the SHA-256 of this canonical prompt/input evidence, making the deterministic path recoverable and integrity-checkable without adding a manifest field.

The serialized `write_scope` values are DOD-811's vocabulary: `mutable` or `read-only`. This spec may describe `mutable` as worktree-writing work in prose, but the manifest and request evidence always write `mutable`.

For `mutable` scope, `prepare-intent` requires:

- an absolute worktree path owned by the current lane;
- `git rev-parse HEAD` yielding a 40-character commit id;
- exact bytes from `git status --porcelain=v1 -z --untracked-files=all` to be empty before spawn;
- `baseline_status_sha256` computed from those exact bytes;
- the index tree from `git write-tree` to equal `<baseline_head>^{tree}`;
- no unresolved intent, unreaped worker, active writer-uncertain quarantine, or foreign live claim for that worktree.

`read-only` work records `read_only_baseline: true` and still records HEAD/status evidence for diagnosis when available, but does not require a clean mutable surface unless the owning playbook already does.

Only after C2 `TIER_READY` evidence, request evidence, and intent data are durable does the adapter append `dispatch-intent`. Spawn is forbidden if that append cannot be proved flushed. Every retry that can create a worker gets a new nonce and a new intent; an authoritative rejection may be retried under lane/Fable policy, while unknown acceptance may not.

### 3. Spawn normalization and id binding

The spawn request carries the exact C2-resolved native model/reasoning pins, the request's context-inheritance control, and the dispatch nonce in runtime metadata and in the worker prompt header. Prompt text is correlation help, not binding evidence.

Spawn observations normalize into exactly one of these paths:

| Native evidence | Durable transition | Required action |
| --- | --- | --- |
| Structured authoritative rejection proves no worker was accepted | `spawn-rejected` | Return the normalized rejection to existing C2 capacity/lane routing; a retry uses a new intent. |
| Accepted response returns one worker id | `dispatched` | Bind that exact id to the nonce before any wait/result consumption. |
| Transport timeout/loss or response cannot prove non-acceptance | `spawn-acceptance-unknown` | Keep intent unresolved; query/enumerate by owning session + nonce. Never spawn a replacement. |
| Response says accepted but omits a stable id | `spawn-acceptance-unknown` | Treat as potentially writing and enter recovery. |
| Response id conflicts with an id already bound to the nonce, or one id binds to another nonce | `evidence-conflict` then `writer-uncertain` | Consume neither identity, quarantine, and stop lane progress. |

If spawn returns an id but the `dispatched` append fails, the session retries durable id binding first while retaining the observation in current context. If binding still cannot be persisted, safety overrides the usual pre-close bookkeeping: the session attempts an emergency native close on that returned id, then records the id-binding failure, emergency-close observation, terminal evidence if available, and quarantine evidence as soon as any durable append path is available. Without a durable `dispatched` chain plus terminal/result evidence, it does not append `reaped`, does not release the worktree, and does not launch a replacement. The returned id is never forgotten.

For `spawn-acceptance-unknown`, `reap-recover` may bind only one uniquely matched runtime descendant whose owning session and nonce both agree. Zero matches are safe only when the selected live-gate path provides authoritative runtime-owned parent-termination evidence covering that exact predecessor and descendants. Multiple matches, incomplete enumeration, or unrecognized evidence remains `writer-uncertain`.

### 4. Await and terminal normalization

Every completion notification is correlated by worker id and nonce, then followed by an explicit wait/query of the same id. Native status values are allowlisted and runtime-versioned in fixtures:

- queued/running with an authoritative worker id becomes `waiting` and is not success;
- a structured wait deadline that also attests queued/running becomes `waiting`, not an error;
- a local/tool timeout with no authoritative current status becomes `wait-error` with `wait-timeout`, followed by re-query of the same id;
- transport failure, malformed response, or unknown status becomes `wait-error` and bounded same-id recovery;
- unknown-worker is not terminal proof by itself and routes to close/recovery;
- native terminal results normalize only to `completed`, `errored`, `interrupted`, or `shutdown`.

Wait timeout never authorizes redispatch. Repeated query failure routes to close; close failure or an unqueryable worker without prior no-write proof activates quarantine.

A completed worker must contain the existing compact worker digest. Missing digest is stored in the normalized result artifact as `missing_digest: true`; the adapter still records the native terminal state, closes/reaps the worker, and returns a lane failure without consuming output. `errored`, `interrupted`, and `shutdown` similarly persist the complete normalized error/status and do not advance PM/git state.

### 5. Result artifacts and terminal ordering

Each distinct normalized terminal result is stored content-addressed at:

```text
<epic-worktree>/.dodi/workers/<session-id>/<worker-id>/result-<sha256>.json
```

The canonical JSON artifact contains only result identity fields:

- schema/runtime version, session/context/nonce/worker identity, terminal status, and runtime-attested terminal timestamp when the runtime supplies one;
- requested semantic tier/model/reasoning and request-evidence hash;
- runtime-attested effective model/reasoning/context and inheritance evidence when present;
- the complete compact digest, or the complete normalized error/missing-digest marker;
- no prompt body, credential, or arbitrary runtime environment.

Observation-specific data lives separately in sibling observation artifacts keyed by observation id/hash. Those records contain the source class (`notification`, `wait`, `close`, or recovery query), redacted native-observation hash, observation arrival timestamp, and runtime-versioned raw status envelope. Two observations of the same worker result may therefore have different observation hashes while pointing at the same canonical result hash. The canonical result hash excludes observation source, observation arrival timestamp, and redacted native payload hash.

The adapter writes the canonical result artifact mode `0600` via a same-directory temporary file, parses it back, flushes and `fsync`s it, atomically renames it, `fsync`s the directory, and verifies filename/content hash before any terminal manifest record is appendable. Existing content at the same hash must be byte-identical. A write, parse, rename, permission, flush, or hash failure leaves no terminal manifest record and forbids all PM/git state advance. The session retries while holding ownership; persistent failure may record close/no-write emergency evidence where possible, but it does not append `reaped`, release the worktree, or consume output until the missing durable result evidence is repaired. Mutable scope remains quarantined.

C2 verification output is stored at:

```text
<epic-worktree>/.dodi/workers/<session-id>/<worker-id>/tier-verification-<sha256>.json
```

It is written mode `0600` with the same temporary-file, parse, flush, atomic rename, directory-`fsync`, and filename/content-hash verification rules as result artifacts. The terminal manifest record stores the absolute tier-verification path/hash alongside the result and observation path/hashes. A tier-verification write failure is a persistence failure: no terminal record is consumable, and mutable scope remains quarantined until repaired.

Terminal processing order is binding:

1. persist normalized result artifact;
2. persist the observation artifact that produced or confirmed that result;
3. call C2 `verify-attestation` from durable request + result evidence;
4. persist a tier-verification artifact containing the exact C2 outcome and evidence hash;
5. append the normalized terminal manifest record only when it can reference the result artifact, observation artifact, and tier-verification artifact;
6. on `TIER_UNVERIFIED`, append `attestation-invalid` instead of a consumable terminal record and retain the artifact without consuming its digest;
7. on `SETUP_REQUIRED`, retain the result and verification artifact, close/reap when possible, return `SETUP_REQUIRED` to the C4-owned recovery path, and do not append `attestation-invalid`;
8. append `close-requested`, perform close, and append `closed` when authoritative;
9. perform final same-id reconciliation, append `reaped`, and prove the slot/no-write postcondition;
10. only then append `digest-ready` in the C3 lifecycle ledger for one verified digest.

No current-context result bypasses this ordering.

### 6. Duplicate and conflicting terminal evidence

Terminal equivalence is exact canonical result hash plus terminal state and worker identity. Observation hashes may differ.

- Equivalent notification/wait/close observations are duplicates. The first terminal evidence is canonical; later equivalent observations may append equivalent bookkeeping but never trigger a second digest consumption.
- Different state, canonical result hash, digest/error, effective attestation, tier-verification outcome, or worker identity is an `evidence-conflict`. Every candidate remains as a content-addressed result artifact and the manifest records all observation hashes in `observations`; no candidate is consumed.
- Conflict recovery performs bounded authoritative re-queries of the same worker and an explicit close. Resolution requires two subsequent authoritative observations plus close status to agree byte-for-byte with one candidate. The adapter then appends the winning terminal evidence and proceeds through attestation/reap once.
- If that agreement cannot be obtained, the adapter appends `writer-uncertain`, activates quarantine, and returns a blocker. A majority, newest timestamp, notification priority, or operator preference is not resolution evidence.

Digest delivery uses a durable ready/claim/ack protocol in the C3 lifecycle ledger:

1. `digest-ready` is appended only after verified terminal evidence, close, and reap.
2. The lane asks the adapter to claim the digest with an idempotency key derived from ticket id, phase/gate, worker id, result hash, expected worktree HEAD, and the next durable lane seam.
3. The adapter appends `digest-claimed` and returns the digest only for that key. A replay with the same key returns the same digest and claim id; a different key is rejected while the claim is unacknowledged.
4. The lane applies the digest only through its normal idempotent seam write, then calls the adapter to append `digest-acked` with the seam evidence hash.
5. A crash after claim but before ack resumes the same claim and replays the same seam; it never opens a second independent consumption path. A crash after ack sees `digest-acked` and does not return the digest again.

This protocol treats "possibly delivered to the caller but not acknowledged" as adopted work requiring the same idempotency key; it does not infer whether the prior in-memory caller used the digest.

### 7. Attestation failure and baseline comparison

After result persistence, C3 invokes DOD-812 `verify-attestation` with the durable request evidence, runtime attestation, and gate context. `WORKER_TIER_VERIFIED` permits cleanup to continue; it does not itself consume the digest. `TIER_UNVERIFIED` maps to `attestation-invalid` after preserving the observed evidence. `SETUP_REQUIRED` is a distinct setup/generation failure: C3 preserves the result and tier-verification artifact, closes/reaps when it can prove doing so safely, returns `SETUP_REQUIRED` to the C4-owned recovery path, and never labels the worker's effective evidence invalid.

For absent runtime attestation, the result artifact stores explicit null/absent observations and the manifest records `attestation-invalid`; requested model/reasoning are never relabeled as effective. Any C1 state-specific schema clarification needed to encode absent observations is made in the shared schema branch during C3 implementation without adding a state or weakening validation.

The adapter then closes/reaps before examining or acting on mutable output. For `mutable` scope, baseline comparison is deterministic:

```text
current HEAD == intent baseline_head
current index tree == baseline_head^{tree}
sha256(git status --porcelain=v1 -z --untracked-files=all) == baseline_status_sha256
```

- If all three match and close/reap/no-write proof is durable, the worktree can be released from uncertainty; the invalid digest remains unusable and the lane retries with a new worker only under existing retry policy.
- If any comparison differs, comparison cannot run, or the worker may still write, activate quarantine. Do not reset, clean, commit, stash, inspect-and-promote, or reuse that worktree.
- After close/reap proof, a successor may start only in a newly created worktree at the recorded `baseline_head`; no file or commit from the contaminated worktree is copied. If no-write proof is absent, the ticket is not redispatched even in a new worktree.
- Read-only intent may be released only after close/reap proof and confirmation that its declared scope did not mutate the worktree; otherwise it is treated as mutable contamination.

### 8. Close, reap, and quarantine

The adapter appends `close-requested` before every native close call when the manifest chain is writable. The one exception is the post-accepted-id emergency close path where the manifest cannot bind or record the worker id: in that case the session closes first to stop a possible writer, then durably records the emergency close attempt/result and keeps the worktree quarantined until the missing chain is repaired or no-write proof is established. Close normalization is fail-closed:

| Close evidence | Meaning |
| --- | --- |
| Authoritative `closed` plus terminal/no-write proof | Append `closed`; eligible for final reconciliation and `reaped`. |
| `running`, pending close, or asynchronous acceptance | Continue bounded same-id query; not reaped. |
| `not-found` | Proof only if the live gate establishes that this exact response means no descendant can write and identity matches; otherwise uncertainty. |
| Tool/transport failure, unsupported status, malformed identity, or unqueryable id | Record evidence if possible, append `writer-uncertain`, quarantine. |

`reaped` means the runtime concurrency slot is released and no worker under that identity can still write. It is appended only after terminal/close proof, result evidence, and any required tier-verification evidence are durable. Failure to append `reaped` blocks close-out and successor dispatch; persistent append failure activates quarantine. Emergency close evidence without the full result chain is not `reaped`.

C3 adds an append-only ledger at:

```text
<epic-worktree>/.dodi/worker-quarantine.jsonl
```

It records `quarantine-activated`, `quarantine-release-proved`, `digest-ready`, `digest-claimed`, and `digest-acked` events keyed by manifest/session/nonce and worker id when known. Each event carries reason, worktree, baseline, evidence paths/hashes, timestamp, and predecessor/successor identity. This is C3-specific safety evidence, not a second dispatch manifest and not a new PM/register authority.

An active `quarantine-activated` record blocks every new dispatch into the affected worktree, including read-only dispatches, until a matching `quarantine-release-proved` record exists. Read-only workers are still processes with filesystem visibility and native lifecycle ambiguity; they cannot be used as a probe inside a quarantined worktree.

Quarantine release requires one of:

1. the exact worker is addressable, terminal/closed/reaped, all evidence conflicts are resolved, and baseline comparison is known; or
2. the live-gate-selected runtime-owned parent-termination proof covers the exact predecessor session/context, nonce, descendants, and worktree; or
3. the worktree remains quarantined and a human resolves the runtime externally, after which the adapter captures the same authoritative no-writer proof. A human assertion or elapsed grace period alone is insufficient.

Release has two meanings. A baseline-clean worktree may be released for reuse after proof. A contaminated worktree is released only for manual disposition/removal after proof; C3 never restores it, and a successor uses a fresh worktree from the baseline commit. An unresolved intent with no approved proof remains quarantined indefinitely, blocks redispatch for that ticket, and returns an escalation-required outcome for C4's future adapter.

### 9. Cross-session takeover

At every driver boot/resume and before any new mutable dispatch, `reap-recover` reads all relevant manifests and quarantine records, validates their chains, and classifies unresolved intents/workers. It does not infer liveness from the current task's in-memory worker list alone.

Recovery order is:

1. resolve intents with no id by exact owning session + nonce enumeration;
2. query every bound but unreaped worker by id;
3. persist any terminal observation before close/reap;
4. close/reap terminal, invalid, or abandoned workers;
5. activate or preserve quarantine for ambiguity;
6. return `QUIESCENT` only when no unresolved possibly-writing identity remains for the selected worktree.

Takeover never changes manifest ownership fields and never rewrites history. It appends recovery observations under the predecessor identity while the new top-level session is the actor recorded in C3 ledger evidence. A successor cannot dispatch beside a predecessor worker that may write.

The live gate selects one supported behavior:

- **Addressable takeover:** worker ids remain enumerable/queryable/closable across context refresh, task resume, and crashed-session takeover; recovery uses the native id.
- **Parent-termination takeover:** the runtime gives authoritative evidence that terminating/losing the owning parent terminates all descendants before another session can resume; recovery records that proof and releases only covered identities.
- **Quarantine-only:** neither addressability nor parent termination is provable; unresolved worktrees remain quarantined with an escalation-required blocker. Scheduled delivery stays disabled unless the parent-approved release gate accepts this exact fail-closed behavior for every unresolved path.

There is no path where an unaddressable possibly-writing worker and a successor writer share a worktree.

## File Surfaces

### New files

| File | C3 responsibility |
| --- | --- |
| `dodi-dev/scripts/codex-worker-adapter.sh` | Deterministic lifecycle state machine, durable writes, observation normalization, baseline checks, quarantine ledger, and action/result JSON. |
| `dodi-dev/scripts/tests/test-codex-worker-adapter.sh` | Deterministic lifecycle, crash-seam, duplicate/conflict, baseline, close/reap, takeover, and redaction tests. |
| `dodi-dev/scripts/tests/fixtures/codex-worker/` | Runtime-versioned redacted spawn/wait/terminal/close/enumeration fixtures plus malformed and conflict cases. |
| `dodi-dev/scripts/tests/fixtures/codex-worker/live/` | Redacted supported-runtime tool schemas, cross-session gate observations, selected takeover mode, runtime version, and evidence hashes. |

### Modified files

| Surface | C3 edit |
| --- | --- |
| `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md` | Replace the C1 lifecycle `UNSUPPORTED_RUNTIME` fence with the native composite protocol, operation postconditions, recovery, and live-gate result; retain C2 operation links. |
| `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md` | Mark C3 lifecycle operations implemented and add concise quarantine/result-ordering links without duplicating mechanics. |
| `dodi-dev/skills/epic-orchestrator/runtime-policy.md` | Link C3 adapter for Codex lifecycle and preserve the single policy authority. |
| `dodi-dev/skills/epic-orchestrator/execution-model.md` | Select Codex native await/close/reap mechanics through the adapter while retaining Claude dual-wake and all lane seams. |
| `dodi-dev/runtime/adapter-contracts.md` | Document deterministic request/result/quarantine paths and C3/C4 quiescence handoff; no profile/register authority change. |
| `dodi-dev/runtime/dispatch-manifest-record.schema.json` | Only C3-specific Codex `data` refinements needed for absent attestation and normalized native evidence; no path, envelope, key, or state change. |
| `dodi-dev/scripts/reap-workers.sh` | Route v1 Codex records through C3 `reap-recover`; preserve legacy/v1 Claude classification and transcript behavior. |
| `dodi-dev/scripts/tests/test-worker-manifest-contract.sh` | Replace C1's Codex `UNSUPPORTED_RUNTIME` expectation with supported lifecycle/recovery fixtures while preserving all Claude fixtures. |
| `scripts/validate-runtime-contracts.sh` | Validate C3 files, paths, state ordering, ownership fences, and live-evidence shape; preserve C4/C5 absence checks. |
| `scripts/validate-phase-skills.sh` | Require executable C3 script/test and installed adapter references. |

### Explicitly unchanged

- `dodi-dev/scripts/await-worker.sh` and its tests; it remains Claude adapter mechanics.
- `dodi-dev/scripts/codex-tier-adapter.sh`, `codex-capacity-classifier.sh`, model-map files, model-pin hook, and C2's attestation/verifier shapes.
- runtime-profile, health, and Linear register paths/authorities; C3 reads generation evidence only through C2/C4 boundaries.
- setup, auth, scheduler, Slack, Gate 2, marketplace, plugin metadata, release docs, and isolated-release validator surfaces.
- mature/deliver lane order, review prompts, worker return contract, retry ceilings, PM labels, and Gate 2 procedure.

## Implementation Sequence

1. Land/reconcile DOD-811 and DOD-812 contracts; capture the exact supported-runtime native lifecycle schemas as redacted fixtures before coding normalization.
2. Implement manifest-locked append, canonical request/result persistence, baseline calculation, and quarantine ledger primitives with crash-point tests.
3. Implement `prepare-intent` and spawn request/observe phases, including unknown acceptance and id-binding-write recovery.
4. Implement await/terminal normalization, content-addressed result persistence, duplicate/conflict reconciliation, and missing-digest handling.
5. Integrate C2 `verify-attestation`, then implement durable tier-verification artifacts, close, final reconciliation, reap, invalid-attestation baseline comparison, and ready/claim/ack digest consumption.
6. Implement `reap-recover` and update `reap-workers.sh` routing while preserving both Claude classifiers.
7. Update installed adapter/canon/contract docs and repository validators without changing C4/C5 surfaces or metadata.
8. Run deterministic fixtures and repository regression.
9. Execute the live cross-session gate, record redacted evidence and the selected takeover mode, and leave C3 blocked if no approved safe path passes.

## Validation Strategy

### Deterministic fixtures

`test-codex-worker-adapter.sh` must cover at least:

- clean mutable and read-only intent creation; dirty worktree, changed index, malformed profile generation, stale request evidence, duplicate nonce, unresolved predecessor, and manifest append failure;
- authoritative spawn rejection, recognized Frontier rejection handoff without local classification, accepted id binding, acceptance unknown, accepted-without-id, id collision, and id-binding append failure followed by close success/failure;
- structured running wait expiry versus tool timeout, transport error, unknown status, unknown worker, terminal status normalization, repeated same-id query, and no redispatch;
- atomic result success and failures at temp write, parse, flush, rename, directory flush, hash verify, terminal append, and existing-content mismatch;
- completed digest, missing digest, errored, interrupted, shutdown, absent/mismatched attestation, distinct `SETUP_REQUIRED`, and no output consumption before verification;
- equivalent notification/wait duplicates by canonical result hash, conflicting state/hash/attestation, two-read conflict resolution, unresolved conflict quarantine, and ready/claim/ack digest consumption across replay;
- close success, asynchronous/running close, not-found with and without approved proof, close transport failure, unqueryable worker, reap append failure, and slot-release proof;
- invalid-attestation baseline unchanged, changed HEAD, changed index tree, tracked/untracked status change, baseline command failure, fresh replacement worktree requirement, and no contaminated-output promotion;
- unresolved no-id intent with unique/zero/multiple enumeration, cross-session bound-id recovery, parent-termination evidence, quarantine-only behavior, proof-based release, and no time/operator-assertion release;
- legacy v0.16 Claude, v1 Claude, and v1 Codex mixed manifests, with no Codex transcript inference and no Claude regression;
- diagnostics/output redaction, mode `0600`, absolute paths, canonical JSON/hashes, lock serialization, interrupted append recovery, and unknown schema/runtime/state failure.

Crash-seam fixtures interrupt after every durable boundary: request artifact, intent, native spawn response before binding, binding, terminal observation before artifact, result artifact before tier verification, tier-verification artifact before terminal record, terminal record before close, close before reap, reap before `digest-ready`, `digest-ready` before `digest-claimed`, and `digest-claimed` before `digest-acked`. A fresh `reap-recover` invocation must select the same next safe action without in-memory context.

### Required live Codex cross-session gate

Before DOD-813 is implementation-complete, run on the parent-supported Codex Desktop/plugin runtime and retain only redacted schemas, ids, timestamps, hashes, and status evidence:

1. Spawn a disposable read-only leaf after durable intent; prove native completion, explicit wait, normalized result persistence, close, reap, and digest acceptance.
2. Repeat with a mutable disposable worktree and prove the baseline remains attributable to the intent.
3. Refresh/compact the top-level context, resume from manifest only, and prove the same worker id is queryable/closable or record the authoritative alternative.
4. Resume from a different top-level task/session and test cross-session enumeration/query/close of a predecessor worker.
5. Crash after durable intent but before id binding; recover by owning session + nonce or prove runtime-owned parent termination. If neither is possible, prove quarantine blocks redispatch and same-worktree reuse.
6. Crash after id return but before binding append; use retained/native enumeration evidence to close and reconcile without launching a replacement.
7. Exercise one explicit close while running and prove whether close is synchronous, how terminal/no-write evidence appears, and when the concurrency slot is released.
8. Deliver duplicate notification/wait terminal observations and capture the equivalent canonical result hash with distinct observation hashes; inject a deterministic conflicting fixture to prove the live adapter refuses consumption.
9. Run a C2-verifiable terminal result and an invalid-attestation mutable result; prove the latter is closed/reaped, baseline-compared, quarantined when changed, and never consumed.
10. Record the supported runtime version, exact redacted tool/status schemas, selected `addressable`, `parent-termination`, or `quarantine-only` mode, and every evidence hash under the live fixture directory.

Discovery, an in-session happy path, deterministic fixtures, or an operator assertion alone does not satisfy this gate. Failure to attest worker identity/status, recover uncertain acceptance, prove no-write after close, or enforce quarantine blocks DOD-813 and therefore blocks scheduled delivery; implementation must not narrow the support claim or fall back to Claude transcript assumptions.

### Repository regression

Run:

```bash
scripts/validate-runtime-contracts.sh
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
```

Metadata remains `0.16.0` until C5. Existing Claude worker tests, Gate 2 guard behavior, lane validators, and ticket-comment templates must remain green.

## Acceptance Criteria

1. Every Codex spawn attempt has flushed request evidence and a schema-valid `dispatch-intent` before native spawn; mutable intents prove a clean HEAD/index/status baseline.
2. Spawn outcomes distinguish authoritative rejection, accepted/bound id, and unknown acceptance. Unknown or conflicting acceptance never launches a successor, and id-binding failure triggers immediate close/recovery.
3. Await distinguishes authoritative still-running expiry from transport/query errors, normalizes only allowlisted terminal states, and never treats timeout, silence, or unknown-worker as completion.
4. Every terminal/error observation is durably stored in parsed, mode-`0600`, content-addressed result and observation artifacts; the terminal manifest record references result, observation, and tier-verification hashes before consumption.
5. Completed output with missing digest and all errored/interrupted/shutdown outcomes close/reap without PM/git advancement. Persistent artifact/manifest failure quarantines rather than losing evidence, appending false `reaped`, or consuming current-context output.
6. Equivalent terminal observations produce one canonical result and one digest-ready record; ready/claim/ack guarantees replay-safe exactly-once consumption. Conflicts consume none until two authoritative re-reads plus close agree with one candidate; unresolved conflicts quarantine.
7. C2 `verify-attestation` is called after result persistence and before terminal consumption. `TIER_UNVERIFIED` is retained as `attestation-invalid`, while `SETUP_REQUIRED` remains a distinct setup/generation blocker; neither path promotes output.
8. Close failure, running/pending close, unqueryable worker, unresolved intent, multiple recovery matches, failed reap append, or unproved no-write state produces `writer-uncertain` quarantine and blocks ticket redispatch.
9. Quarantine release requires exact runtime proof. Baseline-clean worktrees may be reused only after proof; contaminated worktrees are never reused and successors start from the recorded baseline in a new worktree only after no-write proof.
10. `reap-recover` reconstructs the same next action after every crash seam from manifest/request/result/quarantine evidence and never depends on Claude transcripts for Codex.
11. Mixed legacy Claude, v1 Claude, and v1 Codex manifests classify correctly; `await-worker.sh` and Claude transcript/reap behavior remain unchanged.
12. The live current-runtime gate proves and records one approved cross-session addressability/parent-termination/quarantine mode, including the crash-before-binding case. A failed or ambiguous gate leaves DOD-813 blocked.
13. Top-level-only dispatch, leaf workers, one driver writer, serial mutable lanes, no silence-as-success, existing retry/Fable routing, and no automation Gate 2 merge remain intact.
14. C3 does not implement or modify C2 model/capacity/hook policy, C4 setup/profile/register/auth/scheduling/Gate 2/escalation/rollback, C5 release validation/docs/metadata, or Linear labels.
15. All deterministic tests and repository validators pass with metadata still at `0.16.0`.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Spawn is accepted but id delivery is lost | Durable nonce before spawn; exact session+nonce recovery; no retry while acceptance is unknown; quarantine on ambiguity. |
| Agent ids are session-local | Required cross-session live gate; select addressable, parent-termination, or quarantine-only mode; never speculative takeover. |
| Notification and wait disagree | Content-addressed candidates, explicit conflict state, two authoritative re-reads plus close, no majority/newest guess. |
| Terminal output exists only in current context | Artifact-before-manifest ordering with retries; no PM/git advancement on persistence failure. |
| Invalid-tier worker changed files | Close/reap first, exact HEAD/index/status comparison, quarantine contamination, fresh worktree from baseline only. |
| Close response does not prove no writes | Runtime-versioned allowlist and live proof; pending/not-found/unknown remains uncertain unless the selected mode proves otherwise. |
| Quarantine becomes a silent dead end | Durable ledger and escalation-required outcome; C4 consumes the quiescence/blocker status, but C3 does not implement Slack delivery. |
| New C3 paths become a competing state authority | Manifest remains lifecycle authority; request/result/quarantine files are hash-bound supporting evidence with narrow ownership. |
| C3 drifts into C2 verification | Invoke C2 operations and consume named outcomes; validators reject model maps, capacity signatures, or local effective-tier comparisons in C3. |
| Shared reaper breaks Claude | Explicit three-way legacy Claude/v1 Claude/v1 Codex fixtures; `await-worker.sh` unchanged. |
| Crash tears JSONL or result evidence | Manifest lock, one-line append + `fsync`, atomic result rename, directory `fsync`, hash verification, crash-seam replay tests. |

## Migration and Rollback

### Migration

- Existing unversioned manifests remain legacy Claude and are never rewritten.
- Existing v1 Claude records continue through the Claude adapter.
- C1 v1 Codex fixtures that previously returned `UNSUPPORTED_RUNTIME` become C3-supported only when the adapter and runtime-versioned fixture contract are present.
- In-flight unresolved Codex records encountered during development are recovered or quarantined; migration never fabricates terminal/reap records.
- Production Codex lifecycle remains `SETUP_REQUIRED` until C4's same-command profile/health/register verification exists. C3 passing does not enable schedules.
- C5 later repeats C3's live gate inside the isolated release matrix and bumps metadata; C3 does neither.

### Rollback

Rollback disables Codex lifecycle selection and restores the explicit `UNSUPPORTED_RUNTIME` fence. It must not delete or rewrite manifests, result artifacts, request evidence, or quarantine records created by C3.

Before code rollback, run `reap-recover` and require either quiescent proof or active quarantine for every Codex intent/worker. If quiescence cannot be proved, leave affected worktrees and tickets fenced; do not fall back to Claude scripts or remove the adapter while a worker may write. Claude behavior can continue because its adapter and legacy classification are unchanged.

## Blocking Questions

None for specification. The exact native lifecycle payloads and selected cross-session mode are implementation/live-gate evidence, not discretionary architecture choices: an unrecognized or unsafe result blocks DOD-813 rather than weakening the approved fail-closed contract.
