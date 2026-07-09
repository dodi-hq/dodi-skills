# DOD-811 - Runtime Canon, Profile Contract, Root Bootstrap, and Adapter Interfaces

**Date:** 2026-07-09
**Parent epic:** DOD-810
**Type:** Runtime foundation / compatibility contract
**Target repo:** dodi-hq/dodi-skills
**Target release:** dodi-dev 0.17.0

## TL;DR

DOD-811 establishes the runtime-neutral foundation for the DOD-810 Codex compatibility release: ship the operative workflow canon inside the installed plugin, resolve and verify one concrete plugin root before any ordinary script call, and publish versioned contracts for runtime profile, health, Linear register, tier attestation, and worker manifests. It preserves Claude Code behavior while deliberately leaving Codex model selection, native worker lifecycle execution, setup/auth/scheduling/escalation, and end-to-end release validation to C2-C5.

Codex workflow execution is still blocked after C1 alone. C1 makes every dependent consume one shared, fail-closed interface instead of allowing each child to invent paths, profile semantics, or manifest states independently.

## Key Points

- **One installed canon:** `dodi-dev/skills/epic-orchestrator/runtime-policy.md` becomes the only operative runtime-policy source. Repository-root `AGENTS.md` keeps maintainer/editing guidance and points to the shipped canon instead of duplicating it.
- **Verified root, concrete calls:** an invoked skill derives a candidate root only from its absolute `SKILL.md` locator or a verified `${CLAUDE_PLUGIN_ROOT}`, validates it with `runtime-preflight.sh bootstrap`, records the canonical absolute result as `<plugin-root>`, and substitutes that concrete path into every ordinary script call. On Codex, bootstrap is not permission to run workflow scripts; non-bootstrap adapted mechanics remain fenced until C4's profile verifier exists.
- **Hooks are a separate boundary:** C1 does not rewrite hook matchers, payload handling, or hook commands. `${CLAUDE_PLUGIN_ROOT}` remains allowed only in `dodi-dev/hooks/hooks.json`; C2/C4 own Codex hook live-fire behavior.
- **Generation-bound state contract:** the static runtime profile, renewable health projection, stable lock, and Linear register cursor have one path rule, one schema version, and explicit cross-file/hash bindings. C1 defines and tests the contract but does not create a real operator profile or register.
- **One worker-manifest vocabulary:** all runtimes share append-only intent, binding, terminal-evidence, close, reap, conflict, and uncertainty records. Runtime-specific data is namespaced; `output_file` remains Claude adapter data rather than a universal field.
- **Fail closed at every unknown:** invalid root provenance, unknown schema versions, malformed binding data, absent required tier attestation, unresolved dispatch intent, or unknown manifest state cannot be interpreted as success or permission to advance state.
- **C1 does not activate Codex:** C2 supplies model/tier resolution and attestation checks, C3 supplies Codex spawn/wait/close/recovery mechanics, C4 supplies profile/register/setup/auth/scheduling/escalation mutations, and C5 supplies isolated-install and live release evidence.
- **Release metadata remains a release-sweep concern:** C1 notes that released skill changes require a synchronized `0.17.0` metadata bump, but the approved decomposition assigns that bump and release sweep to C5 unless DOD-810 records a parent decision-register amendment.

---

*Everything below is written for agents planning and implementing this child.*

## Decision Context

The approved parent design is `docs/specs/2026-07-09-codex-runtime-compatibility-design.md`. At drafting time DOD-810 has no Decision Register Canon beyond the Gate 1 `Kind: MODE` entry selecting `waterfall`; no later entry supersedes the approved design. Therefore the approved parent design controls this child, and DOD-811 must not reinterpret the model candidates, worker takeover policy, setup topology, or release gates delegated to later children.

The parent dependency graph is:

```text
C1 -> C2 --+
 |         +-> C4 -> C5
 +-> C3 --+
```

C1 is intentionally contract-heavy because every later child depends on its definitions.

## Problem

The installed `dodi-dev/` directory is not currently self-sufficient:

1. Runtime policy used by installed skills lives in repository-root `AGENTS.md`, which is not part of the installed skill contract.
2. Seven released skills emit ordinary commands through `${CLAUDE_PLUGIN_ROOT}`. Codex ordinary shell calls do not receive that ambient variable.
3. `execution-model.md`, `await-worker.sh`, and `reap-workers.sh` assume Claude transcript paths and Claude terminal markers as if those were universal worker semantics.
4. There is no versioned, machine-checkable contract binding static runtime configuration, renewable health, the authoritative Linear register cursor, model attestation, and dispatch evidence.
5. Without a shared interface, C2, C3, and C4 could each choose incompatible field names, hashes, failure states, and path rules.

## Goals

