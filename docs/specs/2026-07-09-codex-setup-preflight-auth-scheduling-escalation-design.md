# DOD-814 - Codex Setup, Preflight, Auth, Scheduling, Gate 2, and Escalation

## TL;DR

Implement `setup-dodi-dev` as the sole explicit, operator-confirmed path that proves a Codex installation safe for Dodi automation, transactionally stages and commits the C1 profile/health generation with detectable mid-rename crash seams, configures restricted scheduled tasks, and establishes a durable Slack escalation route backed by the Linear runtime register. All setup, verification, recovery, and rollback paths fail closed on ambiguous identity, state generation, register history, worker quiescence, hook enforcement, scheduler behavior, marketplace provenance, or server-side Gate 2 protection.

## Key Points

- C4 consumes the C1 profile, health, register, lock, manifest, and adapter contracts exactly; it adds writers and live verification without defining alternate paths, schemas, states, or authorities.
- `setup-dodi-dev` never mutates during discovery: it presents the complete intended marketplace, auth, hook, GitHub, Slack, profile, and task changes, then requires explicit operator confirmation before each mutation class.
- One stable-lock state engine owns setup, health replay, crash recovery, and rollback; profile/health mismatch, torn generations, stale snapshots, and unresolved Linear history never unlock workflow work.
- Direct Linear GraphQL remains canonical. `LINEAR_DODI_API_KEY` is bridged in-process to `LINEAR_API_KEY` without printing or persisting a secret, and one exact runtime-register issue is replayed as an append-only hash chain.
- Lights-out enablement requires a dedicated GitHub automation identity that cannot update or bypass the protected base or administer its rules, plus trusted and live-fired model-pin and Gate 2 hooks; any unreadable or ambiguous permission/matcher evidence blocks enablement.
- The harness-native driver/janitor task pair for each configured scope is created or updated only after quiescence, uses the C2-verified Standard pair, proves no-overlap and successor wake behavior, and exposes no automated epic Gate 2 merge path.
- Slack is the only 0.17 escalation delivery adapter. Every send is preceded by a durable register obligation, retries and repair are generation-bound, and a delivery is complete only after its durable Slack id/link is appended to the register.
- Same-name marketplace sources with different roots are a blocking collision until the operator explicitly migrates or selects the canonical source; setup never upgrades an ambiguous installation.
- C5 remains out of scope: C4 does not add release/install guides, isolated-release validators, final evidence bundles, metadata `0.17.0` bumps, or release signoff.

## Decision Context

- Parent epic: DOD-810.
- Approved parent specification: `docs/specs/2026-07-09-codex-runtime-compatibility-design.md` at `baf219a`.
- Workflow mode: waterfall.
- DOD-811 runtime foundation spec/plan are canonical at `978cad7`.
- DOD-812 tier-map and hook-enforcement spec/plan are canonical at `5d084b5`.
- DOD-813 worker-lifecycle spec/plan are canonical at `a3124f4`.
- Implementation may begin only after the C2 and C3 implementation commits are ancestors of the C4 branch. Their canonical plans are design inputs, not substitutes for landed executable contracts.
- Predicted delivery tier: Capable.

## Problem

DOD-811 through DOD-813 define the runtime profile, health projection, Linear register, model verification, hook request enforcement, and Codex worker lifecycle boundaries. They intentionally leave production Codex operation fenced behind `SETUP_REQUIRED`: there is no authoritative writer for the profile/health generation, no live register replay, no environment-key bridge, no proof that the scheduled GitHub actor is structurally barred from Gate 2, no trusted/live-fired Gate 2 hook, no scheduler mutation or wake/no-overlap proof, and no durable Slack delivery adapter.

Treating these as operator notes would leave the highest-risk automation prerequisites outside deterministic enforcement. A partial setup or setup crash could pair a new profile with old health, restore stale obligations, run old tasks against new state, create a duplicate Linear register, schedule beside unresolved workers, select the wrong marketplace source, or enable an actor that can merge the epic PR. C4 must make those states detectable and non-runnable while preserving all v0.16 workflow semantics.

## Goals

1. Add one explicit `setup-dodi-dev` operator workflow for bootstrap, inspection, confirmed mutation, verification, recovery, update, and rollback.
2. Implement C1's canonical profile/health writer and `runtime-preflight.sh verify-profile` proof producer with stable-lock, generation, register-tip, and same-invocation bindings required by C2.
3. Implement direct Linear runtime-register search, creation, append, replay, and lost-response recovery against C1's schema and hash-chain rules.
4. Resolve `LINEAR_API_KEY` from the approved precedence, including an in-process `LINEAR_DODI_API_KEY` bridge, without exposing secret values in files, output, prompts, fixtures, or task metadata.
5. Prove the scheduled GitHub automation identity, repository access, branch/ruleset posture, protected-base denial, and inability to administer protection before enabling lights-out operation.
6. Verify hook discovery and explicit operator trust, normalize and expand Gate 2 enforcement for the supported Codex runtime, and retain C2's model-pin hook output as an input rather than redefining it.
7. Create/update and test the driver and janitor as harness-native scheduled tasks with exact config fingerprints, Standard main-loop setup, no overlap, quiescent replacement, and successor wake evidence.
8. Implement Slack escalation with register-before-send, durable-delivery-after-send ordering, bounded retries, degradation, re-escalation, and replay/repair semantics.
9. Detect and safely migrate stale marketplace-name collisions without silently selecting or deleting a source.
10. Preserve top-level-only worker dispatch, one mutable lane at a time, one driver writer, no scheduled Gate 2 merge, and no secret leakage.

## Non-Goals

- No change to C1 profile/health/register paths, schema versions, field meanings, hash definitions, stable-lock selection, manifest states, or runtime authority.
- No change to C2 semantic tiers, model candidates, candidate ordering, capacity classification, Fable policy, attestation rules, main-loop tier requirements, or model-pin result shapes.
- No change to C3 spawn/await/result/close/reap mechanics, quarantine ledger, takeover mode, result artifacts, digest protocol, or worker lifecycle vocabulary.
- No new workflow state, lane, review round, dispatch topology, concurrency policy, Gate 1/Gate 2 meaning, or automated epic-PR merge path.
- No Linear connector/MCP dependency, alternate escalation ledger, mutable global `notification-degraded` flag, or second Slack/email fallback adapter.
- No implicit setup during plugin installation, automatic hook trust grant, silent marketplace rewrite, or unconfirmed scheduled-task mutation.
- No C5 isolated install/release validator, install guide, release guide, final compatibility evidence bundle, or metadata/version bump to `0.17.0`.
- No production secret file managed by the plugin. Setup may consume an operator-selected mode-`0600` environment file, but it neither copies nor rewrites the credential.

## Binding Contracts

### C1 runtime-state contract

C4 consumes these C1-owned surfaces after they land:

