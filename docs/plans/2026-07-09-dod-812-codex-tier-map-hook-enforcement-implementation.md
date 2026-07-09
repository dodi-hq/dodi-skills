# DOD-812 Codex Tier Map and Hook Enforcement Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute Tasks 1-8 in order. DOD-812 is C2 only: do not implement Codex worker lifecycle, profile/setup state, scheduling/escalation/Gate 2, release validation, or metadata changes while resolving a failure.

**Goal:** Implement the Codex adapter for the installed Frontier/Capable/Standard/Fast policy: a versioned native model map, same-invocation profile-verifier consumption, effective main-loop and worker attestation, structured Frontier-capacity classification, and model-pin hook enforcement proven against the supported Codex Desktop runtime.

**Architecture:** Keep semantic tier and Fable policy in DOD-811's installed runtime canon and put Codex model/reasoning pairs in one strict, versioned adapter-data file. A read-only `codex-tier-adapter.sh` invokes C4's `runtime-preflight.sh verify-profile` in the same command, validates the returned profile/health/register/runtime proof and the installed map, and then either resolves an exact native pair or verifies runtime-supplied effective attestation. A separate pure classifier recognizes only version-bound structured Frontier-capacity failures. The shared model-pin hook normalizes the observed Claude and Codex request families and blocks invalid request shapes before spawn; terminal attestation remains the authoritative post-execution proof. DOD-811's paths, schemas, generation binding, manifest states, runtime-policy ownership, root bootstrap, and C3 lifecycle fence remain unchanged.

**Tech Stack:** Bash 3.2-compatible command surfaces, Python 3 standard library for JSON/schema-adjacent semantic checks and hashing, JSON Schema draft 2020-12, test-only `jsonschema` from DOD-811's `requirements-dev.txt`, Markdown installed contracts/skills, the supported Codex Desktop/plugin runtime for live-fire, and existing repository validators.

**Source of truth:** `docs/specs/2026-07-09-codex-tier-map-hook-enforcement-design.md` (approved DOD-812 spec), constrained by `docs/specs/2026-07-09-codex-runtime-compatibility-design.md` (approved parent spec), `docs/specs/2026-07-09-runtime-canon-profile-bootstrap-design.md` (DOD-811 contracts), and `docs/plans/2026-07-09-dod-811-runtime-foundation-implementation.md` (foundation implementation sequence). Planning baseline is epic commit `8d6b735`; implementation must start only after DOD-811 is landed, record that exact pre-C2 commit as `DOD_811_BASE`, and consume the landed files rather than recreating them from this plan.

**Scope boundaries:**

- C2 may add the model-map schema/data, read-only tier adapter, read-only capacity classifier, fixture-only verifier, deterministic tests, installed adapter references, all 20 Codex main-loop preflight references, model-pin hook normalization, and C2 validator rules.
- C2 does not change the canonical profile, health, lock, register, or manifest paths; their schemas, generation/hash binding, state vocabulary, nonce/worker keys, result ordering, and lifecycle fence remain DOD-811-owned.
- Every production `resolve-tier`, `verify-main-loop`, and `verify-attestation` command requires `--invoke-verifier <absolute-runtime-preflight.sh>` and invokes C4's `verify-profile` in that same command. No production receipt, cached proof, caller-supplied verifier stdout, test verifier path, or verification bypass is accepted.
- `dodi-dev/scripts/tests/fixtures/codex-tier/verifier/fixture-runtime-preflight.sh` is the only fixture verifier. It is test-only and must never be referenced by a production skill, installed runtime document, production script default, or non-test command.
- C2 does not implement `spawn`, `await`, `persist-result`, `close`, `reap/recover`, result-artifact persistence, baseline comparison, quarantine, takeover, or manifest writes. Those are C3.
- C2 does not modify `runtime-preflight.sh`, write a profile/health/register, provision setup or hook trust, bridge auth, configure tasks, mutate scheduler/wake state, implement escalation, alter Gate 2, or perform branch-protection checks. Those are C4.
- C2 does not add `validate-codex-compatibility.sh`, `validate-codex-install.sh`, install/release documentation, isolated-install validation, or a `0.17.0` metadata bump. Those are C5.
- C2 does not change semantic tier assignments, Fable policy buckets, retry counts, delivery-tier routing, review rounds, catch-attribution grammar, `CAPACITY_PARK`, `FABLE_MAKEUP`, or the v0.16 workflow model.
- The Gate 2 hook script and Gate 2 matcher remain byte-for-byte/structurally unchanged. Only the model-pin matcher may change, and only if current-runtime live-fire proves `Task|Agent` misses the Codex native spawn.
- The live gate may consume an already trusted development installation. It must not grant trust, install/setup a production profile, or treat `/opt/homebrew/bin/codex` 0.38.0 as the supported runtime.

**File surface:**