1. Package every operative runtime rule consumed by installed skills inside `dodi-dev/`.
2. Make script-root derivation deterministic, provenance-checked, runtime-neutral, and independent of the target repository cwd.
3. Define one versioned static runtime-profile contract and one generation-bound health-projection contract.
4. Define the Linear runtime register only as an authority/cursor/hash-chain interface for C4.
5. Define a runtime-neutral worker-adapter API and append-only manifest record grammar for C2/C3/C4.
6. Preserve current Claude Code behavior and current v0.16 workflow semantics.
7. Add focused deterministic validation for canon packaging, root bootstrap, schemas, reference boundaries, and contract fixtures.

## Non-Goals

- No Codex model ids, candidate ordering, reasoning defaults, capacity classifier, main-loop tier verification, worker pin implementation, or model-pin hook changes. Those are C2.
- No Codex `spawn_agent`, wait, close, status normalization, result-artifact writer, quarantine, takeover, cross-session addressability, or mixed-runtime reaper implementation. Those are C3.
- No `setup-dodi-dev` skill, real profile writer, task quiescence, rollback engine, Linear issue discovery/creation, environment-key bridge, GitHub automation identity verification, scheduler mutation, Gate 2 live-fire behavior, Slack delivery, or health updater. Those are C4.
- No isolated Codex installation smoke, live compatibility matrix, user install guide, final compatibility validator, or release decision. Those are C5.
- No change to v0.16 lane ordering, Gate 1, Gate 2, claim rules, coherence semantics, Fable policy, review topology, refresh seams, or one-lane-in-flight policy.
- No copied Codex skill tree and no runtime-specific fork of any `SKILL.md`.

## Design

### 1. Ship the operative runtime canon

Create `dodi-dev/skills/epic-orchestrator/runtime-policy.md`. It is installed with the canonical skill tree and owns these runtime rules:

- semantic model tiers and the rule that runtime aliases are adapter data;
- Fable availability policies, gate assignments, bounded detection, substitution attribution, make-up obligations, and capacity parking;
- top-level-only dispatch and leaf-worker discipline;
- worker return contract and scannable artifact rules;
- deterministic-script doctrine and plugin-root bootstrap;
- decision-register canon rules;
- lights-out invariants and escalation obligations;
- scheduled-operation invariants, including Gate 2 and single-writer behavior;
- context-hygiene, resumability, continuation-brief, and refresh rules;
- runtime-profile and worker-adapter selection boundaries.

`epic-orchestrator/execution-model.md` remains the lane-execution canon, but becomes runtime-neutral. It owns lane seams, continuation behavior, manifest location, and serial/parallel invariants, while linking to:

- `runtime-policy.md` for cross-cutting policy;
- `runtime/worker-adapter-contract.md` for shared lifecycle requirements;
- exactly one runtime adapter selected from runtime context.

Create these adapter documents:

- `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md`: shared operations, records, ordering, and fail-closed postconditions.
- `dodi-dev/skills/epic-orchestrator/runtime/claude-worker-adapter.md`: current native completion plus transcript-backed await/stop/reap mechanics, with `output_file` explicitly scoped to Claude.
- `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`: the required Codex interface and C3-owned implementation boundary. C1 may state required inputs/outputs and terminal classifications, but must not claim native lifecycle support is implemented.

Repository-root `AGENTS.md` retains project shape, editing rules, model-tier authoring vocabulary, validation commands, and a prominent pointer to the installed canon. Operative tables and prose move rather than copy. A future runtime-policy edit must update the shipped file, not add a second authoritative version to `AGENTS.md`.

#### Reference classification

The validation sweep distinguishes two meanings of `AGENTS.md`:

| Reference kind | C1 treatment |
| --- | --- |
| Dodi runtime policy, tier table, Fable policy, context hygiene, scheduled operation | replace with a relative reference to shipped `runtime-policy.md` |
| Target repository coding conventions supplied to a worker as `CLAUDE.md / AGENTS.md` | retain; this means the user's target repository, not dodi-skills runtime policy |
| `docs/specs/...`, `docs/plans/...`, or `templates/...` consumed by an installed skill | reject as repository-only |

The operative-reference sweep includes `execution-model.md`, both lane playbooks, `state-transitions.md`, `drive-epic`, `review`, and `submit-epic-pr`. Prompt references in `spec-drafter-prompt.md`, `plan-writer-prompt.md`, `local-ci-runner-prompt.md`, and the review checklist remain where they explicitly mean target-repository instructions.

### 2. Bootstrap and verify one concrete plugin root

Every entry-point skill that can call a plugin script resolves `<plugin-root>` once before its first script invocation. The algorithm is exact:

1. Require the harness-provided absolute locator of the invoked `SKILL.md`.
2. If `${CLAUDE_PLUGIN_ROOT}` is present, treat its expanded value as the candidate. An invalid present value is a blocker; do not silently fall back to another root.
3. Otherwise require the locator shape `<candidate>/skills/<skill-name>/SKILL.md` and strip that suffix. Do not search cwd, parents, `$PATH`, home directories, marketplace caches, or multiple candidates.
4. Canonicalize the candidate and locator to physical absolute paths.
5. Invoke the candidate's verifier as a concrete path:

   ```bash
   "/absolute/candidate/dodi-dev/scripts/runtime-preflight.sh" bootstrap \
     "/absolute/candidate/dodi-dev" \
     --skill-locator "/absolute/candidate/dodi-dev/skills/<skill>/SKILL.md"
   ```