- `dodi-dev/runtime/runtime-profile.schema.json`;
- `dodi-dev/runtime/runtime-health.schema.json`;
- `dodi-dev/runtime/runtime-register-record.schema.json`;
- `dodi-dev/runtime/dispatch-manifest-record.schema.json`;
- `dodi-dev/runtime/adapter-contracts.md`;
- `dodi-dev/scripts/runtime-preflight.sh bootstrap`;
- the canonical selected profile, health, and stable-lock path derivation.

The default profile remains `${XDG_CONFIG_HOME:-$HOME/.config}/dodi-dev/runtime-profile.json`, with default health `runtime-health.json` and lock `runtime-state.lock`. An explicit absolute non-default `DODI_RUNTIME_PROFILE` owns its C1-defined colocated health and lock paths. There is no repository-local search, no fallback from an invalid explicit path, and no runtime read from a transaction snapshot.

Profile bytes are static authority; health is a generation-bound projection; the Linear issue is escalation authority. C4 may implement transaction records and fixtures as supporting evidence, but none becomes an alternate runtime source.

### C2 tier and hook contract

C4 consumes the landed C2 map and operations:

- `validate-map` and ordered candidates for setup probes;
- `resolve-tier`, `verify-main-loop`, and `verify-attestation` consumer expectations;
- exact `TIER_READY`, `MAIN_LOOP_VERIFIED`, `WORKER_TIER_VERIFIED`, `TIER_UNVERIFIED`, `SETUP_REQUIRED`, and `SETUP_CAPACITY_WAIT` meanings;
- the supported native model/reasoning request fields and attestation source;
- model-pin hook key/hash/matcher/live-fire outputs;
- the Standard pair and main-loop attestation requirement for scheduled tasks.

Setup probes candidates in installed-map order and stores only successful exact pairs. It never substitutes during setup. A recognized exhausted Frontier-capacity probe returns `SETUP_CAPACITY_WAIT`, leaves tasks disabled, and writes no enabled generation. C4 does not inspect free-form failures or reproduce the capacity allowlist.

`verify-profile` produces the ephemeral same-command proof C2 consumes. It accepts an operation nonce and repository, emits exactly one compact JSON result, and never creates a reusable receipt or accepts cached caller proof.

### C3 quiescence contract

Before profile/task replacement, rollback, marketplace replacement that changes the active plugin root, scheduled-task create/update/enable, or lights-out enablement, C4 invokes landed C3 `reap-recover` for the complete quiescence scope. The scope is the deterministic union of:

- every local Git worktree for each configured repository remote, discovered from the canonical repo root with `git worktree list --porcelain`, whether or not that worktree is named by current profile, health task fingerprints, prior setup transaction snapshot, or proposed task configuration;
- every manifest and `worker-quarantine.jsonl` discoverable under those repository worktrees' C3 `.dodi` directories;
- every managed driver/janitor task execution, live claim, or scheduler observation for the same repository/profile scope.

If any scope source is unreadable, ambiguous, duplicated, or conflicts with another source, setup blocks before mutation. The top-level setup session performs any returned native query/close actions and feeds observations back to C3 until each selected worktree/manifest returns `QUIESCENT` or a concrete unresolved/unsafe/escalation-required result with its evidence. C4 does not introduce a `QUARANTINED` C3 status.

`QUIESCENT` is required for lights-out enablement, scheduled-task enablement, and reusing or mutating an existing worktree. A C3-selected quarantine-only takeover mode may support task-disable, rollback, or evidence-preservation work only by leaving the affected worktree and ticket fenced and keeping scheduled delivery disabled. It never authorizes reuse, deletion, redispatch, task enablement, lights-out operation, or concurrent mutation. Any unresolved intent without C3's durable quarantine evidence blocks setup. C4 reports and escalates C3 blockers but never fabricates `closed`, `reaped`, no-write, or quarantine-release evidence.

### v0.16 workflow contract

- Only a top-level resident driver, guard/janitor, or interactive main loop dispatches workers; every worker is a leaf.
- Mutable lanes and implementers remain serial; the epic worktree has one writing session.
- Scheduled runs never merge, auto-merge, or enable auto-merge on an epic PR targeting `main` or `master`.
- Gate 2 remains manual even if client hooks are absent; server-side actor restrictions are authoritative.
- Silence, timeout, unknown state, unreadable evidence, and partial success are failures, not completion.
- No credential, prompt body, arbitrary environment value, native unredacted payload, or Slack token appears in stdout, stderr, profile, health, register payload, PM comment, transaction metadata, task prompt, or fixture.

## Design

### 1. Operator-facing setup state machine

Create `dodi-dev/skills/setup-dodi-dev/SKILL.md` as the operator conversation surface. It links to the installed runtime policy and invokes deterministic scripts; it does not restate their mechanics. It supports these modes:

```text
inspect                 # read-only discovery and proposed-change report
apply --repo OWNER/NAME # explicit confirmed setup/update
repair --repo OWNER/NAME
rollback --transaction ID
status --repo OWNER/NAME
```

The skill always starts with C1 `bootstrap` against one derived candidate plugin root. It then performs read-only discovery and returns a redacted proposed-change object covering:

- runtime/plugin/marketplace provenance and collisions;
- dependencies and C2 map/probe candidates;
- selected profile/health/lock paths and current generation condition;
- Linear key source availability and runtime-register classification;
- hook discovery/hash/trust and required live-fire matrix;
- operator and proposed automation GitHub identities;
- repositories, actual bases, rules/checks/bypass/admin posture;
- Slack plugin/channel availability;
- existing and intended scheduled-task identities/configuration;
- C3 quiescence/quarantine classification;
- mutations, rollback source, and blockers.

Discovery performs no marketplace, trust, PM, Git, Slack, task, profile, health, or runtime-id mutation. `apply` requires an explicit operator confirmation tied to the SHA-256 of that exact proposal. If discovery changes before mutation, setup invalidates the confirmation and presents a new proposal. Separate confirmation gates cover: runtime-id selection, marketplace migration, runtime-register creation, Slack test delivery, scheduled-task create/update, and final lights-out enablement. A blanket prior confirmation cannot authorize a changed action.

The setup session is the sole orchestrator of harness-native actions. Scripts return compact action JSON; the session invokes the named current-runtime tool and writes the redacted observation to a mode-`0600` transaction input for deterministic normalization. A script never claims it directly called Codex automation or Slack tools.

### 2. Auth resolution and secret boundary

Add `dodi-dev/scripts/runtime-auth.sh` as an execution wrapper, not a credential store. Its precedence is:

1. non-empty process `LINEAR_API_KEY`;
2. `LINEAR_API_KEY` from the explicitly configured absolute mode-`0600` environment file;
3. process `LINEAR_DODI_API_KEY`, bridged in the child environment as `LINEAR_API_KEY`;
4. `LINEAR_DODI_API_KEY` from that environment file, bridged in the child environment.