- Create: `dodi-dev/runtime/codex-model-tiers.schema.json`
- Create: `dodi-dev/runtime/codex-model-tiers.json`
- Create: `dodi-dev/scripts/codex-tier-adapter.sh`
- Create: `dodi-dev/scripts/codex-capacity-classifier.sh`
- Create: `dodi-dev/scripts/tests/test-codex-tier-adapter.sh`
- Create: `dodi-dev/scripts/tests/test-codex-capacity-classifier.sh`
- Create: `dodi-dev/scripts/tests/test-hook-require-model-pin.sh`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/map/unknown-schema.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/map/unknown-runtime.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/map/unknown-tier.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/map/unknown-field.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/map/empty-candidates.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/map/duplicate-within-tier.semantic-invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/map/duplicate-across-tiers.semantic-invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/profile/runtime-profile.codex.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/profile/runtime-profile.wrong-tier.semantic-invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/verifier/fixture-runtime-preflight.sh`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/verifier/verify-profile-output.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/main-loop/main-loop.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/main-loop/main-loop.wrong-model.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/main-loop/main-loop.wrong-reasoning.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/main-loop/main-loop.missing-context.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/main-loop/main-loop.foreign-context.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/main-loop/main-loop.unsupported-source.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/main-loop/main-loop.launch-setting-only.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/request.fresh-required.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/request.may-inherit.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/attestation.fresh.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/attestation.wrong-model.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/attestation.wrong-reasoning.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/attestation.missing-effective-pair.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/attestation.inherited.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/attestation.no-inherit-missing.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/attestation.launch-setting-only.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/gate-context.spec-review.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/gate-context.spec-review.same-context.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/gate-context.hard-final.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/gate-context.hard-final.same-writer.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/gate-context.deferred-substitution.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/gate-context.deferred-substitution.missing-makeup.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/gate-context.soft-substitution.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/worker/gate-context.soft-substitution.missing-marker.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/frontier-capacity.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/free-form-capacity.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/invalid-model.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/auth.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/permission.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/account-quota.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/malformed-request.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/network-timeout.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/unknown.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/claude-agent.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/claude-task.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/claude-missing-model.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/claude-arbitrary-model.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-dispatch.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-missing-model.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-missing-reasoning.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-wrong-reasoning.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-mixed-tier.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-unknown-pair.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-ambient-default.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-prompt-only.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/codex-dispatch-malformed.invalid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/hook/non-dispatch.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/runtime-version.txt`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-agent-tool-schema.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-hook-payload.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-terminal-attestation.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-frontier-capacity-signature.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-capacity-signature-source.md`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`
- Modify: `dodi-dev/runtime/adapter-contracts.md`
- Modify: `dodi-dev/skills/assess-epic/SKILL.md`
- Modify: `dodi-dev/skills/brainstorm/SKILL.md`
- Modify: `dodi-dev/skills/create-tests/SKILL.md`
- Modify: `dodi-dev/skills/deliver-ticket/SKILL.md`
- Modify: `dodi-dev/skills/drive-epic/SKILL.md`
- Modify: `dodi-dev/skills/epic-orchestrator/SKILL.md`
- Modify: `dodi-dev/skills/file-ticket/SKILL.md`
- Modify: `dodi-dev/skills/implement-ticket/SKILL.md`
- Modify: `dodi-dev/skills/implement/SKILL.md`
- Modify: `dodi-dev/skills/mature-ticket/SKILL.md`
- Modify: `dodi-dev/skills/pickup-epic/SKILL.md`
- Modify: `dodi-dev/skills/pickup-ticket/SKILL.md`
- Modify: `dodi-dev/skills/pickup/SKILL.md`
- Modify: `dodi-dev/skills/reconcile-tickets/SKILL.md`
- Modify: `dodi-dev/skills/review/SKILL.md`
- Modify: `dodi-dev/skills/submit-epic-pr/SKILL.md`
- Modify: `dodi-dev/skills/submit-ticket-pr/SKILL.md`
- Modify: `dodi-dev/skills/submit/SKILL.md`
- Modify: `dodi-dev/skills/verify/SKILL.md`
- Modify: `dodi-dev/skills/write-plan/SKILL.md`
- Modify: `dodi-dev/scripts/hook-require-model-pin.sh`
- Modify only if live-fire requires it: `dodi-dev/hooks/hooks.json` model-pin entry
- Modify: `scripts/validate-runtime-contracts.sh`
- Modify: `scripts/validate-phase-skills.sh`

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `model-map schema and semantic uniqueness; same-invocation verifier binding; tier resolution; main-loop and worker effective attestation; context independence/model diversity; structured capacity classification; Claude/Codex model-pin payload normalization`
  - Reason: `C2 is a fail-closed decision boundary. Every accepted pair, proof, context, failure class, and hook payload must be reproducible from strict fixtures rather than ambient configuration or prompt claims.`
  - Minimum assertions: `the exact four initial pairs pass; unknown schema/runtime/tier/field, empty lists, duplicate pairs, and cross-tier ambiguity fail; every profile pair belongs to the same map tier; verifier operation/nonce/repo/profile/health/register/setup/runtime/catalog/stable-read binding is current; absent, stale, unavailable, wrong, receipt-based, bypassed, or changed-after-proof verification fails; all 20 main-loop tiers are exact; requested worker pairs and runtime-effective pairs match; fresh-required gates prove no inheritance and a new context; writer/reviewer diversity and degraded equality rules are enforced; only allowlisted structured Frontier failures classify as capacity; malformed/partial/unknown dispatch pins are denied without leaking payloads.`

- Integration: `required`
  - Scope: `installed runtime canon and adapter contracts, all 20 skill preflight references, C4 verifier invocation shape, C3 handoff boundary, shared hook metadata, repository validators, and C2 ownership fences`
  - Reason: `The highest regression risk is a valid leaf script that is bypassed by a skill, duplicates DOD-811 contracts, or silently activates a C3-C5 surface.`
  - Harness: `setup-required`
  - Minimum assertions: `every production tier-adapter call includes --invoke-verifier and contains no receipt/assume/skip/environment bypass; the fixture verifier is referenced only under test paths; each skill verifies its literal required tier before tier-sensitive work; installed policy links rather than duplicates tables; lifecycle remains UNSUPPORTED_RUNTIME until C3; Gate 2 remains unchanged; profile/health/register/manifest schemas and runtime-preflight remain unchanged; C3-C5 files and 0.17.0 metadata are absent; all repository validators and shell tests pass.`

- E2E: `required`
  - Scope: `current supported Codex Desktop native agent schema, pre-spawn model-pin hook deny/allow behavior, effective worker model/reasoning/context/no-inherit attestation, and shared Claude hook compatibility`
  - Reason: `Hook discovery and deterministic fixtures cannot prove that the current native spawn is interceptable or that the runtime exposes effective model and fresh-context evidence.`
  - Harness: `setup-required`
  - Minimum assertions: `record the supported runtime version and redacted native schemas; an omitted pin is denied before any agent id; the exact Standard pair is allowed; terminal metadata exposes effective model, reasoning, worker context id, and runtime-observed no-inherit evidence accepted by verify-attestation; wrong-reasoning and unknown-pair requests are denied before worker creation; a representative non-dispatch tool remains allowed if matching broadened; one Claude-shaped allow and deny remain correct.`

### Critical Flows

- `Codex skill -> DOD-811 verified concrete plugin root/profile path -> codex-tier-adapter verify-main-loop with --invoke-verifier -> same-command C4 verify-profile proof -> installed-map/profile/effective-session match -> MAIN_LOOP_VERIFIED before judgment, writes, or dispatch.`
- `Top-level dispatcher -> resolve-tier with same-command verifier -> TIER_READY exact model/reasoning/profile generation -> C3 durable dispatch-intent and native spawn -> C3 persists terminal artifact -> verify-attestation with same-command verifier -> WORKER_TIER_VERIFIED before digest consumption, or TIER_UNVERIFIED into C3's existing attestation-invalid/quarantine path.`
- `Fresh-required review -> request records fresh-required -> terminal runtime evidence proves inheritance disabled and a new effective context id -> gate-specific writer/reviewer identity checks -> pass; different worker/context ids without no-inherit proof -> TIER_UNVERIFIED.`
- `Exact proven Frontier request -> initial failure plus two retries of the same request -> structured runtime/version/catalog-bound allowlisted failure -> classifier result -> existing hard/deferred/soft policy owner acts; arbitrary text, wrong pair, auth/quota/network/model errors -> no substitution.`
- `Observed native pre-spawn payload -> model-pin hook normalizes exact tool identity/input path -> exact installed-map pair allowed; missing/partial/mixed/unknown pair blocked before agent id; terminal attestation still required.`

### Regression Surface

- `Claude frontmatter aliases, Claude Agent/Task hook behavior, and DODI_ALLOW_UNPINNED=1's explicitly isolated non-Dodi behavior.`
- `DOD-811 profile/health/register/manifest schemas, canonical paths, generation binding, root bootstrap, Claude adapter behavior, and Codex lifecycle UNSUPPORTED_RUNTIME fence.`
- `Gate 2 script, matcher, command root form, and branch-protection behavior.`
- `Semantic tier/Fable policy, review rounds, delivery-tier routing, capacity retry count, catch attribution, CAPACITY_PARK, FABLE_MAKEUP, claims, and lifecycle ordering.`
- `Plugin/marketplace metadata remains synchronized at 0.16.0; C5 owns 0.17.0.`
- `No secrets, prompts, user payloads, auth values, production profiles, or production verifier receipts enter fixtures or diagnostics.`

### Commands

