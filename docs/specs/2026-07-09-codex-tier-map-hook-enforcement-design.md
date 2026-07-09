# DOD-812 - Codex Tier Map and Model-Pin Enforcement

## TL;DR

DOD-812 implements the Codex side of the existing semantic model-tier policy: a versioned Frontier/Capable/Standard/Fast map, fail-closed main-loop verification, explicit native worker model/reasoning pins, effective-attestation checks, approved Frontier capacity routing, and a model-pin hook that actually fires on Codex agent dispatches. It consumes DOD-811's installed runtime canon, profile schema, adapter operations, manifest vocabulary, and generation-binding boundary without creating a profile, spawning or managing a worker, or changing workflow policy.

Codex output is usable only when the requested semantic tier resolves through a same-invocation current profile/health/register verification proof and runtime-supplied evidence attests the expected effective model, reasoning effort, context identity, and required no-inherit/fresh-context property. Missing mappings, stale profile/register evidence, malformed or absent attestation, unknown failure text, an unrecognized hook payload, or an unpinned dispatch fails closed; there is no ambient-model fallback and no guessed substitute.

## Key Points

- Ship `dodi-dev/runtime/codex-model-tiers.json` as versioned adapter data, validated by a colocated schema. The approved initial pairs are Frontier `gpt-5.6-sol`/`xhigh`, Capable `gpt-5.5`/`xhigh`, Standard `gpt-5.6-terra`/`medium`, and Fast `gpt-5.6-luna`/`low`.
- Preserve Frontier/Capable/Standard/Fast as the only workflow vocabulary. Codex model ids and reasoning values never appear as replacement policy in skills or lane playbooks.
- Every Codex entry-point skill verifies its required main-loop tier from runtime-attested session/thread metadata before judgment, workflow writes, or worker dispatch. Claude `model:` frontmatter remains unchanged and non-operative on Codex.
- C2 resolves worker pins and verifies terminal attestation, but C3 owns durable intent, native spawn/wait/close, result persistence, manifest writes, reaping, quarantine, and takeover.
- Only recognized, structured capacity failures for the already-proven Frontier pair enter the installed hard/deferred/soft Fable policy. Unknown errors, wrong pairs, auth/permission failures, and absent attestation never substitute.
- Update only the model-pin hook entry and `hook-require-model-pin.sh`. Gate 2 payload normalization, branch protection, hook trust/setup, scheduling, and escalation remain C4-owned.
- Hook discovery is not evidence. C2 must live-fire a missing-pin deny and an exact native-pin allow against the supported Codex runtime, while deterministic fixtures cover malformed, wrong-pair, Claude, and broad-matcher non-dispatch cases.
- C2 remains fenced until C4 provides a valid generation-bound profile verification result and C3 provides the native worker lifecycle. It does not make Codex lights-out operation available by itself.
- ⚠ The exact Codex hook tool name, pin field names, attestation envelope, and no-inherit evidence are runtime-observed adapter details. Implementation must pin the observed supported shape in fixtures and fail closed if it differs; it may not invent compatibility from a launch setting, prompt text, different context id, or different worker id.

## Decision Context

The DOD-810 parent design was approved at `baf219a`. DOD-811's approved foundation spec and plan are canonical downstream inputs at epic commit `978cad7`.

DOD-811 owns and fixes these boundaries for C2:

- the installed runtime-policy location and the semantic tier/Fable tables;
- the canonical profile path and the profile `models` object;
- profile/health/register generation binding and `verify-state-generation` ownership;
- the dispatch-manifest location, schema envelope, state names, nonce/worker keys, and terminal ordering;
- the adapter operations `resolve-tier` and `verify-attestation`, which C2 implements for Codex;
- the explicit C1 `UNSUPPORTED_RUNTIME` fence until later children implement their adapters.

This spec does not amend those contracts. A required change to a DOD-811 field, path, state, identity key, generation rule, or policy owner is a DOD-811/DOD-810 design issue, not an implementation choice in DOD-812.

## Problem

The released workflow describes model requirements with Claude aliases. Claude Code uses `model:` skill frontmatter for the main loop and an Agent-tool `model` parameter for workers. Codex ignores the frontmatter, does not expose the Claude aliases as native model ids, and may deliver a different hook payload for native agent spawning.

That creates four unsafe gaps:

1. A Codex skill can perform judgment work on the task's ambient model even when the workflow requires a different semantic tier.
2. A worker request can name a desired model without proving the runtime accepted the requested model/reasoning pair or gave it a fresh context.
3. A Frontier dispatch failure can be mistaken for capacity and silently downgraded even when the real cause is an invalid model, auth, permission, malformed input, or an unknown runtime failure.
4. The current `Task|Agent` hook matcher and Claude-shaped `tool_input.model` extraction may be discovered by Codex without intercepting the actual native spawn operation.