The environment-file parser reads only exact allowlisted assignments and does not evaluate shell, command substitutions, expansions, or arbitrary keys. Duplicate keys, both names with different values, wrong owner/mode, relative paths, malformed lines, or an empty selected value are blockers. When both names hold byte-identical values, canonical `LINEAR_API_KEY` wins and the legacy name is reported only as present, never by value.

Supported commands are `check` and `exec -- <plugin-owned-command>`. `check` emits only source class, readability/permission state, and a one-way runtime identity obtained from a successful Linear `viewer` query; it does not emit key length, prefix, suffix, hash, or raw response. `exec` sets canonical `LINEAR_API_KEY` only in the child process and removes `LINEAR_DODI_API_KEY` from that child environment before invoking `linear-api.sh` or another allowlisted plugin command.

Scheduled-task configuration references the operator-selected secure environment source and invokes the wrapper. The profile records only C1's `auth.linear_source` reference (`env:LINEAR_API_KEY` or a C1-valid `file:/...` source reference), runtime id, register id, and GitHub host. No setup transcript or task prompt contains credential values.

### 3. Direct Linear runtime register

Add `dodi-dev/scripts/runtime-register.sh` as the only register query/mutation implementation. It uses `runtime-auth.sh exec` and the existing direct GraphQL helper. It validates every remote record against C1's schema and canonical hash rules before returning a classification.

#### Discovery and genesis

The `linear_runtime_id` is selected before any register discovery. An existing valid profile supplies it. If no profile exists, read-only `inspect` may show an operator-provided candidate id or a generated candidate id in the proposed-change report, but it does not persist that id and does not search or create a register under it. The first `apply` mutation class is a separately confirmed runtime-id selection tied to the proposal hash; only then does setup flush a mode-`0600` `runtime-id-selection` record. After flushing the selection, setup re-runs discovery under the selected id and presents a fresh proposal for register creation or adoption. The selected id is included in subsequent proposal hashes, transaction idempotency data, and `RUNTIME_INIT` payload. Restart reuses the flushed selection; it never regenerates or searches under a different id after a crash.

The issue description contains the complete immutable `RUNTIME_INIT` sequence-0 record. The issue title includes a deterministic non-secret marker derived from the selected runtime id, but title search is only candidate discovery; setup paginates active and archived issues and parses each candidate description to match the exact `linear_runtime_id`.

Results are fail-closed:

| Discovery result | Outcome |
| --- | --- |
| exactly one valid matching genesis | `REGISTER_FOUND`; replay comments |
| zero matches and no unresolved create intent | `REGISTER_ABSENT`; creation may be proposed |
| more than one exact runtime id | `REGISTER_DUPLICATE`; tasks remain disabled |
| title collision with invalid/mismatched genesis | `REGISTER_COLLISION`; no adoption or overwrite |
| missing/malformed genesis, runtime mismatch, unreadable archived page | `REGISTER_INVALID`; no creation or replay |

After confirmation, issue creation sends the complete genesis in the single `issueCreate` mutation. Before sending, the setup transaction records a flushed `register-create-intent` containing runtime id, genesis hash, mutation nonce, and expected team, but no credential. On success it records the issue id and re-reads the issue. On timeout, transport loss, malformed response, or local persistence failure after send, it records `REGISTER_CREATE_UNCERTAIN`, performs bounded exact-id search/replay, and never issues a second create in that transaction.

Restart replays the durable intent. One exact issue with the intended genesis is adopted; multiple matches block as duplicate; zero visible matches after bounded read-after-write retries remain uncertain and require operator/Linear reconciliation. Setup never treats local-file deletion or a zero-result query after ambiguous creation as permission to create again.

#### Append and replay

Subsequent comments are only C1 `ESCALATION_OBLIGATION` and `ESCALATION_DELIVERED` records. Under the stable runtime-state lock, the adapter:

1. paginates and validates the complete chain from genesis;
2. requires contiguous monotonic sequence, exact prior hash, unique sequence, one linear successor per record, matching runtime id, and a readable tip;
3. treats an exact duplicate event/state/payload hash as idempotent replay;
4. rejects a reused event id with different state/payload, duplicate sequence, gap, hash mismatch, fork, unknown species, edited genesis, or record after a broken predecessor;
5. appends one complete comment derived from the current tip;
6. re-reads through the new tip and requires the intended record to appear exactly once before projecting it locally.

A lost comment-create response follows the same rule as issue creation: re-read and adopt one exact intended record; never append again while acceptance is unknown. Linear read failure blocks verification/replay. Linear write failure blocks Slack send. No local health state can override a remote duplicate, fork, gap, or unreadable tip.

### 4. Sole profile/health writer and transaction recovery

Add `dodi-dev/scripts/runtime-state.sh` as the only plugin-owned profile/health updater. Setup, rollback, `verify-profile` replay, Slack delivery, and janitor repair invoke this script; they do not replace health independently.

The selected stable C1 lock serializes every read-decide-write transition. Transaction directories are mode `0700`, live beside the lock, and are named by a cryptographically random setup run id. Each contains schema-valid redacted metadata, the exact prior profile/health bytes when present, normalized prior task configuration, staged next files, action observations, and content hashes. Secret values and Slack message bodies are excluded. Files are mode `0600`; file and directory `fsync` precede state advancement.

#### Apply ordering

1. Disable new starts for every managed scheduled-task identity whose fingerprint references the selected profile path, profile generation, repository, worktree, or automation actor across all configured scopes, and prove the disabled fingerprints per scope.
2. Wait for running driver/janitor executions in every affected scope to finish; timeout is a blocker, not cancellation proof.
3. Verify no live driver claim remains and run C3 recovery over the complete quiescence scope. Profile/task replacement and task enablement require `QUIESCENT`; rollback with active quarantine may continue only with tasks disabled and the affected worktree fenced.
4. Acquire the stable lock and re-check task disablement, no live C4 escalation-attempt lease sidecar, proposal hash, plugin root, and current profile/health bytes.
5. Snapshot and flush the complete prior pair and task configuration.
6. Replay and validate the authoritative Linear chain through its current tip.
7. Stage complete new profile and health files, projecting every unresolved obligation into the new generation.
8. Validate schemas, cross-bindings, exact permissions, profile byte hash, projection hash, register cursor, plugin/model/hook/repository/task fingerprints, and no-secret policy.
9. Flush both staged files and transaction state; atomically rename profile first and health second; `fsync` the directory after each rename.
10. Re-run `verify-profile`, then enable tasks only after task fingerprints and health routing are healthy.

A crash between profile and health renames leaves a detectable `setup_run_id`/profile-hash mismatch. Every ordinary consumer returns `SETUP_REQUIRED`; no consumer selects the old health, transaction snapshot, default profile, or an empty reconstruction. On the next explicit setup run, `recover` validates the transaction and remote register, keeps tasks disabled, and offers only deterministic forward completion from still-valid staged evidence or rollback. Ambiguous/malformed transaction evidence blocks both automatic choices and requires manual artifact preservation and repair.