- Unit: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; dodi-dev/scripts/tests/test-codex-tier-adapter.sh && dodi-dev/scripts/tests/test-codex-capacity-classifier.sh && dodi-dev/scripts/tests/test-hook-require-model-pin.sh`
- Integration: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; scripts/validate-runtime-contracts.sh && scripts/validate-phase-skills.sh && scripts/validate-plugin-metadata.sh && scripts/validate-ticket-comment-templates.sh`
- E2E: `Use the supported Codex Desktop/plugin runtime's native tool invocation captured in dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md; then run python3 -m json.tool on each redacted JSON artifact and rerun the three C2 tests. The live tool calls are harness operations, not /opt/homebrew/bin/codex 0.38.0 shell evidence.`
- Broader regression: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done` plus the Task 8 syntax, ownership, metadata, and diff batteries.

### Harness Requirements

- `bash, python3, git, rg, jq, mktemp, stat, shasum or sha256sum, and the DOD-811 test environment at /tmp/dodi-runtime-contracts-venv.`
- `If absent, create the test-only environment exactly: python3 -m venv /tmp/dodi-runtime-contracts-venv && /tmp/dodi-runtime-contracts-venv/bin/python -m pip install --requirement requirements-dev.txt.`
- `A parent-approved supported Codex Desktop/plugin runtime with native multi-agent support and an already trusted development installation of the C2 build. Trust/setup/profile provisioning is an external C4-owned prerequisite, not work this plan may perform.`
- `A disposable read-only target/worktree for native allow dispatches. The live test must not touch Linear, GitHub, Slack, scheduler state, production profiles, or target-repository mutable files.`
- `All production scripts use only Python 3 standard library. jsonschema remains test/validator-only.`

### Non-Required Rationale

- Unit: `not applicable (required).`
- Integration: `not applicable (required).`
- E2E: `not applicable (required); only the C2 native pin/attestation/hook slice is required here. C3 lifecycle, C4 setup/Gate 2/scheduling/escalation, and C5 isolated-install/release matrices remain outside this E2E scope.`

### Verification Rules

- Missing deterministic harness is not a skip reason; set it up or report a concrete blocker.
- Missing pre-trusted supported Codex live harness is a C2 completion blocker; do not implement trust/setup or substitute fixture/discovery evidence.
- If native explicit model/reasoning inputs, effective attestation, no-inherit proof, or pre-spawn interception is unavailable, return DOD-812 to the epic as blocked. Do not weaken the design to prompt metadata or post-spawn cancellation.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec, DOD-811 contract, or ownership mismatch, demote the ticket to the spec/epic decision lane.

---

## Tasks

### Task 1: Add the versioned Codex model map and strict fixtures

**Files:**
- Create: `dodi-dev/runtime/codex-model-tiers.schema.json`
- Create: `dodi-dev/runtime/codex-model-tiers.json`
- Create: `dodi-dev/scripts/tests/test-codex-tier-adapter.sh`
- Create: all files under `dodi-dev/scripts/tests/fixtures/codex-tier/map/`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/profile/runtime-profile.codex.valid.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/profile/runtime-profile.wrong-tier.semantic-invalid.json`

- [ ] **Step 1:** Confirm DOD-811 is landed before making C2 changes and record the exact base.

```bash
set -euo pipefail
test -f dodi-dev/runtime/runtime-profile.schema.json
test -f dodi-dev/runtime/runtime-health.schema.json
test -f dodi-dev/runtime/runtime-register-record.schema.json
test -f dodi-dev/runtime/dispatch-manifest-record.schema.json
test -f dodi-dev/runtime/adapter-contracts.md
test -f dodi-dev/skills/epic-orchestrator/runtime-policy.md
test -f dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md
test -f dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md
test -x dodi-dev/scripts/runtime-preflight.sh
export DOD_811_BASE="$(git rev-parse HEAD)"
printf 'DOD_811_BASE=%s\n' "$DOD_811_BASE"
```

Expected: all `test` commands exit 0 and one exact 40-character base SHA is printed. Preserve that SHA in lane evidence and use it for Tasks 6-8. If any foundation file is absent or materially differs from the approved DOD-811 contract, stop; do not recreate it in C2.

- [ ] **Step 2:** Implement `codex-model-tiers.schema.json` with draft 2020-12, stable `$id` `https://dodi.dev/schemas/dodi-dev/codex-model-tiers/v1`, `schema_version: 1`, `map_version: 1`, `runtime: codex`, exactly `frontier|capable|standard|fast`, at least one ordered candidate per tier, non-empty `model` and `reasoning`, and `additionalProperties: false` at every C2-owned object.

JSON Schema must reject shape errors and duplicate pairs within one candidate array. `test-codex-tier-adapter.sh` must separately enforce cross-tier uniqueness because JSON Schema cannot express that reliably.

- [ ] **Step 3:** Add the installed map with exactly these initial candidates and no policy, profile path, setup, trust, scheduler, capacity bucket, or lifecycle fields:

```text
frontier -> gpt-5.6-sol / xhigh
capable  -> gpt-5.5 / xhigh
standard -> gpt-5.6-terra / medium
fast     -> gpt-5.6-luna / low
```

Candidate order is discovery order only. The map does not prove availability and must not contain an ambient/default fallback.

- [ ] **Step 4:** Add map/profile fixtures and the first test slice. Use DOD-811's exact profile schema and canonical fields; do not add a model-map version to the profile. The valid Codex profile fixture binds all four exact pairs to their matching tiers. The wrong-tier fixture remains schema-valid but fails the named C2 semantic assertion.

Minimum map assertions: valid schema; exact defaults; unknown schema/runtime/tier/field rejection; empty candidates rejection; duplicate-within-tier rejection; cross-tier duplicate rejection; and all four profile pairs found under the same installed-map tier.

- [ ] **Step 5:** Verify the map slice.

```bash
set -euo pipefail
chmod +x dodi-dev/scripts/tests/test-codex-tier-adapter.sh
bash -n dodi-dev/scripts/tests/test-codex-tier-adapter.sh
python3 -m json.tool dodi-dev/runtime/codex-model-tiers.schema.json >/dev/null
python3 -m json.tool dodi-dev/runtime/codex-model-tiers.json >/dev/null
PATH=/tmp/dodi-runtime-contracts-venv/bin:$PATH dodi-dev/scripts/tests/test-codex-tier-adapter.sh --map-only
```

Expected: final line `codex tier map tests ok`; exit 0.

- [ ] **Step 6:** Commit the model-map slice.

```bash
git add dodi-dev/runtime/codex-model-tiers.schema.json dodi-dev/runtime/codex-model-tiers.json dodi-dev/scripts/tests/test-codex-tier-adapter.sh dodi-dev/scripts/tests/fixtures/codex-tier/map dodi-dev/scripts/tests/fixtures/codex-tier/profile
git commit -m "feat: add versioned Codex model tier map"
```

### Task 2: Capture supported-runtime contracts and implement same-invocation verification

**Files:**
- Create: `dodi-dev/scripts/codex-tier-adapter.sh`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/verifier/fixture-runtime-preflight.sh`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/verifier/verify-profile-output.valid.json`
- Create: all files under `dodi-dev/scripts/tests/fixtures/codex-tier/main-loop/`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/runtime-version.txt`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-agent-tool-schema.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-terminal-attestation.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-frontier-capacity-signature.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-capacity-signature-source.md`
- Modify: `dodi-dev/scripts/tests/test-codex-tier-adapter.sh`

- [ ] **Step 1:** Before implementing `verify-attestation` or the capacity allowlist, capture the supported-runtime contract fixtures from an already trusted development installation or authoritative runtime documentation. Record the runtime version, native agent tool schema, explicit native model/reasoning request field paths, terminal effective model/reasoning/context/no-inherit field paths, and either one qualifying structured Frontier-capacity failure signature or an authoritative-documentation citation proving the exact structured signature.

