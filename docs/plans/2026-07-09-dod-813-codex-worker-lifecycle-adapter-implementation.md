# DOD-813 Codex Worker Lifecycle Adapter Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute Tasks 1-11 in order. DOD-813 is C3 only: do not implement model mapping/capacity/hooks/main-loop preflight, setup/profile/register/auth/scheduling/Gate 2/escalation/rollback, release validation/documentation, metadata changes, or Linear state while resolving a failure.

**Goal:** Implement a fail-closed Codex-native worker lifecycle adapter that durably records intent before spawn, normalizes native spawn/wait/close evidence, persists and tier-verifies terminal results before consumption, closes/reaps every accepted worker, and prevents successor writes until recovery or quarantine proves the worktree safe.

**Architecture:** Add one Bash 3.2-compatible command surface, `dodi-dev/scripts/codex-worker-adapter.sh`, with Python 3 standard-library internals for strict JSON parsing, canonical hashing, atomic mode-`0600` artifacts, manifest/ledger locking, git-baseline checks, and deterministic state transitions. The script emits compact native action JSON but never calls harness-native worker tools itself; the top-level session performs spawn/wait/query/enumerate/close and feeds an exact mode-`0600` observation file back into the adapter. Preserve DOD-811's manifest envelope, states, identity keys, profile-generation fields, and Claude boundary; consume DOD-812's `TIER_READY` and `verify-attestation` outcomes without duplicating tier selection or attestation comparison.

**Tech Stack:** Bash 3.2-compatible CLI wrappers, Python 3 standard library (`argparse`, `fcntl`, `hashlib`, `json`, `os`, `pathlib`, `secrets`, `subprocess`, `tempfile`) for deterministic mechanics, JSON Schema draft 2020-12 with test-only `jsonschema`, Git plumbing commands for mutable baselines, Markdown installed contracts, redacted runtime-versioned Codex Desktop/plugin fixtures, and existing repository validators.

**Source of truth:** `docs/specs/2026-07-09-codex-worker-lifecycle-adapter-design.md` at epic commit `522a42a` (approved DOD-813 spec), constrained by `docs/specs/2026-07-09-codex-runtime-compatibility-design.md` at Gate 1 commit `baf219a`, DOD-811's approved spec/plan and canonical artifacts at `978cad7`, and DOD-812's approved spec/plan through `5d084b5`. Workflow mode is waterfall. Implementation must start only after the landed C1 and C2 code is reconciled into the C3 worktree; record the exact landed pre-C3 commit as `DOD_812_BASE` and consume the landed contracts rather than recreating them from planning artifacts.

**Scope boundaries:**

- C3 owns `prepare-intent`, Codex `spawn`, `await`, `persist-result`, `close`, `reap-recover`, digest ready/claim/ack, native observation normalization, lifecycle/quarantine evidence, baseline comparison, shared reaper routing, C3 contract documentation, validators, deterministic tests, and the required live cross-session gate.
- The dispatcher must obtain a current C2 `TIER_READY` object before `prepare-intent`. C3 request evidence adds ticket, phase/gate, worktree, session/context, prompt hash, purpose, scope, and `context_inheritance` bindings; C3 does not require C2 to echo those C3-owned lifecycle fields and never selects a model/reasoning pair.
- C3 calls C2 `verify-attestation` only after the normalized result and observation artifacts are durable. `WORKER_TIER_VERIFIED` may continue to close/reap and digest readiness; `TIER_UNVERIFIED` maps to DOD-811 `attestation-invalid`; `SETUP_REQUIRED` remains a distinct setup/generation blocker and must never be relabeled as invalid effective attestation.
- Production C3 operations require C2's production same-invocation verifier path and therefore return `SETUP_REQUIRED` until C4 implements production `runtime-preflight.sh verify-profile`. Deterministic tests use only C2's fixture verifier; the live gate may use an explicitly trusted development installation without writing production setup state.
- C3 does not implement or modify C2 model-map data/schema, capacity signatures/classifier, model-pin hook/matcher, semantic tier/Fable policy, worker-tier comparison, or any main-loop preflight.
- C3 does not implement or modify C4 setup/profile/health/register writers, auth bridge, task/scheduler configuration, Gate 2, escalation delivery, quiescence/rollback engine, or production `verify-profile`.
- C3 does not add C5 install/release guides or validators, isolated-release matrices, marketplace/plugin metadata changes, or the `0.17.0` bump. Metadata stays synchronized at `0.16.0`.
- `dodi-dev/scripts/await-worker.sh` and its tests remain unchanged. Legacy unversioned manifests remain Claude-only; v1 Claude records retain transcript/output-file behavior. Codex never infers terminal state from transcript text, `output_file`, mtime, timeout, silence, process absence, or operator assertion.
- Preserve top-level-only dispatch, leaf workers, one lane in flight, one driver writer, serialized mutable implementers, existing retry/review/Fable routing, no silence-as-success, and the absolute prohibition on automated Gate 2 merge.

**File surface:**

- Create: `dodi-dev/scripts/codex-worker-adapter.sh`
- Create: `dodi-dev/scripts/tests/test-codex-worker-adapter.sh`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/runtime-version.txt`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/pre-c3-baseline.txt`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/schema/agent-tool.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/schema/wait-tool.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/schema/close-tool.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/schema/enumerate-tool.redacted.json`
- Create: runtime observations under `dodi-dev/scripts/tests/fixtures/codex-worker/spawn/`, `wait/`, `terminal/`, `close/`, `recovery/`, `conflict/`, and `malformed/` as enumerated in Tasks 2-7.
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/runtime-version.txt`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/native-tool-schemas.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/cross-session-observations.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/predecessor-session.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/successor-session.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/crash-seams.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/handoff-runbook.md`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/takeover-mode.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/evidence-hashes.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/live-gate-evidence.md`
- Modify: `dodi-dev/scripts/reap-workers.sh`
- Modify: `dodi-dev/scripts/tests/test-worker-manifest-contract.sh`
- Modify only as required for C3 Codex `data` branches: `dodi-dev/runtime/dispatch-manifest-record.schema.json`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Modify: `dodi-dev/skills/epic-orchestrator/execution-model.md`
- Modify: `dodi-dev/runtime/adapter-contracts.md`
- Modify: `scripts/validate-runtime-contracts.sh`
- Modify: `scripts/validate-phase-skills.sh`

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `canonical JSON/hash helpers; mode-0600 atomic artifacts; manifest/ledger lock-and-append; request evidence and mutable/read-only baselines; spawn/wait/terminal/close normalization; result/observation/tier-verification ordering; duplicate/conflict reconciliation; digest ready/claim/ack; quarantine/release; reap-recover classification and crash replay`
  - Reason: `C3 is a crash-sensitive state machine. Every transition and persistence seam must be deterministic from durable evidence, including failure injection, without relying on native runtime availability.`
  - Minimum assertions: `all approved states and outcomes pass; malformed/unknown versions, statuses, identities, hashes, paths, transitions, profile bindings, fixture shapes, and ledger chains fail closed; every artifact is canonical, content-addressed where required, mode 0600, atomically installed, hash-verified, and redacted; appends are complete JSON lines under one manifest-local exclusive lock; concurrent writers serialize; interrupted writes do not create false success; recovery chooses the same next safe action after every durable seam.`