The result would look operational while violating the review-diversity and fail-closed invariants that the workflow depends on.

## Goals

1. Define and validate one versioned Codex mapping from the four canonical semantic tiers to ordered native model/reasoning candidates.
2. Verify required Codex main-loop tiers from effective runtime attestation before any tier-sensitive work.
3. Produce exact native worker pin data from the verified profile and reject output whose effective attestation does not satisfy the requested tier and gate policy.
4. Connect recognized Frontier capacity failures to the existing hard/deferred/soft policy without changing that policy or its durable artifacts.
5. Make the model-pin hook enforce explicit valid pins on both Claude Agent and Codex native agent dispatch payloads.
6. Provide deterministic fixtures and a required current-runtime live-fire gate that a plan writer and implementer can execute without implementing C3-C5.
7. Preserve all Claude Code behavior and the single canonical skill tree.

## Non-Goals

- No Codex worker lifecycle implementation: no native spawn, wait, completion, close, reap, recovery, takeover, quarantine, baseline comparison, result-artifact persistence, or manifest mutation. Those are C3.
- No new dispatch-manifest field, state, key, path, or terminal ordering. C2 supplies values to DOD-811's existing requested/effective fields.
- No runtime profile or health writer, `verify-profile` implementation, setup skill, Linear register operation, auth bridge, hook-trust grant, marketplace migration, scheduled-task creation, wake test, Gate 2 expansion, branch-protection check, Slack delivery, or escalation flow. Those are C4.
- No isolated Codex install smoke, end-to-end release validator, install guide, release evidence bundle, or metadata bump to `0.17.0`. Those are C5.
- No change to semantic tier assignments, Fable gate-policy buckets, delivery-tier routing, review-round counts, catch-attribution grammar, `CAPACITY_PARK`, `FABLE_MAKEUP`, or retry-ceiling behavior.
- No attempt to make Codex honor Claude `model:` frontmatter or to switch the active model inside an already-started Codex task.
- No arbitrary fallback candidate, ambient model, operator assertion, launch profile, or prompt instruction treated as effective-tier evidence.
- No model-pin compatibility work for the Gate 2 hook. C2 must avoid altering the Gate 2 matcher or script while changing the shared hook metadata file.

## Binding Contracts

### Installed policy

After DOD-811 lands, `dodi-dev/skills/epic-orchestrator/runtime-policy.md` is the only installed operative home for semantic tiers, Fable policy, dispatch discipline, and context independence. C2 may add Codex adapter links and operational instructions there, but must not copy the tier or Fable tables into a second skill file.

### Static profile

C2 consumes the DOD-811 `runtime-profile.schema.json` fields:

```text
runtime.kind
runtime.version
runtime.model_catalog_sha256
models.frontier.id / reasoning
models.capable.id / reasoning
models.standard.id / reasoning
models.fast.id / reasoning
generated_by.setup_run_id
plugin.root / version
```

C2 never writes them. C4 resolves candidates by live probe, writes the complete static profile, and verifies profile/health/register generation binding. C2 accepts tier work only by invoking C4's verifier during the same adapter command. The verifier result must identify the canonical profile path, exact profile hash, `setup_run_id`, runtime version, catalog fingerprint, health projection path/hash, Linear register issue id, register cursor sequence/comment/hash, register tip evidence, stable-read/lock evidence, requested operation, and caller-provided operation nonce. Until `runtime-preflight.sh verify-profile` exists and returns that proof, C2 production commands return `SETUP_REQUIRED` without workflow writes.

The proof is not a reusable local permission slip. The adapter never accepts caller-supplied proof files, cached verifier stdout, or production receipt paths. It invokes the verifier itself and consumes the returned JSON only for that one command. C2 does not define the verifier's signing/HMAC secret, receipt store, register read, health replay, or lock mechanics; those remain C4. It does define the consumer contract: wrong-operation, wrong-nonce, wrong-repo, wrong-profile, wrong-health, wrong-cursor, missing-register-tip, missing-lock-evidence, unverifiable verifier output, or an unavailable verifier returns `SETUP_REQUIRED`. Re-hashing the profile alone is insufficient evidence.

### Worker adapter

C2 implements only these DOD-811 operation results:

| Operation | C2 postcondition |
| --- | --- |
| `resolve-tier` | Return one semantic tier plus the exact requested Codex model/reasoning pair from the verified profile, or fail closed. |
| `verify-attestation` | Compare requested tier/pair and gate context requirements to runtime-attested effective model/reasoning/context identity; return verified evidence or `TIER_UNVERIFIED`. |