Write only redacted artifacts under `dodi-dev/scripts/tests/fixtures/codex-tier/live/`. Store no prompt, user data, credentials, absolute home paths, task content, unrelated environment values, or raw transcripts. If explicit model/reasoning fields, effective attestation, no-inherit evidence, or an interceptable pre-spawn payload is absent, mark DOD-812 blocked. If no structured Frontier-capacity signature is available from observation or authoritative documentation, mark the capacity classifier blocked and do not invent a positive capacity fixture.

- [ ] **Step 2:** Implement this exact command surface. Do not add `--verification-receipt`, `--assume-verified`, `--skip-generation`, environment bypasses, or a default verifier.

```text
codex-tier-adapter.sh validate-map --map <absolute-path>
codex-tier-adapter.sh resolve-tier --tier <tier> --profile <file> --invoke-verifier <absolute-runtime-preflight.sh> --repo <owner/name> --operation-nonce <nonce>
codex-tier-adapter.sh verify-main-loop --tier <tier> --profile <file> --attestation <file> --invoke-verifier <absolute-runtime-preflight.sh> --repo <owner/name> --operation-nonce <nonce>
codex-tier-adapter.sh verify-attestation --tier <tier> --profile <file> --request <file> --attestation <file> --gate-context <file> --invoke-verifier <absolute-runtime-preflight.sh> --repo <owner/name> --operation-nonce <nonce>
```

Use exit 0 for one complete success JSON object, 2 for usage/dependency/malformed local input, 3 for `SETUP_REQUIRED`, 4 for `TIER_UNVERIFIED`, and 5 for safe-output failure. Print diagnostics only to stderr; never emit partial JSON, prompt content, credentials, arbitrary environment values, or raw payloads.

- [ ] **Step 3:** For each production operation except `validate-map`, invoke the passed verifier path in the same process as:

```text
<absolute-runtime-preflight.sh> verify-profile --repo <owner/name> --operation <resolve-tier|verify-main-loop|verify-attestation> --operation-nonce <nonce>
```

The path must be absolute. Consume exactly one JSON object from that invocation and require `PROFILE_VERIFIED`, schema version, requested operation, nonce, repo, canonical profile path/hash/setup run id, health path/hash/profile/projection binding, register issue/cursor/tip binding, Codex runtime/version/catalog fingerprint, and stable-read/lock evidence. Re-read and hash the named profile and verifier-reported health bytes after proof capture; validate the installed map and profile; require the verifier path to resolve under the proven `profile.plugin.root`; reject changed bytes, mismatched path/generation/runtime/catalog/register evidence, unknown proof fields/version, nonzero verifier exit, multiple/invalid stdout objects, and unavailable verifier as `SETUP_REQUIRED`.

This is an ephemeral same-command consumer contract documented for C4; it does not create a receipt file, signing secret, second verifier, profile field, health field, register field, or generation authority.

- [ ] **Step 4:** Implement the fixture verifier only at the listed test path. It must accept the same `verify-profile --repo --operation --operation-nonce` argv shape and emit fresh fixture proof using the caller's operation/nonce. The test harness copies it into a temporary installed-plugin layout at `<temp-plugin-root>/dodi-dev/scripts/runtime-preflight.sh`, points the temporary profile's proven `plugin.root` at that root, and invokes only that disposable copy; this exercises the production path check without adding a fixture path exception. Test-only case selection may exercise wrong operation, wrong nonce, wrong repo, stale hash, missing register tip, missing lock/stable-read evidence, unavailable verifier, malformed output, and mutation-after-proof. No production source may refer to the fixture source path, temporary path convention, or its case controls.

- [ ] **Step 5:** Implement `resolve-tier`: lowercase semantic tiers only, current proof first, exact `profile.models.<tier>` pair, same-tier installed-map membership, and `TIER_READY` output carrying semantic tier, requested model/reasoning, profile setup run id/hash, runtime version, and catalog fingerprint. It performs no spawn, manifest write, candidate fallback, profile search, or profile mutation.

- [ ] **Step 6:** Implement `verify-main-loop` against runtime-supplied current session/thread metadata. Require recognized attestation source for the proven runtime version, effective model, effective reasoning, and current context id. Require the effective pair to equal the profile/map pair for the requested tier and the attested context to equal the current context represented by the input. Configured task model, frontmatter, launch request, task title, prompt text, operator assertion, or profile pair alone must fail with `TIER_UNVERIFIED`.

- [ ] **Step 7:** Extend tests for all proof and main-loop cases, including unavailable verifier, production bypass-option rejection, test-verifier path rejection when presented as an installed production verifier, and changed-after-proof. Test output safety by forcing a closed stdout consumer and by placing recognizable secret/prompt sentinels in rejected fixtures; neither sentinel may appear in stdout/stderr.

- [ ] **Step 8:** Verify.

```bash
set -euo pipefail
chmod +x dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/tests/fixtures/codex-tier/verifier/fixture-runtime-preflight.sh
bash -n dodi-dev/scripts/codex-tier-adapter.sh
bash -n dodi-dev/scripts/tests/fixtures/codex-tier/verifier/fixture-runtime-preflight.sh
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-agent-tool-schema.redacted.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-terminal-attestation.redacted.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-frontier-capacity-signature.redacted.json >/dev/null
PATH=/tmp/dodi-runtime-contracts-venv/bin:$PATH dodi-dev/scripts/tests/test-codex-tier-adapter.sh --resolution-and-main-loop
```

Expected: final line `codex tier resolution and main-loop tests ok`; exit 0.

- [ ] **Step 9:** Commit the adapter slice.

```bash
git add dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/tests/test-codex-tier-adapter.sh dodi-dev/scripts/tests/fixtures/codex-tier/verifier dodi-dev/scripts/tests/fixtures/codex-tier/main-loop dodi-dev/scripts/tests/fixtures/codex-tier/live/runtime-version.txt dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-agent-tool-schema.redacted.json dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-terminal-attestation.redacted.json dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-frontier-capacity-signature.redacted.json dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-capacity-signature-source.md
git commit -m "feat: verify Codex tier resolution and main loop"
```

### Task 3: Enforce worker effective attestation and fresh-context evidence

**Files:**
- Modify: `dodi-dev/scripts/codex-tier-adapter.sh`
- Modify: `dodi-dev/scripts/tests/test-codex-tier-adapter.sh`
- Create: all files under `dodi-dev/scripts/tests/fixtures/codex-tier/worker/`

- [ ] **Step 1:** Define the `--request` input as an ephemeral C2 verification input derived by C3 from DOD-811's existing durable intent, not a new manifest shape. It must carry the existing semantic tier, requested model/reasoning, profile setup run id/hash, owning session/context ids, and `context_inheritance` exactly `fresh-required|may-inherit|same-context-required`. Reject unknown or missing fields.

Define `--gate-context` as ephemeral evidence from the existing gate/register state: gate kind, hard/deferred/soft policy where applicable, writer effective model/context identity where applicable, exact existing `tier-degraded(fable→<tier>,<policy>)` marker where applicable, and a durable existing `FABLE_MAKEUP` obligation id for deferred equality. It does not write or add a manifest/register field.

- [ ] **Step 2:** Parse only the runtime-versioned, live-observed terminal attestation shape. Verify the requested tier/pair/generation against the same-command verifier and installed map, then require runtime-attested effective model/reasoning/context identity to match the request. Requested launch fields, a new worker id, a different context id, prompt text, or operator claims are not effective evidence.