- Integration: `required`
  - Scope: `DOD-811 manifest/schema and adapter contracts; DOD-812 TIER_READY/verify-attestation handoff; Codex routing in reap-workers.sh; installed runtime policy/execution links; shared validators; mixed legacy Claude/v1 Claude/v1 Codex manifests; ownership and metadata fences`
  - Reason: `The main regression risk is a locally correct adapter that weakens shared state ordering, bypasses C2 verification, routes Claude through Codex mechanics, or activates C4/C5 surfaces.`
  - Harness: `setup-required`
  - Minimum assertions: `TIER_READY is required before intent; request evidence binds ticket/gate/worktree/session/prompt to the current C2 proof; verify-attestation runs after result persistence; TIER_UNVERIFIED becomes attestation-invalid while SETUP_REQUIRED remains distinct; Codex reaping invokes reap-recover; both Claude branches remain unchanged; runtime validators require C3 files/order/fences; C4/C5 files and metadata changes remain absent; all repository shell tests and validators pass.`

- E2E: `required`
  - Scope: `supported Codex Desktop/plugin native spawn/wait/query/enumerate/close lifecycle; durable result and digest acceptance; mutable baseline attribution; context refresh and cross-session recovery; crash-before-binding recovery; no-write/slot-release proof; duplicate observations; valid and invalid C2 attestation; selected takeover mode`
  - Reason: `Fixtures cannot establish worker-id addressability across top-level sessions, runtime-owned descendant termination, close semantics, slot release, or the safe quarantine-only fallback on the supported current runtime.`
  - Harness: `setup-required`
  - Minimum assertions: `one read-only and one mutable disposable leaf complete through intent/result/attestation/close/reap/digest; a manifest-only resume handles the same id; a different top-level session tests predecessor enumeration/query/close; crash before id binding and after id return are recovered or quarantined without redispatch; running close proves when no-write and slot release hold; equivalent notification/wait evidence has one result hash; invalid attestation is never consumed; one addressable, parent-termination, or quarantine-only mode is selected and hash-bound.`

### Critical Flows

- `Top-level dispatcher -> C2 resolve-tier -> TIER_READY -> C3 prepare-intent -> mode-0600 request artifact -> clean mutable baseline or diagnosed read-only baseline -> flushed dispatch-intent -> native spawn action.`
- `Native spawn observation -> authoritative rejection, exact worker-id binding, or spawn-acceptance-unknown -> no replacement while acceptance is unknown -> enumerate/query by owning session + nonce or quarantine.`
- `Notification -> explicit same-id wait/query -> allowlisted terminal observation -> canonical result artifact -> observation artifact -> C2 verify-attestation -> tier-verification artifact -> terminal/attestation-invalid handling -> close -> reconciliation -> reaped/no-write proof.`
- `Verified completed digest -> digest-ready -> idempotency-keyed digest-claimed -> normal lane seam -> digest-acked; replay before ack returns the same claim, replay after ack returns no digest.`
- `Invalid/missing attestation or uncertain ownership -> close/reap first -> exact HEAD/index/status baseline comparison -> clean release only with no-write proof, otherwise writer-uncertain quarantine -> no same-worktree successor.`
- `Driver boot/resume -> reap-recover over all relevant manifests and worker-quarantine.jsonl -> resolve no-id intents -> query bound unreaped ids -> persist terminal evidence -> close/reap or quarantine -> QUIESCENT only when no possibly-writing identity remains.`

### Regression Surface

- `DOD-811 manifest absolute path, v1 envelope, state vocabulary, identity keys, profile-generation fields, baseline fields, hash/path validation, and adapter-specific terminal ordering.`
- `DOD-812 model map, exact native pins, capacity classifier, hook enforcement, same-invocation verifier, effective-tier comparison, context-inheritance rules, and named outcomes.`
- `Legacy v0.16 Claude and v1 Claude transcript/output-file classification, await-worker.sh, dual-wake behavior, and existing reaper output.`
- `Installed runtime-policy ownership, execution-model lane seams, one-writer/one-lane constraints, retry/Fable/review topology, catch attribution, CAPACITY_PARK, FABLE_MAKEUP, claims, and Gate 2.`
- `C4 setup/profile/health/register/auth/scheduler/escalation/rollback surfaces and C5 install/release surfaces remain unimplemented and unmodified.`
- `Plugin and marketplace metadata remains synchronized at 0.16.0; no secrets, raw prompts, digest bodies in diagnostics, credentials, arbitrary environment values, or unredacted native payloads enter fixtures or logs.`

### Commands