C3 remains responsible for calling those operations at the durable boundaries, writing the requested values into `dispatch-intent`, persisting the effective values in the normalized result artifact/terminal record, and handling any invalid mutable output. `resolve-worker` and `verify-worker` are not separate adapter operations; if a shell command uses those words internally, it must be a thin CLI alias to the canonical `resolve-tier` and `verify-attestation` operations and emit the same JSON contract.

### Failure vocabulary

C2 uses these externally visible outcomes:

| Outcome | Meaning |
| --- | --- |
| `TIER_READY` | Requested tier resolved to an exact pair from a currently verified profile. |
| `MAIN_LOOP_VERIFIED` | Effective session/thread attestation matches the required tier. |
| `WORKER_TIER_VERIFIED` | Effective worker pair and required context-independence checks pass. |
| `FRONTIER_CAPACITY` | A structured allowlisted failure matches the already-proven Frontier pair after bounded retries. |
| `SETUP_CAPACITY_WAIT` | Setup-time Frontier probe remained capacity-blocked; C4 must not enable/write a profile. |
| `TIER_UNVERIFIED` | Effective model/reasoning/context evidence is absent, malformed, mismatched, or cannot prove independence. |
| `SETUP_REQUIRED` | Profile verification, map/catalog/runtime binding, auth/permission/model validity, or another static prerequisite is invalid or unknown. |

These outcomes are adapter results, not new manifest states. C3 maps `TIER_UNVERIFIED` to DOD-811's existing `attestation-invalid` path after persisting terminal output, and C4 owns setup behavior for `SETUP_CAPACITY_WAIT`/`SETUP_REQUIRED`.

## Design

### 1. Versioned Codex model map

Create:

- `dodi-dev/runtime/codex-model-tiers.schema.json`
- `dodi-dev/runtime/codex-model-tiers.json`

The map is installed adapter data, not mutable user state. Schema version 1 contains:

```json
{
  "schema_version": 1,
  "map_version": 1,
  "runtime": "codex",
  "tiers": {
    "frontier": {
      "candidates": [
        {"model": "gpt-5.6-sol", "reasoning": "xhigh"}
      ]
    },
    "capable": {
      "candidates": [
        {"model": "gpt-5.5", "reasoning": "xhigh"}
      ]
    },
    "standard": {
      "candidates": [
        {"model": "gpt-5.6-terra", "reasoning": "medium"}
      ]
    },
    "fast": {
      "candidates": [
        {"model": "gpt-5.6-luna", "reasoning": "low"}
      ]
    }
  }
}
```

The schema requires positive integer `schema_version` and `map_version`, exactly the four lowercase semantic-tier keys, at least one ordered candidate per tier, non-empty model/reasoning strings, unique pairs within each candidate list, and no unknown fields for schema v1. `validate-map` adds the cross-tier semantic check: a candidate pair may appear in only one tier in the same map, otherwise a hook could not infer an unambiguous tier from native pin fields. The shipped initial map has one approved candidate per tier. Adding or reordering a later candidate increments `map_version` in a versioned plugin change; it is not local setup mutation. DOD-811's existing plugin version/root and runtime catalog fingerprint bind the installed map without adding a new profile field.

Candidate order is discovery order only. Catalog presence does not select or prove a pair. C4 must probe candidates in order and place only a successful pair into each `profile.models.<tier>` entry. C2 verifies that every profile pair is present under the same tier in the installed map and that the profile's runtime version/catalog fingerprint is the one C4 just verified. A profile pair absent from the installed map is `SETUP_REQUIRED`, even if Codex accepts it.

The map contains no profile path, setup generation, hook trust, scheduler setting, capacity policy bucket, or lifecycle state.

### 2. Read-only tier adapter

Create `dodi-dev/scripts/codex-tier-adapter.sh` as the deterministic implementation surface. Use shell for command/exit handling and Python standard-library JSON/schema-adjacent semantic checks consistent with DOD-811's scripts. It is read-only and prints one JSON object to stdout; diagnostics go to stderr and never include prompt content, credentials, or arbitrary environment values.

Required command surface:

```text
codex-tier-adapter.sh validate-map --map <absolute-path>
codex-tier-adapter.sh resolve-tier --tier <tier> --profile <file> --invoke-verifier <absolute runtime-preflight.sh> --repo <owner/name> --operation-nonce <nonce>
codex-tier-adapter.sh verify-main-loop --tier <tier> --profile <file> --attestation <file> --invoke-verifier <absolute runtime-preflight.sh> --repo <owner/name> --operation-nonce <nonce>
codex-tier-adapter.sh verify-attestation --tier <tier> --profile <file> --request <file> --attestation <file> [gate context arguments] --invoke-verifier <absolute runtime-preflight.sh> --repo <owner/name> --operation-nonce <nonce>
```