- [ ] **Step 3:** Enforce context inheritance mechanically:

```text
fresh-required -> recognized runtime evidence explicitly attests inheritance/thread carryover disabled, and effective worker context differs from owning context
may-inherit -> effective context is present; no fresh-context claim is made
same-context-required -> effective context equals the required context
```

For `fresh-required`, missing/unknown ancestry fields or launch-setting-only evidence returns `TIER_UNVERIFIED`. Normalize only the exact supported runtime source/version shape captured in Task 2; do not accept a caller-normalized boolean as proof.

- [ ] **Step 4:** Enforce gate-specific rules without changing policy:

- spec-review independence requires different attested author/reviewer context ids plus runtime-attested no-inherit launch;
- hard Frontier delivery final requires a reviewer effective model different from the Standard/Capable writer model;
- deferred equality requires the exact degradation marker and a durable `FABLE_MAKEUP` obligation id;
- soft equality requires the exact degradation marker and forbids claiming a make-up requirement;
- missing, malformed, or inconsistent gate evidence returns `TIER_UNVERIFIED`.

- [ ] **Step 5:** Return one compact `WORKER_TIER_VERIFIED` object suitable for C3 to place under the existing terminal record's `data` namespace. Do not append a manifest record, persist a result, compare a worktree baseline, close/reap, quarantine, or map failure into a new state. Document that C3 persists `attestation-invalid` and owns cleanup on exit 4.

- [ ] **Step 6:** Add all required positive and negative tests: exact pair; wrong/missing effective pair; same-context spec reviewer; missing no-inherit evidence; inherited context; launch-setting-only evidence; hard-final writer-model equality; valid hard diversity; valid deferred/soft equality; deferred missing make-up; soft missing marker; malformed gate context; and no output leakage.

- [ ] **Step 7:** Verify.

```bash
set -euo pipefail
bash -n dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/tests/test-codex-tier-adapter.sh
PATH=/tmp/dodi-runtime-contracts-venv/bin:$PATH dodi-dev/scripts/tests/test-codex-tier-adapter.sh --worker-attestation
```

Expected: final line `codex worker attestation tests ok`; exit 0.

- [ ] **Step 8:** Commit the attestation slice.

```bash
git add dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/tests/test-codex-tier-adapter.sh dodi-dev/scripts/tests/fixtures/codex-tier/worker
git commit -m "feat: verify Codex worker tier attestation"
```

### Task 4: Wire installed contracts and all 20 main-loop preflights

**Files:**
- Modify: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`
- Modify: `dodi-dev/runtime/adapter-contracts.md`
- Modify: all 20 `dodi-dev/skills/*/SKILL.md` files listed in File surface
- Modify: `dodi-dev/scripts/tests/test-codex-tier-adapter.sh`

- [ ] **Step 1:** Add concise installed contract links and operation postconditions. `runtime-policy.md` keeps the only operative tier/Fable tables and links the Codex adapter for preflight, attestation, and capacity application. `worker-adapter-contract.md` and `codex-worker-adapter.md` mark only `resolve-tier` and `verify-attestation` as C2-implemented; `spawn`, `await`, `persist-result`, `close`, and `reap/recover` remain explicitly `UNSUPPORTED_RUNTIME` until C3. `adapter-contracts.md` documents the same-command C4 verifier consumer proof without changing profile paths, generation authority, manifest states, or lifecycle ordering.

- [ ] **Step 2:** Add a mechanically identical `## Codex Main-Loop Preflight` first-step reference to every entry-point skill. It runs after DOD-811 root/bootstrap/profile-path resolution and before questions, bulk workflow reads, artifact/git/PM writes, or worker dispatch. Its production adapter command must include:

```text
"<plugin-root>/scripts/codex-tier-adapter.sh" verify-main-loop \
  --tier <literal-required-tier> \
  --profile "<canonical-profile>" \
  --attestation "<harness-supplied-current-session-attestation>" \
  --invoke-verifier "<plugin-root>/scripts/runtime-preflight.sh" \
  --repo "<owner/name>" \
  --operation-nonce "<fresh-nonce>"
```

Claude follows existing frontmatter behavior and does not run this Codex profile verifier. A Codex failure returns `TIER_UNVERIFIED` or `SETUP_REQUIRED` before tier-sensitive work and directs recovery to a fresh correctly configured task, never an in-place switch.

- [ ] **Step 3:** Pin this exact entry-point matrix without changing frontmatter:

```text
Frontier: brainstorm, mature-ticket, write-plan
Fast: assess-epic, pickup-epic, pickup-ticket
Standard: create-tests, deliver-ticket, drive-epic, epic-orchestrator,
          file-ticket, implement-ticket, implement, pickup,
          reconcile-tickets, review, submit-epic-pr, submit-ticket-pr,
          submit, verify
```

There is no Capable main-loop entry point in the current 20-skill tree. Worker/gate tiers remain resolved at dispatch time.

- [ ] **Step 4:** Extend the adapter test to enumerate exactly the same 20 skill names and tiers, parse every file, require one preflight before the first tier-sensitive section/command, require `--invoke-verifier` with the concrete installed `runtime-preflight.sh`, reject fixture verifiers and bypass flags, and require `brainstorm`, `mature-ticket`, and `write-plan` to say Frontier explicitly.

- [ ] **Step 5:** Verify references and policy ownership.

```bash
set -euo pipefail
PATH=/tmp/dodi-runtime-contracts-venv/bin:$PATH dodi-dev/scripts/tests/test-codex-tier-adapter.sh --skill-preflights
test "$(find dodi-dev/skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')" -eq 20
test "$(rg -l '^## Codex Main-Loop Preflight$' dodi-dev/skills/*/SKILL.md | wc -l | tr -d ' ')" -eq 20
test "$(rg -l -- '--invoke-verifier .*runtime-preflight\.sh' dodi-dev/skills/*/SKILL.md | wc -l | tr -d ' ')" -eq 20
! rg -n 'gpt-5\.6-sol|gpt-5\.5|gpt-5\.6-terra|gpt-5\.6-luna' dodi-dev/skills
```

Expected: final focused-test line `codex skill preflight tests ok`; all counts are 20; no native model-id matches under skills; exit 0.

- [ ] **Step 6:** Commit the installed-reference slice.

```bash
git add dodi-dev/runtime/adapter-contracts.md dodi-dev/skills dodi-dev/scripts/tests/test-codex-tier-adapter.sh
git commit -m "feat: require Codex main loop tier preflight"
```

### Task 5: Add the structured Frontier-capacity classifier

**Files:**
- Create: `dodi-dev/scripts/codex-capacity-classifier.sh`
- Create: `dodi-dev/scripts/tests/test-codex-capacity-classifier.sh`
- Create: all files under `dodi-dev/scripts/tests/fixtures/codex-tier/capacity/`
- Modify only if provenance needs correction: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-frontier-capacity-signature.redacted.json`
- Modify only if provenance needs correction: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-capacity-signature-source.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime-policy.md`
- Modify: `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md`

- [ ] **Step 1:** Before implementing the allowlist, verify the Task 2 capacity provenance. `codex-frontier-capacity-signature.redacted.json` must contain the exact structured runtime error/status path and runtime version/catalog binding, and `codex-capacity-signature-source.md` must cite either the live observation that produced it or authoritative runtime documentation. If neither a structured observed signature nor authoritative structured documentation exists, stop DOD-812 as blocked; do not invent a positive capacity fixture from free-form text.

- [ ] **Step 2:** Implement a pure, read-only classifier with this command surface:

```text
codex-capacity-classifier.sh classify --phase <setup|workflow> --attempt-count <integer> --failure <file> --request <file> --binding <file>
```

`request` supplies the exact requested semantic tier/model/reasoning and dispatch/probe identity. `binding` supplies the already verified runtime version/catalog/profile pair identity from the same executing flow. The classifier never invokes a worker, retries, resolves a substitute, reads/writes PM state, or accepts free-form failure text as evidence.

- [ ] **Step 3:** Version an allowlist keyed by supported runtime version plus the exact structured error code/status path from the Task 2 provenance. Return `FRONTIER_CAPACITY` only when the request is Frontier, the pair exactly equals the proven Frontier pair, runtime/catalog binding is current, failure identity belongs to the actual attempt, and `attempt-count` proves the installed initial attempt plus two same-request retries. For setup phase, emit `SETUP_CAPACITY_WAIT`; for workflow phase, emit only the classification for the existing policy owner.

Return `NOT_CAPACITY` for structured non-capacity and ambiguous failures; return `SETUP_REQUIRED` for invalid/stale binding. Never classify substrings such as `capacity`, `busy`, `model`, `quota`, or `unavailable`.

- [ ] **Step 4:** Cover every positive allowlisted signature by deriving it from `codex-frontier-capacity-signature.redacted.json`, then add negative variants for wrong runtime, catalog, tier, model, reasoning, attempt identity, or retry count. Cover invalid model, auth, permission, account quota, malformed request, network timeout, transport ambiguity, unknown status, and tempting free-form text. Prove setup never falls back and workflow does not apply policy before attempt count 3.

- [ ] **Step 5:** Link classifier output to the existing installed policy without copying its table or writing its artifacts. State that the dispatcher owns retries and hard/deferred/soft action, and that C2 writes no label, `CAPACITY_PARK`, `FABLE_MAKEUP`, continuation brief, or degradation comment.

- [ ] **Step 6:** Verify.

```bash
set -euo pipefail
chmod +x dodi-dev/scripts/codex-capacity-classifier.sh dodi-dev/scripts/tests/test-codex-capacity-classifier.sh
bash -n dodi-dev/scripts/codex-capacity-classifier.sh dodi-dev/scripts/tests/test-codex-capacity-classifier.sh
dodi-dev/scripts/tests/test-codex-capacity-classifier.sh
grep -qF 'structured capacity signature source:' dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-capacity-signature-source.md
```

Expected: final line `codex capacity classifier tests ok`; exit 0.

- [ ] **Step 7:** Commit the classifier slice.

```bash
git add dodi-dev/scripts/codex-capacity-classifier.sh dodi-dev/scripts/tests/test-codex-capacity-classifier.sh dodi-dev/scripts/tests/fixtures/codex-tier/capacity dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-frontier-capacity-signature.redacted.json dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-capacity-signature-source.md dodi-dev/skills/epic-orchestrator/runtime-policy.md dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md
git commit -m "feat: classify Codex Frontier capacity failures"
```

### Task 6: Normalize the model-pin hook and prove current-runtime behavior

**Files:**
- Modify: `dodi-dev/scripts/hook-require-model-pin.sh`
- Modify only if live-fire requires it: `dodi-dev/hooks/hooks.json` model-pin entry
- Modify only if live-fire reveals a compatible attestation-shape correction: `dodi-dev/scripts/codex-tier-adapter.sh`
- Create: `dodi-dev/scripts/tests/test-hook-require-model-pin.sh`
- Create: all files under `dodi-dev/scripts/tests/fixtures/codex-tier/hook/`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-hook-payload.redacted.json`
- Create: `dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md`
- Modify/refresh: Task 2 live fixtures under `dodi-dev/scripts/tests/fixtures/codex-tier/live/` when final live-fire confirms or corrects the observed runtime contract
- Modify: `dodi-dev/scripts/tests/test-codex-tier-adapter.sh` only to consume the redacted observed attestation shape