#### Health replay and concurrent updates

For a same-generation strict-prefix health cursor, `runtime-state.sh replay-health` holds the stable lock across profile re-read, register-tip read, chain validation, projection merge, flush, atomic health rename, and final verification. Ahead, forked, gap-bearing, hash-invalid, wrong-generation, or wrong-register health is never replayable and returns `SETUP_REQUIRED`.

An escalation attempt obtains a short local attempt lease in a C4-owned mode-`0600` sidecar beside the selected health file while holding the stable lock, then releases the lock before the external Slack call. The lease identifies event id, profile setup id, profile hash, task/run id, attempt number, and expiry. It is concurrency evidence only: it is not part of the closed C1 health schema, not a register authority, and not a delivery record. Other updaters may repair unrelated events but cannot concurrently send the leased event. A crashed/expired lease makes the unresolved register obligation retryable; elapsed time never marks delivery. Health attempt counters and last-attempt/error fields are updated only by replaying validated register state plus completed attempt observations under the stable lock.

#### Rollback

Rollback first disables tasks and repeats quiescence. Under the stable lock it restores the exact prior static profile and prior task definition only if their plugin/runtime provenance is still usable. It never restores snapshot health as live state. Instead it replays the current Linear register into a newly generated health projection bound to the restored profile's existing `setup_run_id` and exact byte hash.

Any obligation added after the snapshot remains present. If prior plugin/model/hook/task evidence is no longer valid, register replay fails, task restoration is ambiguous, or post-rollback `verify-profile` fails, every profile-bound managed task remains disabled and setup returns `ROLLBACK_INCOMPLETE`. Rollback never deletes current transaction/register/quarantine evidence.

### 5. `runtime-preflight.sh verify-profile`

Extend the C1 script rather than adding a second verifier:

```text
runtime-preflight.sh verify-profile \
  --repo <owner/name> \
  --operation <operation> \
  --operation-nonce <nonce>
```

The C2-facing invocation shape is exactly the one DOD-812 consumes: `--repo`, `--operation`, and `--operation-nonce`; there is no optional boundary argument on this command. The operation allowlist is partitioned:

- C2 operations: `resolve-tier`, `verify-main-loop`, and `verify-attestation`;
- C4 boundary operations: `driver-entry`, `driver-loop`, `child-merge`, `daily-heartbeat`, `setup-apply`, and `repair`.

Success stdout is the strict C2-compatible proof object only: `PROFILE_VERIFIED`, schema version, requested operation, nonce, repo, canonical profile path/hash/setup id, health path/hash/profile/projection binding, register issue/cursor/tip binding, Codex runtime/version/catalog fingerprint, and stable-read/lock evidence. It does not add `checked_boundaries`, escalation routing, task details, or C4-only diagnostics to stdout, because C2 rejects unknown proof fields. C4-only boundary evidence is written to the setup transaction or task fingerprint evidence by the caller that requested the C4 operation.

The verifier resolves the canonical paths and performs a non-mutating preliminary read. If health is a same-generation strict prefix of the register, it invokes `runtime-state.sh replay-health` while holding no stable lock; `replay-health` owns the lock for its mutation and returns after the health projection is current. Then `verify-profile` acquires the stable lock once, validates permissions/schemas/cross-bindings, and reads one stable profile/health/register generation. It never recursively acquires the stable lock. If the final stable read discovers a new strict prefix after a race, it releases the lock and retries the replay/final-read sequence once; a second race or any invalid/ahead/forked health returns `SETUP_REQUIRED`.

The C4 operation selects the required live fingerprints:

- `driver-entry` and `driver-loop`: local plugin, runtime, model map/catalog, profile, health, register, and hook evidence;
- `child-merge`: all above plus fresh branch/rules/check/actor posture;
- `daily-heartbeat`: all above plus current task ids/config/no-overlap/wake fingerprints;
- `setup-apply` and `repair`: the same checks but with task-disabled and transaction context explicitly recorded outside the proof JSON.

Boundary fingerprint failure emits one redacted named reason and exit `3`/`SETUP_REQUIRED` with no partial stdout. C2 may consume the generation proof only for that invocation. C2 re-reading named bytes after process return detects a local race; no receipt file, HMAC key, environment bypass, assumed proof, or test verifier is accepted in production.

Binding failure emits one redacted named reason and exit `3`/`SETUP_REQUIRED` with no partial stdout. A cryptographically valid generation can still be routed as `stale` or `degraded` by the separate C4 health classifier below; that routing never appears in the C2 proof object.

### 6. GitHub automation identity and server-side Gate 2

Setup distinguishes the interactive operator credential from the scheduled automation credential. The profile stores actor identity and posture, never a token. The scheduled credential must resolve to one dedicated GitHub App installation or machine user and must not equal the operator's human actor.

For each enabled repository, setup uses `gh api` with the scheduled credential to collect and normalize:

- authenticated actor/app installation identity and repository selection;
- repository role and token/app permission metadata;
- actual default target base (`main` or `master` as repository truth dictates);
- all classic branch-protection and organization/repository rulesets that apply to that base;
- required pull-request and required-check rules;
- every bypass actor/team/app and direct-update allowance;
- any permission capable of creating, editing, disabling, or deleting branch protection/rulesets.

All pages must be readable and all applicable rule sources must normalize into one deterministic fingerprint. A `404`/`403`, partial pagination, unsupported ruleset type, repository-admin ambiguity, organization-owner ambiguity for a machine user, custom permission ambiguity, mutable broad token, shared human credential, bypass membership, ability to push/update the base, or ability to administer rules is a hard blocker.

Static inspection is necessary but insufficient. With operator confirmation in a disposable repository or temporary protected branch carrying equivalent rules, the scheduled credential must be denied for direct push/ref update, merge/auto-merge, raw REST/GraphQL merge, and protection/ruleset mutation. The test also proves allowed read-only inspection, child-PR creation, and child merge into an epic branch. Test cleanup uses the operator credential only after scheduled denial evidence is durable.

Scheduled capability configuration excludes native merge, auto-merge, ref-update, branch-rule mutation, and arbitrary authenticated raw-HTTP mutation tools. Child merges use the plugin-owned wrapper and refuse `main`/`master`. General shell receives only the restricted scheduled credential, so server-side rules remain authoritative even if a client hook is bypassed.

### 7. Hook trust and Gate 2 live-fire

Setup verifies both hook entries are discovered from the selected installed plugin root and that their exact command, key, script hash, matcher, and trust state match live runtime observations. It never grants trust automatically. An untrusted hook produces an operator action; setup resumes only after the operator explicitly trusts the exact hash and discovery is re-read.

C2 owns the model-pin normalizer and its native dispatch matrix. C4 consumes its hash/result and repeats setup live-fire; it does not change accepted tier pairs or attestation policy.