- Unit: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; dodi-dev/scripts/tests/test-codex-worker-adapter.sh`
- Integration: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; dodi-dev/scripts/tests/test-worker-manifest-contract.sh && scripts/validate-runtime-contracts.sh && scripts/validate-phase-skills.sh && scripts/validate-plugin-metadata.sh && scripts/validate-ticket-comment-templates.sh`
- E2E: `Run Tasks 10.1-10.10 through the supported Codex Desktop/plugin native worker tools, write only redacted evidence under dodi-dev/scripts/tests/fixtures/codex-worker/live/, validate each JSON/JSONL artifact, then rerun dodi-dev/scripts/tests/test-codex-worker-adapter.sh and scripts/validate-runtime-contracts.sh.`
- Broader regression: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done` plus the Task 11 syntax, ownership, metadata, and diff checks.

### Harness Requirements

- `bash 3.2+, python3, git, rg, jq, mktemp, stat, shasum or sha256sum, and a filesystem supporting advisory locks, atomic same-directory rename, chmod 0600, file fsync, and directory fsync.`
- `If absent, create the test-only schema environment exactly: python3 -m venv /tmp/dodi-runtime-contracts-venv && /tmp/dodi-runtime-contracts-venv/bin/python -m pip install --requirement requirements-dev.txt.`
- `Deterministic tests create isolated temporary git repositories/worktrees and use the C2 fixture verifier only. They must not require network, Linear, GitHub, Slack, production profiles, or native worker tools.`
- `The E2E gate requires the parent-approved supported Codex Desktop/plugin runtime, native multi-agent tools, an explicitly trusted development installation containing landed C1/C2/C3 code, two disposable worktrees, and at least two top-level tasks/sessions. C4 production setup is not created by this plan.`
- `All production adapter code uses Python 3 standard library only. jsonschema remains test/validator-only.`

### Non-Required Rationale

- Unit: `not applicable (required).`
- Integration: `not applicable (required).`
- E2E: `not applicable (required). The live cross-session gate is an explicit DOD-813 completion condition; discovery, in-session happy-path evidence, deterministic fixtures, elapsed time, or an operator assertion cannot replace it.`

### Verification Rules

- Missing deterministic harness is not a skip reason; set it up or report a concrete blocker.
- Missing supported Codex live harness, cross-session addressability evidence, authoritative parent-termination evidence, or a complete fail-closed quarantine proof blocks DOD-813 completion. Do not narrow the support claim or substitute Claude transcript mechanics.
- A live unknown/unsupported native identity, status, close, enumeration, or no-write shape blocks implementation until the spec/epic decision lane accepts it; do not guess from text, timing, absence, or process state.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a DOD-811 manifest/schema conflict, DOD-812 handoff mismatch, or C3/C4 ownership ambiguity, demote the ticket to the spec/epic decision lane.
- A clean unit/integration run does not complete C3 without Task 10 live evidence. A failed or ambiguous live gate leaves the ticket blocked and scheduled Codex delivery disabled.

---

## Tasks

### Task 1: Reconcile landed C1/C2 contracts and freeze the C3 baseline

**Files:**
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/pre-c3-baseline.txt`
- Inspect only: `dodi-dev/runtime/dispatch-manifest-record.schema.json`
- Inspect only: `dodi-dev/runtime/adapter-contracts.md`
- Inspect only: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Inspect only: `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md`
- Inspect only: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`
- Inspect only: `dodi-dev/scripts/codex-tier-adapter.sh`
- Inspect only: `dodi-dev/scripts/tests/fixtures/codex-tier/`
- Inspect only: `dodi-dev/scripts/reap-workers.sh`

- [ ] **Step 1:** Confirm DOD-811 and DOD-812 implementation commits are present before the first C3 code edit. DOD-811/DOD-812 plan commits (`978cad7` and `5d084b5`) must be ancestors, and landed C1/C2 implementation files must exist (`runtime-preflight.sh`, runtime schemas, `codex-tier-adapter.sh`, `codex-capacity-classifier.sh`, `codex-model-tiers.json`, C2 tests/fixtures). If either implementation is absent, stop; waterfall mode does not permit implementing against plans alone.
- [ ] **Step 2:** Compare the landed manifest envelope/states/keys and C2 CLI/output shapes against the approved C3 spec. Required handoff is: current `TIER_READY` before intent; C3-owned request binding for ticket/gate/worktree/session/prompt; result persistence before `verify-attestation`; exact `WORKER_TIER_VERIFIED`, `TIER_UNVERIFIED`, and `SETUP_REQUIRED` outcomes. A conflicting field, path, state, or ordering is a spec/decision-register blocker, not a local compatibility shim.
- [ ] **Step 3:** Prove the pre-C3 fence is intact: Codex lifecycle remains `UNSUPPORTED_RUNTIME`, production C2 calls without C4 `verify-profile` return `SETUP_REQUIRED`, Claude tests pass, and metadata is `0.16.0` in all envelopes.
- [ ] **Step 4:** Persist and verify the baseline. Write `dodi-dev/scripts/tests/fixtures/codex-worker/pre-c3-baseline.txt` before any other C3 edit; it must contain `DOD_812_BASE=<current HEAD>`, the latest commit touching every required C1/C2 implementation surface named below, and the verification command exits. Task 11 must read this file rather than relying on a shell variable.

Run:

```bash
set +e
git status --short; status_exit=$?
test -f dodi-dev/scripts/runtime-preflight.sh; runtime_preflight_exists=$?
test -f dodi-dev/runtime/runtime-profile.schema.json; runtime_profile_schema_exists=$?
test -f dodi-dev/runtime/runtime-health.schema.json; runtime_health_schema_exists=$?
test -f dodi-dev/runtime/runtime-register-record.schema.json; runtime_register_schema_exists=$?
test -f dodi-dev/runtime/dispatch-manifest-record.schema.json; dispatch_manifest_schema_exists=$?
test -f dodi-dev/runtime/adapter-contracts.md; adapter_contracts_exists=$?
test -f dodi-dev/skills/epic-orchestrator/runtime-policy.md; runtime_policy_exists=$?
test -f dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md; worker_contract_exists=$?
test -f dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md; codex_worker_doc_exists=$?
test -f dodi-dev/scripts/codex-tier-adapter.sh; codex_tier_adapter_exists=$?
test -f dodi-dev/scripts/codex-capacity-classifier.sh; codex_capacity_classifier_exists=$?
test -f dodi-dev/runtime/codex-model-tiers.schema.json; codex_model_schema_exists=$?
test -f dodi-dev/runtime/codex-model-tiers.json; codex_model_map_exists=$?
test -d dodi-dev/scripts/tests/fixtures/codex-tier; codex_tier_fixtures_exist=$?
git merge-base --is-ancestor 978cad7 HEAD; dod811_ancestor_exit=$?
git merge-base --is-ancestor 5d084b5 HEAD; dod812_ancestor_exit=$?
rg -n 'TIER_READY|WORKER_TIER_VERIFIED|TIER_UNVERIFIED|SETUP_REQUIRED' dodi-dev/scripts/codex-tier-adapter.sh; tier_outcomes_exit=$?
rg -n 'UNSUPPORTED_RUNTIME' dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md dodi-dev/scripts/reap-workers.sh; unsupported_fence_exit=$?
set -e
for exit_name in status_exit runtime_preflight_exists runtime_profile_schema_exists runtime_health_schema_exists runtime_register_schema_exists dispatch_manifest_schema_exists adapter_contracts_exists runtime_policy_exists worker_contract_exists codex_worker_doc_exists codex_tier_adapter_exists codex_capacity_classifier_exists codex_model_schema_exists codex_model_map_exists codex_tier_fixtures_exist dod811_ancestor_exit dod812_ancestor_exit tier_outcomes_exit unsupported_fence_exit; do
  eval "test \"\${$exit_name}\" = 0"