- [ ] **Step 1:** On the parent-approved supported Codex Desktop/plugin runtime, re-confirm the Task 2 native agent schema and terminal attestation/no-inherit contract, then inspect the actual pre-spawn hook envelope from an already trusted development installation. Record runtime version, top-level tool/event identity, exact nested model/reasoning fields, and terminal attestation/no-inherit fields in the listed redacted live fixtures. Store no prompt, user data, credentials, absolute home paths, task content, or unrelated environment values.

If the live completion's attestation shape differs from Task 2's fixture while still providing explicit effective model/reasoning/context and no-inherit evidence, update `codex-terminal-attestation.redacted.json`, `codex-tier-adapter.sh`, and the adapter tests in this task, then rerun Task 3's worker-attestation tests before proceeding. If the runtime lacks the required evidence, stop DOD-812 as blocked.

If the supported runtime does not expose explicit native model and reasoning fields, an interceptable pre-spawn payload, effective terminal model/reasoning/context identity, and runtime-observed no-inherit evidence, stop DOD-812 as blocked. Do not continue with inferred fields.

- [ ] **Step 2:** Implement hook normalization for exactly two runtime-observed families:

```text
Claude Agent/Task -> tool_input.model must be exactly fable|opus|sonnet|haiku
Codex native dispatch -> observed native model + reasoning fields must form one exact, unambiguous installed-map pair
```

Recognized dispatch payloads with missing, duplicate, malformed, partial, ambient/default, mixed-tier, unknown, wrong-reasoning, or prompt-only pins exit 2 before spawn. Positively identified non-dispatch payloads no-op only if live-fire required a broad matcher. Malformed JSON on a dispatch-only matcher fails closed. Diagnostics name the semantic repair and never print the input.

Keep `DODI_ALLOW_UNPINNED=1` only as the existing explicit non-Dodi escape and isolate it to one regression test; no Dodi skill/production instruction may set it.

- [ ] **Step 3:** First keep the existing `${CLAUDE_PLUGIN_ROOT}` command form and `Task|Agent` matcher. If and only if live-fire proves that matcher misses the observed Codex native spawn, change only the model-pin matcher to the narrowest working matcher. Do not alter the Gate 2 entry, its order, matcher, command, or script.

- [ ] **Step 4:** Add deterministic hook tests for valid Claude Agent/Task aliases; missing/arbitrary Claude models; exact Codex pair; missing model/reasoning; wrong reasoning; mixed/unknown pair; ambient/default; prompt-only; exact observed tool/input paths; recognized ambiguous/malformed dispatch; broad-matcher non-dispatch no-op if applicable; escape isolation; and redacted diagnostics.

- [ ] **Step 5:** Run the required live-fire matrix through Codex Desktop native tool calls and record the exact redacted invocation envelopes and outcomes in `live-fire-evidence.md`:

1. omit the pin and prove hook denial occurs before any agent id;
2. send the exact Standard `gpt-5.6-terra`/`medium` pair and prove allow plus one disposable completion;
3. prove terminal metadata contains effective Standard model, `medium` reasoning, worker context id, and runtime-observed no-inherit/fresh-context evidence consumable by `verify-attestation`;
4. send wrong-reasoning and unknown-pair requests and prove both deny before any worker id;
5. if matcher broadened, invoke one representative non-dispatch tool and prove no effect;
6. run one Claude-shaped allow and one Claude-shaped deny fixture/smoke.

