# DOD-811 Runtime Foundation Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute Tasks 1-8 in order. DOD-811 is contract and bootstrap work only: do not implement any C2-C5 capability while resolving a test failure.

**Goal:** Ship the installed runtime canon, versioned profile/health/register/manifest contracts, verified plugin-root bootstrap, and runtime-neutral adapter interfaces required by DOD-810 without activating Codex workflow execution.

**Architecture:** Put operative cross-runtime policy and adapter contracts inside the installed `dodi-dev/` tree, with strict JSON Schema v1 documents and fixtures defining the shared state vocabulary. A read-only `runtime-preflight.sh bootstrap` validates one caller-derived root and reports canonical profile/health/lock paths; released skills then replace ambient-root commands with one verified concrete `<plugin-root>`, while Codex remains fenced after `ROOT_READY` because C4 profile verification does not exist yet. Preserve current Claude transcript behavior through an explicitly Claude-scoped adapter and a narrow legacy/v1 manifest classifier; leave Codex tier selection, native lifecycle mechanics, state mutation, and release validation to C2-C5.

**Tech Stack:** Bash 3.2-compatible scripts, Python 3 standard library for runtime JSON/path handling, JSON Schema draft 2020-12, test-only Python `jsonschema`, Markdown skills/contracts, existing repository validators.

**Source of truth:** `docs/specs/2026-07-09-runtime-canon-profile-bootstrap-design.md` (approved child spec), constrained by `docs/specs/2026-07-09-codex-runtime-compatibility-design.md` (approved parent spec). Implementation baseline is `1009fab`; use quoted headings and semantic anchors rather than line numbers if the epic branch moves.

**Scope boundaries:**

- C1 defines semantic tier/profile/manifest fields but does not choose Codex model ids, reasoning values, capacity signatures, or attestation policy implementation (C2).
- C1 documents Codex worker operations and blocked states but does not call `spawn_agent`, `wait_agent`, or `close_agent`, persist native result artifacts, recover/take over workers, or implement Codex reaping (C3).
- C1 creates no profile, health file, lock, Linear runtime register, setup skill, secret bridge, scheduler task, GitHub actor check, Gate 2 live-fire change, Slack delivery, updater, replay, or rollback implementation (C4).
- C1 does not add isolated-install/live runtime gates, user install documentation, final compatibility validation, or a `0.17.0` metadata bump (C5).
- `dodi-dev/hooks/hooks.json`, both hook scripts, `dodi-dev/scripts/await-worker.sh`, and `dodi-dev/scripts/linear-api.sh` remain byte-identical to `1009fab`.
- `ROOT_READY` proves only root/skill provenance. On Codex, every non-bootstrap deterministic script or adapted mechanic remains fenced with `SETUP_REQUIRED` or `UNSUPPORTED_RUNTIME` until C4's `verify-profile` exists.

**File surface:**

- Create: `requirements-dev.txt`
- Create: `dodi-dev/runtime/adapter-contracts.md`
- Create: `dodi-dev/runtime/runtime-profile.schema.json`
- Create: `dodi-dev/runtime/runtime-health.schema.json`
- Create: `dodi-dev/runtime/runtime-register-record.schema.json`
- Create: `dodi-dev/runtime/dispatch-manifest-record.schema.json`
- Create: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Create: `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md`
- Create: `dodi-dev/skills/epic-orchestrator/runtime/claude-worker-adapter.md`
- Create: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`
- Create: `dodi-dev/scripts/runtime-preflight.sh`
- Create: `dodi-dev/scripts/tests/test-runtime-preflight.sh`
- Create: `dodi-dev/scripts/tests/test-worker-manifest-contract.sh`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/**`
- Create: `scripts/validate-runtime-contracts.sh`
- Modify: `AGENTS.md`
- Modify: `dodi-dev/skills/epic-orchestrator/execution-model.md`
- Modify: `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md`
- Modify: `dodi-dev/skills/epic-orchestrator/lanes/deliver-playbook.md`
- Modify: `dodi-dev/skills/epic-orchestrator/state-transitions.md`
- Modify: `dodi-dev/skills/assess-epic/SKILL.md`
- Modify: `dodi-dev/skills/deliver-ticket/SKILL.md`
- Modify: `dodi-dev/skills/drive-epic/SKILL.md`
- Modify: `dodi-dev/skills/epic-orchestrator/SKILL.md`
- Modify: `dodi-dev/skills/mature-ticket/SKILL.md`
- Modify: `dodi-dev/skills/reconcile-tickets/SKILL.md`
- Modify: `dodi-dev/skills/submit-ticket-pr/SKILL.md`
- Modify: `dodi-dev/skills/review/SKILL.md`
- Modify: `dodi-dev/skills/submit-epic-pr/SKILL.md`
- Modify: `dodi-dev/scripts/reap-workers.sh` (classification only; no Codex lifecycle implementation)
- Modify: `scripts/validate-phase-skills.sh`

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `runtime-preflight.sh bootstrap path/provenance logic; profile/health/register/manifest schemas; legacy and v1 manifest classification`
  - Reason: `The C1 deliverable is a deterministic contract surface. Exit classes, schema branches, path normalization, and fail-closed record classification need direct fixture coverage.`
  - Minimum assertions: `valid and invalid schema fixtures classify as declared; dispatch-intent validates without worker_id; every v1 manifest state has either a valid fixture or an explicit unsupported/blocker fixture; malformed/unknown records fail; semantic register/health/hash-chain fixtures fail validator checks; valid Claude roots bootstrap from unrelated cwd; invalid roots/locators/metadata fail with the specified exit class; legacy and v1 Claude records classify; v1 Codex records return UNSUPPORTED_RUNTIME.`

  - Additional semantic assertions: `schema-valid health fixtures must separately prove rejection of profile hash mismatch, projection hash mismatch, and cursor binding mismatch; the register hash-chain semantic fixture proves sequence/previous-record linkage rejection.`

- Integration: `required`
  - Scope: `installed policy packaging, runtime-policy reference graph, seven script-calling entry points, concrete-root command sweep, metadata-envelope parity, and validator registration`
  - Reason: `The central regression risk is cross-file drift: a valid script or schema is insufficient if an installed skill still depends on repo-root policy or emits an ambient root expression.`
  - Harness: `setup-required`
  - Minimum assertions: `all installed runtime references resolve under dodi-dev; only target-repository convention references to AGENTS.md remain; duplicate AGENTS.md canon for tier, Fable, scannable-artifact, dispatch, scheduled-operation, deterministic-script, decision-register, lights-out, and context-hygiene rules is absent; all 25 current ordinary root expressions are removed; hook metadata keeps its two allowed expressions; ROOT_READY text is paired with the Codex workflow-readiness fence; C2/C5 surfaces are explicitly absent; all existing validators stay green.`

- E2E: `not-required`
  - Scope: `isolated Codex install, live tier attestation, native worker lifecycle, setup/profile creation, scheduled operation, Slack escalation, and Claude/Codex release matrix`
  - Reason: `Those paths require C2-C4 implementations and are explicitly owned by C5's final release gate. C1 supplies contracts and deterministic fixtures only.`
  - Harness: `not-applicable`
  - Minimum assertions: `not applicable in DOD-811; C5 must consume the C1 schemas, bootstrap script, and fixtures rather than create competing contracts.`