6. Accept only a successful report proving the locator is inside that root, both plugin envelopes identify `dodi-dev` at the same version, `skills/` and `scripts/` exist, and the invoked skill exists beneath `skills/`.
7. Record the report's canonical `plugin_root` as `<plugin-root>` for the invocation. Every later ordinary call substitutes that literal absolute path, for example `"<plugin-root>/scripts/claim.sh"`; no unresolved environment expression reaches an ordinary shell call.

The script validates; it does not discover. This avoids the bootstrap cycle in which a helper would need the plugin root in order to find itself.

Root readiness is not workflow readiness on Codex. C1's bootstrap verifier may run without a profile because setup needs it to locate the installed plugin, but every Codex adapted mechanic beyond bootstrap still fails closed after root verification with `SETUP_REQUIRED` or `UNSUPPORTED_RUNTIME` until C4 ships `runtime-preflight.sh verify-profile` and writes a valid profile/health/register binding. In C1, the concrete `<plugin-root>` substitution therefore preserves Claude behavior and creates the future Codex call shape; it must not let Codex invoke mutating ticket, GitHub, scheduler, Linear, worker, or claim scripts from a merely `ROOT_READY` report.

#### `runtime-preflight.sh bootstrap` contract

Bootstrap mode is read-only and profile-independent. It accepts no ticket, repository mutation, PM operation, GitHub operation, or secret. Its stdout is one JSON document with at least:

```json
{
  "schema_version": 1,
  "status": "ROOT_READY",
  "plugin_root": "/canonical/absolute/path/dodi-dev",
  "skill_locator": "/canonical/absolute/path/dodi-dev/skills/drive-epic/SKILL.md",
  "skill_name": "drive-epic",
  "plugin_id": "dodi-dev",
  "plugin_version": "<installed metadata version>",
  "profile_path": "/resolved/non-secret/path/runtime-profile.json"
}
```

Exit classes are stable:

| Exit | Meaning |
| --- | --- |
| `0` | root and skill provenance verified |
| `2` | invalid invocation or missing dependency |
| `3` | candidate, locator, metadata, or containment verification failed |
| `4` | output could not be produced without violating the read-only/redaction contract |

Diagnostics go to stderr, contain paths and failed check names, and never contain environment values other than non-secret resolved paths. Bootstrap mode does not require or inspect a runtime profile.

`plugin_id` in this report is the plugin envelope name (`dodi-dev`). The runtime profile's `plugin.id` remains the marketplace-qualified installation id (`dodi-dev@dodi-skills` in the parent design). C4 binds them by requiring the profile's qualified id to start with the bootstrap envelope name plus `@`, and by requiring the profile's `plugin.root` and `plugin.version` to equal the bootstrap report.

The ordinary-call sweep covers script references in:

- `assess-epic/SKILL.md`
- `deliver-ticket/SKILL.md`
- `drive-epic/SKILL.md`
- `epic-orchestrator/SKILL.md`
- `mature-ticket/SKILL.md`
- `reconcile-tickets/SKILL.md`
- `submit-ticket-pr/SKILL.md`

`dodi-dev/hooks/hooks.json` is the only approved `${CLAUDE_PLUGIN_ROOT}` exception. C1 verifies that exception is confined to hook metadata and makes no claim about Codex matcher/payload behavior.

### 3. Canonical static runtime profile

Add `dodi-dev/runtime/runtime-profile.schema.json`, using JSON Schema draft 2020-12 and `schema_version: 1`. The canonical path is:

```text
${DODI_RUNTIME_PROFILE:-${XDG_CONFIG_HOME:-$HOME/.config}/dodi-dev/runtime-profile.json}
```

There is no repository-local profile and no candidate search. An explicit invalid `DODI_RUNTIME_PROFILE` never falls back to the default. The containing directory is mode `0700`; the profile is mode `0600`; secret values are forbidden.

`DODI_RUNTIME_PROFILE` and `XDG_CONFIG_HOME`, when set, must be absolute. A relative override is invalid rather than cwd-relative, because the same invocation must resolve the same state from an unrelated target repository.

The profile is required for Codex adapted mechanics and scheduled operation. Claude Code retains its v0.16 manual entry behavior and does not acquire a new profile prerequisite in C1.

The schema carries the parent design's complete static contract:

| Object | Required contract | Primary consumer |
| --- | --- | --- |
| `generated_by` | `plugin_version`, unique `setup_run_id` | C4 generation writer and rollback |
| `runtime` | runtime kind/version and model-catalog fingerprint | C2/C4 drift checks |
| `plugin` | plugin id/version/root plus marketplace name/root | C1 root proof, C4 provenance |
| `models` | Frontier/Capable/Standard/Fast resolved model and reasoning pairs | C2 |
| `hooks` | Gate 2 and model-pin key/hash/trust evidence | C2/C4 |
| `auth` | secret-source reference, `linear_runtime_id`, register issue id, GitHub host | C4 |
| `escalation` | adapter id, channel id, retry policy, health policy | C4 |
| `repositories` | repo path/base plus branch rules, actor posture, task ids/config/wake evidence | C4 |
| `validated_at` | setup verification timestamp | C4 |

Unknown top-level fields are rejected for schema v1 so misspellings cannot become silently ignored configuration. Additive evolution requires schema v2 or an explicitly versioned extension field.

The schema defines shape only. Cross-field validity is part of the contract:

- `generated_by.plugin_version == plugin.version ==` installed metadata version;
- `plugin.root` equals the current verified `<plugin-root>`;
- all four semantic model tiers are populated before a Codex tiered dispatch;
- `auth.linear_source` is a source reference such as `env:LINEAR_API_KEY`, never a key;
- every enabled repository has one actual base branch and complete protection/task evidence;
- unknown runtime kind or schema version returns `SETUP_REQUIRED`.

C1 ships valid and invalid fixtures for this contract. C4 implements the real writer and live verifier; no production profile is created by C1.

### 4. Generation-bound health projection

Add `dodi-dev/runtime/runtime-health.schema.json`. Health and lock paths are deterministic functions of the **canonical selected profile path**, not of whether that path was reached by default or by an environment alias.

First resolve and canonicalize the default profile path:

```text
<default-profile> = ${XDG_CONFIG_HOME:-$HOME/.config}/dodi-dev/runtime-profile.json
```

Then resolve the selected profile:

- no `DODI_RUNTIME_PROFILE` -> `<default-profile>`;
- explicit `DODI_RUNTIME_PROFILE` -> its canonical absolute path.

If the selected path equals `<default-profile>`, use the default pair:

```text
health: ${XDG_CONFIG_HOME:-$HOME/.config}/dodi-dev/runtime-health.json
lock:   ${XDG_CONFIG_HOME:-$HOME/.config}/dodi-dev/runtime-state.lock
```

Otherwise the explicit non-default profile owns a colocated pair:

```text
health: <selected-profile-with-.json-replaced-by-.health.json, or .health.json appended>
lock:   <selected-profile>.lock
```

An explicit override that canonicalizes to the default path is normalized to the default pair; it cannot select a second health file or lock for the same profile. A relative `DODI_RUNTIME_PROFILE` or `XDG_CONFIG_HOME` remains invalid.

Health contains:

```json
{
  "schema_version": 1,
  "setup_run_id": "...",
  "profile_sha256": "sha256-of-exact-profile-bytes",
  "runtime_id": "...",
  "register_cursor": {
    "issue_id": "...",
    "comment_id": "...",
    "sequence": 7,
    "record_sha256": "..."
  },
  "projection": {
    "adapter": "slack",
    "channel_id": "...",
    "last_attempt_at": "...",
    "last_success_at": "...",
    "consecutive_failures": 0,
    "obligations": {}
  },
  "projection_sha256": "..."
}
```

`profile_sha256` hashes the exact static profile bytes. To avoid a self-hash cycle, `projection_sha256` hashes the RFC 8785 canonical JSON bytes of the `projection` object only. The following binding must hold before health is consumed:

1. `health.setup_run_id == profile.generated_by.setup_run_id`;
2. `health.profile_sha256` matches the exact profile file;
3. `health.runtime_id == profile.auth.linear_runtime_id`;
4. `health.register_cursor.issue_id == profile.auth.linear_register_issue_id`;
5. `health.projection_sha256` matches the canonical projection;
6. the cursor is equal to, or a strict valid prefix of, the authoritative register chain.

Missing, malformed, generation-mismatched, hash-invalid, forked, or ahead-of-register health returns `SETUP_REQUIRED`. A valid strict prefix is eligible for C4 replay under the stable lock; C1 does not implement replay. An empty or recreated local file is never interpreted as healthy.

Each obligation is keyed by durable event id and records ticket/event identity, `pending | retrying | delivered`, attempt count, last error/attempt, and durable delivery id/link/time. Global `notification-degraded` is derived from obligations and retry windows, not stored as a separately mutable flag.

#### Persistence interface for C4

C1 defines these pair-update postconditions without implementing setup:

- Setup, rollback, the health updater, and escalation delivery use the same stable lock; no component invents a second lock.
- A writer stages complete files beside the live pair, validates all schema and cross-bindings, flushes file and directory data, then atomically renames profile followed by health. A crash between renames leaves a detectable generation/hash mismatch and cannot unlock work.
- Setup snapshots the prior profile, health, and task configuration before replacing either live file. The snapshot is not a competing read source for runtime consumers.
- A same-generation health update may replace health only after re-reading the current profile bytes and authoritative register tip under the lock. It never mutates the static profile.
- Rollback may restore prior static profile/task configuration, but it must replay the current register tip into a newly bound health projection; it may not restore a stale obligation set from the snapshot.
- Consumers either validate one stable read under the lock or prove an optimistic read stayed stable by re-reading the generation/hash fields. A mixed-generation pair is always `SETUP_REQUIRED`.

C4 owns transaction-directory layout, quiescence, task disable/re-enable, remote replay, crash recovery, and rollback implementation. These postconditions are the interface its tests must prove.

### 5. Direct Linear API and runtime-register interface

Add `dodi-dev/runtime/runtime-register-record.schema.json` and document it in `runtime/adapter-contracts.md`. C1 defines only the interface:

- Direct Linear GraphQL remains canonical; there is no connector dependency.
- The profile stores `linear_source`, stable `linear_runtime_id`, and exactly one register issue id, never credentials.
- The issue description contains one immutable `RUNTIME_INIT` genesis record.
- Append-only comments contain `ESCALATION_OBLIGATION` or `ESCALATION_DELIVERED` records.
- Every record carries schema version, runtime id, monotonic sequence, previous-record hash, event id where applicable, timestamp, payload, and its record hash.
- `record_sha256` is SHA-256 over RFC 8785 canonical JSON for the record with `record_sha256` omitted. Genesis has sequence `0` and no previous hash; every later record links the prior hash.
- The health cursor names the exact issue, last comment, sequence, and record hash it projects.
- Duplicate runtime ids, missing genesis, gaps, duplicate sequences, hash mismatch, fork, runtime-id mismatch, or unreadable tip are blockers.

C1 does not query Linear, create/search an issue, append a comment, bridge environment keys, recover a lost create response, replay a real chain, or send Slack. C4 must implement those operations against this schema and the parent design's ordering rules.

### 6. Shared worker-adapter contract

Add `dodi-dev/runtime/dispatch-manifest-record.schema.json`. The dispatch manifest remains:

```text
<epic-worktree-abs>/.dodi/dispatch-manifest-<session-run-id>.jsonl
```

It is append-only. Every v1 line has a common envelope, with `worker_id` absent until the runtime has bound one to the dispatch nonce:

```json
{
  "schema_version": 1,
  "runtime": "claude",
  "session_id": "...",
  "context_id": "...",
  "dispatch_nonce": "...",
  "state": "dispatched",
  "ts": "...",
  "data": {}
}
```

Common required fields for every v1 record are `schema_version`, `runtime`, `session_id`, `context_id`, `dispatch_nonce`, `state`, `ts`, and `data`. `worker_id` is required only for states at or after `dispatched`; it is forbidden on `dispatch-intent` unless the runtime can prove a preallocated id before spawn. Records before id binding key on `(runtime, session_id, dispatch_nonce)`. Records after id binding also carry `worker_id` and key on `(runtime, worker_id)` for wake, close, and reap operations.

Before a spawn attempt, the top-level dispatcher flushes a `dispatch-intent` record containing:

- unique nonce, runtime, owning session/context, absolute worktree, purpose, and declared write scope;
- semantic tier plus requested model/reasoning supplied by the selected tier adapter (C2 for Codex, the existing alias mapping for Claude);
- profile `setup_run_id` and profile hash for an adapted Codex dispatch;
- clean baseline HEAD and porcelain/status hash for mutable work, or an explicit read-only baseline;
- prompt/input digest sufficient to identify the intended work without storing secrets.

State-specific records use the same envelope:

| State | Minimum meaning |
| --- | --- |
| `dispatch-intent` | durable pre-spawn ownership, scope, tier, profile generation, and baseline |
| `spawn-rejected` | runtime authoritatively proved no worker was accepted |
| `spawn-acceptance-unknown` | transport failed without proof of non-acceptance; intent remains unresolved |
| `dispatched` | worker id durably bound to the nonce |
| `waiting` / `wait-error` | non-terminal observation; never success |
| `completed` / `errored` / `interrupted` / `shutdown` | normalized terminal observation plus durable result-artifact path/hash where required |
| `attestation-invalid` | terminal output persisted but effective model/reasoning/context proof is absent or invalid |
| `evidence-conflict` | authoritative observations disagree; consume neither |
| `close-requested` / `closed` | stop request and authoritative result |
| `reaped` | terminal/closed proof recorded and concurrency slot released |
| `writer-uncertain` | no proof the worker cannot still mutate; quarantine and escalate |

Ordering invariants:

1. intent is durable before spawn;
2. worker id binding is durable before waiting on or consuming that worker;
3. terminal evidence is adapter-specific and durable before the terminal manifest record: Codex requires the complete normalized result artifact to be parsed, flushed, atomically renamed, and hash-verified; Claude may use its existing output file plus transcript terminal record, with the referenced file/transcript state flushed or otherwise proven stable before the terminal record is consumed;
4. where the runtime contract requires attestation, effective model/reasoning/context proof passes before a digest is consumed; C2 owns this check for Codex, while Claude retains its current explicit-alias evidence;
5. close/reap evidence is durable before a successor writer or close-out;
6. silence, timeout, unknown state, missing artifact, hash mismatch, unresolved intent, and conflict never advance PM or git state.

The logical key is `(runtime, session_id, dispatch_nonce)` before id binding and `(runtime, worker_id)` afterward. Duplicate equivalent terminal observations are bookkeeping; conflicting observations are evidence conflicts.

Runtime-specific fields live under `data`. Claude may record `output_file` and transcript terminal evidence. Codex records native status, result artifact, effective attestation, close result, and recovery evidence. A missing `schema_version` record matching the exact v0.16 shape is a legacy Claude record during upgrade; it is never inferred to be Codex. C1 defines that classification boundary and ships fixtures; C3 owns implementation changes that make the reaper recover, close, or quarantine Codex records.

#### Adapter operation boundary

The executing session uses one adapter with these semantic operations:

| Operation | Required postcondition | Owner |
| --- | --- | --- |
| `prepare-intent` | flushed `dispatch-intent` | shared contract, C3 implementation for Codex |
| `resolve-tier` | requested semantic tier mapped to explicit runtime pair | C2 |
| `spawn` | bound worker id, authoritative rejection, or unresolved acceptance | runtime adapter; C3 for Codex |
| `await` | waiting, terminal, or query error for the same worker id | runtime adapter; C3 for Codex |
| `persist-result` | complete artifact path/hash durable before terminal record | C3 |
| `verify-attestation` | effective pair/context satisfies gate policy where required | C2 for Codex, consumed by C3; current alias evidence for Claude |
| `close` | close result recorded; uncertainty remains quarantined | C3 |
| `reap/recover` | terminal/reaped proof or `writer-uncertain` | C3; C4 setup quiescence consumes it |
| `verify-state-generation` | profile/health/register bindings current | C4; C2/C3 fail closed on mismatch |

The Claude adapter continues to use native completion plus `await-worker.sh` and transcript evidence. C1 moves that prose out of the shared execution model and defines legacy v0.16 and v1 Claude manifest shapes as contract fixtures. It does not need to change `reap-workers.sh` unless the existing implementation cannot classify the documented Claude shapes in tests. A v1 Codex record returns an explicit unsupported-runtime blocker in C1's contract fixtures; C3 later changes the runtime adapter/reaper to handle Codex status, result artifacts, close, reap, quarantine, and recovery behavior.

### 7. Child dependency contracts

| Dependent | C1-owned inputs it must consume | It must not redefine |
| --- | --- | --- |
| C2 - tier map + hook enforcement | semantic tier names, profile `models`, intent requested fields, terminal effective-attestation fields, runtime-policy Fable table | profile paths, manifest states, tier names, generation binding |
| C3 - Codex worker lifecycle | adapter operations, intent baseline, manifest envelope/states, result-artifact ordering, legacy-Claude classification fixtures | nonce identity, terminal vocabulary, uncertainty semantics, profile-generation fields |
| C4 - setup/auth/scheduling/escalation | profile/health schemas and paths, stable lock path, register schema/hash chain, adapter quiescence query, bootstrap report | alternate profile search, mutable global degraded flag, second register authority, secret persistence |
| C5 - validation/release | C1 validators/fixtures and all installed contract paths | a second compatibility schema or release-only policy copy |

If a later child finds a C1 contract insufficient, it returns to DOD-811 spec review or records a parent decision-register amendment. It does not silently add a competing field or path.

## Proposed File Surfaces

### New files

| File | C1 responsibility |
| --- | --- |
| `dodi-dev/skills/epic-orchestrator/runtime-policy.md` | installed operative policy canon and root-bootstrap instructions |
| `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md` | runtime-neutral lifecycle API and fail-closed ordering |
| `dodi-dev/skills/epic-orchestrator/runtime/claude-worker-adapter.md` | current Claude mechanics, explicitly runtime-scoped |
| `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md` | required C3 interface and blocked status, without implementation claims |
| `dodi-dev/runtime/adapter-contracts.md` | profile/health/register/manifest cross-binding semantics and consumer matrix |
| `dodi-dev/runtime/runtime-profile.schema.json` | static profile schema v1 |
| `dodi-dev/runtime/runtime-health.schema.json` | generation-bound health schema v1 |
| `dodi-dev/runtime/runtime-register-record.schema.json` | genesis and escalation record schema v1 |
| `dodi-dev/runtime/dispatch-manifest-record.schema.json` | shared/legacy manifest record grammar |
| `dodi-dev/scripts/runtime-preflight.sh` | read-only root/bootstrap verifier; later extended by C4 |
| `dodi-dev/scripts/tests/test-runtime-preflight.sh` | unrelated-cwd, Claude-root, Codex-locator, mismatch, traversal, metadata, and redaction cases |
| `dodi-dev/scripts/tests/test-worker-manifest-contract.sh` | legacy/v1 Claude fixtures, pre-binding intent without `worker_id`, and fail-closed v1 Codex fixture |
| `scripts/validate-runtime-contracts.sh` | repository validation for schemas, fixtures, canon/reference boundaries, and root-command rules |