The verifier input is the C4-owned same-invocation state-generation proof described above. C2 re-hashes/re-reads the named profile and any verifier-reported health bytes before use, then verifies the operation/nonce/repo/profile/health/register/runtime/catalog binding in the live verifier output. C4 owns how the report is generated and all health/register checks. A missing verifier, wrong operation, wrong nonce, wrong status, stale hash, path mismatch, changed file, unknown field/version, missing health/register binding, or non-Codex runtime returns `SETUP_REQUIRED`.

The implementation may include a fixture-only verifier executable under `dodi-dev/scripts/tests/fixtures/` for C2 tests before C4 lands. Production skills and scripts must pass the installed `runtime-preflight.sh` verifier path, and validators reject `--assume-verified`, `--skip-generation`, `--verification-receipt`, environment escape hatches, or test verifier paths outside test files.

`resolve-tier` returns the semantic tier and exact native pin pair from `profile.models.<tier>`. It does not spawn, write an intent, or guess native tool fields. The caller supplies the returned values to C3's `prepare-intent` and spawn operation.

Exit meanings are stable:

- `0`: named success status with complete JSON;
- `2`: usage, missing dependency, or malformed local input;
- `3`: `SETUP_REQUIRED`;
- `4`: `TIER_UNVERIFIED`;
- `5`: safe-output failure with no partial stdout.

Capacity classification is a separate pure operation because a dispatch failure is not tier success.

### 3. Main-loop preflight

Every released entry-point skill has a required main-loop tier:

- a `model:` frontmatter alias maps through installed policy (`fable` -> Frontier, `opus` -> Capable, `sonnet` -> Standard, `haiku` -> Fast);
- `brainstorm` and `write-plan`, which intentionally omit frontmatter for Claude interactive behavior, require Frontier as already stated by installed policy.

Add a concise `## Codex Main-Loop Preflight` section to all 20 `dodi-dev/skills/*/SKILL.md` files, or an equivalent mechanically validated first-step reference that keeps each required tier explicit. It must run after DOD-811 root bootstrap/profile verification and before the skill asks judgment questions, reads bulk workflow state, writes an artifact, mutates Git/PM state, or dispatches a phase worker.

The preflight passes harness-supplied effective session/thread metadata to `verify-main-loop`. Valid evidence contains at least:

- runtime kind and version;
- effective model id;
- effective reasoning value;
- current session/thread context id;
- an attestation source/type recognized for the supported runtime version.

The configured task model, frontmatter value, requested launch pair, model catalog, profile pair, task title, operator statement, and model name in a prompt are not effective evidence.

If the evidence is missing, unrecognized, stale for another context, or mismatched, the skill returns `TIER_UNVERIFIED` before tier-sensitive work. Recovery is a fresh Codex task launched on the required setup-verified pair and exposing supported runtime attestation; the running task does not attempt an in-place model switch.

The check applies to manual and scheduled Codex entry points. C4 owns configuring scheduled tasks and supplying valid generation proof. Claude Code follows its existing frontmatter behavior and does not acquire a Codex profile prerequisite.

### 4. Native worker pins and attestation

For every Codex worker dispatch, the top-level dispatcher obtains `TIER_READY` before C3 writes the durable intent. The exact pair is carried in DOD-811's existing fields:

```text
semantic tier
requested model
requested reasoning
profile setup_run_id
profile hash
```

The pair is then supplied to the runtime's actual native model and reasoning pin fields. The field names are pinned from the supported Codex runtime's observed tool schema and live hook payload; prose-only prompt metadata is not a pin. If the runtime has no explicit field for both values, C2 cannot claim worker-tier support and returns `TIER_UNVERIFIED`/an implementation blocker rather than embedding the values in the prompt.

After C3 receives and durably persists terminal output, it calls `verify-attestation` before consuming the digest. C2 compares:

1. requested semantic tier and pair against the still-current verified profile and installed map;
2. runtime-attested effective model and reasoning against the request;
3. attested worker context identity against the dispatch/session identities and gate-specific independence requirements;
4. runtime-attested context lineage/inheritance evidence against the request's declared independence mode;
5. where applicable, the effective writer/reviewer models and context ids supplied by the gate.

Gate-specific rules remain exactly those approved by DOD-810:

- spec drafting and final spec review both use Frontier, but must have different attested context ids and the reviewer must be launched with runtime-attested inherited-context disabled;
- a hard-policy Frontier delivery final must attest a model id different from its Standard/Capable writer;
- a deferred/soft Frontier substitution may equal the writer only when the existing `tier-degraded(fable→<tier>,<policy>)` attribution and any required `FABLE_MAKEUP` obligation are recorded;
- worker id inequality and context id inequality alone never prove context independence.