### Critical Flows

- `Absolute invoked SKILL.md locator -> one candidate root (present CLAUDE_PLUGIN_ROOT wins, invalid present value never falls back) -> runtime-preflight.sh bootstrap -> ROOT_READY with canonical concrete plugin_root -> Claude ordinary command substitutes that root.`
- `Codex absolute skill locator -> ROOT_READY only -> non-bootstrap adapted mechanic checks for C4 profile verification -> SETUP_REQUIRED or UNSUPPORTED_RUNTIME -> no PM/git/repository mutation.`
- `Canonical selected profile path -> exact default-vs-non-default comparison -> one deterministic health path and one stable lock path; an explicit path canonicalizing to the default uses the default pair.`
- `Top-level dispatcher -> durable dispatch-intent without worker_id -> spawn boundary -> durable binding before wait/consume -> adapter-specific durable terminal evidence before terminal record -> attestation before digest consumption -> close/reap proof before successor writer.`
- `Legacy unversioned Claude manifest and v1 Claude manifest -> Claude classifier; v1 Codex manifest -> explicit C3-owned unsupported-runtime blocker, never Claude transcript inference.`

### Regression Surface

- `Current Claude entry behavior, transcript final-line detection, and legacy manifest classification.`
- `Model/Fable policy, Gate 1/Gate 2, claim, coherence, lane ordering, context-refresh, and one-lane-in-flight semantics; this work only relocates their operative canon.`
- `Plugin metadata remains 0.16.0 and synchronized; C5 owns the 0.17.0 bump.`
- `Hook metadata and scripts retain their current command/matcher/payload behavior.`
- `Generic target-repository CLAUDE.md / AGENTS.md convention inputs and docs/specs or docs/plans output locations remain valid; only repo-owned runtime dependencies are forbidden.`

### Commands

- Unit: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; scripts/validate-runtime-contracts.sh && dodi-dev/scripts/tests/test-runtime-preflight.sh && dodi-dev/scripts/tests/test-worker-manifest-contract.sh`
- Integration: `scripts/validate-phase-skills.sh && scripts/validate-plugin-metadata.sh && scripts/validate-ticket-comment-templates.sh`
- E2E: `not-applicable - C5 owns isolated-install and live runtime validation`
- Broader regression: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done` plus the Task 8 reference/scope battery.

### Harness Requirements

- `bash, python3, git, rg, jq, mktemp, stat, shasum or sha256sum; no Linear/GitHub/Slack credentials and no runtime profile.`
- `Create the test-only schema environment once: python3 -m venv /tmp/dodi-runtime-contracts-venv && /tmp/dodi-runtime-contracts-venv/bin/python -m pip install --requirement requirements-dev.txt.`
- `All runtime scripts remain Python-standard-library-only. The jsonschema dependency is used by repository validation, not by the installed workflow at runtime.`

### Non-Required Rationale

- Unit: `not applicable (required).`
- Integration: `not applicable (required).`
- E2E: `C1 cannot truthfully exercise model attestation, native Codex worker operations, generated state, scheduling, escalation, or release compatibility before C2-C4 exist; simulating those here would cross child ownership and create false release evidence.`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---

## Tasks

### Task 1: Add the versioned runtime schemas and contract fixtures

**Files:**
- Create: `requirements-dev.txt`
- Create: `dodi-dev/runtime/runtime-profile.schema.json`
- Create: `dodi-dev/runtime/runtime-health.schema.json`
- Create: `dodi-dev/runtime/runtime-register-record.schema.json`
- Create: `dodi-dev/runtime/dispatch-manifest-record.schema.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/profile/runtime-profile.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/profile/runtime-profile.secret.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/profile/runtime-profile.version.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/health/runtime-health.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/health/runtime-health.hash.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/health/runtime-health.profile-hash.semantic-invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/health/runtime-health.projection-hash.semantic-invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/health/runtime-health.cursor.semantic-invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/health/runtime-health.obligation.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/register/runtime-register-genesis.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/register/runtime-register-obligation.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/register/runtime-register-shape.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/register/runtime-register-chain.semantic-invalid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/legacy-claude.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-intent.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-spawn-rejected.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-acceptance-unknown.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-dispatched-live.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-waiting.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-wait-error.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-completed.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-errored.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-interrupted.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-shutdown.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-attestation-invalid.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-evidence-conflict.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-close-requested.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-closed.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-reaped.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-claude-writer-uncertain.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-codex-intent.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-codex-dispatched.valid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-intent-worker-id.invalid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-state.invalid.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/runtime-contracts/manifest/v1-common-field.invalid.jsonl`

- [ ] **Step 1:** Add the test-only dependency, exactly:

```text
jsonschema==4.23.0
```

Do not import it from `dodi-dev/scripts/runtime-preflight.sh` or any other installed runtime script.

- [ ] **Step 2:** Implement all four schemas with `"$schema": "https://json-schema.org/draft/2020-12/schema"`, the exact stable `$id` values below, `schema_version: {"const": 1}`, and `additionalProperties: false` at every object whose fields C1 owns.

```text
dodi-dev/runtime/runtime-profile.schema.json: https://dodi.dev/schemas/dodi-dev/runtime-profile/v1
dodi-dev/runtime/runtime-health.schema.json: https://dodi.dev/schemas/dodi-dev/runtime-health/v1
dodi-dev/runtime/runtime-register-record.schema.json: https://dodi.dev/schemas/dodi-dev/runtime-register-record/v1
dodi-dev/runtime/dispatch-manifest-record.schema.json: https://dodi.dev/schemas/dodi-dev/dispatch-manifest-record/v1
```

The profile schema must require exactly these top-level fields: `schema_version`, `generated_by`, `runtime`, `plugin`, `models`, `hooks`, `auth`, `escalation`, `repositories`, and `validated_at`. Pin these nested contracts:

```text
generated_by: plugin_version, setup_run_id
runtime: kind (claude|codex), version, model_catalog_sha256
plugin: id, version, root, marketplace_name, marketplace_root
models: frontier, capable, standard, fast; each requires id and reasoning but does not enumerate Codex values
hooks: gate2 and model_pin; each requires key, hash, trusted
auth: linear_source, linear_runtime_id, linear_register_issue_id, github_host
escalation: adapter, channel_id, retry_policy.delays_sec, health_policy.stale_after_sec, health_policy.re_escalate_after_sec
repositories: patternProperties owner/name; each requires path, base_branch, branch_protection, tasks
branch_protection: rules_sha256, required_checks_sha256, automation_actor, actor_bypass, actor_can_update_base, actor_can_admin_rules, verified_at
tasks: driver and janitor; driver additionally requires wake_test_id and wake_tested_at
validated_at: date-time
```

Use `^[a-f0-9]{64}$` for SHA-256 fields, `^/` for absolute paths, non-empty strings for ids, non-negative integers for policy delays, and `^(env:[A-Z][A-Z0-9_]*|file:/.*)$` for `auth.linear_source`. The schema must reject `linear_api_key`, token, password, or arbitrary extension fields by shape; it stores source references only.