C4 expands `hook-gate2-guard.sh` and, only if live-fire requires it, the Gate 2 entry in `hooks/hooks.json`. The guard normalizes the current-runtime tool/event identity, cwd, command/tool input, repository, PR/ref, and target base. The narrowest proven matcher is used; if `Bash` misses a relevant Codex mutation family, use a broad PreToolUse matcher with positive no-op classification for unrelated tools and fail-closed classification for recognized or dispatch-like GitHub mutation payloads.

The deny matrix covers:

- `gh pr merge` into `main`/`master`;
- REST or GraphQL merge and enable-auto-merge calls;
- native GitHub merge, auto-merge, or ref-update tools;
- direct `git push` or force-push to the protected base;
- raw API ref updates or merge calls;
- opaque/indirect shell mutation against the equivalently protected test branch;
- branch-protection/ruleset creation, edit, disable, or deletion with the scheduled credential.

Allow cases cover read-only GitHub calls, child PR creation, child merge into an epic branch, and non-protected ordinary pushes. A merge-capable tool with unparseable payload/repository/base, malformed input under a mutation matcher, unknown native mutation family, hook timeout, matcher ambiguity, absent invocation, untrusted hash, or any failed matrix case blocks lights-out enablement. The hook remains defense-in-depth; a passing hook cannot compensate for failed server-side actor restrictions.

### 8. Harness-native scheduled tasks

Add `dodi-dev/scripts/codex-scheduler-adapter.sh` to normalize scheduler discovery, create/update/disable/enable, execution status, no-overlap, and wake-test observations. It returns action JSON for the top-level setup session and accepts only supported-runtime redacted observations; it does not implement a cron/daemon wrapper.

After explicit confirmation, setup creates or updates exactly one managed driver task and one managed janitor task for each configured scope. A scope is the tuple `(repo, epic worktree, profile path, scheduled automation identity)`, has a deterministic scope id in the proposal, and must appear in the current profile or the confirmed proposal before any task mutation. Same-name tasks outside the configured scope, duplicate ids inside the scope, or scheduler entries whose scope cannot be proven are blocking collisions, not extra managed tasks.

| Task | Contract |
| --- | --- |
| `dodi-drive-epic` | hourly, off-peak minute; liveness guard/resident driver; C2-verified Standard main loop; no overlap; scoped repo/worktree and restricted automation identity; no epic merge capability |
| `dodi-reconcile-tickets` | daily after deployment window; C2-verified Standard main loop; no overlap; same profile/env/identity restrictions; repair-only semantics |

The normalized task fingerprint includes task id/name, schedule/time zone, enabled state, runtime/plugin/profile generation, repo/worktree scope, exact skill instruction hash, model/reasoning, environment-source references, allowed capabilities, automation GitHub actor, no-overlap mode, and failure-notification behavior. Secret values are excluded. Same-name duplicate task ids, unmanaged task collisions, unknown fields, unsupported no-overlap semantics, a config hash mismatch, or an execution using a different profile/actor/model blocks enablement.

Live tests are mandatory:

1. **Boot:** each task starts with `verify-profile`, authenticates as the scheduled actors/sources, and obtains C2 `MAIN_LOOP_VERIFIED` for Standard before reads or writes.
2. **No overlap:** a disposable setup probe holds its first execution at a durable barrier while a second scheduler event is issued. The second execution must be suppressed/coalesced or start only after the first terminal event. Two concurrently running executions fail the gate.
3. **Successor wake:** a disposable two-run probe uses the same task runtime/config and a mode-`0600` durable seam. Run one records a synthetic `refresh-park` continuation and exits; the scheduler's supported successor-wake path starts a distinct run/context that reads only that seam and records completion. In-memory continuation or operator manual start is not evidence.
4. **Failure wake:** a synthetic failed run produces the harness-native task-failure notification without exposing secrets.
5. **Gate 2:** the scheduled credential/capability matrix fails every protected-base mutation and passes the allowed child/read cases.

The disposable probes perform no Linear ticket transition, production branch mutation, or worker dispatch. Their task ids, run ids, distinct context ids, config hashes, timestamps, and redacted outcomes are retained in the setup transaction; test tasks are removed after proof. Failure to remove a test task blocks final enablement.

Task updates always follow the state transaction's disable/quiesce/snapshot/apply/test/enable order. A scheduler timeout, unknown update acceptance, wake failure, no-overlap failure, duplicate task, or inability to restore the prior task definition leaves both production tasks disabled. Setup never guesses from task names or elapsed time.

### 9. Slack escalation adapter

Add `dodi-dev/scripts/slack-escalation-adapter.sh` as an action/observation adapter over the installed Slack plugin. The profile allows only adapter `slack`, one channel id, retry delays `[0, 30, 120]`, stale-after 24 hours, and re-escalate-after 24 hours as approved defaults. Setup verifies the Slack plugin is enabled in the same scheduled-task runtime and that the target resolves to the configured dedicated channel.

For each durable event id:

1. Under the stable lock, replay the register and append or adopt exactly one `ESCALATION_OBLIGATION` before any send.
2. Project the pending obligation, acquire the C4 escalation-attempt sidecar lease, and record the attempt number selected from the C1 health retry policy; release the lock.
3. Emit a `SEND_SLACK` action containing only the artifact's `## TL;DR`, `## Key Points`, safe links, event id, and configured channel.
4. The top-level/scheduled session invokes the installed Slack plugin and writes a redacted observation.
5. Reacquire the lock, verify the same sidecar lease or an expired/recovered lease for the same event/attempt, replay the register, and accept success only with a durable Slack message id, link/permalink, channel identity, and timestamp matching the action.
6. Append or adopt exactly one `ESCALATION_DELIVERED`, then project that matching obligation as delivered.

Timeout, transport error, malformed response, wrong channel, missing durable id/link, or unknown acceptance is not delivery. Retry attempts are due at 0, 30, and 120 seconds; a crash may duplicate a Slack message after unknown acceptance, but cannot lose the obligation or mark it delivered. A deterministic event id is rendered in each message so duplicates are recognizable.

After exhaustion, the obligation remains unresolved, derived health becomes degraded, and the adapter attempts a `notification-degraded` comment on the affected ticket naming the event id and evidence link without secret/error payloads. The scheduled task exits failed so the harness-native failure notification fires. Failure to write that ticket comment does not erase or resolve the register obligation; the next janitor run repairs from the register.

The janitor selects each unresolved obligation independently. A later success resolves only the matching event. Open human-wait items whose own last successful delivery is older than 24 hours receive a new obligation referencing the prior message id and current age. No aggregate Slack success clears another event, and no alternate delivery adapter is attempted.

Setup's low-risk Slack test uses this exact production path: confirmed test obligation, send, delivered record, and health projection. Deleting a test message is not required and cannot delete the register history.

#### Escalation health classification