Discovery, `hooks/list`, fixture invocation, or post-spawn cancellation is not evidence. The evidence file must name the supported runtime version, plugin build/root hash, hook matcher/key/hash, pre-existing trusted status, each exact redacted tool input, deny/allow result, worker-id presence/absence, and terminal artifact reference. It must explicitly state that C2 performed no trust/setup mutation.

- [ ] **Step 6:** Validate and replay the captured fixtures.

```bash
set -euo pipefail
chmod +x dodi-dev/scripts/tests/test-hook-require-model-pin.sh
bash -n dodi-dev/scripts/hook-require-model-pin.sh dodi-dev/scripts/tests/test-hook-require-model-pin.sh
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-agent-tool-schema.redacted.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-hook-payload.redacted.json >/dev/null
python3 -m json.tool dodi-dev/scripts/tests/fixtures/codex-tier/live/codex-terminal-attestation.redacted.json >/dev/null
dodi-dev/scripts/tests/test-hook-require-model-pin.sh
PATH=/tmp/dodi-runtime-contracts-venv/bin:$PATH dodi-dev/scripts/tests/test-codex-tier-adapter.sh --live-attestation-fixture
! rg -ni 'authorization|api[_-]?key|bearer|password|secret|prompt|user_data' dodi-dev/scripts/tests/fixtures/codex-tier/live
```

Expected: final lines `model pin hook tests ok` and `codex live attestation fixture tests ok`; redaction scan has no matches; exit 0.

- [ ] **Step 7:** Prove Gate 2 remained unchanged against the captured `DOD_811_BASE`.

```bash
set -euo pipefail
git diff --exit-code "$DOD_811_BASE" -- dodi-dev/scripts/hook-gate2-guard.sh
python3 - "$DOD_811_BASE" <<'PY'
import json, subprocess, sys
base = json.loads(subprocess.check_output(["git", "show", f"{sys.argv[1]}:dodi-dev/hooks/hooks.json"]))
work = json.load(open("dodi-dev/hooks/hooks.json"))
assert base["hooks"]["PreToolUse"][0] == work["hooks"]["PreToolUse"][0]
print("Gate 2 hook entry unchanged")
PY
```

Expected: no diff output and `Gate 2 hook entry unchanged`; exit 0.

- [ ] **Step 8:** Commit the hook/live-evidence slice.

```bash
git add dodi-dev/scripts/hook-require-model-pin.sh dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/tests/test-hook-require-model-pin.sh dodi-dev/scripts/tests/test-codex-tier-adapter.sh dodi-dev/scripts/tests/fixtures/codex-tier/hook dodi-dev/scripts/tests/fixtures/codex-tier/live
git add dodi-dev/hooks/hooks.json
git commit -m "feat: enforce Codex native model pins"
```

If `hooks.json` is unchanged, `git add` is harmless and does not create metadata churn.

### Task 7: Extend validators with C2 contracts and ownership fences

**Files:**
- Modify: `scripts/validate-runtime-contracts.sh`
- Modify: `scripts/validate-phase-skills.sh`

- [ ] **Step 1:** Extend `validate-runtime-contracts.sh` to schema-check the installed map and map fixtures, run semantic same-tier/cross-tier uniqueness assertions, parse every redacted JSON fixture, and prove the valid profile's four pairs agree with the installed map. Keep DOD-811's profile/health/register/manifest schema checks intact.

- [ ] **Step 2:** Replace only DOD-811's expected C2-absence assertions with C2 presence/contract checks:

- model ids occur only in `dodi-dev/runtime/codex-model-tiers.json` and C2 test fixtures/tests, never installed workflow policy or skill prose;
- all three C2 scripts/tests exist, are executable, and are `bash -n` clean;
- all 20 skill preflights have the exact required tier matrix and production verifier invocation;
- production tier-adapter calls require `--invoke-verifier`; production source rejects `--verification-receipt`, `--assume-verified`, `--skip-generation`, and verification environment bypasses;
- fixture verifier path/case controls occur only below `dodi-dev/scripts/tests/`;
- map/profile pairs agree by semantic tier;
- hook map lookup does not hardcode a second pair list;
- live evidence files exist, parse, name a runtime version, and pass redaction checks.

- [ ] **Step 3:** Add permanent C2 ownership fences while preserving DOD-811's C3-C5 absence checks. Do not put `DOD_811_BASE` byte-diff logic inside `validate-runtime-contracts.sh`; that base-relative audit is Task 8's responsibility where the lane supplies the exact SHA.

- required DOD-811 foundation files still exist and retain their expected public command/schema surfaces: `runtime-preflight.sh bootstrap`, the four runtime schemas, `reap-workers.sh`, `await-worker.sh`, `linear-api.sh`, Gate 2 hook entry shape, and metadata version `0.16.0`;
- C2 scripts contain no `spawn_agent`, `wait_agent`, `close_agent`, manifest append, result persistence, baseline mutation/comparison, close/reap, quarantine/takeover, Linear/Slack/GitHub write, scheduler/task mutation, setup/profile writer, trust grant, or Gate 2 operation;
- `codex-worker-adapter.md` retains `UNSUPPORTED_RUNTIME` for every C3 operation;
- no `setup-dodi-dev`, production profile/register fixture, `validate-codex-compatibility.sh`, `validate-codex-install.sh`, `docs/guides`, `docs/release`, or `0.17.0` metadata exists;
- runtime-policy remains the only operative tier/Fable table and no skill duplicates native ids or policy buckets.

Where a static token such as `close` is too broad, validate exact commands/function names or parse the documented allowlist; do not create a brittle prose substring ban.

- [ ] **Step 4:** Extend `validate-phase-skills.sh` to require/executable-check `codex-tier-adapter.sh`, `codex-capacity-classifier.sh`, all three tests, the installed map/schema, and the all-20 preflight matrix. Keep phase validation dependency-free; the dedicated runtime validator owns jsonschema and cross-document checks.

- [ ] **Step 5:** Verify validators and expected output.

```bash
set -euo pipefail
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
bash -n scripts/validate-runtime-contracts.sh scripts/validate-phase-skills.sh
scripts/validate-runtime-contracts.sh
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
```

Expected, in order: existing DOD-811 runtime schema/fixture success, `codex tier contracts ok`, `phase skills ok`, `plugin metadata ok: 0.16.0`, and `ticket comment templates ok`; all exit 0.

- [ ] **Step 6:** Commit the validator slice.

```bash
git add scripts/validate-runtime-contracts.sh scripts/validate-phase-skills.sh
git commit -m "test: validate Codex tier enforcement contracts"
```

### Task 8: Run complete regression, live-evidence, and C2 ownership audits

**Files:**
- Verify only. Adjust only planned C2 files for a confirmed C2 defect; do not change specs, DOD-811 contracts, C3-C5 surfaces, or metadata to make checks pass.

- [ ] **Step 1:** Run focused C2 tests and every plugin script test.

```bash
set -euo pipefail
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
dodi-dev/scripts/tests/test-codex-tier-adapter.sh
dodi-dev/scripts/tests/test-codex-capacity-classifier.sh
dodi-dev/scripts/tests/test-hook-require-model-pin.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
```

Expected: the three C2 final `... tests ok` lines plus every existing test's final success line; all exit 0.

- [ ] **Step 2:** Run all repository validators.