- [ ] **Step 3:** Implement the health schema. Require `schema_version`, `setup_run_id`, `profile_sha256`, `runtime_id`, `register_cursor`, `projection`, and `projection_sha256`. `register_cursor` requires `issue_id`, `comment_id`, `sequence`, and `record_sha256`; sequence zero requires `comment_id: null`, while sequence greater than zero requires a non-empty comment id. `projection` requires adapter/channel, nullable attempt/success timestamps, non-negative `consecutive_failures`, and an `obligations` map.

Each obligation key is a durable event id. Each value requires ticket id, event id, state (`pending|retrying|delivered`), non-negative attempts, nullable last error/attempt, and nullable delivery id/link/time. Add an `if state == delivered` branch requiring non-null delivery id/link/time. Do not add a mutable global `notification_degraded` field.

- [ ] **Step 4:** Implement the register-record schema as a strict `oneOf` over:

```text
RUNTIME_INIT: sequence == 0, previous_record_sha256 == null, no event_id, payload.created_at required
ESCALATION_OBLIGATION: sequence >= 1, previous hash and event_id required, payload ticket/event identity required
ESCALATION_DELIVERED: sequence >= 1, previous hash and event_id required, payload message_id/link/delivered_at required
```

Every branch requires `schema_version`, `record_type`, `runtime_id`, `sequence`, `previous_record_sha256`, `ts`, `payload`, and `record_sha256`. The schema validates record shape only; `adapter-contracts.md` and C4 own RFC 8785 hash-chain verification and remote-chain reads.

- [ ] **Step 5:** Implement the manifest schema as a strict `oneOf` over the exact legacy Claude v0.16 dispatch/reap records and the v1 envelope.

The legacy Claude v0.16 branch has no `schema_version` and uses these exact shapes with `additionalProperties: false`:

```text
legacy dispatch: {session_id: string, worker_id: string, output_file: absolute-path string, purpose: non-empty string, tier: frontier|capable|standard|fast, ts: RFC3339 UTC string}
legacy reap: {worker_id: string, reaped: true, verdict: live|terminal|STALLED, ts: RFC3339 UTC string}
```

The v1 common fields are:

```json
{
  "schema_version": 1,
  "runtime": "claude",
  "session_id": "session-1",
  "context_id": "context-1",
  "dispatch_nonce": "nonce-1",
  "state": "dispatch-intent",
  "ts": "2026-07-09T00:00:00Z",
  "data": {
    "worktree": "/tmp/epic-worktree",
    "purpose": "read runtime contract",
    "write_scope": "read-only",
    "tier": "standard",
    "requested_model": "sonnet",
    "requested_reasoning": "runtime-default",
    "baseline_head": "1111111111111111111111111111111111111111",
    "baseline_status_sha256": "2222222222222222222222222222222222222222222222222222222222222222",
    "prompt_sha256": "3333333333333333333333333333333333333333333333333333333333333333"
  }
}
```

The state enum is `dispatch-intent`, `spawn-rejected`, `spawn-acceptance-unknown`, `dispatched`, `waiting`, `wait-error`, `completed`, `errored`, `interrupted`, `shutdown`, `attestation-invalid`, `evidence-conflict`, `close-requested`, `closed`, `reaped`, and `writer-uncertain`. Require `worker_id` for id-bound states. On `dispatch-intent`, allow it only when `data.preallocated_worker_id_proof` is a non-empty runtime proof; otherwise forbid it. Allow no-worker `writer-uncertain` for unresolved acceptance. Require intent data to carry absolute worktree, purpose, write scope, tier, requested model/reasoning, prompt digest, profile generation/hash when runtime is Codex, and mutable baseline HEAD/status hash or an explicit read-only baseline.

Define concrete `data` requirements per state, not just an open object:

| State group | Required `data` fields |
| --- | --- |
| `dispatch-intent` | `worktree`, `purpose`, `write_scope`, `tier`, `requested_model`, `requested_reasoning`, `prompt_sha256`, plus either `baseline_head` + `baseline_status_sha256` or `read_only_baseline: true`; Codex also requires `profile_setup_run_id` and `profile_sha256` |
| `spawn-rejected` | `reason_code`, `message` |
| `spawn-acceptance-unknown` | `transport_error`, `retryable` |
| `dispatched` | `accepted_at`, `runtime_worker_ref`; Claude may also carry `output_file` |
| `waiting` | `observed_at`, `status` |
| `wait-error` | `observed_at`, `error_code`, `message` |
| `completed`, `errored`, `interrupted`, `shutdown` | `terminal_at`, `terminal_status`; Claude requires `output_file` plus `transcript_terminal_evidence`; Codex requires `result_artifact`, `result_sha256`, `effective_model`, `effective_reasoning`, and `effective_context_id` |
| `attestation-invalid` | terminal evidence fields plus `attestation_error` |
| `evidence-conflict` | `conflict_summary`, `observations` |
| `close-requested` | `requested_at`, `reason` |
| `closed` | `closed_at`, `close_status` |
| `reaped` | `reaped_at`, `terminal_source` |
| `writer-uncertain` | `uncertainty_reason`, `last_observation_at` |

Pin JSON types and enums for the v1 schema, not only names:

```text
runtime: claude|codex
schema_version: integer const 1
session_id, context_id, dispatch_nonce, worker_id, runtime_worker_ref: non-empty strings
state: dispatch-intent|spawn-rejected|spawn-acceptance-unknown|dispatched|waiting|wait-error|completed|errored|interrupted|shutdown|attestation-invalid|evidence-conflict|close-requested|closed|reaped|writer-uncertain
ts and every *_at/observed_at timestamp: RFC3339 UTC string
worktree, output_file, result_artifact: absolute-path strings
tier: frontier|capable|standard|fast
write_scope: read-only|worktree-write
requested_model, requested_reasoning, purpose, message, reason, uncertainty_reason, conflict_summary, attestation_error, transport_error: non-empty strings
prompt_sha256, baseline_status_sha256, profile_sha256, result_sha256, transcript_terminal_evidence.final_lines_sha256: lowercase SHA-256 strings
baseline_head: 40-character lowercase git SHA
read_only_baseline and retryable: booleans
profile_setup_run_id: non-empty string, required only when runtime is codex
status: live|STALLED|running|queued
terminal_status: completed|errored|interrupted|shutdown
reason_code: runtime-rejected|invalid-request|capacity-unavailable|unsupported-runtime
error_code: wait-timeout|transport-error|unsupported-runtime|unknown-worker
close_status: closed|not-found|unsupported-runtime|uncertain
terminal_source: manifest-terminal|close-proof|legacy-transcript
transcript_terminal_evidence: object with path absolute-path string, final_lines_sha256 SHA-256 string, terminal_marker non-empty string, observed_at RFC3339 UTC string
observations: non-empty array of objects with source non-empty string, status non-empty string, observed_at RFC3339 UTC string, detail non-empty string
```

Runtime-specific evidence belongs under `data`: Claude may use `output_file` plus transcript evidence; Codex terminal records require `result_artifact`, `result_sha256`, and effective attestation fields. Do not make `output_file` universal.