`runtime-state.sh classify-health` derives routing from the validated register chain and C1 health projection; it never stores a mutable global degraded flag. Invalid profile/health/register bindings, malformed obligation values, impossible timestamps, negative attempts, a delivered state missing durable id/link/time, or an obligation whose event id does not match its register record return `SETUP_REQUIRED`, not `stale` or `degraded`.

An empty obligations map is `healthy` unless an independent open human-wait item has crossed `re_escalate_after_sec` and therefore needs a new obligation. For each obligation, retry delays are indexed by the number of completed attempts in health. With the approved delays `[0, 30, 120]`, attempt `0` is due immediately, attempt `1` is due 30 seconds after the recorded last attempt, and attempt `2` is due 120 seconds after the recorded last attempt. `last_attempt_at: null` is valid only with `attempts: 0`; otherwise classification returns `SETUP_REQUIRED`. Attempts greater than or equal to the delay count with no matching delivered record are exhausted. `stale_after_sec` is measured from the obligation record timestamp; an unresolved obligation at or beyond that age is `degraded` regardless of retry-window position.

| Per-event condition | Event route |
| --- | --- |
| Matching `ESCALATION_DELIVERED` after the obligation, with durable Slack id/link/time | `healthy` |
| No obligations and no due human-wait re-escalation | `healthy` |
| Unresolved obligation age is at least `stale_after_sec` | `degraded`; janitor repair is due even if a retry delay would otherwise wait |
| No completed attempt yet, or next retry delay has elapsed and attempts remain | `degraded` for task exit/repair eligibility; janitor may attempt delivery |
| Attempts remain but the next retry delay has not elapsed | `stale`; no new lane starts, janitor waits or performs unrelated read-only waiting-on-you sweep |
| Attempts are exhausted without delivery | `degraded`; janitor attempts register-backed repair and task exits failed after evidence |
| Expired sidecar lease with no delivered record | Same as the underlying obligation's due/exhausted route; it may retry and duplicate Slack but never marks delivered |
| Open human-wait item whose last successful delivery age is at least `re_escalate_after_sec` and no current re-escalation obligation exists | `stale`; janitor creates the next register obligation before sending |

Overall precedence is `SETUP_REQUIRED` over `degraded` over `stale` over `healthy`. `healthy` permits ordinary driver lane selection only if every other preflight boundary also passes. `stale` and `degraded` both block new driver lanes; setup and the janitor may run only escalation repair and the read-only waiting-on-you sweep until every event classifies `healthy`.

### 10. Marketplace collision detection and migration

Setup combines runtime marketplace listing with direct inspection of the supported Codex marketplace configuration. For marketplace name `dodi-skills`, it canonicalizes every source root and installed plugin provenance.

- One name and one canonical source/root is healthy.
- Same name with different canonical roots, symlink-resolved roots, or installed cache provenance is `MARKETPLACE_COLLISION`.
- A legacy `~/plugins/dodi-dev` source resolving the old layout is stale even if its metadata parses.
- Unreadable config, duplicate entries, relative roots that cannot be canonicalized, or CLI/config disagreement is ambiguous and blocking.

The proposal shows exact non-secret roots and versions. After separate confirmation, the operator chooses either removal/rename of the stale source or the canonical repository source. Setup snapshots marketplace configuration before mutation, performs the supported `codex plugin marketplace` action, re-lists marketplace/plugin/cache provenance, and continues only when exactly one canonical root remains. It never edits a same-name entry in place by guess, deletes an unknown root, upgrades the wrong package, or enables tasks against a stale cache.

A crash or failed migration leaves setup incomplete and tasks disabled. If supported rollback can restore the exact prior marketplace config, it does so from the snapshot and verifies provenance; otherwise it preserves both snapshots and reports manual repair. C4 may include concise migration actions in `setup-dodi-dev`; C5 owns the release install guide and broad install-path documentation.

## Fail-Closed Matrix

| Condition | Required behavior |
| --- | --- |
| profile missing/malformed/wrong mode or profile-health generation/hash mismatch | `SETUP_REQUIRED`; no fallback, workflow write, task enable, or empty health recreation |
| setup crash between profile and health rename | tasks stay disabled; recover validates transaction/register and only completes forward or rolls back deterministically |
| stale rollback snapshot | restore static profile/tasks only if still valid; rebuild health from current register, never snapshot obligations |
| duplicate register, fork, gap, duplicate sequence, runtime mismatch, missing genesis, unreadable tip | block setup/replay/send; preserve evidence; require register repair |
| issue/comment create response lost | record uncertain acceptance, bounded exact replay, never duplicate the mutation while uncertain |
| task refuses to quiesce or health lease remains live | timeout and block; do not kill-and-assume or replace state |
| unresolved C3 worker without durable quarantine/no-write proof | block setup/task enable/redispatch; never infer termination |
| active C3 quarantine | affected worktree/ticket remains fenced; no reuse, deletion, cleanup, or replacement writer |
| GitHub actor shared with human, bypass-capable, base-write-capable, or rules-admin-capable | hard blocker; tasks are not created/enabled |
| GitHub API/rules/admin evidence unreadable or semantically ambiguous | hard blocker; no optimistic interpretation of `404`, `403`, role, or custom permission |
| Gate 2 hook absent/untrusted/matcher misses/mutation payload ambiguous | hard blocker; fail recognized mutation closed and keep lights-out disabled |
| scheduler duplicate, unknown update acceptance, no-overlap or wake test failure | every affected profile-bound managed task remains disabled; restore only from verified snapshot |
| Slack send/read response ambiguous | obligation remains unresolved; retry may duplicate but never falsely deliver |
| Slack retries exhausted, due, or waiting inside retry window | route by the escalation health truth table; block new driver lane; janitor repair/read-only wait sweep only |
| Linear unavailable before Slack send | do not send; task fails with durable local transaction evidence only |
| stale marketplace same-name collision | no install/upgrade/profile enable until explicit migration produces one canonical source |

## File Surfaces

### New files

| File | C4 responsibility |
| --- | --- |
| `dodi-dev/skills/setup-dodi-dev/SKILL.md` | Operator-facing inspect/apply/repair/rollback/status flow and explicit confirmations. |
| `dodi-dev/scripts/runtime-auth.sh` | Secret-safe canonical Linear environment bridge and allowlisted command wrapper. |
| `dodi-dev/scripts/runtime-register.sh` | Direct GraphQL register search/create/append/replay and chain validation. |
| `dodi-dev/scripts/runtime-state.sh` | Sole profile/health transaction writer, health replay, recovery, and rollback engine. |
| `dodi-dev/scripts/codex-scheduler-adapter.sh` | Harness-native scheduler action/observation normalization and live-test evaluation. |
| `dodi-dev/scripts/slack-escalation-adapter.sh` | Register-backed Slack action/observation, retry, degradation, and repair. |
| `dodi-dev/scripts/tests/test-runtime-auth.sh` | Precedence, env-file, redaction, and execution-boundary tests. |
| `dodi-dev/scripts/tests/test-runtime-register.sh` | Register genesis/chain/idempotency/lost-response/fork/gap tests. |
| `dodi-dev/scripts/tests/test-runtime-state.sh` | Lock, generation, crash seam, replay, concurrency, recovery, and rollback tests. |
| `dodi-dev/scripts/tests/test-codex-scheduler-adapter.sh` | Task normalization, collision, no-overlap, wake, and unknown-acceptance tests. |
| `dodi-dev/scripts/tests/test-slack-escalation-adapter.sh` | Obligation ordering, retries, duplicate delivery, degradation, and repair tests. |
| `dodi-dev/scripts/tests/fixtures/runtime-setup/` | Redacted runtime-versioned Linear/GitHub/hook/scheduler/Slack/marketplace observations and malformed cases. |