```bash
set -euo pipefail
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
scripts/validate-runtime-contracts.sh
scripts/validate-plugin-metadata.sh
scripts/validate-phase-skills.sh
scripts/validate-ticket-comment-templates.sh
```

Expected: `codex tier contracts ok`, `plugin metadata ok: 0.16.0`, `phase skills ok`, and `ticket comment templates ok`; all exit 0.

- [ ] **Step 3:** Run the final C2 static contract battery.

```bash
set -euo pipefail
for file in dodi-dev/runtime/*.schema.json dodi-dev/runtime/codex-model-tiers.json; do python3 -m json.tool "$file" >/dev/null; done
bash -n dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/codex-capacity-classifier.sh dodi-dev/scripts/hook-require-model-pin.sh
test "$(find dodi-dev/skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')" -eq 20
test "$(rg -l '^## Codex Main-Loop Preflight$' dodi-dev/skills/*/SKILL.md | wc -l | tr -d ' ')" -eq 20
! rg -n -- '--verification-receipt|--assume-verified|--skip-generation' dodi-dev --glob '!scripts/tests/**'
! rg -n 'fixture-runtime-preflight|FIXTURE_' dodi-dev --glob '!scripts/tests/**'
! rg -n 'spawn_agent|wait_agent|close_agent' dodi-dev/scripts/codex-tier-adapter.sh dodi-dev/scripts/codex-capacity-classifier.sh
grep -qF 'UNSUPPORTED_RUNTIME' dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md
test ! -e dodi-dev/skills/setup-dodi-dev/SKILL.md
test ! -e scripts/validate-codex-compatibility.sh
test ! -e scripts/validate-codex-install.sh
test ! -d docs/guides
test ! -d docs/release
echo 'DOD-812 contract battery ok'
```

Expected: `DOD-812 contract battery ok`; exit 0.

- [ ] **Step 4:** Prove DOD-811 and C3-C5 ownership surfaces did not change. Substitute the exact recorded Task 1 SHA if the shell no longer carries it.

```bash
set -euo pipefail
: "${DOD_811_BASE:?export the exact Task 1 DOD_811_BASE SHA}"
git diff --exit-code "$DOD_811_BASE" -- \
  dodi-dev/runtime/runtime-profile.schema.json \
  dodi-dev/runtime/runtime-health.schema.json \
  dodi-dev/runtime/runtime-register-record.schema.json \
  dodi-dev/runtime/dispatch-manifest-record.schema.json \
  dodi-dev/scripts/runtime-preflight.sh \
  dodi-dev/scripts/reap-workers.sh \
  dodi-dev/scripts/await-worker.sh \
  dodi-dev/scripts/linear-api.sh \
  dodi-dev/scripts/hook-gate2-guard.sh \
  dodi-dev/.claude-plugin/plugin.json \
  dodi-dev/.codex-plugin/plugin.json \
  .claude-plugin/marketplace.json \
  .agents/plugins/marketplace.json
python3 - "$DOD_811_BASE" <<'PY'
import json, subprocess, sys
base = json.loads(subprocess.check_output(["git", "show", f"{sys.argv[1]}:dodi-dev/hooks/hooks.json"]))
work = json.load(open("dodi-dev/hooks/hooks.json"))
assert base["hooks"]["PreToolUse"][0] == work["hooks"]["PreToolUse"][0]
print("C2 unchanged ownership surfaces ok")
PY
```

Expected: no diff output and `C2 unchanged ownership surfaces ok`; exit 0.

- [ ] **Step 5:** Reconfirm required live evidence and redaction. This verifies the already executed native gate; it does not replace it.

```bash
set -euo pipefail
test -s dodi-dev/scripts/tests/fixtures/codex-tier/live/runtime-version.txt
test -s dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md
for file in dodi-dev/scripts/tests/fixtures/codex-tier/live/*.json; do python3 -m json.tool "$file" >/dev/null; done
grep -qF 'missing pin denied before worker id' dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md
grep -qF 'exact Standard pair allowed' dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md
grep -qF 'effective model/reasoning/context/no-inherit attested' dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md
grep -qF 'wrong reasoning denied before worker id' dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md
grep -qF 'unknown pair denied before worker id' dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md
grep -qF 'no trust or setup mutation performed by C2' dodi-dev/scripts/tests/fixtures/codex-tier/live/live-fire-evidence.md
! rg -ni 'authorization|api[_-]?key|bearer|password|secret|prompt|user_data' dodi-dev/scripts/tests/fixtures/codex-tier/live
echo 'DOD-812 live evidence audit ok'
```

Expected: `DOD-812 live evidence audit ok`; exit 0.

- [ ] **Step 6:** Review final scope and diff quality.

```bash
set -euo pipefail
: "${DOD_811_BASE:?export the exact Task 1 DOD_811_BASE SHA}"
git diff --check "$DOD_811_BASE"
git status --short
git diff --stat "$DOD_811_BASE"
git diff --name-only "$DOD_811_BASE" | sort
```

Expected: `git diff --check` exits 0; every changed file appears in this plan's File surface; no production profile/receipt, secret, C3 lifecycle implementation, C4 setup/register/scheduler/escalation/Gate 2 implementation, C5 validator/docs, metadata bump, or v0.16 workflow redesign appears.

- [ ] **Step 7:** Commit only a narrow C2 correction if Task 8 exposed one. If no file changed, do not create an empty commit.

```bash
git add <only-planned-C2-files-adjusted-for-a-confirmed-C2-defect>
git commit -m "fix: close DOD-812 tier enforcement gaps"
```

## Handoff Assumptions And Blockers

- DOD-811 lands before implementation with its approved profile/health/register/manifest schemas, installed runtime policy, adapter documents, root bootstrap, validator, and explicit Codex lifecycle fence. Material drift is an epic/spec decision, not permission for C2 to shadow the contract.
- C4's future `runtime-preflight.sh verify-profile` producer will implement the ephemeral same-command proof contract documented by C2: operation/nonce/repo plus canonical profile, health, register tip, generation, runtime/catalog, and stable-read evidence. Until it exists, production C2 operations correctly return `SETUP_REQUIRED`; only the fixture verifier may make deterministic tests pass.
- C3 will consume `TIER_READY`, native pin field observations, `context_inheritance`, `WORKER_TIER_VERIFIED`, and classifier output at DOD-811's existing durable seams. It must not duplicate map selection, capacity signatures, or effective-tier comparison.
- C4 owns setup, model probing, profile/health/register writes, trust grants, task configuration, drift repair, Gate 2, and escalation. A pre-trusted development installation is required for C2 live-fire, but C2 must not create it.
- C5 will rerun these deterministic and live checks in the isolated install/release matrix and owns release documentation, final compatibility validators, and the synchronized `0.17.0` metadata bump.
- The four approved model/reasoning pairs remain the 0.17 defaults. Runtime rejection is a hard implementation/live-gate blocker, not permission to choose an unreviewed fallback.
- The supported Codex Desktop runtime is assumed to expose explicit model/reasoning request fields, an interceptable pre-spawn hook payload, effective terminal model/reasoning/context identity, and runtime-observed no-inherit evidence. If any is absent, return `BLOCKED` for DOD-812 and DOD-810; do not substitute prompt claims, launch settings, different ids, fixtures, discovery, or post-spawn cancellation.
- No plan-time architecture blocker is known. The implementation remains incomplete until both deterministic checks and the current-runtime live-fire evidence pass.