- [ ] **Step 6:** Add minimal valid and one-defect invalid fixtures using the exact filenames above. The valid profile fixture uses the current `0.16.0` installed version so C1 validation stays truthful; C5 must update that fixture with the metadata bump. The valid Codex intent fixture intentionally has no `worker_id`, proving pre-binding intent is representable. Manifest fixtures cover every v1 state from Step 5, either as an exact-state file named above or as a documented unsupported/blocker Codex fixture. For Claude, include both live/STALLED-style non-terminal fixtures and separate `completed`, `errored`, `interrupted`, `shutdown`, `attestation-invalid`, `evidence-conflict`, `close-requested`, `closed`, `reaped`, and `writer-uncertain` fixtures. For Codex, include intent and dispatched fixtures that schema-validate but are expected to return `UNSUPPORTED_RUNTIME` from the C1 classifier.

The `*.invalid.json` and `*.invalid.jsonl` fixtures are schema-invalid by shape: forbidden secret field, unknown schema version, malformed hash, delivered obligation without delivery evidence, worker id on intent without preallocation proof, unknown state, or missing common field. Semantic-only failures use the suffix `.semantic-invalid.json` or `.semantic-invalid.jsonl`; these parse and may schema-validate, but `validate-runtime-contracts.sh` must reject them through named semantic checks. `runtime-health.profile-hash.semantic-invalid.json`, `runtime-health.projection-hash.semantic-invalid.json`, and `runtime-health.cursor.semantic-invalid.json` are schema-valid health records with incorrect profile byte hash, projection hash, and register cursor binding respectively. `runtime-register-chain.semantic-invalid.jsonl` is the broken-chain fixture; do not name it `*.invalid.json` because the register schema intentionally validates record shape only.

- [ ] **Step 7:** Parse every schema and fixture before adding semantic validation.

Run:

```bash
set -euo pipefail
for file in dodi-dev/runtime/*.schema.json; do python3 -m json.tool "$file" >/dev/null; done
find dodi-dev/scripts/tests/fixtures/runtime-contracts -type f \( -name '*.json' -o -name '*.jsonl' \) -print0 |
  while IFS= read -r -d '' file; do
    if [[ "$file" == *.jsonl ]]; then
      python3 -c 'import json,sys; [json.loads(line) for line in open(sys.argv[1]) if line.strip()]' "$file"
    else
      python3 -m json.tool "$file" >/dev/null
    fi
  done
echo 'runtime contract JSON parses'
```

Expected: `runtime contract JSON parses`; exit 0 and no parser diagnostics.

- [ ] **Step 8:** Commit the schema and fixture slice.

```bash
git add requirements-dev.txt dodi-dev/runtime/*.schema.json dodi-dev/scripts/tests/fixtures/runtime-contracts
git commit -m "feat: define runtime state and manifest contracts"
```

### Task 2: Ship the runtime policy and adapter contract documentation

**Files:**
- Create: `dodi-dev/runtime/adapter-contracts.md`
- Create: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Create: `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md`
- Create: `dodi-dev/skills/epic-orchestrator/runtime/claude-worker-adapter.md`
- Create: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`
- Modify: `AGENTS.md`

- [ ] **Step 1:** Create `runtime-policy.md` as the only installed operative home for the current semantic model tiers, Fable availability table and mechanics, top-level-only/leaf dispatch rule, worker return contract, scannable artifact rules, deterministic-script doctrine, decision-register canon, lights-out/escalation invariants, scheduled-operation/Gate 2/single-writer rules, and context-hygiene/resumability rules.

Add two new normative sections:

```markdown
## Plugin Root Bootstrap

An entry-point skill that calls a plugin script resolves one candidate from the absolute invoked `SKILL.md` locator, except that a present `${CLAUDE_PLUGIN_ROOT}` is the candidate on Claude Code and invalid presence is a blocker. It calls that candidate's `scripts/runtime-preflight.sh bootstrap` by concrete absolute path, records the canonical returned `plugin_root` as `<plugin-root>`, and substitutes that concrete path into every ordinary script call. It never searches cwd, parents, PATH, home, or caches.

`ROOT_READY` proves root and skill provenance only. On Codex, it is not workflow readiness: until `runtime-preflight.sh verify-profile` exists and validates the C4-owned profile/health/register binding, every non-bootstrap deterministic script and adapted mechanic exits `SETUP_REQUIRED` or `UNSUPPORTED_RUNTIME` without workflow writes.

## Runtime Context Selection

Runtime profile, health, lock, tier, and worker-adapter selection follow `../../runtime/adapter-contracts.md` and `runtime/worker-adapter-contract.md`. Unknown schema versions, runtime kinds, adapters, manifest states, generation bindings, or attestation are blockers, never permission to advance PM or git state.
```

Preserve Claude aliases as authoring vocabulary, but state that aliases are adapter data rather than universal runtime ids.

- [ ] **Step 2:** In `AGENTS.md`, retain project shape, editing rules, harness-neutral authoring guidance, the model-tier authoring vocabulary, and validation commands. Replace the duplicated operative sections with one prominent `## Installed Runtime Canon` pointer to `dodi-dev/skills/epic-orchestrator/runtime-policy.md`. The pointer must say that runtime behavior changes go to the shipped file first and that `AGENTS.md` is not available in an installed plugin. Do not leave a second tier/Fable/scheduled/context table in `AGENTS.md`.

- [ ] **Step 3:** Create `dodi-dev/runtime/adapter-contracts.md` with exact sections for profile resolution, canonical path derivation, cross-field profile validity, health generation/hash/register binding, stable-lock/pair-update postconditions, Linear register hash-chain interface, manifest location/schema selection, and a C2/C3/C4/C5 consumer matrix.

The path algorithm must state exactly:

```text
default_profile = canonical(${XDG_CONFIG_HOME:-$HOME/.config}/dodi-dev/runtime-profile.json)
selected_profile = canonical(${DODI_RUNTIME_PROFILE}) when explicitly set, else default_profile
if selected_profile == default_profile:
  health = sibling runtime-health.json
  lock   = sibling runtime-state.lock
else:
  health = replace trailing .json with .health.json, else append .health.json
  lock   = selected_profile + .lock
```

Both overrides must be absolute when set. Comparison happens after canonicalization, so an explicit alias of the default path selects the default health/lock pair. State the six health-consumption bindings from the spec, exact-profile-byte SHA-256, RFC 8785 projection-only hash, strict-prefix replay eligibility, and `SETUP_REQUIRED` outcomes. Document postconditions only; do not specify C4 transaction-directory internals beyond the approved interface.

- [ ] **Step 4:** Create `worker-adapter-contract.md` with the common operation table (`prepare-intent`, `resolve-tier`, `spawn`, `await`, `persist-result`, `verify-attestation`, `close`, `reap/recover`, `verify-state-generation`), logical keys before/after binding, state vocabulary, fail-closed conditions, and ordering invariants.

Pin terminal evidence ordering as adapter-specific: Codex must durably parse/flush/rename/hash the normalized result artifact before its terminal record; Claude may rely on its existing output file and transcript terminal evidence, proved stable before consumption. Do not state that every adapter writes a Codex-style artifact.

- [ ] **Step 5:** Create `claude-worker-adapter.md` by moving the current Claude-specific native completion, `await-worker.sh`, `stop_reason:end_turn`, transcript mtime, output-file, and reaper behavior out of shared prose. Create `codex-worker-adapter.md` as an interface/status document: enumerate required native inputs, normalized outcomes, uncertainty/quarantine rules, and durable evidence, but lead with `Status: UNSUPPORTED_RUNTIME in C1; C3 implements spawn/wait/close/recovery.` Do not claim a callable Codex adapter exists.