Contract fixtures may live under `dodi-dev/scripts/tests/fixtures/runtime-contracts/`; they are test data, not runtime authority.

### Modified files

| Surface | C1 edit |
| --- | --- |
| `AGENTS.md` | retain maintainer rules, replace duplicated operative canon with installed-canon pointer, keep validation commands |
| `dodi-dev/skills/epic-orchestrator/execution-model.md` | remove universal Claude transcript assumptions; reference policy and adapter contract |
| both lane playbooks + `state-transitions.md` | replace operative `AGENTS.md` references with shipped-canon links |
| the seven script-calling `SKILL.md` files listed in section 2 | add/reuse bootstrap and replace ambient-variable calls with concrete `<plugin-root>` calls |
| `drive-epic/SKILL.md`, `review/SKILL.md`, `submit-epic-pr/SKILL.md` | replace runtime-policy references; preserve behavior |
| `dodi-dev/scripts/reap-workers.sh` | unchanged unless existing behavior fails the C1 manifest-contract fixtures; no Codex recovery implementation in C1 |
| `scripts/validate-phase-skills.sh` | require the new installed docs/script/schemas; keep script syntax/executable checks |
| `scripts/validate-plugin-metadata.sh` | preserve metadata parity; C5 switches the expected release version to `0.17.0` |

### Explicitly unchanged in C1

- `dodi-dev/hooks/hooks.json` and both hook scripts;
- `await-worker.sh` behavior;
- skill frontmatter model aliases;
- Linear API behavior in `linear-api.sh`;
- scheduled tasks, credentials, Slack, branch protection, and marketplace installation state;
- `.agents/plugins/marketplace.json` shape and source path.

## Implementation Sequence

1. Add the machine-readable schemas and cross-binding document first; validate fixtures.
2. Add `runtime-policy.md` and adapter contract documents from the approved parent design.
3. Refactor `execution-model.md` and operative skill references to consume the shipped canon.
4. Implement and test `runtime-preflight.sh bootstrap` from unrelated cwd and copied/installed-root fixtures.
5. Replace ordinary skill script commands with concrete `<plugin-root>` placeholders governed by the bootstrap.
6. Add deterministic reference/schema/bootstrap validation.
7. Run the complete existing validation suite and leave the `0.17.0` metadata bump to C5's release sweep unless a parent amendment moves it earlier.

No step may make a real Linear, GitHub, scheduler, Slack, or operator-profile mutation.

## Acceptance Criteria

1. Every operative policy dependency consumed by an installed skill resolves inside `dodi-dev/`; repository-root `AGENTS.md` is not required at runtime.
2. `runtime-policy.md` contains the complete approved tier/Fable/dispatch/deterministic/decision-register/lights-out/scheduled/context canon without a competing operative copy in `AGENTS.md`.
3. Target-repository `CLAUDE.md / AGENTS.md` convention references remain intact and are distinguishable from forbidden dodi runtime-policy references.
4. From an unrelated cwd, a valid Claude candidate root and a valid Codex-style absolute skill locator both produce the same canonical `<plugin-root>` and verified plugin/skill identity.
5. Present-but-invalid `${CLAUDE_PLUGIN_ROOT}`, relative locators, locator/root mismatch, path traversal, missing scripts/metadata, plugin-id mismatch, and metadata-version mismatch fail closed.
6. Every ordinary script call in released skills uses the invocation's concrete `<plugin-root>`; `${CLAUDE_PLUGIN_ROOT}` appears only in hook metadata and bootstrap explanation/tests.
7. Bootstrap mode succeeds without profile/auth/repository context, is read-only, emits parseable redacted JSON, and never searches for alternate roots.
8. Profile, health, register-record, and manifest-record schemas parse; valid fixtures pass and fixtures with missing required fields, unknown versions/states, malformed hashes, or forbidden secret fields fail.
9. A Codex invocation that reaches `ROOT_READY` still cannot run non-bootstrap deterministic scripts or adapted mechanics without C4's valid profile verification; C1 returns `SETUP_REQUIRED` or `UNSUPPORTED_RUNTIME` rather than mutating state.
10. The health contract unambiguously verifies setup generation, exact profile bytes, profile/runtime/register identity, projection hash, and register cursor direction, with health and lock paths derived uniquely from the canonical selected profile path.
11. The manifest contract requires durable pre-spawn intent, baseline, explicit tier request, generation binding, terminal artifact ordering, attestation before consumption, and close/reap proof before successor writes; `dispatch-intent` is representable before `worker_id` exists.
12. Legacy unversioned v0.16 and v1 Claude manifest fixtures remain classifiable; v1 Codex fixtures fail with an explicit unsupported-runtime blocker until C3 lands, and no shared contract requires `output_file` for Codex.
13. C1 documentation never claims Codex tier resolution, native worker lifecycle, setup, scheduling, escalation, or release validation is implemented; those dependent capabilities remain explicitly blocked.
14. Existing Claude validators and focused worker-script tests remain green; C1 introduces no v0.16 workflow-state transition or PM behavior change.
15. Version-bearing metadata is not bumped by C1 unless DOD-810 records an amendment; C5 owns the `0.17.0` release bump and verifies both marketplaces still resolve the same `./dodi-dev` directory with no second skill tree or symlink.