### Modified files

| Surface | C4 edit |
| --- | --- |
| `dodi-dev/scripts/runtime-preflight.sh` | Add production `verify-profile` and boundary checks while preserving C1 bootstrap. |
| `dodi-dev/scripts/hook-gate2-guard.sh` | Normalize current-runtime mutation families and enforce the complete Gate 2 deny matrix. |
| `dodi-dev/hooks/hooks.json` | Change only Gate 2 matcher shape if its live-fire proves required; preserve command root and C2 model-pin entry. |
| `dodi-dev/runtime/adapter-contracts.md` | Mark C4 verifier/register/state/scheduler/escalation operations implemented and link mechanics. |
| `dodi-dev/skills/epic-orchestrator/runtime-policy.md` | Link setup/preflight and degraded-health routing without copying schemas or mechanics. |
| `dodi-dev/skills/drive-epic/SKILL.md` | Require boot/loop/boundary verification, task identity, and degraded-health lane fence. |
| `dodi-dev/skills/reconcile-tickets/SKILL.md` | Route escalation through the adapter and constrain degraded mode to repair/read-only wait sweep. |
| `dodi-dev/skills/epic-orchestrator/execution-model.md` | Link C4 generation/quiescence boundaries while preserving lane and Gate 2 semantics. |
| `scripts/validate-runtime-contracts.sh` | Validate C4 paths, schema ownership, operation ordering, redaction, fixtures, and C5 fences. |
| `scripts/validate-phase-skills.sh` | Require setup skill/frontmatter, executable helpers/tests, and installed references. |

### Explicitly unchanged