- [ ] **Step 6:** Verify canon completeness and single ownership.

Run:

```bash
set -euo pipefail
for heading in 'Model Tiers' 'Fable Availability Policy' 'Dispatch Discipline' 'Scannable Artifacts' 'Deterministic Skeleton' 'Decision Register' 'Lights-Out Invariants' 'Scheduled Operation' 'Context Hygiene' 'Plugin Root Bootstrap' 'Runtime Context Selection'; do
  grep -qF "## $heading" dodi-dev/skills/epic-orchestrator/runtime-policy.md || exit 1
done
grep -qF 'ROOT_READY' dodi-dev/skills/epic-orchestrator/runtime-policy.md
grep -qF 'not workflow readiness' dodi-dev/skills/epic-orchestrator/runtime-policy.md
grep -qF 'canonical selected profile path' dodi-dev/runtime/adapter-contracts.md
grep -qF 'terminal evidence is adapter-specific' dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md
grep -qF 'Status: `UNSUPPORTED_RUNTIME` in C1' dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md
for duplicate in '## Model Tiers' '## Fable Availability Policy' '## Dispatch Discipline' '## Scannable Artifacts' '## Deterministic Skeleton' '## Decision Register' '## Lights-Out Invariants' '## Scheduled Operation' '## Context Hygiene'; do
  ! grep -qF "$duplicate" AGENTS.md || { echo "duplicate runtime canon in AGENTS.md: $duplicate" >&2; exit 1; }
done
! rg -n '\| Tier \| Claude alias \||pending-capacity|FABLE_MAKEUP|healthy-quiet|resident driver|refresh-park|top-level session dispatches workers' AGENTS.md
echo 'runtime canon packaged'
```

Expected: `runtime canon packaged`; exit 0.

- [ ] **Step 7:** Commit the installed canon slice.

```bash
git add AGENTS.md dodi-dev/runtime/adapter-contracts.md dodi-dev/skills/epic-orchestrator/runtime-policy.md dodi-dev/skills/epic-orchestrator/runtime
git commit -m "docs: ship runtime policy and adapter contracts"
```

### Task 3: Make shared execution prose runtime-neutral and sweep policy references

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/execution-model.md`
- Modify: `dodi-dev/skills/epic-orchestrator/lanes/mature-playbook.md`
- Modify: `dodi-dev/skills/epic-orchestrator/lanes/deliver-playbook.md`
- Modify: `dodi-dev/skills/epic-orchestrator/state-transitions.md`
- Modify: `dodi-dev/skills/drive-epic/SKILL.md`
- Modify: `dodi-dev/skills/review/SKILL.md`
- Modify: `dodi-dev/skills/submit-epic-pr/SKILL.md`

- [ ] **Step 1:** Refactor `execution-model.md` to link to `runtime-policy.md` for tiers/Fable/context policy and `runtime/worker-adapter-contract.md` for lifecycle semantics. Replace universal Claude transcript/`await-worker.sh` language with: select exactly one adapter from verified runtime context; follow that adapter's await/terminal/close/reap contract; silence is never success. Keep lane seams, serial/parallel rules, manifest absolute location, continuation behavior, and refresh limits unchanged.

- [ ] **Step 2:** Replace operative `AGENTS.md` references in both lane playbooks, `state-transitions.md`, `drive-epic`, `review`, and `submit-epic-pr` with relative links to the shipped runtime policy or execution model. Preserve the four target-repository convention references exactly:

```text
dodi-dev/skills/mature-ticket/spec-drafter-prompt.md
dodi-dev/skills/review/SKILL.md
dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md
dodi-dev/skills/write-plan/plan-writer-prompt.md
```

The `review/SKILL.md` code-quality row still means the target repository's `CLAUDE.md / AGENTS.md`; do not rewrite it.

- [ ] **Step 3:** Ensure no relocated prose changes Fable gate assignments, substitution attribution, capacity parking, final-gate diversity, claim/coherence behavior, lane ordering, Gate 2, or reset seams. This task is reference ownership only.

- [ ] **Step 4:** Verify the reference classification.

Run:

```bash
set -euo pipefail
expected="$(printf '%s\n' \
  dodi-dev/skills/mature-ticket/spec-drafter-prompt.md \
  dodi-dev/skills/review/SKILL.md \
  dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md \
  dodi-dev/skills/write-plan/plan-writer-prompt.md | sort)"