The C3 spawn request must carry an explicit `context_inheritance` value in its request evidence: `fresh-required`, `may-inherit`, or `same-context-required`. Frontier final spec-review and every gate requiring independent judgment use `fresh-required`. For `fresh-required`, accepted evidence must include a runtime-observed field or signed attestation that inheritance/thread carryover was disabled for the worker plus the new effective context id. If the supported Codex runtime exposes no ancestry/inheritance field and no explicit no-inherit launch option whose use is attested in terminal metadata, `verify-attestation` returns `TIER_UNVERIFIED` and the gate cannot pass. Prompt text, a new worker id, a different context id, or an operator assertion is not non-inheritance evidence.

`verify-attestation` returns a compact verified evidence object suitable for inclusion under the Codex terminal record's existing `data` namespace. It does not append the record. Missing or mismatched evidence returns `TIER_UNVERIFIED`; C3 must persist `attestation-invalid`, close/reap, compare the baseline, and quarantine mutable output according to its own spec.

### 5. Frontier capacity classifier and policy routing

Create `dodi-dev/scripts/codex-capacity-classifier.sh` as a pure, read-only classifier with checked-in fixtures. It accepts a normalized runtime failure plus the verified requested tier/pair/runtime/catalog binding and returns one of:

```text
FRONTIER_CAPACITY
NOT_CAPACITY
SETUP_REQUIRED
```

Recognition is allowlist-based and versioned. Only structured fields or runtime-documented error codes/status values observed in the supported Codex runtime may produce `FRONTIER_CAPACITY`. Free-form substring matching such as `capacity`, `busy`, `model`, `quota`, or `unavailable` is forbidden. The classifier also requires:

- requested semantic tier is Frontier;
- requested pair exactly equals the profile's already-proven Frontier pair;
- runtime version/catalog binding matches the current verified proof;
- the failure is from the actual spawn/probe attempt for that request.

Invalid model/reasoning, auth, permission, account quota, malformed request, network ambiguity, unknown rejection, missing fields, stale profile proof, and failures for Capable/Standard/Fast return `NOT_CAPACITY` or `SETUP_REQUIRED`; they never trigger Fable substitution.

The executing dispatcher retains the installed policy's bounded detection sequence: initial failure, two spaced retries of the same exact Frontier request, then classification/policy application. C2 does not invent a new retry count or durable state.

Routing after recognized failure is the existing installed policy:

- **setup probe:** return `SETUP_CAPACITY_WAIT`; C4 writes no enabled profile and performs no substitution;
- **hard workflow gate:** a resident driver uses existing `pending-capacity` + `CAPACITY_PARK` + continuation-brief mechanics; a manual session stops and reports to the operator;
- **deferred workflow gate:** resolve and explicitly pin the Capable pair, verify its effective attestation, append the existing degradation marker, and queue the existing `FABLE_MAKEUP` obligation;
- **soft workflow gate:** resolve and explicitly pin the Capable pair, verify its effective attestation, and append the existing degradation marker without a make-up obligation.

Persistent park/probe flapping remains governed by the existing no-progress retry ceiling. C2 does not write labels, register comments, continuation briefs, or obligations itself; it supplies the classification and verified substitute pin that the existing lane/driver owns.

### 6. Model-pin hook normalization and enforcement

Modify:

- `dodi-dev/scripts/hook-require-model-pin.sh`
- only the model-pin hook entry in `dodi-dev/hooks/hooks.json`

Keep the current hook command root form because the approved parent audit found Codex resolves `${CLAUDE_PLUGIN_ROOT}` in installed hook commands. Do not change it unless C2's live-fire disproves that behavior.

The hook must normalize two tested payload families:

1. Claude Code Agent/Task payloads with an explicit valid alias pin.
2. Codex native agent-spawn payloads with explicit model and reasoning pins matching one unambiguous candidate pair in the installed map.

The normalizer uses the actual top-level tool/event identity and exact nested input path observed in fixtures. If `Task|Agent` does not intercept the Codex spawn tool, broaden only the model-pin matcher to the narrowest matcher that live-fire proves works. Under a broad PreToolUse matcher:

- a positively identified non-dispatch tool is an immediate no-op;
- a positively identified dispatch with missing, malformed, duplicate, unknown, or partial pin fields is blocked;
- a dispatch-like/recognized spawn payload whose pin location cannot be normalized is blocked;
- malformed JSON on a matcher known to be dispatch-only is blocked, not silently allowed;
- unrelated tools must not be blocked merely because they lack model fields.

Claude accepted pins are the installed aliases `fable`, `opus`, `sonnet`, and `haiku`; a non-empty arbitrary string is no longer sufficient. Codex accepted pins require both native model and reasoning fields and an exact pair from the installed map. A known model with the wrong reasoning value, a mixed pair across tiers, an omitted reasoning field, an ambient/default marker, or a prompt-only tier declaration is blocked.