done
mkdir -p dodi-dev/scripts/tests/fixtures/codex-worker
{
  printf 'DOD_812_BASE=%s\n' "$(git rev-parse HEAD)"
  printf 'head_subject=%s\n' "$(git log -1 --format=%s)"
  printf 'status_exit=%s\n' "$status_exit"
  printf 'runtime_preflight_exists=%s\n' "$runtime_preflight_exists"
  printf 'runtime_profile_schema_exists=%s\n' "$runtime_profile_schema_exists"
  printf 'runtime_health_schema_exists=%s\n' "$runtime_health_schema_exists"
  printf 'runtime_register_schema_exists=%s\n' "$runtime_register_schema_exists"
  printf 'dispatch_manifest_schema_exists=%s\n' "$dispatch_manifest_schema_exists"
  printf 'adapter_contracts_exists=%s\n' "$adapter_contracts_exists"
  printf 'runtime_policy_exists=%s\n' "$runtime_policy_exists"
  printf 'worker_contract_exists=%s\n' "$worker_contract_exists"
  printf 'codex_worker_doc_exists=%s\n' "$codex_worker_doc_exists"
  printf 'codex_tier_adapter_exists=%s\n' "$codex_tier_adapter_exists"
  printf 'codex_capacity_classifier_exists=%s\n' "$codex_capacity_classifier_exists"
  printf 'codex_model_schema_exists=%s\n' "$codex_model_schema_exists"
  printf 'codex_model_map_exists=%s\n' "$codex_model_map_exists"
  printf 'codex_tier_fixtures_exist=%s\n' "$codex_tier_fixtures_exist"
  printf 'dod811_ancestor_exit=%s\n' "$dod811_ancestor_exit"
  printf 'dod812_ancestor_exit=%s\n' "$dod812_ancestor_exit"
  printf 'tier_outcomes_exit=%s\n' "$tier_outcomes_exit"
  printf 'unsupported_fence_exit=%s\n' "$unsupported_fence_exit"
  printf 'runtime_preflight_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/scripts/runtime-preflight.sh)"
  printf 'runtime_profile_schema_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/runtime/runtime-profile.schema.json)"
  printf 'runtime_health_schema_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/runtime/runtime-health.schema.json)"
  printf 'runtime_register_schema_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/runtime/runtime-register-record.schema.json)"
  printf 'dispatch_manifest_schema_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/runtime/dispatch-manifest-record.schema.json)"
  printf 'adapter_contracts_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/runtime/adapter-contracts.md)"
  printf 'runtime_policy_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/skills/epic-orchestrator/runtime-policy.md)"
  printf 'worker_contract_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md)"
  printf 'codex_worker_doc_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md)"
  printf 'codex_tier_adapter_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/scripts/codex-tier-adapter.sh)"
  printf 'codex_capacity_classifier_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/scripts/codex-capacity-classifier.sh)"
  printf 'codex_model_schema_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/runtime/codex-model-tiers.schema.json)"
  printf 'codex_model_map_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/runtime/codex-model-tiers.json)"
  printf 'codex_tier_fixtures_commit=%s\n' "$(git log -1 --format=%H -- dodi-dev/scripts/tests/fixtures/codex-tier)"
} > dodi-dev/scripts/tests/fixtures/codex-worker/pre-c3-baseline.txt
rg -n '^DOD_812_BASE=[0-9a-f]{40}$' dodi-dev/scripts/tests/fixtures/codex-worker/pre-c3-baseline.txt
! rg -n '=(1|2|3|4|5|6|7|8|9)$' dodi-dev/scripts/tests/fixtures/codex-worker/pre-c3-baseline.txt
scripts/validate-plugin-metadata.sh
```

Expected: clean status before C3 edits except the newly created baseline file after the write; both ancestor checks exit `0`; required landed C1/C2 implementation files/fixture directories exist; all four C2 outcomes exist; the C1 lifecycle fence is still visible; baseline file contains a 40-character `DOD_812_BASE`, commit ids for every required C1/C2 surface, and only zero-valued verification exits; metadata validator exits `0` at `0.16.0`.

### Task 2: Pin runtime-versioned native lifecycle schemas and deterministic observations

**Files:**
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/runtime-version.txt`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/schema/agent-tool.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/schema/wait-tool.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/schema/close-tool.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/schema/enumerate-tool.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/spawn/accepted.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/spawn/rejected.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/spawn/accepted-without-id.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/spawn/transport-timeout.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/wait/queued.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/wait/running.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/wait/deadline-running.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/wait/tool-timeout.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/wait/transport-error.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/wait/unknown-worker.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/terminal/completed.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/terminal/completed-missing-digest.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/terminal/errored.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/terminal/interrupted.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/terminal/shutdown.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/close/closed.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/close/running.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/close/pending.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/close/not-found.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/close/transport-error.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/recovery/enumeration-one-match.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/recovery/enumeration-zero-match.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/recovery/enumeration-multiple-match.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/recovery/parent-termination.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/conflict/equivalent-notification.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/conflict/equivalent-wait.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/conflict/different-result.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/malformed/unknown-runtime.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/malformed/unknown-status.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/malformed/identity-mismatch.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/malformed/raw-secret.invalid.json`

- [ ] **Step 1:** Capture only redacted shapes observed from the parent-supported current Codex Desktop/plugin runtime. Preserve native field names, nullability, status/acceptance meanings, identity locations, and runtime version; replace ids, timestamps, text, and payloads with stable non-secret fixture values. Do not infer a schema from `/opt/homebrew/bin/codex` or prose.
- [ ] **Step 2:** Keep one semantic condition per fixture. Every valid observation includes runtime version, source operation, owning session/context, dispatch nonce where the runtime carries it, and worker id where available. Invalid fixtures contain exactly one named defect.
- [ ] **Step 3:** Add no production normalization yet. If native spawn cannot carry both the C2 pin pair and `context_inheritance`, if a stable worker identity cannot be observed, or if tool status meanings cannot be allowlisted, stop with a concrete DOD-813 blocker.
- [ ] **Step 4:** Validate fixture hygiene.

Run:

```bash
find dodi-dev/scripts/tests/fixtures/codex-worker -name '*.json' -print0 | xargs -0 -n1 python3 -m json.tool >/dev/null
rg -n 'prompt|authorization|token|secret|cookie|credential' dodi-dev/scripts/tests/fixtures/codex-worker
```

Expected: every JSON file parses; the redaction grep returns no raw prompt/credential fields except deliberate key names in `malformed/raw-secret.invalid.json` used to prove rejection.

### Task 3: Build locked persistence primitives and pre-spawn intent

**Files:**
- Create: `dodi-dev/scripts/codex-worker-adapter.sh`
- Create: `dodi-dev/scripts/tests/test-codex-worker-adapter.sh`

- [ ] **Step 1:** Create an executable Bash wrapper with `set -euo pipefail` that dispatches to Python 3 standard-library code. Expose exactly `prepare-intent`, `spawn --phase request|observe`, `await --phase request|observe`, `persist-result`, `close --phase request|observe`, `reap-recover`, and `digest --phase ready|claim|ack`. Successful stdout is one compact JSON object; diagnostics are stderr-only; exits are `0` named outcome, `2` malformed input/dependency, `3` `SETUP_REQUIRED`, `4` unresolved/unsafe lifecycle, and `5` safe-output/persistence failure.
- [ ] **Step 2:** Implement canonical JSON as UTF-8, sorted keys, compact separators, no NaN, trailing newline only for JSONL. Implement SHA-256 helpers, absolute-path checks, strict fixture/runtime-version dispatch, same-directory temporary writes, parse-back, file `fsync`, `chmod 0600`, atomic rename, directory `fsync`, filename/content-hash verification, and byte-identical idempotent reuse. Never emit partial stdout.
- [ ] **Step 3:** Use one manifest-local advisory lock file derived from the absolute manifest path and Python `fcntl.flock(LOCK_EX)`. Under that lock, validate the complete manifest and `<worktree>/.dodi/worker-quarantine.jsonl`, evaluate the transition against the latest identity chain, append one complete schema-valid JSON line, flush/file-`fsync`, directory-`fsync` when created, then unlock. The manifest and ledger must use this same lock; no read-decide-append may occur outside it.
- [ ] **Step 4:** Implement `prepare-intent` to require and verify a current C2 `TIER_READY` evidence file/hash, semantic tier, requested model/reasoning, profile generation/hash, repo, operation nonce, and verifier binding. Add C3 ticket, gate/phase, absolute worktree, owning session/context, purpose, declared scope (`mutable|read-only`), prompt SHA-256, and `context_inheritance` (`fresh-required|may-inherit|same-context-required`). Store no prompt body.
- [ ] **Step 5:** Generate a cryptographically random nonce and atomically write `<worktree>/.dodi/workers/<session-id>/requests/<dispatch-nonce>.json` mode `0600` before appending DOD-811 `dispatch-intent`. Set manifest `prompt_sha256` to the canonical request/input evidence hash so the deterministic request path is recoverable without adding a manifest field.
- [ ] **Step 6:** For `mutable`, require absolute lane-owned worktree, 40-character `git rev-parse HEAD`, empty exact bytes from `git status --porcelain=v1 -z --untracked-files=all`, `git write-tree == <baseline_head>^{tree}`, and no unresolved intent/unreaped worker/active quarantine/foreign live claim. Hash exact porcelain bytes. For `read-only`, record `read_only_baseline: true` and diagnostic HEAD/status when available without weakening an owning playbook's cleanliness rule.
- [ ] **Step 7:** Add failure injection around temporary write, parse-back, chmod, file fsync, rename, directory fsync, hash verification, manifest lock, schema validation, append, and append fsync. Add concurrent-process tests proving one complete sequence-ordered JSON line per successful writer and no false success on interrupted append.
- [ ] **Step 8:** Verify.

Run:

```bash
chmod +x dodi-dev/scripts/codex-worker-adapter.sh dodi-dev/scripts/tests/test-codex-worker-adapter.sh
bash -n dodi-dev/scripts/codex-worker-adapter.sh dodi-dev/scripts/tests/test-codex-worker-adapter.sh
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group persistence
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group prepare-intent
```

Expected: each group ends `codex worker adapter <group> tests ok`; exit `0`. Dirty worktree, stale C2 proof, duplicate nonce, unresolved predecessor, active quarantine, malformed hashes, and persistence failures all fail with the expected nonzero class and no spawn action.

### Task 4: Implement spawn and await request/observation normalization

**Files:**
- Modify: `dodi-dev/scripts/codex-worker-adapter.sh`
- Modify: `dodi-dev/scripts/tests/test-codex-worker-adapter.sh`
- Test: `dodi-dev/scripts/tests/fixtures/codex-worker/spawn/*.json`
- Test: `dodi-dev/scripts/tests/fixtures/codex-worker/wait/*.json`
- Test: `dodi-dev/scripts/tests/fixtures/codex-worker/malformed/*.json`

- [ ] **Step 1:** Make `spawn --phase request` require one flushed intent/request pair and no later spawn transition. Emit one redacted native action containing the exact C2 model/reasoning pins, explicit `context_inheritance`, session/context, nonce metadata, worker prompt header correlation, purpose/scope, and prompt/input reference. Do not include the raw prompt in diagnostics or persisted action output.
- [ ] **Step 2:** Make `spawn --phase observe` accept only the runtime-versioned fixture shape and normalize exactly: authoritative rejection -> `spawn-rejected`; accepted with one stable id -> `dispatched`; timeout/loss or accepted-without-id -> `spawn-acceptance-unknown`; identity collision -> `evidence-conflict` then `writer-uncertain` plus quarantine. Preserve C2 capacity evidence for caller routing but do not classify it locally.
- [ ] **Step 3:** On id-return plus failed `dispatched` append, return an emergency-close action for that retained id before ordinary bookkeeping. Durable recovery must later retain id-binding failure, close observation, any terminal evidence, and quarantine. Never append `reaped` or launch a replacement without a complete bound/result chain.
- [ ] **Step 4:** Make `await --phase request` require a durable bound id and emit explicit same-id wait/query action. Correlate completion notifications by worker id and nonce, but require a subsequent explicit wait/query before terminal consumption.
- [ ] **Step 5:** Make `await --phase observe` normalize allowlisted queued/running and authoritative wait-deadline-with-running to `waiting`; local/tool timeout without status to `wait-error/wait-timeout`; transport/malformed/unknown status to `wait-error`; unknown-worker to close/recovery; terminal only to `completed|errored|interrupted|shutdown`. No timeout/error authorizes redispatch.
- [ ] **Step 6:** Verify.

Run:

```bash
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group spawn
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group await
```

Expected: both groups end in `tests ok`; accepted ids bind exactly once; unknown acceptance remains unresolved; wait expiry remains nonterminal; malformed/unknown evidence exits `4`; no test launches a successor for an unresolved nonce.

### Task 5: Persist result, observation, and tier-verification evidence in binding order

**Files:**
- Modify: `dodi-dev/scripts/codex-worker-adapter.sh`
- Modify: `dodi-dev/scripts/tests/test-codex-worker-adapter.sh`
- Test: `dodi-dev/scripts/tests/fixtures/codex-worker/terminal/*.json`
- Test: `dodi-dev/scripts/tests/fixtures/codex-worker/conflict/*.json`
- Modify only if the landed C1 schema cannot encode approved C3 evidence: `dodi-dev/runtime/dispatch-manifest-record.schema.json`

- [ ] **Step 1:** Normalize terminal identity fields into `<worktree>/.dodi/workers/<session-id>/<worker-id>/result-<sha256>.json`: schema/runtime version, session/context/nonce/worker, terminal status and runtime-attested time, requested tier/model/reasoning and request hash, runtime-attested effective model/reasoning/context/inheritance when present, and complete compact digest or normalized error/missing-digest marker. Exclude observation source/arrival time/native payload hash so equivalent observations share one result hash.
- [ ] **Step 2:** Persist each observation separately as sibling `observation-<sha256>.json` with source (`notification|wait|close|recovery-query`), redacted native observation hash, arrival timestamp, runtime-versioned raw status envelope, result hash, and exact identity. Apply the Task 3 atomic mode-`0600` content-addressed rules to result and observation artifacts.
- [ ] **Step 3:** After both artifacts are durable, invoke the landed C2 `codex-tier-adapter.sh verify-attestation` using durable request evidence plus an attestation projection derived from the result, current profile, `--invoke-verifier`, repo, operation nonce, and gate/context arguments. Persist the exact output as `tier-verification-<sha256>.json` with the same atomic/hash rules. Do not implement effective-pair/context comparison in C3.
- [ ] **Step 4:** Enforce the terminal order: result -> observation -> C2 verify-attestation -> tier-verification artifact -> terminal manifest append referencing absolute paths/hashes. `WORKER_TIER_VERIFIED` permits verified terminal handling; `TIER_UNVERIFIED` appends `attestation-invalid` with absent evidence represented as null/absent, never requested-as-effective; `SETUP_REQUIRED` stores evidence, returns exit `3`, closes/reaps when safely possible, and does not append `attestation-invalid`.
- [ ] **Step 5:** Keep completed-with-missing-digest, errored, interrupted, and shutdown evidence complete and durable, but mark them non-consumable. Artifact or terminal-append persistence failure cannot advance PM/git, append false `reaped`, release mutable scope, or return a digest.
- [ ] **Step 6:** Treat exact result hash + terminal state + worker identity as equivalence. Equivalent observations add bookkeeping only. Different state/hash/digest/error/effective attestation/tier outcome/identity appends `evidence-conflict`, retains every candidate, and consumes none. Resolve only after two authoritative same-id re-reads plus explicit close agree byte-for-byte with one candidate; no majority/newest/operator choice.
- [ ] **Step 7:** Add crash injection after native terminal observation, result artifact, observation artifact, C2 result, tier artifact, and terminal append. A fresh invocation must select the same next safe action and never regenerate a conflicting artifact.
- [ ] **Step 8:** Verify.

Run:

```bash
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group terminal
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group attestation
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group conflict
```

Expected: all groups end `tests ok`; equivalent notification/wait fixtures produce one canonical result hash and distinct observation hashes; `TIER_UNVERIFIED` and `SETUP_REQUIRED` remain observably distinct; no digest is returned before verification/close/reap.

### Task 6: Implement close, reap, baseline comparison, quarantine, and digest replay safety

**Files:**
- Modify: `dodi-dev/scripts/codex-worker-adapter.sh`
- Modify: `dodi-dev/scripts/tests/test-codex-worker-adapter.sh`
- Test: `dodi-dev/scripts/tests/fixtures/codex-worker/close/*.json`

- [ ] **Step 1:** Append `close-requested` before each ordinary native close action. Normalize authoritative closed plus terminal/no-write proof to `closed`; running/pending/asynchronous acceptance to bounded same-id query; not-found to proof only when the selected live mode explicitly authorizes that exact identity response; transport/unsupported/malformed/unqueryable to `writer-uncertain` and quarantine. Preserve the emergency-close exception from Task 4.
- [ ] **Step 2:** Append `reaped` only after durable terminal/result/tier evidence as applicable, authoritative close/no-write proof, final same-id reconciliation, and runtime slot-release proof. A failed reap append remains unsafe and quarantined; emergency close without a complete chain is never reaped.
- [ ] **Step 3:** Implement exact mutable baseline comparison after close/reap: current HEAD equals `baseline_head`; current index tree equals `baseline_head^{tree}`; exact porcelain-v1-z hash equals `baseline_status_sha256`. Any difference, command failure, or possible writer activates quarantine. A read-only worker that mutates is treated as mutable contamination.
- [ ] **Step 4:** Append lock-serialized events to `<worktree>/.dodi/worker-quarantine.jsonl`: `quarantine-activated`, `quarantine-release-proved`, `digest-ready`, `digest-claimed`, `digest-acked`. Key by manifest/session/nonce and worker id when known; include reason, worktree, baseline, evidence paths/hashes, actor predecessor/successor identities, and timestamp. This ledger is supporting safety evidence, not a second manifest or PM/register authority.
- [ ] **Step 5:** Block every dispatch, including read-only, while quarantine is active. Release baseline-clean reuse only after exact worker terminal/closed/reaped/conflict-resolved proof or selected runtime-owned parent-termination proof. Contaminated worktrees release only for manual disposition/removal after no-write proof; successors use a fresh worktree at `baseline_head` and copy nothing. Human assertion or elapsed time never releases.
- [ ] **Step 6:** Implement `digest --phase ready|claim|ack`. `ready` requires one verified completed digest after close/reap; `claim` derives/validates the key from ticket, phase/gate, worker id, result hash, expected worktree HEAD, and next durable lane seam, appends one claim, and returns the digest only for that key; replay returns the same claim/digest; a different key conflicts until ack; `ack` requires seam evidence hash and prevents later return.
- [ ] **Step 7:** Add crash tests for close-before-reap, reap-before-ready, ready-before-claim, claim-before-ack, and post-ack replay. Add invalid-attestation cases for unchanged baseline, changed HEAD, changed index tree, tracked/untracked status delta, baseline command failure, and fresh replacement requirement.
- [ ] **Step 8:** Verify.

Run:

```bash
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group close-reap
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group quarantine
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group digest
```

Expected: all groups end `tests ok`; no `reaped` without no-write/slot proof; active quarantine denies every dispatch; same claim replays exactly; acked digest is not returned; contaminated output is never promoted or reused.

### Task 7: Implement manifest-only recovery and shared Codex reaper routing

**Files:**
- Modify: `dodi-dev/scripts/codex-worker-adapter.sh`
- Modify: `dodi-dev/scripts/reap-workers.sh`
- Modify: `dodi-dev/scripts/tests/test-codex-worker-adapter.sh`
- Modify: `dodi-dev/scripts/tests/test-worker-manifest-contract.sh`
- Test: `dodi-dev/scripts/tests/fixtures/codex-worker/recovery/*.json`

- [ ] **Step 1:** Implement `reap-recover` to read and validate all relevant manifests and quarantine records at driver boot/resume and before mutable dispatch. Return ordered native actions: resolve no-id intents by exact owning session+nonce enumeration; query every bound unreaped id; persist terminal observations; close/reap terminal/invalid/abandoned workers; activate/preserve quarantine for ambiguity; return `QUIESCENT` only when no unresolved possibly-writing identity remains.
- [ ] **Step 2:** Permit exactly one enumeration match to bind only when both session and nonce agree. Zero matches are safe only with selected live-mode runtime-owned parent-termination proof covering the exact predecessor/context/nonce/descendants/worktree. Multiple matches, incomplete enumeration, unrecognized evidence, unqueryable worker, or unresolved no-id intent remains `writer-uncertain`.
- [ ] **Step 3:** Preserve predecessor manifest ownership fields and append recovery observations under that worker identity; record the successor actor only in C3 ledger evidence. Never rewrite history, fabricate terminal/reap, or dispatch beside a predecessor that may write.
- [ ] **Step 4:** Change only the v1 Codex branch in `reap-workers.sh`: resolve the concrete plugin root using landed runtime bootstrap rules, invoke `codex-worker-adapter.sh reap-recover` with absolute manifest/worktree/session evidence, and propagate its compact JSON/exit class. Preserve the legacy unversioned Claude and v1 Claude branches, transcript logic, diagnostics, and exit behavior.
- [ ] **Step 5:** Replace C1's v1 Codex `UNSUPPORTED_RUNTIME` expectations in `test-worker-manifest-contract.sh` with supported adapter/recovery fixtures. Keep all legacy/v1 Claude fixture assertions and add mixed-manifest tests proving no Codex transcript inference and no Claude routing change.
- [ ] **Step 6:** Run recovery from a fresh process after every durable seam: request, intent, native spawn response before binding, binding, terminal observation before result, result before tier verification, tier artifact before terminal, terminal before close, close before reap, reap before ready, ready before claim, claim before ack. Assert the same next safe action without in-memory state.
- [ ] **Step 7:** Verify.

Run:

```bash
bash -n dodi-dev/scripts/reap-workers.sh dodi-dev/scripts/tests/test-worker-manifest-contract.sh
dodi-dev/scripts/tests/test-codex-worker-adapter.sh --group recovery
dodi-dev/scripts/tests/test-worker-manifest-contract.sh
```

Expected: recovery group ends `tests ok`; manifest contract final line is `worker manifest contract tests ok`; all exit `0`; no `UNSUPPORTED_RUNTIME` remains for v1 Codex lifecycle, while both Claude paths remain green.

### Task 8: Update installed lifecycle contracts without duplicating policy or mechanics

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Modify: `dodi-dev/skills/epic-orchestrator/execution-model.md`
- Modify: `dodi-dev/runtime/adapter-contracts.md`
- Modify only if required: `dodi-dev/runtime/dispatch-manifest-record.schema.json`

- [ ] **Step 1:** Replace the C1 Codex lifecycle `UNSUPPORTED_RUNTIME` fence in `runtime/codex-worker-adapter.md` with the composite request/observe protocol, operation commands, action/observation ownership split, exact artifact paths, terminal ordering, named outcomes/exit classes, recovery/quarantine rules, digest protocol, Claude exclusions, and the three allowed takeover modes (`addressable`, `parent-termination`, `quarantine-only`) as unselected alternatives. Do not claim a selected live mode yet; Task 10 records the selected mode after evidence exists. Retain links to C2 operations rather than restating model map/capacity/attestation policy.
- [ ] **Step 2:** Mark `prepare-intent`, Codex `spawn`, `await`, `persist-result`, `close`, and `reap/recover` implemented in `worker-adapter-contract.md`. Keep DOD-811 operations/states/keys unchanged; add concise links for artifact-before-terminal, `TIER_UNVERIFIED` versus `SETUP_REQUIRED`, quarantine, and ready/claim/ack.
- [ ] **Step 3:** In `runtime-policy.md`, select the Codex lifecycle adapter by verified runtime context and link its C3 mechanics. In `execution-model.md`, replace only the Codex unsupported branch with native action/observe await/close/reap selection while preserving Claude dual wake, lane seams, seriality, refresh behavior, retry/Fable policy, and Gate 2.
- [ ] **Step 4:** Update `dodi-dev/runtime/adapter-contracts.md` with deterministic request/result/observation/tier-verification/quarantine paths, lock ownership, C2 result handoff, and C4 quiescence consumer output. Do not add profile/register authority or a second state machine.
- [ ] **Step 5:** Refine `dispatch-manifest-record.schema.json` only if landed C1 cannot represent approved absent attestation, observation path/hash arrays, or result/tier-verification references under state-specific Codex `data`. Preserve schema v1, envelope, path, state, identity, profile, baseline, and hash meanings. Requested values must never satisfy effective fields.
- [ ] **Step 6:** Verify references and ownership.

Run:

```bash
rg -n 'prepare-intent|persist-result|reap-recover|digest-ready|worker-quarantine.jsonl' dodi-dev/skills/epic-orchestrator/runtime dodi-dev/runtime/adapter-contracts.md
rg -n 'output_file|stop_reason:end_turn|transcript' dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md
rg -n 'model map|capacity signature|setup-dodi-dev|Gate 2|Slack|0.17.0' dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md
```

Expected: required C3 references exist; Codex document contains no Claude evidence assumptions; any scope-term matches are explicit exclusions/links, not C3-owned implementations; the document states that live mode is pending until Task 10 rather than fabricating a selected mode.

### Task 9: Register C3 contracts and deterministic validation

**Files:**
- Modify: `scripts/validate-runtime-contracts.sh`
- Modify: `scripts/validate-phase-skills.sh`
- Modify: `dodi-dev/scripts/tests/test-codex-worker-adapter.sh`

- [ ] **Step 1:** Extend `validate-runtime-contracts.sh` with two modes. Default/pre-live mode validates deterministic C3 fixtures and permits the live directory to be absent or explicitly pending. `--require-codex-worker-live` validates the live-evidence files created by Task 10 and requires exactly one selected takeover mode. Both modes validate manifest and quarantine JSONL chains, absolute evidence paths, canonical lowercase SHA-256, mode/path conventions, state order, pre/post-binding identity, result->observation->tier->terminal ordering, no digest before reaped, no release without proof, and unknown schema/runtime/state failure.
- [ ] **Step 2:** Add ownership fences: C3 files may reference but not define model pairs, capacity signatures, profile/register writers, scheduler/Gate 2/Slack/rollback, release validators/docs, production verifier bypasses, or metadata `0.17.0`; `await-worker.sh` must remain outside the C3 diff; test verifier references remain under tests only.
- [ ] **Step 3:** Extend `validate-phase-skills.sh` to require executable `codex-worker-adapter.sh` and `test-codex-worker-adapter.sh`, syntax-check both, and require installed adapter/runtime/execution references. Keep it dependency-light; the runtime-contract validator owns `jsonschema` setup reporting.
- [ ] **Step 4:** Make the full deterministic test default run every group and end with exactly `codex worker adapter tests ok`. It must cover all spec-listed normal, malformed, crash, duplicate/conflict, attestation, close/reap, baseline, quarantine, recovery, mixed-runtime, redaction, permissions, canonicalization, lock, and append cases.
- [ ] **Step 5:** Verify.

Run:

```bash
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
dodi-dev/scripts/tests/test-codex-worker-adapter.sh
scripts/validate-runtime-contracts.sh
scripts/validate-phase-skills.sh
```

Expected: focused test ends `codex worker adapter tests ok`; both validators exit `0` in pre-live mode without requiring Task 10 artifacts; missing harness reports the exact venv setup command rather than skipping.

### Task 10: Execute and retain the live Codex cross-session gate

**Files:**
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/runtime-version.txt`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/native-tool-schemas.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/cross-session-observations.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/predecessor-session.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/successor-session.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/crash-seams.redacted.jsonl`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/handoff-runbook.md`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/takeover-mode.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/evidence-hashes.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-worker/live/live-gate-evidence.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md` (record selected mode only)

- [ ] **Step 1:** Create `handoff-runbook.md` before live actions. It must name the disposable repo/worktree paths, manifest path, adapter command template, redaction rules, and the exact native action families the top-level session will perform: spawn, wait/query by id, enumerate descendants by owning session+nonce, close by id, query after close, and slot/no-write verification. If the runtime lacks an authoritative action family, record that absence in the runbook and route the corresponding scenario to quarantine-only.
- [ ] **Step 2:** In the predecessor top-level task/session, write `predecessor-session.redacted.json` before spawning any worker. Required fields: runtime version, redacted session/context id, worktree path hash, manifest path hash, adapter build commit, start timestamp, and the redacted native tool schema hashes. Then spawn a disposable read-only leaf only after durable intent. Prove native completion, explicit wait/query, normalized result/observation persistence, C2 verification, close, reap, digest claim, lane-seam simulation, and ack.
- [ ] **Step 3:** Repeat in a disposable mutable clean worktree. Prove recorded HEAD/index/status baseline remains attributable to the exact intent and that no output is consumed before attestation/close/reap. Append every native action/observation as one redacted JSON line to `cross-session-observations.redacted.jsonl` with `scenario`, `action_id`, `native_action`, `input_sha256`, `output_sha256`, `authority_predicate`, and `adapter_transition`.
- [ ] **Step 4:** Test same-task refresh/resume by writing a `crash-seams.redacted.jsonl` record for the manifest path, dispatch nonce, worker id, current durable seam, and next adapter command, then deliberately end the predecessor turn at that seam. The resumed task may read only the durable manifest, request/result artifacts, quarantine ledger, and `crash-seams.redacted.jsonl`; it must not rely on in-memory worker lists. It runs `codex-worker-adapter.sh reap-recover` to emit the next native action and proves the same id is queryable/closable or captures the exact authoritative alternative.
- [ ] **Step 5:** Test a different top-level successor session. Write `successor-session.redacted.json` with its own redacted session/context id and the predecessor manifest/worktree hashes. From that successor, run the adapter's recovery action sequence, then perform native enumeration/query/close against the predecessor worker. Parent-termination mode is allowed only if the native evidence explicitly names the predecessor session/context, descendants, nonce/worktree coverage, and no-write guarantee; otherwise it is not selected.
- [ ] **Step 6:** Simulate crash after durable intent but before id binding by stopping the predecessor immediately after `dispatch-intent` and before native spawn, and separately after native spawn returns but before `spawn --phase observe` persists binding. For the no-spawn seam, recovery must prove no accepted worker exists by enumeration or parent-termination evidence. For the accepted-but-unbound seam, preserve the redacted native spawn response only in `crash-seams.redacted.jsonl`; the successor must recover by exact owning session+nonce enumeration/query or quarantine. Zero enumeration matches without authoritative parent-termination coverage is not proof.
- [ ] **Step 7:** Exercise close while running and slot release. The native evidence must include close request id, worker id, close result, at least one subsequent same-id query/enumeration, and the adapter's slot/no-write predicate. `not-found` is proof only if the runtime documentation/schema or observed native result explicitly defines it as no descendant can write for that id/session; otherwise quarantine-only is required. Unknown or version-different semantics block the gate.
- [ ] **Step 8:** Deliver equivalent notification and wait observations, proving one canonical result hash and distinct observation hashes. Inject the deterministic conflict fixture and prove consumption is refused.
- [ ] **Step 9:** Run one C2-verifiable result and one invalid-attestation mutable result. Prove invalid output is retained as evidence, closed/reaped, baseline-compared, quarantined when changed, and never claimed. Also exercise `SETUP_REQUIRED` separately and prove it is not `attestation-invalid`.
- [ ] **Step 10:** Record only runtime version, redacted schemas, synthetic ids/timestamps, selected `addressable|parent-termination|quarantine-only` mode, exact mode predicates, command/action sequence, outcomes, and SHA-256 hashes. `takeover-mode.json` must name one mode and every unresolved path it covers. `evidence-hashes.json` must bind every live artifact except `evidence-hashes.json` itself and must include `hash_manifest_excludes_self: true`; there is no self-hash requirement. Update the installed adapter document to that selected mode without broadening it.
- [ ] **Step 11:** Validate live evidence.

Run:

```bash
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-worker/live/native-tool-schemas.redacted.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-worker/live/predecessor-session.redacted.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-worker/live/successor-session.redacted.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-worker/live/takeover-mode.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-worker/live/evidence-hashes.json >/dev/null
while IFS= read -r line; do printf '%s\n' "$line" | python3 -m json.tool >/dev/null; done < dodi-dev/scripts/tests/fixtures/codex-worker/live/cross-session-observations.redacted.jsonl
while IFS= read -r line; do printf '%s\n' "$line" | python3 -m json.tool >/dev/null; done < dodi-dev/scripts/tests/fixtures/codex-worker/live/crash-seams.redacted.jsonl
dodi-dev/scripts/tests/test-codex-worker-adapter.sh
scripts/validate-runtime-contracts.sh --require-codex-worker-live
```

Expected: all live files parse and hash-verify; `evidence-hashes.json` binds every other live artifact and explicitly excludes itself; deterministic test exits `0`; live-required validator exits `0`; exactly one takeover mode is selected and every scenario in `crash-seams.redacted.jsonl` is covered by that mode. If no approved path proves every unresolved worker cannot share a worktree with a successor, stop with DOD-813 blocked and leave scheduled Codex delivery disabled.

### Task 11: Run complete regression and C3 ownership audit

**Files:**
- Verify only: all C3 files listed in this plan
- Verify unchanged: `dodi-dev/scripts/await-worker.sh`
- Verify unchanged outside C3: C2 model/capacity/hook files, C4/C5 surfaces, metadata envelopes

- [ ] **Step 1:** Run syntax, focused, repository, and full shell regression.

```bash
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
bash -n dodi-dev/scripts/codex-worker-adapter.sh dodi-dev/scripts/reap-workers.sh dodi-dev/scripts/tests/test-codex-worker-adapter.sh dodi-dev/scripts/tests/test-worker-manifest-contract.sh scripts/validate-runtime-contracts.sh scripts/validate-phase-skills.sh
dodi-dev/scripts/tests/test-codex-worker-adapter.sh
dodi-dev/scripts/tests/test-worker-manifest-contract.sh
scripts/validate-runtime-contracts.sh
scripts/validate-runtime-contracts.sh --require-codex-worker-live
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
```

Expected: every command exits `0`; focused tests print their exact `tests ok` lines; metadata remains synchronized at `0.16.0`.

- [ ] **Step 2:** Run file-surface and ownership checks against the persisted `DOD_812_BASE`.

```bash
DOD_812_BASE="$(sed -n 's/^DOD_812_BASE=//p' dodi-dev/scripts/tests/fixtures/codex-worker/pre-c3-baseline.txt)"
test -n "$DOD_812_BASE"
git cat-file -e "$DOD_812_BASE^{commit}"
git diff --check "$DOD_812_BASE"...HEAD
git diff --name-only "$DOD_812_BASE"...HEAD
test -z "$(git diff --name-only "$DOD_812_BASE"...HEAD -- dodi-dev/scripts/await-worker.sh dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/codex-capacity-classifier.sh dodi-dev/scripts/hook-require-model-pin.sh dodi-dev/hooks/hooks.json)"
test -z "$(git diff "$DOD_812_BASE"...HEAD -- dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .claude-plugin/marketplace.json .agents/plugins/marketplace.json)"
rg -n '0\.17\.0' dodi-dev .claude-plugin .agents scripts
```

Expected: baseline file yields a valid commit; no whitespace errors; changed files are limited to the declared C3 surface; C2/Claude-await files and metadata diffs are empty; `0.17.0` has no new C3-owned occurrence.

- [ ] **Step 3:** Audit fail-closed invariants from durable evidence: no spawn without flushed intent, no replacement on unknown acceptance, no terminal without content-addressed result/observation/tier artifacts, no `TIER_UNVERIFIED` consumption, no `SETUP_REQUIRED` relabel, no `reaped` without no-write/slot proof, no digest before reaped, no quarantine release by time/assertion, no same-worktree successor beside uncertainty, no Codex transcript inference, and no automated Gate 2 merge.
- [ ] **Step 4:** Record implementation evidence for plan review: implementation commits, exact commands/exits, live gate mode/hashes, any expected `SETUP_REQUIRED` production limitation pending C4, and the final diff surface. Do not self-approve or apply Linear labels.

## Handoff Assumptions And Blockers

- DOD-811 and DOD-812 implementations land before C3 execution; this plan may not manufacture their contracts from specs/plans.
- The current supported Codex Desktop/plugin runtime exposes explicit native spawn, wait/query, enumeration or authoritative parent termination, close, effective attestation, and no-write/slot-release evidence matching redacted fixtures.
- C2 provides callable `resolve-tier`/`verify-attestation`, exact `TIER_READY`/`WORKER_TIER_VERIFIED`/`TIER_UNVERIFIED`/`SETUP_REQUIRED` JSON outcomes, the fixture verifier, and explicit native model/reasoning/context-inheritance fields.
- Production C3 remains `SETUP_REQUIRED` until C4 lands `runtime-preflight.sh verify-profile`; deterministic tests and the explicitly trusted development live gate do not create production setup state.
- The plan-reviewer must classify delivery tier before `ready-to-implement`. Expected classification is `capable` because the ticket implements crash-safe append-only state machines, cross-session reconciliation, locking, idempotence, and no-write invariants; the reviewer owns the final `standard|capable` decision and any `needs-capable-delivery` label application.
- Any landed C1/C2 mismatch in path, schema, state, identity, verifier shape, or ordering returns to DOD-810/DOD-813 design review rather than creating a compatibility branch.
- Any live inability to prove stable worker identity, uncertain-acceptance recovery, no-write after close, slot release, or complete quarantine blocking leaves DOD-813 blocked and scheduled Codex delivery disabled.