actual="$(rg -l 'AGENTS\.md' dodi-dev/skills | sort)"
test "$actual" = "$expected"
! rg -n 'stop_reason|transcript mtime|output_file' dodi-dev/skills/epic-orchestrator/execution-model.md
grep -qF 'runtime/worker-adapter-contract.md' dodi-dev/skills/epic-orchestrator/execution-model.md
scripts/validate-phase-skills.sh >/dev/null
echo 'runtime-neutral references ok'
```

Expected: `runtime-neutral references ok`; exit 0.

- [ ] **Step 5:** Commit the reference sweep.

```bash
git add dodi-dev/skills/epic-orchestrator/execution-model.md dodi-dev/skills/epic-orchestrator/lanes dodi-dev/skills/epic-orchestrator/state-transitions.md dodi-dev/skills/drive-epic/SKILL.md dodi-dev/skills/review/SKILL.md dodi-dev/skills/submit-epic-pr/SKILL.md
git commit -m "docs: route workflow policy through installed canon"
```

### Task 4: Implement the read-only plugin-root bootstrap

**Files:**
- Create: `dodi-dev/scripts/runtime-preflight.sh`
- Create: `dodi-dev/scripts/tests/test-runtime-preflight.sh`

- [ ] **Step 1:** Implement only this command surface:

```bash
runtime-preflight.sh bootstrap <candidate-plugin-root> --skill-locator <absolute-SKILL.md>
```

Use Bash for argument/exit handling and an embedded Python 3 standard-library block for physical canonicalization, containment checks, metadata parsing, path derivation, and JSON emission. Do not add `verify-profile`; C4 extends the script later.

- [ ] **Step 2:** Enforce these checks in order without searching for alternatives:

1. Candidate and skill locator are absolute and contain no unresolved environment expression.
2. Canonical locator has exact shape `<canonical-root>/skills/<one-segment-skill-name>/SKILL.md` and is physically contained by the canonical root.
3. `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` both parse, both names equal `dodi-dev`, and versions match.
4. `skills/`, `scripts/`, `scripts/runtime-preflight.sh`, and the invoked skill exist beneath the root.
5. `DODI_RUNTIME_PROFILE` and `XDG_CONFIG_HOME`, when present, are absolute. Resolve/canonicalize the selected profile, then derive health and lock from the canonical selected path exactly as Task 2 specifies. Do not inspect or create those files.

- [ ] **Step 3:** On success emit one JSON object to stdout with `schema_version`, `status: ROOT_READY`, `plugin_root`, `skill_locator`, `skill_name`, `plugin_id`, `plugin_version`, `profile_path`, `health_path`, and `lock_path`. Diagnostics go only to stderr. Use exits: `0` verified, `2` bad invocation/missing dependency, `3` candidate/locator/metadata/containment failure, `4` safe output failure. Never print arbitrary environment values or secrets. For deterministic test coverage only, support `DODI_RUNTIME_PREFLIGHT_TEST_MODE=1 DODI_RUNTIME_PREFLIGHT_TEST_FORCE_OUTPUT_FAILURE=1`; when both are set, force the final JSON emission path to fail after all validation has passed, print no partial JSON, and exit `4`. Ignore the force variable unless test mode is also set.

- [ ] **Step 4:** Build `test-runtime-preflight.sh` with temporary copied plugin roots and an unrelated cwd. Cover:

- valid Claude-style candidate plus locator;
- valid Codex-style locator with no `CLAUDE_PLUGIN_ROOT` dependency;
- present-but-invalid `CLAUDE_PLUGIN_ROOT` selected as the candidate -> exit 3 with no fallback to the valid locator-derived root;
- profile-free bootstrap;
- explicit non-default profile -> colocated `.health.json` and `.lock`;
- explicit path canonicalizing to default -> default health/lock pair;
- relative `DODI_RUNTIME_PROFILE` and relative `XDG_CONFIG_HOME` -> exit 3;
- relative locator, root/locator mismatch, traversal/symlink escape, missing scripts, missing metadata, id mismatch, and version mismatch -> exit 3;
- unexpected argument -> exit 2;
- deterministic safe-output failure with `DODI_RUNTIME_PREFLIGHT_TEST_MODE=1 DODI_RUNTIME_PREFLIGHT_TEST_FORCE_OUTPUT_FAILURE=1` -> exit 4, no partial stdout, and stderr contains `safe-output-failure`;
- stdout parses as one JSON object and stderr contains no sentinel secret value;
- file-tree hash/mode snapshot before and after proves bootstrap is read-only.

- [ ] **Step 5:** Verify.

Run:

```bash
set -euo pipefail
chmod +x dodi-dev/scripts/runtime-preflight.sh dodi-dev/scripts/tests/test-runtime-preflight.sh
bash -n dodi-dev/scripts/runtime-preflight.sh
bash -n dodi-dev/scripts/tests/test-runtime-preflight.sh
dodi-dev/scripts/tests/test-runtime-preflight.sh
```

Expected: final line `runtime-preflight tests ok`; exit 0.

- [ ] **Step 6:** Commit the bootstrap slice.

```bash
git add dodi-dev/scripts/runtime-preflight.sh dodi-dev/scripts/tests/test-runtime-preflight.sh
git commit -m "feat: verify concrete plugin roots before script use"
```

### Task 5: Bootstrap all script-calling skills and replace ambient ordinary commands

**Files:**
- Modify: `dodi-dev/skills/assess-epic/SKILL.md`
- Modify: `dodi-dev/skills/deliver-ticket/SKILL.md`
- Modify: `dodi-dev/skills/drive-epic/SKILL.md`
- Modify: `dodi-dev/skills/epic-orchestrator/SKILL.md`
- Modify: `dodi-dev/skills/mature-ticket/SKILL.md`
- Modify: `dodi-dev/skills/reconcile-tickets/SKILL.md`
- Modify: `dodi-dev/skills/submit-ticket-pr/SKILL.md`

- [ ] **Step 1:** Add a short `## Runtime Bootstrap` section to each entry point. Do not copy the algorithm. Link to the installed policy (`../epic-orchestrator/runtime-policy.md#plugin-root-bootstrap`, or `runtime-policy.md#plugin-root-bootstrap` from `epic-orchestrator`) and require it once before the first plugin script call.

Each section must explicitly say:

```markdown
Record the successful bootstrap report's canonical absolute `plugin_root` as `<plugin-root>` and substitute that concrete value into every ordinary command below. `ROOT_READY` is not Codex workflow readiness: in C1, a Codex invocation stops with `SETUP_REQUIRED` or `UNSUPPORTED_RUNTIME` before any non-bootstrap script or adapted mechanic because `verify-profile` is C4-owned and not implemented.
```

- [ ] **Step 2:** Replace all 25 current `${CLAUDE_PLUGIN_ROOT}` occurrences in these seven skills with `<plugin-root>` command references. Commands must use the quoted concrete form, for example:

```bash
"<plugin-root>/scripts/claim.sh" <ticket> <action> <session-run-id>
"<plugin-root>/scripts/release-claim.sh" <ticket> <exit-state> --session <session-run-id>
merge_sha="$("<plugin-root>/scripts/verify-merge.sh" <child-pr-number> <epic-branch>)"
```

Do not introduce `${CODEX_PLUGIN_ROOT}`, a shell-global `PLUGIN_ROOT`, cwd search, cache search, or a second bootstrap helper. Hook commands are outside this sweep.

- [ ] **Step 3:** Preserve all command arguments, exit meanings, and workflow ordering. This task changes how the executable path is sourced, not script behavior.

- [ ] **Step 4:** Verify the exact sweep and Codex fence.

Run:

```bash
set -euo pipefail
test "$(rg -o '\$\{CLAUDE_PLUGIN_ROOT\}' dodi-dev/skills | wc -l | tr -d ' ')" -eq 1
test "$(rg -l '\$\{CLAUDE_PLUGIN_ROOT\}' dodi-dev/skills)" = 'dodi-dev/skills/epic-orchestrator/runtime-policy.md'
test "$(rg -o '\$\{CLAUDE_PLUGIN_ROOT\}' dodi-dev/hooks/hooks.json | wc -l | tr -d ' ')" -eq 2
! rg -n '\$\{(CLAUDE|CODEX)_PLUGIN_ROOT\}/scripts/' dodi-dev/skills
for skill in assess-epic deliver-ticket drive-epic epic-orchestrator mature-ticket reconcile-tickets submit-ticket-pr; do
  grep -q '^## Runtime Bootstrap$' "dodi-dev/skills/$skill/SKILL.md" || exit 1
  grep -qF 'ROOT_READY' "dodi-dev/skills/$skill/SKILL.md" || exit 1
  grep -Eq 'SETUP_REQUIRED|UNSUPPORTED_RUNTIME' "dodi-dev/skills/$skill/SKILL.md" || exit 1
done
scripts/validate-phase-skills.sh >/dev/null
echo 'concrete root commands ok'
```

Expected: `concrete root commands ok`; exit 0. The one allowed skill-tree occurrence is explanatory candidate provenance in `runtime-policy.md`, not an ordinary command.

- [ ] **Step 5:** Commit the command sweep.

```bash
git add dodi-dev/skills/assess-epic/SKILL.md dodi-dev/skills/deliver-ticket/SKILL.md dodi-dev/skills/drive-epic/SKILL.md dodi-dev/skills/epic-orchestrator/SKILL.md dodi-dev/skills/mature-ticket/SKILL.md dodi-dev/skills/reconcile-tickets/SKILL.md dodi-dev/skills/submit-ticket-pr/SKILL.md
git commit -m "docs: bootstrap concrete roots for plugin script calls"
```

### Task 6: Classify manifest contracts without implementing Codex lifecycle

**Files:**
- Modify: `dodi-dev/scripts/reap-workers.sh`
- Create: `dodi-dev/scripts/tests/test-worker-manifest-contract.sh`

- [ ] **Step 1:** Refactor the embedded Python classifier in `reap-workers.sh` to parse records through three explicit branches:

```text
no schema_version + exact legacy dispatch/reap shape -> legacy Claude path
schema_version == 1 + runtime == claude -> v1 Claude path using data.output_file/transcript evidence
schema_version == 1 + runtime == codex -> print UNSUPPORTED_RUNTIME and return blocker status
anything else -> print UNKNOWN_RECORD and return blocker status
```

For v1 records, key unresolved pre-binding intent by `(runtime, session_id, dispatch_nonce)` and id-bound records by `(runtime, worker_id)`. A `dispatch-intent` with no worker id is valid input but unresolved; report `UNRESOLVED_INTENT`, never drop it. Preserve legacy `live`, `terminal`, and `STALLED` behavior and current stdout columns for legacy callers. Do not query, wait, close, or reap Codex workers and do not append synthetic terminal records.

- [ ] **Step 2:** Use exit `0` only when every record is classifiable by the supported Claude paths. Use exit `4` when any Codex v1, unresolved intent, unknown version/runtime/state, malformed record, or conflicting evidence requires C3 or human handling. Keep usage/JSON-read errors at exit `2`.

- [ ] **Step 3:** Implement `test-worker-manifest-contract.sh` against the Task 1 fixtures and temporary transcript files. Minimum assertions:

- legacy Claude terminal remains `terminal`, exit 0;
- legacy Claude non-terminal remains `live`/`STALLED`, exit 0;
- v1 Claude intent without worker id is recognized as `UNRESOLVED_INTENT`, exit 4;
- v1 Claude `spawn-rejected` records prove no worker was accepted, print `SPAWN_REJECTED`, and exit 4 without leaving a live slot;
- v1 Claude `spawn-acceptance-unknown` records print `ACCEPTANCE_UNKNOWN`, exit 4, and preserve the unresolved intent identity for C3/human handling;
- v1 Claude `dispatched`, `waiting`, and `wait-error` records classify as live/non-terminal without terminal success, and a stale output/transcript fixture reaches the same STALLED branch as legacy where applicable;
- v1 Claude bound terminal states (`completed`, `errored`, `interrupted`, `shutdown`) use `data.output_file` plus transcript terminal evidence and classify deterministically;
- v1 Claude `attestation-invalid`, `evidence-conflict`, `close-requested`, `closed`, `reaped`, and `writer-uncertain` fixtures each take their explicit branch; `reaped` is the only one that releases the slot without requiring C3/human handling;
- v1 Codex intent/dispatched records print `UNSUPPORTED_RUNTIME`, exit 4;
- unknown state/missing common field print a blocker, exit 4;
- no Codex fixture is interpreted through transcript or `output_file` fallback;
- `dispatch-intent` schema validation succeeds without worker id and fails with one when no `preallocated_worker_id_proof` is present.

- [ ] **Step 4:** Verify.

Run:

```bash
set -euo pipefail
chmod +x dodi-dev/scripts/tests/test-worker-manifest-contract.sh
bash -n dodi-dev/scripts/reap-workers.sh
bash -n dodi-dev/scripts/tests/test-worker-manifest-contract.sh
PATH=/tmp/dodi-runtime-contracts-venv/bin:$PATH dodi-dev/scripts/tests/test-worker-manifest-contract.sh
```

Expected: final line `worker manifest contract tests ok`; exit 0.

- [ ] **Step 5:** Commit the classification slice.

```bash
git add dodi-dev/scripts/reap-workers.sh dodi-dev/scripts/tests/test-worker-manifest-contract.sh
git commit -m "test: pin legacy and v1 worker manifest classification"
```

### Task 7: Add deterministic runtime-contract validation and register new surfaces

**Files:**
- Create: `scripts/validate-runtime-contracts.sh`
- Modify: `scripts/validate-phase-skills.sh`

- [ ] **Step 1:** Implement `validate-runtime-contracts.sh` with `set -euo pipefail`. Require `python3` and the test-only `jsonschema` module; if absent, exit 2 with the exact setup command from Testing Contract rather than silently skipping.

The embedded Python validator must:

- load each schema and run `Draft202012Validator.check_schema`;
- map each profile/health/register fixture directory to its schema;
- validate every `*.valid.json` successfully and require every `*.invalid.json` to produce at least one validation error;
- validate each v1 JSONL line against the manifest schema and validate exact legacy records through its legacy branch;
- require each `*.valid.jsonl` to pass and each `*.invalid.jsonl` to fail;
- require every `*.semantic-invalid.json` and `*.semantic-invalid.jsonl` to pass JSON parsing and, where applicable, schema validation, then fail a named semantic assertion;
- enforce cross-document fixture assertions not expressible in JSON Schema: profile generated/plugin versions equal; profile `plugin.id` starts with the bootstrap envelope id plus `@`; health `setup_run_id` equals profile `generated_by.setup_run_id`; health runtime/register ids equal the profile; health `profile_sha256` equals the exact valid profile fixture bytes; health `projection_sha256` equals the canonical projection hash; register cursor is equal to or a strict valid prefix of the semantic chain tip; the three health semantic-invalid fixtures fail the named profile-hash, projection-hash, and cursor-binding checks while still parsing and schema-validating; register chain sequence and previous-record hashes link; no key matching `secret|token|password|api_key`; Codex intent carries setup/profile binding; terminal evidence branch matches runtime;
- print `runtime schemas and fixtures ok` only after all checks pass.

- [ ] **Step 2:** Add shell reference checks to the validator:

- required runtime docs, four schemas, bootstrap script, and test files exist;
- schemas and JSON fixtures parse;
- all plugin scripts are executable and `bash -n` clean;
- installed `AGENTS.md` references match the four target-repository allowlisted files from Task 3;
- `AGENTS.md` does not retain `## Model Tiers` or the `| Tier | Claude alias |` table while `runtime-policy.md` does;
- generic docs/specs and docs/plans output-location references match the existing five allowlisted lines; date-specific repo docs and `templates/ticket-comments` dependencies are absent;
- no symlink exists under `dodi-dev/skills`;
- no `${CLAUDE_PLUGIN_ROOT}/scripts` or `${CODEX_PLUGIN_ROOT}/scripts` ordinary command remains in skills;
- only `runtime-policy.md` may mention `${CLAUDE_PLUGIN_ROOT}` in installed prose, and only `hooks.json` may use it in executable hook metadata;
- every seven script-calling skill has the bootstrap/fence text;
- Codex adapter says unsupported and C2-C5 forbidden implementation markers are absent (no native tool command examples presented as executable support, no setup skill, no production profile/register fixture outside tests);
- C2-owned model-tier implementation surfaces are absent: no `dodi-dev/runtime/codex-model-tiers.json`, no Codex model ids such as `gpt-5.6-sol` or `gpt-5.5` under `dodi-dev/runtime` or `dodi-dev/skills`, and no capacity-signature classifier script;
- C5-owned release/compatibility surfaces are absent: no `scripts/validate-codex-compatibility.sh`, no `scripts/validate-codex-install.sh`, no `docs/guides` or `docs/release` Codex install guide/release evidence file, and no metadata version change to `0.17.0`;
- metadata still reads `0.16.0` in the three version-bearing files.

- [ ] **Step 3:** Extend `validate-phase-skills.sh` to require `runtime-policy.md`, all three adapter documents, `adapter-contracts.md`, all four schemas, `runtime-preflight.sh`, and the two focused tests. Add `runtime-preflight.sh` to `plugin_scripts` so existence, executable mode, and `bash -n` are enforced. Keep phase validation dependency-free and do not invoke `validate-runtime-contracts.sh` from it; the dedicated validator owns schema execution and reports the concrete harness blocker when `jsonschema` is absent.