The hook is defense-in-depth for request shape. It does not prove effective tier; `verify-attestation` remains mandatory after terminal attestation. The existing `DODI_ALLOW_UNPINNED=1` escape remains available only for non-Dodi interactive work and is covered by regression tests; Dodi workflow/scheduled instructions must never set it. C4 owns setup/trust enforcement and C5 owns final installed-release validation.

Hook diagnostics name the semantic fix without leaking prompt content or dumping the payload. Codex messages use semantic tiers and the expected native field names; Claude messages retain alias guidance.

### 7. Integration with DOD-811, C3, C4, and C5

#### DOD-811 landing order

C2 implementation starts from the landed DOD-811 code, not from parallel re-creations of its planned files. Any file list below that names a DOD-811-created surface means modify/consume that landed surface.

#### C3 handoff

C3 consumes:

- `resolve-tier` output before `prepare-intent`/spawn;
- the observed native pin field contract;
- `verify-attestation` after durable result persistence and before digest consumption;
- the `context_inheritance` request/evidence contract for independent Frontier gates;
- classifier output for a failed Frontier spawn;
- attestation-invalid evidence for C3's existing close/reap/baseline/quarantine path.

C3 must not duplicate map selection, capacity signatures, or effective-tier comparison in its lifecycle adapter.

#### C4 handoff

C4 consumes:

- map candidate order for setup probes;
- `validate-map` and tier verification operations;
- setup-only `SETUP_CAPACITY_WAIT` behavior;
- the same-invocation verifier consumer requirements;
- model-pin hook hash/key and live-fire cases for setup trust verification;
- main-loop requirements when configuring scheduled tasks.

C4 owns the proof producer, profile writes, drift checks, trust grants, automation, Gate 2, and escalation. C2's tests may use fixtures but cannot create production runtime state.

#### C5 handoff

C5 includes C2's deterministic tests and repeats all live-fire/model-attestation checks in the isolated install and release gate. C2 does not create `scripts/validate-codex-compatibility.sh`, `scripts/validate-codex-install.sh`, release docs, or change metadata.

## Proposed File Surfaces

### New files

| File | C2 responsibility |
| --- | --- |
| `dodi-dev/runtime/codex-model-tiers.schema.json` | Versioned installed map grammar and uniqueness constraints. |
| `dodi-dev/runtime/codex-model-tiers.json` | Approved initial ordered Codex model/reasoning candidates. |
| `dodi-dev/scripts/codex-tier-adapter.sh` | Read-only map/profile resolution plus main-loop and worker-attestation verification. |
| `dodi-dev/scripts/codex-capacity-classifier.sh` | Version-bound structured Frontier-capacity classification only. |
| `dodi-dev/scripts/tests/test-codex-tier-adapter.sh` | Map, profile binding, main-loop, worker attestation, independence, and fail-closed fixtures. |
| `dodi-dev/scripts/tests/test-codex-capacity-classifier.sh` | Positive exact signatures and negative arbitrary/auth/model/quota/network cases. |
| `dodi-dev/scripts/tests/test-hook-require-model-pin.sh` | Claude/Codex payload normalization, allow/deny, malformed, broad-matcher no-op, and redaction tests. |
| `dodi-dev/scripts/tests/fixtures/codex-tier/` | Redacted runtime-versioned model, attestation, capacity, and hook payload fixtures. |

### Modified files

| Surface | C2 edit |
| --- | --- |
| `dodi-dev/skills/epic-orchestrator/runtime-policy.md` | Link the Codex tier adapter; state preflight/attestation/capacity application without duplicating policy tables. |
| `dodi-dev/skills/epic-orchestrator/runtime/worker-adapter-contract.md` | Mark Codex `resolve-tier`/`verify-attestation` as C2-implemented while lifecycle remains C3-blocked. |
| `dodi-dev/skills/epic-orchestrator/runtime/codex-worker-adapter.md` | Document the callable C2 tier operations but retain `UNSUPPORTED_RUNTIME` for spawn/wait/close/recovery until C3. |
| `dodi-dev/runtime/adapter-contracts.md` | Add map/profile/attestation cross-binding and C2-C4 consumer links; do not change paths or states. |
| `dodi-dev/skills/*/SKILL.md` | Mechanically validated Codex main-loop preflight reference with the skill's existing required semantic tier. |
| `dodi-dev/scripts/hook-require-model-pin.sh` | Normalize and validate Claude and Codex dispatch pin shapes, fail closed for recognized dispatch ambiguity. |
| `dodi-dev/hooks/hooks.json` | Change only the model-pin matcher if live-fire proves `Task|Agent` misses Codex native spawn. |
| `scripts/validate-runtime-contracts.sh` | Replace C1's expected C2-absence assertions with map/schema/script/reference checks. |
| `scripts/validate-phase-skills.sh` | Require/executable-check the C2 scripts/tests and required skill preflight references. |