- C1 runtime schema files and C1-owned path/hash/state definitions.
- C2 model map/schema, tier adapter, capacity classifier, accepted pairs, model-pin policy, and attestation semantics.
- C3 worker adapter, request/result/observation/tier artifacts, manifest/quarantine ledgers, takeover behavior, and `await-worker.sh` Claude mechanics.
- Lane playbooks, review prompts, labels, retry ceilings, Fable buckets, catch attribution, and Gate 1/Gate 2 workflow states.
- `.claude-plugin/plugin.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `.agents/plugins/marketplace.json`; C5 performs the synchronized release bump.
- C5 validator names, install/release guides, and release evidence directories.

## Implementation Sequence

1. Reconcile landed C1/C2/C3 implementations and freeze exact schemas, commands, output statuses, hook observations, and C3 takeover/quiescence mode. Stop on any contract mismatch.
2. Add redacted fixture families and deterministic tests first, including every fail-closed matrix row and unknown schema/runtime/action cases.
3. Implement `runtime-auth.sh` and register read-only discovery/replay; prove no secret reaches any output or artifact.
4. Implement register creation/append idempotency and lost-response recovery against a disposable Linear register fixture/live test issue.
5. Implement the stable-lock state engine, transaction snapshots, atomic pair commit, strict-prefix replay, crash recovery, and current-register rollback.
6. Extend `runtime-preflight.sh verify-profile` and satisfy C2's same-invocation operation/nonce/repo/profile/health/register/runtime/catalog proof tests.
7. Implement GitHub identity/rules normalization and the server-side deny/allow live matrix with disposable protected-branch evidence.
8. Expand and live-fire Gate 2 hook handling; consume and re-run C2 model-pin trust/live-fire without changing C2 policy.
9. Implement scheduler action/observation normalization, exact task fingerprints, quiescent create/update/restore, and boot/no-overlap/successor-wake/failure tests.
10. Implement Slack action/observation delivery, attempt leases, retries, degradation, re-escalation, and janitor repair using the real register order.
11. Implement marketplace collision discovery and separately confirmed migration/rollback.
12. Add `setup-dodi-dev` as the thin orchestration surface and update installed consumers/contracts to call the deterministic helpers.
13. Run deterministic suites, repository validators, disposable live integration matrices, ownership/redaction audits, and metadata/C5 absence checks. Do not enable production tasks as an implementation test unless the operator explicitly confirms the final setup proposal.

## Validation Strategy

### Deterministic tests

Fixtures cover valid and malformed C1 generations; crash before/after every snapshot, remote mutation, flush, and rename; concurrent updater/setup/rollback processes; strict-prefix and invalid register chains; issue/comment lost-create responses; C3 `QUIESCENT`, quarantine-backed blocker, and unresolved/unsafe outputs; GitHub classic/ruleset/bypass/admin permutations; hook payload families; scheduler duplicate/no-overlap/wake outcomes; Slack success/unknown/duplicate/retry/degraded/repair plus C4 attempt-lease sidecars; marketplace symlink and same-name collisions; and comprehensive secret canaries.

Tests use isolated temporary homes/config roots/repos and stub only external action observations. They do not require production credentials, mutate production profiles, or treat fixture verification as live proof. Every script emits one compact result or no stdout on safe-output failure.

### Live integration gates

- Linear: read-only viewer/team query, confirmed disposable register creation, lost-response replay simulation where safely injectable, append/replay, and archived search.
- GitHub: dedicated scheduled actor identity plus protected temporary-branch deny matrix and allowed child/read cases.
- Hooks: discovered/trusted exact hashes and every deny/allow payload through the supported Codex runtime.
- Scheduler: production-shaped disposable task boot, no-overlap, successor wake, failed-run notification, cleanup, and exact task observation schema.
- Slack: confirmed low-risk test obligation through durable message evidence and register/health completion.
- State: one disposable crash between profile/health rename followed by deterministic recovery, and one rollback preserving a post-snapshot register obligation.

C5 later repeats the required release matrix in an isolated install. C4 retains only implementation evidence needed to prove its contracts; it does not assemble or sign the final release bundle.

### Repository checks

Run the repository's existing metadata/phase/comment validators plus landed C1-C3 runtime validators and all new C4 tests. Verify executable bits, shell compatibility, JSON/JSONL parsing, permissions, `git diff --check`, exact file ownership, no secret canaries, no C1-C3 contract redefinition, unchanged metadata at `0.16.0`, and absence of C5 files.

## Acceptance Criteria

1. `setup-dodi-dev inspect` is fully read-only and reports one redacted proposal; every mutation class requires explicit confirmation bound to the unchanged proposal hash.
2. Auth resolution follows the exact precedence, bridges `LINEAR_DODI_API_KEY` only in-process, rejects unsafe environment files, and leaks no secret-derived material.
3. Register discovery uses one separately confirmed crash-durable selected `linear_runtime_id`, searches active and archived issues only after that selection exists, and accepts exactly one valid runtime id. Duplicate/collision/missing-genesis/fork/gap/hash/sequence/runtime/tip failures block all dependent work.
4. Issue and comment lost-response paths adopt one exact replayed mutation or remain uncertain; they never duplicate a create/append while acceptance is unknown.
5. One stable-lock state engine is the only profile/health writer. All files have required permissions, flush/rename ordering, schema validity, exact hashes, and current register binding.
6. Every setup crash seam is replay-safe. A crash between pair renames returns `SETUP_REQUIRED`, tasks remain disabled, and recovery cannot mix generations or trust snapshot health.
7. Rollback preserves every current register obligation, restores only verified static/task state, and leaves tasks disabled on incomplete proof.
8. `verify-profile` satisfies C2's same-invocation operation/nonce/repo/profile/health/register/runtime/catalog/stable-read contract, emits no C4-only proof fields, and provides no receipt or bypass.
9. Static mismatch always fences workflow writes. Valid stale/degraded health follows the deterministic truth table, including `stale_after_sec`, retry timing, null attempts, empty obligations, and re-escalation age; it blocks new driver lanes and allows only setup repair and janitor escalation repair/read-only wait sweep.
10. Setup consumes C3 recovery outputs over the complete quiescence scope, including all local Git worktrees for each configured repository remote and all profile-bound scheduled-task scopes. Unresolved workers or inadequate quarantine proof block setup; active quarantine never permits worktree reuse, task enablement, lights-out operation, or a successor writer.
11. Every enabled repository has a dedicated scheduled GitHub actor, complete readable rules evidence, required PR/check protection, no base update/bypass/admin path, and passing server-side deny/allow live tests.
12. Both exact hook hashes are discovered and explicitly trusted. Model-pin live-fire consumes C2 policy, and Gate 2 live-fire blocks every protected-base/rules mutation while allowing child/read operations.
13. Exactly one managed driver task and one managed janitor task exist per configured scope. Their exact Standard pair, profile/env/actor/capabilities/config are verified; no-overlap, boot, successor wake, failure notification, and probe cleanup pass.
14. No scheduled capability or credential can merge/auto-merge/update a protected base or administer its rules; scheduled epic Gate 2 remains impossible even if the client hook is bypassed.
15. Slack is the sole adapter; every send has a prior register obligation and a non-authoritative C4 attempt-lease sidecar, every completed delivery has a later durable delivered record, and retries/degradation/re-escalation/repair are event-specific and replay-safe.
16. Same-name marketplace collisions block install/update/enablement until a separately confirmed migration yields one canonical source and verified installed provenance.
17. Top-level-only dispatch, leaf workers, one mutable lane, one driver writer, v0.16 review/Fable/claim/Gate semantics, and Claude behavior remain unchanged.
18. All C4 deterministic and live gates pass, repository validators pass, C1-C3 ownership fences pass, no secrets are found, metadata remains `0.16.0`, and no C5 release surface is added.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Pair rename is not multi-file atomic | Generation/hash binding makes the intermediate state invalid; tasks are disabled and explicit transaction recovery completes or rolls back. |
| Linear create succeeds but response is lost | Flushed intent plus exact-id/hash replay; no second mutation while acceptance is unknown. |
| Local health races Slack or setup | One stable lock and sole updater; short attempt leases prevent concurrent sends without holding the lock over network calls. |
| Register is externally edited or concurrently forked | Full replay and post-append re-read; any fork/gap/hash mismatch blocks projection and delivery. |
| Scheduler reports config success before applying it | Re-list and fingerprint actual task state, then live boot/no-overlap/wake tests; unknown acceptance leaves tasks disabled. |
| GitHub role appears restricted but retains indirect authority | Normalize all applicable rules/permissions and require real denied mutations with the scheduled credential. Ambiguity blocks. |
| Hook payload changes across Codex versions | Runtime-versioned fixtures and live-fire; unknown mutation payloads fail closed and invalidate the profile hash/fingerprint. |
| Slack succeeds but acknowledgment is lost | Register obligation remains unresolved and retry may duplicate, but no false delivered state or lost escalation occurs. |
| Quarantine creates silent operational debt | C3 durable blocker is converted into a registered C4 escalation; affected work remains fenced until authoritative release proof. |
| Marketplace migration targets the wrong source | Canonical root/provenance comparison, separate confirmation, snapshot, re-list, and no silent in-place rewrite. |
| Setup documentation drifts from scripts | Skill references script operations and named postconditions; validators reject duplicated mechanics and missing operation links. |

## Migration and Rollback

### Migration

1. Start with tasks absent or disabled and run read-only inspect against the selected supported Codex runtime.
2. Resolve marketplace collision explicitly and verify one installed canonical plugin root.
3. Verify auth sources, C2 model probes, C3 quiescence, hooks, GitHub actor/protection, and Slack availability.
4. Find and replay an existing register, or separately confirm creation of one complete genesis issue.
5. Snapshot any prior valid generation/tasks, write the first or next bound profile/health generation, and prove `verify-profile`.
6. Create/update disposable task probes, pass no-overlap/wake/failure/Gate 2 tests, then remove probes.
7. Send the registered Slack setup test and prove register/health delivery.
8. Create/update production tasks disabled, verify exact fingerprints, then explicitly confirm lights-out enablement.

Existing Claude manual workflows continue throughout. Codex adapted mechanics remain `SETUP_REQUIRED` until the complete generation passes; partial migration does not degrade into profile-free operation.

### Rollback

Disable every affected profile-bound managed task first, wait for terminal status in each scope, and consume C3 quiescence/quarantine evidence. Restore marketplace provenance only through its separately verified snapshot if needed. Under the stable lock, restore a still-compatible prior static profile/task definition and rebuild health from the current register tip. Verify hooks, GitHub actor/protection, task disabled state, and the rolled-back generation before optionally re-enabling.

If any prior component is no longer compatible or any worker/register/task state is uncertain, retain the current and snapshot evidence, keep every affected profile-bound managed task disabled, return `ROLLBACK_INCOMPLETE`, and continue Claude/manual operation only where its v0.16 prerequisites are independently satisfied.

## Blocking Questions

None for specification. Native Codex scheduler, hook, Slack, GitHub permission, and C3 takeover payloads must be captured from the landed supported runtime during implementation; an unrecognized or ambiguous result blocks C4 rather than relaxing this design.