- [ ] **Step 4:** Verify the dedicated and existing validators.

Run:

```bash
set -euo pipefail
chmod +x scripts/validate-runtime-contracts.sh
bash -n scripts/validate-runtime-contracts.sh scripts/validate-phase-skills.sh
PATH=/tmp/dodi-runtime-contracts-venv/bin:$PATH scripts/validate-runtime-contracts.sh
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
```

Expected, in order: `runtime schemas and fixtures ok`, a runtime reference/bootstrap success line, `phase skills ok`, `plugin metadata ok: 0.16.0`, and `ticket comment templates ok`; all exit 0.

- [ ] **Step 5:** Commit the validator slice.

```bash
git add scripts/validate-runtime-contracts.sh scripts/validate-phase-skills.sh
git commit -m "test: validate installed runtime contracts and roots"
```

### Task 8: Run the complete regression and C1 ownership audit

**Files:**
- Verify only; do not change metadata, hooks, later-child surfaces, or the approved specs to make checks pass.

- [ ] **Step 1:** Run focused tests and all existing script tests.

```bash
set -euo pipefail
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
scripts/validate-runtime-contracts.sh
dodi-dev/scripts/tests/test-runtime-preflight.sh
dodi-dev/scripts/tests/test-worker-manifest-contract.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
```

Expected: focused success lines plus every existing `test-*.sh` final `... tests ok` line; all exit 0.

- [ ] **Step 2:** Run all repository validators.

```bash
set -euo pipefail
scripts/validate-plugin-metadata.sh
scripts/validate-phase-skills.sh
scripts/validate-ticket-comment-templates.sh
```

Expected: `plugin metadata ok: 0.16.0`, `phase skills ok`, `ticket comment templates ok`; all exit 0.

- [ ] **Step 3:** Run the final static contract battery.

```bash
set -euo pipefail
for file in dodi-dev/runtime/*.schema.json; do python3 -m json.tool "$file" >/dev/null; done
! rg -n '\$\{(CLAUDE|CODEX)_PLUGIN_ROOT\}/scripts/' dodi-dev/skills
test "$(rg -o '\$\{CLAUDE_PLUGIN_ROOT\}' dodi-dev/hooks/hooks.json | wc -l | tr -d ' ')" -eq 2
find dodi-dev/skills -type l -print | tee /tmp/dod-811-symlinks.txt
test ! -s /tmp/dod-811-symlinks.txt
test ! -e dodi-dev/skills/setup-dodi-dev/SKILL.md
! rg -n 'spawn_agent|wait_agent|close_agent' dodi-dev/scripts
test ! -e dodi-dev/runtime/codex-model-tiers.json
test ! -e dodi-dev/scripts/codex-capacity-classifier.sh
! rg -n 'gpt-5\.6-sol|gpt-5\.5|gpt-5\.6-terra|gpt-5\.6-luna' dodi-dev/runtime dodi-dev/skills
test ! -e scripts/validate-codex-compatibility.sh
test ! -e scripts/validate-codex-install.sh
test ! -d docs/guides
test ! -d docs/release
grep -qF 'ROOT_READY' dodi-dev/skills/epic-orchestrator/runtime-policy.md
grep -qF 'not workflow readiness' dodi-dev/skills/epic-orchestrator/runtime-policy.md
grep -qF 'dispatch-intent' dodi-dev/runtime/dispatch-manifest-record.schema.json
grep -qF 'UNSUPPORTED_RUNTIME' dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md
echo 'DOD-811 contract battery ok'
```

Expected: `DOD-811 contract battery ok`; exit 0.

- [ ] **Step 4:** Prove C2-C5 and immutable C1 surfaces were not changed.

```bash
set -euo pipefail
git diff --exit-code 1009fab -- \
  dodi-dev/hooks/hooks.json \
  dodi-dev/scripts/hook-gate2-guard.sh \
  dodi-dev/scripts/hook-require-model-pin.sh \
  dodi-dev/scripts/await-worker.sh \
  dodi-dev/scripts/linear-api.sh \
  dodi-dev/runtime/codex-model-tiers.json \
  dodi-dev/.claude-plugin/plugin.json \
  dodi-dev/.codex-plugin/plugin.json \
  .claude-plugin/marketplace.json \
  .agents/plugins/marketplace.json
test "$(git diff --name-only 1009fab -- dodi-dev/scripts | rg -v '^(dodi-dev/scripts/runtime-preflight\.sh|dodi-dev/scripts/reap-workers\.sh|dodi-dev/scripts/tests/)' | wc -l | tr -d ' ')" -eq 0
test "$(git diff --name-only 1009fab -- scripts | rg 'validate-codex-(compatibility|install)\\.sh' | wc -l | tr -d ' ')" -eq 0
test "$(git diff --name-only 1009fab -- docs | rg '^(docs/guides|docs/release)/' | wc -l | tr -d ' ')" -eq 0
echo 'C1 ownership audit ok'
```

Expected: `C1 ownership audit ok`; exit 0 and no diff output from immutable files.

- [ ] **Step 5:** Review the final diff for contract ownership and secrets.

Run:

```bash
set -euo pipefail
git diff --check
git status --short
git diff --stat 1009fab
git diff 1009fab -- dodi-dev/runtime dodi-dev/skills/epic-orchestrator/runtime-policy.md dodi-dev/skills/epic-orchestrator/runtime
```

Expected: `git diff --check` exits 0; status lists only the planned C1 files; the diff contains schemas, docs, fixtures, bootstrap/classifier/validators, and reference/root substitutions only. No credential value, production state file, Linear id, Slack channel, Codex model id, native worker implementation, setup/scheduler mutation, final release validator, or metadata version change appears.

- [ ] **Step 6:** Commit the final verification-only adjustments if Task 8 exposed any narrow C1 defect. If no adjustment was needed, do not create an empty commit.

```bash
git add <only-files-adjusted-to-fix-C1-validation>
git commit -m "fix: close DOD-811 runtime contract validation gaps"
```

## Handoff Assumptions And Blockers

- The approved DOD-811 spec has no open blocking question and the DOD-810 canon has no post-Gate-1 amendment that changes C1 ownership.
- The valid profile fixture follows the currently installed `0.16.0` metadata so cross-binding tests are truthful; C5 updates it atomically with the `0.17.0` release metadata.
- C2 must consume the schema's semantic tiers, requested fields, and attestation fields without redefining paths or manifest states.
- C3 must consume the worker operations, nonce/binding keys, terminal ordering, and uncertainty states; C1's explicit `UNSUPPORTED_RUNTIME` is the expected blocker until C3 lands.
- C4 must extend `runtime-preflight.sh` with `verify-profile` and implement setup/register/health/scheduling/escalation under the documented stable-lock and generation-binding postconditions; `ROOT_READY` alone never authorizes that work.
- C5 must consume these validators and fixtures for isolated/live release evidence and owns the synchronized `0.17.0` metadata bump.
- No implementation blocker is known. If a later child needs a competing field, path, hash rule, manifest state, or adapter ordering, stop and return to DOD-811 spec review or record a DOD-810 decision-register amendment.