### Explicitly unchanged

- DOD-811 profile, health, register, and dispatch-manifest schemas except registering the separate model-map schema in validators;
- `dodi-dev/scripts/runtime-preflight.sh` production command surface in C2;
- `dodi-dev/scripts/reap-workers.sh`, `await-worker.sh`, and every lifecycle operation;
- `dodi-dev/scripts/hook-gate2-guard.sh` and the Gate 2 hook matcher;
- skill frontmatter aliases and all lane/review/Fable assignments;
- Linear, Slack, GitHub, marketplace, automation, setup, and metadata files.

## Validation Strategy

### Deterministic unit and contract tests

`test-codex-tier-adapter.sh` must cover at least:

- valid map and exact four-tier initial defaults;
- unknown schema/runtime/tier/field, duplicate pair, empty candidate list, and cross-tier duplicate rejection;
- every profile pair must occur under the same installed-map tier;
- same-invocation verifier profile/health/register/setup/runtime/catalog binding, wrong-operation rejection, wrong-nonce rejection, stale proof rejection, unavailable-verifier rejection, production `--verification-receipt` rejection, and changed-after-proof rejection;
- all 20 entry-point main-loop requirements, including Frontier for `brainstorm` and `write-plan`;
- matching main-loop evidence, wrong model, wrong reasoning, missing context, stale/foreign context, unsupported attestation source, and launch-setting-only rejection;
- matching worker evidence, wrong/missing effective pair, same-context spec reviewer rejection, missing no-inherit evidence rejection, inherited-context rejection, hard-final writer-model equality rejection, and correctly attributed deferred/soft equality acceptance;
- no secret/prompt/payload dump and no partial stdout on output failure.

`test-codex-capacity-classifier.sh` must cover:

- each exact structured positive signature captured from the supported runtime;
- same code with wrong runtime version, catalog, semantic tier, model, or reasoning;
- free-form text containing tempting words;
- invalid model, auth, permission, account quota, malformed request, network timeout, transport ambiguity, and unknown errors;
- setup mapping to `SETUP_CAPACITY_WAIT` without fallback and workflow mapping only after the existing retry count.

`test-hook-require-model-pin.sh` must cover:

- Claude Agent and Task valid aliases allowed;
- missing and arbitrary Claude model values blocked;
- Codex native exact pair allowed;
- missing model, missing reasoning, wrong reasoning, mixed-tier pair, unknown pair, ambient/default marker, and prompt-only declaration blocked;
- exact observed dispatch tool identities and payload paths;
- recognized dispatch malformed/ambiguous payload blocked;
- positively identified non-dispatch payload allowed under any broad matcher;
- `DODI_ALLOW_UNPINNED=1` legacy behavior isolated to its explicit test;
- diagnostics are concise and redacted.

### Contract integration

Extend `scripts/validate-runtime-contracts.sh` to:

- schema-check the model map and fixtures;
- enforce that static map pairs and profile fixture pairs agree by semantic tier;
- enforce that Codex model ids live in adapter data/fixtures, not workflow policy prose;
- require every Codex entry-point tier preflight and reject production bypass flags;
- require C2 scripts to be read-only, executable, `bash -n` clean, and free of worker lifecycle/PM/scheduler operations;
- remove DOD-811's assertions that C2 files/model ids are absent, while preserving C3-C5 absence assertions;
- preserve profile paths, manifest states, metadata `0.16.0`, and the C1 `UNSUPPORTED_RUNTIME` lifecycle fence.

### Required Codex live-fire

Before DOD-812 is considered implementation-complete, run on the parent-approved supported Codex Desktop/plugin runtime and record the runtime version plus redacted observed schemas in test fixtures/evidence:

1. inspect the native agent tool schema and hook payload without storing prompt/user data;
2. invoke one disposable native agent dispatch with the model pin omitted and prove the hook denies it before an agent id is returned;
3. invoke one disposable dispatch with the exact Standard pair and prove the hook allows it;
4. prove terminal metadata attests the expected effective model, reasoning, worker context id, and requested no-inherit/fresh-context evidence usable by `verify-attestation`;
5. invoke wrong-reasoning and unknown-pair deny cases without creating a worker;
6. if the matcher was broadened, invoke one representative non-dispatch tool and prove it is unaffected;
7. run one Claude-shaped allow and deny fixture/smoke so shared hook compatibility is not lost.