## Validation Commands

```bash
scripts/validate-plugin-metadata.sh
scripts/validate-phase-skills.sh
scripts/validate-ticket-comment-templates.sh
scripts/validate-runtime-contracts.sh
dodi-dev/scripts/tests/test-runtime-preflight.sh
dodi-dev/scripts/tests/test-worker-manifest-contract.sh
```

Focused static checks:

```bash
bash -n dodi-dev/scripts/runtime-preflight.sh
python3 -m json.tool dodi-dev/runtime/runtime-profile.schema.json >/dev/null
python3 -m json.tool dodi-dev/runtime/runtime-health.schema.json >/dev/null
python3 -m json.tool dodi-dev/runtime/runtime-register-record.schema.json >/dev/null
python3 -m json.tool dodi-dev/runtime/dispatch-manifest-record.schema.json >/dev/null
rg -n 'docs/(specs|plans)/|templates/ticket-comments' dodi-dev/skills
rg -n '\$\{CLAUDE_PLUGIN_ROOT\}|\$\{CODEX_PLUGIN_ROOT\}' dodi-dev/skills
find dodi-dev/skills -type l -print
```

The first `rg` permits no installed-skill runtime dependency. The second permits only explanatory bootstrap text that is asserted by `validate-runtime-contracts.sh`; it permits no ordinary command. Hook metadata is tested separately and is outside that skill-tree scan.

The C5 isolated-install smoke and live Codex gate are not C1 validation commands. C1 provides the paths and fixtures those gates later consume.

## Migration, Compatibility, and Rollback

- **Claude Code:** behavior remains current. Its adapter uses `${CLAUDE_PLUGIN_ROOT}` only to propose a candidate, then ordinary calls use the verified concrete root. Current transcript await/reap behavior remains in place.
- **Codex after C1 only:** installed policy and root bootstrap are available, but every non-bootstrap deterministic script, tiered dispatch, or worker lifecycle path returns a concrete unsupported/setup blocker until C4 profile verification and the relevant C2/C3 adapters exist. Lights-out remains disabled.
- **Existing manifests:** unversioned v0.16 records remain defined as legacy Claude records. New Claude writers may use v1 once implemented, and C1 fixtures pin both Claude shapes. C3 owns Codex reaping and must not rewrite old JSONL history.
- **Existing local state:** C1 creates no operator profile or health file and no Linear register, so there is no local-state migration yet.
- **Rollback:** restoring the pre-C1 plugin restores repository-root policy dependence and ambient-root calls. Because C1 has no PM or operator-state mutation, rollback is code-only. Any v1 manifest created during development remains append-only evidence and must not be deleted blindly.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Shipped canon and `AGENTS.md` drift | move operative text, retain one pointer, and fail validation on operative repo-root references |
| Root verification itself depends on knowing the root | derive one candidate from the invoked skill locator, call the verifier by that concrete candidate path, and never search |
| A stale Claude variable masks the installed skill root | present-but-invalid variable fails instead of falling back |
| C1 schemas overfit later implementations | version every contract, namespace runtime data, keep adapter operations semantic, and require explicit amendment for shape changes |
| Health projection hash is circular | hash only the canonical `projection` object; bind the exact profile separately |
| C3 mistakes old Claude records for Codex | legacy shape is explicitly Claude-only; runtime is mandatory in v1 |
| C1 appears to make Codex autonomous | adapter docs and acceptance criteria state blocked dependent capabilities explicitly |
| Metadata bump collides across children | C1 documents the same-change release rule but leaves the actual `0.17.0` bump to C5, matching the approved decomposition |
| Runtime-register scope expands into setup | C1 ships schemas and invariants only; all API calls, initialization, replay, and delivery stay in C4 |

## Blocking Questions

None. The parent design and DOD-811 intent are sufficient to draft and plan this child. Any requested change to the approved profile fields, register authority, model-tier semantics, Codex takeover safety, or child ownership boundaries requires a DOD-810 decision-register amendment rather than an implementation-time choice.