Discovery, `hooks/list`, or a unit fixture alone does not satisfy this gate. Hook trust provisioning is C4-owned; C2 may use an explicitly trusted development installation for the live test but must not add setup mutation. If native explicit model/reasoning pins, effective attestation, or an interceptable pre-spawn hook payload are unavailable, DOD-812 remains blocked and DOD-810 cannot claim Codex tier enforcement; implementation must not degrade to prompt instructions or post-spawn cancellation.

### Repository regression

Run:

```bash
scripts/validate-runtime-contracts.sh
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
```

Expected metadata remains `0.16.0` until C5. Existing Claude tests and workflow semantics must remain green.

## Acceptance Criteria

1. The installed model map schema parses, contains exactly the approved four initial pairs, rejects ambiguity, and is the only Codex model-id authority consumed by runtime code.
2. Every profile-resolved pair is bound to the same semantic tier in the installed map and to current C4 verification evidence; stale or absent proof returns `SETUP_REQUIRED`.
3. Every Codex entry-point skill checks its required effective main-loop tier before judgment, writes, or dispatch, including Frontier checks for `brainstorm`, `write-plan`, and `mature-ticket`.
4. Every Codex worker request carries an explicit native model and reasoning pin resolved from the verified profile; ambient defaults and prompt-only pins are rejected.
5. Runtime-attested effective worker model/reasoning/context identity and required inheritance/fresh-context evidence are verified before output consumption; requested values alone never pass.
6. Spec-review context independence and hard delivery writer/reviewer diversity are enforced from attested identities; deferred/soft equality is accepted only with existing degradation/make-up evidence.
7. Only allowlisted structured failures for the current proven Frontier pair enter Fable capacity handling after the approved retries. All ambiguous/non-Frontier failures fail closed without substitution.
8. The model-pin hook live-fires on current Codex native spawn: missing/wrong pins are denied before worker creation and an exact pair is allowed. Broad matching, if required, leaves non-dispatch tools unaffected.
9. Claude Agent/Task aliases remain enforced and existing Claude smoke/tests pass.
10. C2 performs no native worker lifecycle, profile/register/setup/scheduler/escalation operation, isolated release validation, or metadata bump.
11. DOD-811 profile paths, manifest states, generation binding, policy ownership, and C3 lifecycle fence remain unchanged.
12. Deterministic tests, all repository validators, and the required current-runtime C2 live-fire pass with redacted evidence.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Codex model ids or reasoning values change | Versioned ordered map, catalog fingerprint binding, C4 re-probe, no ambient fallback. |
| Requested pin differs from effective execution | Mandatory runtime attestation before consumption; invalid output follows C3 quarantine. |
| Frontmatter creates false confidence on Codex | Explicit per-entry-point main-loop preflight; frontmatter documented as Claude-only mechanics. |
| Capacity text is over-classified | Structured versioned allowlist plus negative fixtures; arbitrary text never substitutes. |
| Broad hook matcher blocks unrelated tools | Normalize tool identity first, no-op for proven non-dispatch tools, live-fire an allow case. |
| Hook allows a request but runtime changes it | Hook is request-shape defense only; terminal attestation is the authoritative tier check. |
| C2 accidentally implements C3 lifecycle | Scripts are read-only and validators reject spawn/wait/close/reap/manifest mutation. |
| C2 duplicates C4 generation logic | Require same-invocation C4 verifier proof; no profile writer, search, health/register replay, receipt consumption, or bypass. |
| Shared hook edit disturbs Gate 2 | Change only the model-pin entry; validate Gate 2 metadata/script byte-for-byte against the C2 base where practical. |
| Live runtime lacks pin/attestation/hook capability | Block DOD-812 and release; do not weaken the approved architecture. |

## Delegated Assumptions

- ⚠ **Approved, non-blocking for drafting:** the four parent-spec initial Codex model/reasoning pairs are the 0.17 release defaults. Runtime rejection is an implementation/live-gate blocker, not permission to select an unreviewed pair.
- ⚠ **Runtime-observed adapter shape:** current Codex exposes explicit worker model and reasoning inputs, effective model/reasoning/context attestation, and a pre-spawn hook payload. C2 must capture the exact redacted shape and fail closed if the live runtime disproves any part.
- ⚠ **C4 proof handoff:** C4's `verify-profile` success report can provide canonical profile path/hash, health projection binding, register cursor/tip evidence, setup generation, runtime version, and catalog fingerprint without changing DOD-811's stored profile contract. C2 may define consumer requirements but not a competing authority.
- **Binding assumption:** DOD-811 lands before C2 delivery with the approved file paths and schemas. If its implementation differs materially from the approved spec/plan, C2 must reconcile against the landed contract through the epic decision process rather than shadow it.
- **No blocking product or architecture question is open.** The remaining uncertainties are explicit compatibility gates with fail-closed outcomes already approved by DOD-810.
