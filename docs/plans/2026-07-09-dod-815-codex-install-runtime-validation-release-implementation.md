# DOD-815 Codex Install, Runtime Validation, and 0.17.0 Release Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan. Execute Tasks 1-11 in order. DOD-815 is C5 only: treat landed C1-C4 runtime behavior as immutable input, and stop on a missing or incompatible dependency instead of adding a release-only compatibility path.

## TL;DR

DOD-815 turns the landed C1-C4 implementation into one candidate-bound `0.17.0` release verdict. It adds a candidate-safe deterministic validator, a fresh installed-artifact harness, current Codex and Claude live gates, checked operator guidance, and an acyclic `C -> E -> I` provenance chain whose final evidence remains outside the published plugin payload.

The release is blocked by any stale candidate, dependency mismatch, unsupported runtime, incomplete live family, unknown cleanup, secret leak, Claude regression, metadata drift, or unresolved Gate 2 decision. C5 validates and records C1-C4 behavior; it does not redefine that behavior.

## Key Points

- Start only after landed DOD-811 through DOD-814 implementation commits and their owning validators/evidence are present; planning commits are not executable dependencies.
- Keep `scripts/validate-codex-compatibility.sh` default mode read-only, network-free, and valid before final C5 live evidence exists.
- Install from a detached candidate checkout into fresh `HOME`, `CODEX_HOME`, XDG, target-repository, marketplace, and cache roots; never inspect or mutate the operator's normal Codex state.
- Derive the released skill set from canonical `dodi-dev/skills/*/SKILL.md` frontmatter and prove the installed payload, roots, hooks, and metadata match the candidate.
- Stage raw and redacted release evidence outside the repository until candidate C is immutable; commit only redacted artifacts under `docs/release/0.17.0-evidence/` as E.
- Keep the provenance graph acyclic: evidence names C but not E or I, while the release index at I names C and E and no artifact hashes itself or the index.
- Bump only the three version-bearing envelopes to `0.17.0`; `.agents/plugins/marketplace.json` is verify-only, remains versionless, and keeps source `./dodi-dev`.
- Preserve the existing human DOD-810 Gate 2. A validator may emit `RELEASE_READY` but may not merge, auto-merge, tag, publish, alter protection, or enable production tasks.

**Goal:** Prove that one immutable `0.17.0` candidate installs and runs correctly on the supported current Codex Desktop/plugin runtime, preserves focused Claude Code behavior, carries synchronized docs/metadata, and has complete redacted release evidence suitable for the human DOD-810 Gate 2 decision.

**Architecture:** Add one top-level compatibility composer that invokes the owning C1-C4 validators and checks C5 packaging, docs, evidence, and provenance without copying their schemas. Add a separate isolated-install harness that owns only temporary marketplace/cache setup, installed-root discovery, payload comparison, and compact capture. Candidate C contains code, fixtures, docs, metadata, and the release-index template; E adds only redacted live evidence; I fills only the terminal release index.

**Tech Stack:** Bash 3.2-compatible command surfaces, Python 3 standard library for strict JSON/JSONL parsing, canonical serialization, hashing, Git ancestry/diff checks, redaction, and path validation; Git detached worktrees; supported current Codex Desktop/plugin and Claude Code runtimes; existing C1-C4 scripts and shell-test harnesses; `jq`, `rg`, `shasum`/`sha256sum`, and existing repository validators.

**Source of truth:** `docs/specs/2026-07-09-codex-install-runtime-validation-release-design.md @ 0549b53`, constrained by the DOD-810 Gate 1 design at `baf219a`, the parent Decision Register canon, and landed C1-C4 executable contracts. The sibling specs/plans at `978cad7`, `5d084b5`, `a3124f4`, and `a7a63a2` establish ownership and expected handoffs, but the implementation must reconcile the real landed tree before editing C5 surfaces.

**Scope boundaries:**

- C5 owns release validation, installed-artifact proof, final Codex/Claude matrix evidence, release docs, synchronized version metadata, evidence redaction/hashing, provenance restrictions, and release readiness reporting.
- C5 invokes C1 profile/root/register/manifest validation, C2 tier/hook/capacity validation, C3 lifecycle/quarantine/recovery validation, and C4 setup/auth/scheduler/Gate 2/Slack/marketplace validation. It does not parse or reimplement their state machines.
- C5 may reject an upstream contract or return the ticket to its owner. It may not add fallback paths, alternate schemas, relaxed status handling, new tier mappings, lifecycle inference, setup shortcuts, or narrower support claims.
- Final live evidence is repository release evidence, not plugin runtime content. Nothing under `docs/release/0.17.0-evidence/` may be copied into `dodi-dev/` or included in the installed-payload hash.
- The local `/opt/homebrew/bin/codex` observed during planning is legacy `codex-cli 0.38.0` and has no plugin subcommand. It is explicitly unsupported and cannot satisfy any install or live gate; use the parent-approved current Desktop/plugin runtime.
- `.agents/plugins/marketplace.json` is inspect/verify-only by default. A separately approved metadata defect is required before changing it; never add a version property.

## File Structure

### Create

- `scripts/validate-codex-compatibility.sh` - four-mode release verdict composer and C/E/I provenance checker.
- `scripts/validate-codex-install.sh` - temporary-home candidate marketplace/install/discovery/payload harness.
- `scripts/normalize-codex-release-evidence.py` - C5-only formatter that converts already-validated owner command outputs and redacted native observations into sorted release JSONL; it never interprets C1-C4 runtime semantics.
- `dodi-dev/scripts/tests/test-codex-release-validation.sh` - deterministic positive/negative C5 test suite.
- `dodi-dev/scripts/tests/fixtures/codex-release/cases.jsonl` - fail-closed case inventory and expected status codes.
- `dodi-dev/scripts/tests/fixtures/codex-release/secret-canaries.txt` - synthetic scanner canaries only.
- `dodi-dev/scripts/tests/fixtures/codex-release/release-manifest.valid.json` - synthetic valid E-manifest shape with non-real ids/hashes.
- `dodi-dev/scripts/tests/fixtures/codex-release/installed-payload-manifest.valid.json` - synthetic path/mode/hash shape.
- `dodi-dev/scripts/tests/fixtures/codex-release/codex-release-matrix.valid.jsonl` - one synthetic record for every required Codex scenario id.
- `dodi-dev/scripts/tests/fixtures/codex-release/claude-non-regression.valid.jsonl` - one synthetic record for every required Claude scenario id.
- `dodi-dev/scripts/tests/fixtures/codex-release/external-cleanup.valid.jsonl` - synthetic complete cleanup families.
- `docs/guides/codex-install-upgrade.md` - checked operator install, setup, upgrade, rollback, and removal sequence.
- `docs/release/0.17.0-release-evidence.md` - candidate-time template, then terminal I signoff index.
- At E only: `docs/release/0.17.0-evidence/release-manifest.json`.
- At E only: `docs/release/0.17.0-evidence/installed-payload-manifest.json`.
- At E only: `docs/release/0.17.0-evidence/skill-hook-discovery.redacted.json`.
- At E only: `docs/release/0.17.0-evidence/codex-release-matrix.redacted.jsonl`.
- At E only: `docs/release/0.17.0-evidence/claude-non-regression.redacted.jsonl`.
- At E only: `docs/release/0.17.0-evidence/external-cleanup.redacted.jsonl`.
- At E only: `docs/release/0.17.0-evidence/evidence-hashes.json`.

### Modify

- `scripts/validate-plugin-metadata.sh` - require synchronized `0.17.0` versions and verify both marketplace topologies.
- `scripts/validate-phase-skills.sh` - register C5 scripts/test/docs and preserve all landed C1-C4 checks.
- `scripts/validate-runtime-contracts.sh` - remove C5-absence/`0.16.0` fences and expose owning evidence checks to the composer; do not duplicate schemas.
- `dodi-dev/.claude-plugin/plugin.json` - version only, `0.16.0` to `0.17.0`.
- `dodi-dev/.codex-plugin/plugin.json` - version only, `0.16.0` to `0.17.0`.
- `.claude-plugin/marketplace.json` - plugin entry version only, `0.16.0` to `0.17.0`; source stays `./dodi-dev`.
- Landed candidate-valid fixtures whose owning validator requires plugin-version equality, including at minimum `dodi-dev/scripts/tests/fixtures/runtime-contracts/profile/runtime-profile.valid.json` and `dodi-dev/scripts/tests/fixtures/codex-tier/profile/runtime-profile.codex.valid.json`; Task 1 records the complete real list before modification.

### Inspect Only

- `.agents/plugins/marketplace.json` - assert no `version` property and local source path `./dodi-dev`.
- All landed C1-C4 production scripts, schemas, policy, adapters, skills, tests, live evidence, and ownership baselines except the three approved validator composition points above.
- `dodi-dev/hooks/hooks.json`, `dodi-dev/scripts/hook-require-model-pin.sh`, and `dodi-dev/scripts/hook-gate2-guard.sh` - validate installed identity/trust/live behavior without changing C2/C4 semantics.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: `mode parsing; candidate/default checks; strict JSON/JSONL and hash validation; metadata/topology checks; canonical skill manifest derivation; release-record redaction; scenario completeness; evidence hash graph; C/E/I ancestry and allowed-diff rules; secret/path scanners; compact status emission`
  - Reason: `C5 is a fail-closed release boundary. Every malformed, stale, missing, leaking, mismatched, synthetic-for-live, or unknown outcome must be rejected deterministically without relying on a live runtime.`
  - Minimum assertions: `unknown/combined flags fail; default passes without final evidence; required modes fail when evidence is absent; all fail-closed matrix statuses are exercised; metadata values must all be 0.17.0; Codex marketplace must remain versionless; symlink/mirror/extra/missing skill and root/hook mismatch fail; C2-C4 validators are invoked rather than reimplemented; hash tampering/self-hash/index-hash fails; absolute home paths and every canary fail; live-required scenarios reject synthetic evidence; unresolved cleanup fails; C/E/I wrong ancestry or out-of-surface diff fails; stdout is one parseable summary object and diagnostics contain no canary.`

- Integration: `required`
  - Scope: `landed C1-C4 validators/evidence, top-level release composer, installed plugin metadata/skills/hooks/scripts, docs commands/statuses/links, version-bound fixtures, repository validators, and the single canonical skill tree`
  - Reason: `A correct local parser is insufficient if it bypasses an owning validator, validates the source tree instead of the installed artifact, drifts docs from executable commands, or changes marketplace/plugin packaging.`
  - Harness: `setup-required`
  - Minimum assertions: `all exact landed C1-C4 implementation commits are ancestors of C; their owning default and live-required validators pass; compatibility default passes before E; isolated install proves cache outside source and byte-for-byte payload parity except recorded installer metadata; source and installed skill/hook sets match; ordinary installed commands have no unresolved ambient root; docs tokens resolve; all three version-bearing envelopes equal 0.17.0; .agents marketplace is unchanged/versionless; every shell test and repository validator passes.`

- E2E: `required`
  - Scope: `fresh current Codex Desktop/plugin install; installed-root bootstrap/profile/hook trust; complete C2-C4 candidate-bound Codex matrix; focused unrelated-repository Claude Code non-regression; external cleanup; evidence-only E and index-only I; final human Gate 2 package`
  - Reason: `Repository fixtures cannot prove current installer/cache behavior, app-server discovery, exact hook trust, native model/worker/task behavior, restricted GitHub authority, Slack delivery, cross-session recovery, or Claude runtime compatibility.`
  - Harness: `setup-required`
  - Minimum assertions: `all isolated-install assertions and every named Codex/Claude scenario pass live where required; only explicitly allowed conflict/failure records are synthetic-negative; all external scopes clean up authoritatively; E adds only the seven evidence files; I changes only the index; --require-live-release and --release exit 0; release index has no blocker/unknown and records rollback readiness; no validator or task performs the human Gate 2 action.`

### Critical Flows

- `clean candidate C -> compatibility default -> owning C1-C4 validators/tests -> packaging/docs/metadata/reference checks -> CANDIDATE_VALID without requiring E or I.`
- `detached worktree at C -> fresh HOME/CODEX_HOME/XDG/target repo -> local candidate marketplace -> installed cache outside source -> exact payload/skill/hook/root proof -> cleanup -> isolated-install evidence.`
- `installed root at C -> separately confirmed C4 setup -> C2 tier/hook matrix -> C3 lifecycle/recovery/quarantine matrix -> C4 register/GitHub/scheduler/Slack/marketplace/rollback matrix -> complete redacted Codex records.`
- `same candidate shared tree -> unrelated temporary Claude repository with no Codex profile -> shared root + both hooks + pinned leaf + transcript fallback + mixed manifests + reap/claim smoke -> redacted Claude records.`
- `immutable C + staged redacted evidence -> verify every record binds C/tree/payload/runtime and every cleanup is complete -> commit evidence-only E -> hash E artifacts without self/index/E identity.`
- `template index -> name C and E plus manifest/hash-manifest hashes -> commit index-only I -> validate C..E and E..I surfaces -> RELEASE_READY -> human DOD-810 Gate 2 remains pending.`

### Regression Surface

- `C1 profile/health/register/manifest schemas, root bootstrap, generation/hash binding, canonical paths, runtime ownership, and adapter interfaces.`
- `C2 model/reasoning pairs, tier order, same-invocation proof, capacity signatures/policy routing, hook matching, and attestation semantics.`
- `C3 spawn/await/result/close/reap ordering, digest claim/ack, no-write proof, quarantine, takeover mode, and Claude transcript behavior.`
- `C4 inspect/confirm setup boundary, stable-lock state writer, direct Linear register authority, GitHub/Gate 2 posture, scheduler, Slack, marketplace migration, rollback, and release fences.`
- `v0.16 workflow semantics: one canonical skill tree, top-level-only leaf workers, serial mutable lanes, one driver writer, Fable policy, claims, review/coherence gates, resumability, and human Gate 2.`
- `Both marketplace envelopes continue to point at the same ./dodi-dev directory; no copied/symlinked skills, repository-only installed dependency, root plugin envelope, or synthetic Codex marketplace version is introduced.`

### Commands

- Unit: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; dodi-dev/scripts/tests/test-codex-release-validation.sh`
- Integration: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; scripts/validate-codex-compatibility.sh && scripts/validate-runtime-contracts.sh && scripts/validate-phase-skills.sh && scripts/validate-plugin-metadata.sh && scripts/validate-ticket-comment-templates.sh`
- E2E: `scripts/validate-codex-compatibility.sh --require-isolated-install`, then after E `scripts/validate-codex-compatibility.sh --require-live-release`, then at I `scripts/validate-codex-compatibility.sh --release`.
- Broader regression: `export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"; for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done` plus `git diff --check` and Task 11's ownership/redaction/provenance audit.

### Harness Requirements

- `bash 3.2+, python3, git, jq, rg, mktemp, stat, shasum or sha256sum, readlink/realpath equivalent, and a filesystem supporting executable bits, chmod, atomic rename, and isolated temporary directories.`
- `Create/reuse the landed C1 test environment exactly: python3 -m venv /tmp/dodi-runtime-contracts-venv && /tmp/dodi-runtime-contracts-venv/bin/python -m pip install --requirement requirements-dev.txt.`
- `Unit tests build disposable fake repositories and temporary homes. They use only synthetic ids/hashes/canaries and stub current-runtime observations; they never read or mutate the operator's marketplace, profile, tasks, GitHub repository, Linear workspace, or Slack channel.`
- `Isolated install requires the parent-approved current Codex Desktop/plugin runtime with marketplace/plugin, app-server skill/hook discovery, and local-path installation support. Legacy codex-cli 0.38.0 is a negative prerequisite, not a fallback.`
- `Live Codex requires separately confirmed disposable Linear, equivalent protected GitHub branch/repository, restricted scheduled actor, low-risk Slack channel, marketplace/task scopes, two top-level contexts, and C4 cleanup/rollback support.`
- `Claude smoke requires a supported Claude Code runtime, candidate plugin installation, an unrelated temporary target repository, no Codex profile/marketplace in that environment, and native leaf dispatch/transcript access.`
- `Raw logs and native payloads stay in a mode-0700 temporary staging root outside the repository. Only schema-minimal redacted records enter E after scanners and cleanup pass.`

### Non-Required Rationale

- Unit: `not applicable (required).`
- Integration: `not applicable (required).`
- E2E: `not applicable (required). Missing current-runtime, external-scope, cross-session, cleanup, or Claude evidence blocks 0.17.0; deterministic fixtures and earlier C2-C4 live runs do not substitute.`

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.
- A C1-C4 failure is returned to its owning child; C5 must not add competing mechanics or weaken the required matrix.
- Any source, runtime, validator, guide, metadata, dependency evidence, or plugin-payload change after C invalidates the C5 run and requires a new C plus complete rerun.
- Unknown external acceptance or cleanup is failure, not warning. Preserve evidence and use C4 recovery; never retry a mutation by guess.
- Secret-scanner failure stops release. Revoke/rotate if needed, purge unsafe staging data, and regenerate E; never redact by deleting required proof.
- `--release` is read-only and may only report readiness. The human DOD-810 Gate 2 remains the sole merge decision.

---

## Tasks

### Task 1: Reconcile landed C1-C4 implementation and freeze the C5 input inventory

**Files:**
- Inspect only: all landed files named by the DOD-811 through DOD-814 plans and owning validators.
- Inspect only: `scripts/validate-runtime-contracts.sh`.
- Inspect only: `scripts/validate-phase-skills.sh`.
- Inspect only: `scripts/validate-plugin-metadata.sh`.
- Inspect only: `.agents/plugins/marketplace.json`.

- [ ] **Step 1:** Start from a clean branch containing the landed DOD-811 through DOD-814 implementations. Verify the planning anchors are ancestors, then identify the actual implementation commits from the landed owned paths. Do not use `978cad7`, `5d084b5`, `a3124f4`, or `a7a63a2` as implementation proof.

```bash
set -euo pipefail
git status --short
for anchor in 978cad7 5d084b5 a3124f4 a7a63a2 0549b53; do
  git merge-base --is-ancestor "$anchor" HEAD
done
for path in \
  dodi-dev/scripts/runtime-preflight.sh \
  dodi-dev/scripts/codex-tier-adapter.sh \
  dodi-dev/scripts/codex-worker-adapter.sh \
  dodi-dev/scripts/runtime-state.sh \
  dodi-dev/scripts/codex-scheduler-adapter.sh \
  dodi-dev/scripts/slack-escalation-adapter.sh \
  scripts/validate-runtime-contracts.sh; do
  test -f "$path"
  git log -1 --format='%H %s' -- "$path"
done
```

Expected: clean status; every ancestry/file check exits `0`; each owned implementation path prints a non-empty 40-character commit. Missing executable code is `DEPENDENCY_EVIDENCE_INVALID` and blocks Task 2.

- [ ] **Step 2:** Run every landed owning validator, including its live-required mode, and record the exact command names/evidence paths for C2, C3, and C4. Reconcile any renamed landed paths now; do not manufacture a path from this plan if the approved implementation landed a different one.

```bash
set -euo pipefail
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
scripts/validate-runtime-contracts.sh
scripts/validate-runtime-contracts.sh --require-codex-worker-live
scripts/validate-runtime-contracts.sh --require-codex-setup-live
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
```

Expected: every command exits `0`; C2 live evidence is accepted by its landed focused tests/reference checks; C3 and C4 live-required modes report complete current implementation evidence. A stale/missing artifact returns to the owning child.

- [ ] **Step 3:** Inventory operative version equality and release-fence references before editing. Classify every `0.16.0` hit as candidate-valid fixture/metadata to update, historical/migration/non-regression text to preserve, or stale operative assumption to remove. Confirm `.agents/plugins/marketplace.json` has no version and source path is `./dodi-dev`.

```bash
set -euo pipefail
rg -n '0\.16\.0|C5|validate-codex-compatibility|validate-codex-install' \
  scripts dodi-dev .claude-plugin .agents docs/plans/2026-07-09-dod-81[1-4]-*.md
python3 - <<'PY'
import json
from pathlib import Path
p = json.loads(Path('.agents/plugins/marketplace.json').read_text())
entry = p['plugins'][0]
assert 'version' not in entry
assert entry['source']['path'] == './dodi-dev'
print('codex marketplace verify-only ok')
PY
```

Expected: a reviewable list of exact candidate-valid fixture paths; no unexplained operative `0.16.0`; final line `codex marketplace verify-only ok`.

- [ ] **Step 4:** Establish one durable external staging root before writing any release evidence: `C5_STAGING_ROOT="$(mktemp -d)/dodi-skills-0.17.0-staging"`, `mkdir -m 700 "$C5_STAGING_ROOT"`, and record that absolute path in implementation evidence/PR notes. Write the mode-`0600` dependency ledger at `$C5_STAGING_ROOT/task1-dependency-ledger.json`. The record must include child id, exact implementation commit, owning validator command, live evidence path/hash, C3 takeover mode, C4 contract-freeze/baseline identity, and every approved version-bound fixture path. The ledger is C5 release input only; do not add a new runtime contract file. Every later task reuses this same root via `STAGING="$C5_STAGING_ROOT"`; no later task creates a replacement staging root.

### Task 2: Add C5 fixtures and fail-first release-validation tests

**Files:**
- Create: `dodi-dev/scripts/tests/test-codex-release-validation.sh`.
- Create: every `dodi-dev/scripts/tests/fixtures/codex-release/` file listed in File Structure.

- [ ] **Step 1:** Create `cases.jsonl` with one closed record per fail-closed status and explicit expected mode/result. Include at least `DEPENDENCY_EVIDENCE_INVALID`, `CANDIDATE_STALE`, `PROVENANCE_MISMATCH`, `INSTALL_ROOT_MISMATCH`, `HOOK_TRUST_MISMATCH`, `CODEX_LIVE_GATE_FAILED`, `CLAUDE_REGRESSION`, `METADATA_DRIFT`, `DOCS_EVIDENCE_DRIFT`, `SECRET_LEAK`, and `ROLLBACK_INCOMPLETE`.

Each line has this exact shape:

```json
{"case_id":"candidate-e-delta-outside-evidence","mode":"release","mutation":"e-outside-allowlist","expected_status":"CANDIDATE_STALE","expected_exit":1}
```

- [ ] **Step 2:** Create synthetic valid evidence fixtures using only fixed example ids, all-zero/all-one 64-character hashes, relative paths, and `example.invalid` URLs. The valid release manifest must name C but no E/I/index identity; `evidence-hashes.json` is generated inside the test temp tree and excludes itself/index.
- [ ] **Step 3:** In `test-codex-release-validation.sh`, construct disposable Git repositories representing valid C, E, and I, then mutate one condition at a time. Copy the validator under test into each temp repository rather than adding test-only root overrides to production code.
- [ ] **Step 4:** Assert default mode passes with no `docs/release/0.17.0-evidence/` directory, while live/release modes fail closed when evidence is absent. Assert all unknown flags and invalid mode combinations exit nonzero.
- [ ] **Step 5:** Cover clean/stale dependency commits; C/E/I ancestry and path allowlists; missing/extra/duplicate/disabled/symlinked skills; marketplace duplicate/source/version drift; plugin-root and hook-hash mismatches; docs token/link drift; malformed JSON/JSONL; missing/extra/tampered/self-referential hashes; live-vs-synthetic classification; unknown cleanup; absolute home paths; key/webhook/header/private-key/canary leaks; and rollback-incomplete state.
- [ ] **Step 6:** Add fail-first normalizer cases for sorted JSONL output, duplicate scenario rejection, missing owner command hash, forbidden E/I/index identity fields, unallowlisted native observation ids, unredacted absolute paths, and records that claim `live` without an owner command result.
- [ ] **Step 7:** Require a single parseable JSON object on stdout for every invocation. Capture stderr and assert it contains the status/case id but no fixture payload, secret canary, absolute temporary home, prompt, transcript, or environment dump.

Run:

```bash
set +e
dodi-dev/scripts/tests/test-codex-release-validation.sh
rc=$?
set -e
test "$rc" -ne 0
```

Expected before Tasks 3-4: nonzero because the production validators do not exist. Preserve this fail-first result in implementation evidence.

### Task 3: Implement the candidate-safe compatibility composer

**Files:**
- Create: `scripts/validate-codex-compatibility.sh`.
- Create: `scripts/normalize-codex-release-evidence.py`.
- Modify: `scripts/validate-runtime-contracts.sh`.
- Modify: `scripts/validate-phase-skills.sh`.
- Test: `dodi-dev/scripts/tests/test-codex-release-validation.sh`.

- [ ] **Step 1:** Implement exact mutually exclusive modes: default, `--require-isolated-install`, `--require-live-release`, and `--release`. Unknown flags fail. Default derives candidate identity from clean `HEAD`; live mode derives C from E's strict evidence bundle; release mode derives I only from `git rev-parse HEAD` in a clean checkout, reads C and E from the index, and rejects any index field or evidence record that supplies an I identity.
- [ ] **Step 2:** Keep default candidate-safe: invoke all owning deterministic validators/tests; require candidate-time C1-C4 evidence paths and command registrations; validate packaging, docs template, metadata, skill manifest, reference resolution, permissions, syntax, fixtures, redaction rules, and Git cleanliness; do not require the final C5 evidence directory or completed index fields.
- [ ] **Step 3:** Derive canonical skill names by parsing each real `dodi-dev/skills/*/SKILL.md` frontmatter `name`. Reject duplicates, missing/extra names, non-directory mirrors, symlinks, or a hard-coded pre-C4 count. Require one physical `dodi-dev/skills/` tree.
- [ ] **Step 4:** Validate references without duplicating C1-C4 mechanics: invoke their scripts; verify required path/hash fields and owning evidence hashes; scan C5 code for competing schema/state/tier/lifecycle/setup implementations; permit `${CLAUDE_PLUGIN_ROOT}` only in hook metadata/commands and explanatory installed policy, not unresolved ordinary skill commands.
- [ ] **Step 5:** Make `--require-isolated-install` call `scripts/validate-codex-install.sh` against a detached clean worktree at C, validate its compact output, and delete temporary roots after authoritative cleanup. This mode may mutate only its local temporary marketplace/cache.
- [ ] **Step 6:** Make `--require-live-release` read E's bundle, prove E changes only `docs/release/0.17.0-evidence/`, run candidate validators from C, verify exact dependency ancestry/hashes, scenario completeness/runtime/payload binding/redaction/cleanup, and reject any evidence record that names E, I, or the index.
- [ ] **Step 7:** Make `--release` compute `I="$(git rev-parse HEAD)"` after proving `git status --short` is empty. It then reads the release index, rejects any `index_commit`, `signoff_commit`, `I`, or equivalent self-identity field, proves the index names C and E only, proves E is an ancestor of I, proves `C..E` is evidence-only and `E..I` changes only `docs/release/0.17.0-release-evidence.md`, re-runs default/evidence checks read-only, requires a completed no-blocker signoff checklist, and emits `RELEASE_READY`. Do not invoke install or external mutations from release mode.
- [ ] **Step 8:** Implement `normalize-codex-release-evidence.py` as a pure formatter over C5 staging directories plus the explicit Task 1 dependency ledger. It accepts only the mode-`0600` ledger, redacted native observations, and owner-command JSON outputs; writes `release-manifest.json` from the ledger and current C5 staging facts; requires each live record to name an owner command and owner output hash; sorts JSONL by `scenario`; rejects duplicates and forbidden E/I/index identity fields; and writes no secrets or absolute home/cache paths. It must not validate or rediscover C1-C4 semantics; the owning commands and Task 1 ledger supply that provenance before normalization.
- [ ] **Step 9:** Emit exactly one compact JSON summary on stdout, for example:

```json
{"validator":"codex-compatibility","mode":"default","candidate":"<40-hex>","status":"CANDIDATE_VALID","checks_passed":12,"checks_failed":0}
```

Diagnostics go to stderr as status plus short check ids only. Never print raw logs, evidence bodies, paths under a user's home, environment values, or secrets.
- [ ] **Step 10:** Update `scripts/validate-runtime-contracts.sh` only to remove the C5-absence/version fence and expose existing owning checks. Update `scripts/validate-phase-skills.sh` to require the three top-level C5 scripts, focused test/fixtures, guide, and release-index template while preserving every C1-C4 registration.

Run:

```bash
set -euo pipefail
bash -n scripts/validate-codex-compatibility.sh
python3 -m py_compile scripts/normalize-codex-release-evidence.py
scripts/validate-codex-compatibility.sh | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["status"] == "CANDIDATE_VALID"'
dodi-dev/scripts/tests/test-codex-release-validation.sh
```

Expected after Task 4 exists and before E: shell/Python syntax exits `0`; default emits one JSON object with `CANDIDATE_VALID`; focused tests end `codex release validation tests ok`, including normalizer duplicate/forbidden-field/redaction cases.

### Task 4: Implement the isolated candidate installation harness

**Files:**
- Create: `scripts/validate-codex-install.sh`.
- Modify: `dodi-dev/scripts/tests/test-codex-release-validation.sh`.
- Create/modify: install/provenance cases in `dodi-dev/scripts/tests/fixtures/codex-release/cases.jsonl`.

- [ ] **Step 1:** Implement `validate-codex-install.sh --candidate-root <absolute-detached-root> --output-dir <absolute-mode-0700-staging-dir>`. Reject a non-absolute/non-clean/non-detached candidate root, an output directory inside the candidate, a legacy/unsupported runtime, inherited Dodi state, or unknown flags.
- [ ] **Step 2:** Create fresh `HOME`, `CODEX_HOME`, `XDG_CONFIG_HOME`, target repository, marketplace/cache, raw-log, and redacted-output directories under one trap-owned temp root. Export an allowlist environment rather than inheriting operator Codex/plugin/profile/task variables. Record only runtime version and non-secret fingerprints.
- [ ] **Step 3:** Use the supported runtime's captured plugin help/schema and the approved local marketplace operation to add the absolute candidate root, then install `dodi-dev@dodi-skills`. Before install, prove marketplace/plugin/cache/profile/trust/task listings contain no Dodi entry. After install, canonicalize the cache root and prove it is outside source/output/operator roots.
- [ ] **Step 4:** Build canonical candidate and installed payload manifests as sorted relative `path`, normalized `mode`, and SHA-256 records. Exclude only runtime-discovered installer-owned metadata with an exact field/path allowlist captured in the release manifest; reject any unclassified delta.
- [ ] **Step 5:** Through current app-server/runtime discovery, prove installed skills equal the frontmatter-derived canonical set and hooks equal exactly the model-pin and Gate 2 entries. Bind hook metadata command, installed script hash/root, observed matcher/action schema, and trust to the installed payload hash. Source-root/old-cache trust never passes.
- [ ] **Step 6:** Invoke C1 root bootstrap from an installed skill locator. Prove installed locator/root equality and negative source-root, mixed-root, traversal, missing-metadata, and locator/root mismatch cases. Before profile setup, require read-only inspect success and approved setup fences for mutating/tiered operations.
- [ ] **Step 7:** After separate C4 confirmation in a disposable scope, verify profile/health/register bind installed root/version/generation and C2 `verify-profile` accepts them. Validate required runtime canon, schemas, model map, both adapters, setup skill, and deterministic helpers are installed with no repository-only dependency.
- [ ] **Step 8:** Seed a separate same-name stale marketplace/cache fixture and prove C4 collision detection blocks install/upgrade/profile enablement until an explicitly confirmed migration yields one source. Never delete/rewrite/prefer a root silently.
- [ ] **Step 9:** Uninstall and remove all temporary marketplace/profile/task/worktree/secret state through owning runtime/C4 operations. Verify absence and emit failure on unknown cleanup. Delete raw logs only after compact output validates.
- [ ] **Step 10:** Write only the two compact staging artifacts owned by install capture: `installed-payload-manifest.json` and `skill-hook-discovery.redacted.json`, plus JSON summary on stdout. The caller later folds install scenario results into the release manifest/Codex matrix.

Run in the supported current Desktop/plugin runtime:

```bash
set -euo pipefail
CANDIDATE="$(git rev-parse HEAD)"
TMP_ROOT="$(mktemp -d)"
trap 'git worktree remove --force "$CANDIDATE_ROOT" >/dev/null 2>&1 || true; rm -rf "$TMP_ROOT"' EXIT
CANDIDATE_ROOT="$TMP_ROOT/candidate-C"
git worktree add --detach "$CANDIDATE_ROOT" "$CANDIDATE"
test -z "$(git -C "$CANDIDATE_ROOT" status --short)"
test -z "$(git -C "$CANDIDATE_ROOT" symbolic-ref -q --short HEAD || true)"
STAGING="$TMP_ROOT/0.17.0-install-evidence"
mkdir -m 700 "$STAGING"
git -C "$CANDIDATE_ROOT" rev-parse --verify HEAD
"$CANDIDATE_ROOT/scripts/validate-codex-install.sh" \
  --candidate-root "$CANDIDATE_ROOT" \
  --output-dir "$STAGING"
python3 -m json.tool "$STAGING/installed-payload-manifest.json" >/dev/null
python3 -m json.tool "$STAGING/skill-hook-discovery.redacted.json" >/dev/null
```

Expected: one `ISOLATED_INSTALL_VALID` summary from a clean detached candidate root; installed cache is outside source; both JSON files parse; all temporary runtime state is removed. On an attached/dirty candidate root or legacy local `codex-cli 0.38.0`, expected result is a supported-runtime/prerequisite failure and no state mutation.

### Task 5: Add checked install/upgrade guidance and the candidate index template

**Files:**
- Create: `docs/guides/codex-install-upgrade.md`.
- Create: `docs/release/0.17.0-release-evidence.md`.
- Modify: `dodi-dev/scripts/tests/test-codex-release-validation.sh`.

- [ ] **Step 1:** Write the guide as operator sequence plus named postconditions, not duplicated runtime algorithms. Include supported current Desktop/plugin prerequisites and explicit non-support of legacy CLI `0.38.0`.
- [ ] **Step 2:** Include the exact canonical remote install commands and a local-development equivalent using an absolute repository path:

```bash
codex plugin marketplace add dodi-hq/dodi-skills --ref main
codex plugin add dodi-dev@dodi-skills
```

The local command must be copied from the supported runtime's captured `codex plugin marketplace add --help`; do not infer it from the unsupported local CLI.
- [ ] **Step 3:** Document provenance inspection before install/upgrade; `setup-dodi-dev inspect`; separately confirmed runtime-id/register/profile/hook/task/Slack setup classes; disabled-task verification; separately confirmed lights-out enablement; expected fail-closed statuses and owning repair surfaces; and no manual guessed cache deletion.
- [ ] **Step 4:** Document evidence-preserving rollback: disable tasks, await authoritative terminal state, require C3 quiescence/quarantine, restore verified prior marketplace/profile/task provenance through C4, replay current register obligations, re-verify hook/profile/task fingerprints, and keep tasks disabled on `ROLLBACK_INCOMPLETE`.
- [ ] **Step 5:** Add removal/cleanup verification and required Linear/GitHub/scheduler/Slack prerequisites without values. Link installed scripts/commands for mechanics; do not link installed skills to repository-only specs/plans.
- [ ] **Step 6:** Create the candidate index template with `## TL;DR`, `## Key Points`, fields for C/E/tree/runtime/payload hashes, links to all seven E artifacts, matrix/cleanup/rollback status, blockers, and `Human Gate 2 decision: PENDING`. At C, identities/hashes remain explicit template tokens and no claim says live validation passed.
- [ ] **Step 7:** Extend deterministic tests so version, marketplace id/path, command names, status names, evidence links, template fields, and human Gate 2 wording must agree with metadata/scripts. Missing/stale text is `DOCS_EVIDENCE_DRIFT`.

Run:

```bash
set -euo pipefail
scripts/validate-codex-compatibility.sh
rg -n '0\.38\.0|setup-dodi-dev|ROLLBACK_INCOMPLETE|Human Gate 2 decision' \
  docs/guides/codex-install-upgrade.md \
  docs/release/0.17.0-release-evidence.md
```

Expected: default validator exits `0`; guide contains supported/unsupported, setup, rollback, and cleanup boundaries; index remains an honest candidate template.

### Task 6: Perform the synchronized 0.17.0 metadata and fixture sweep

**Files:**
- Modify: `dodi-dev/.claude-plugin/plugin.json`.
- Modify: `dodi-dev/.codex-plugin/plugin.json`.
- Modify: `.claude-plugin/marketplace.json`.
- Modify: `scripts/validate-plugin-metadata.sh`.
- Modify: only Task 1's exact candidate-valid version-bound fixture list.
- Inspect only: `.agents/plugins/marketplace.json`.

- [ ] **Step 1:** Change only the three current version-bearing values from `0.16.0` to `0.17.0`. Preserve plugin names/ids, descriptions, source topology, capabilities, and all other metadata.
- [ ] **Step 2:** Update `scripts/validate-plugin-metadata.sh` to require exact `0.17.0` equality across the Claude marketplace and both plugin envelopes; require both marketplace entries to resolve `./dodi-dev`; require Codex marketplace name/id agreement and absence of a `version` property.
- [ ] **Step 3:** Update candidate-valid C1/C2/C4 fixtures only where their owning validator requires equality to installed metadata. Preserve historical/migration/non-regression evidence that truthfully records an older version; add an explicit allowlist reason for each retained operative-looking `0.16.0`.
- [ ] **Step 4:** Assert `.agents/plugins/marketplace.json` is byte-for-byte unchanged from the pre-C5 baseline. Assert no root plugin envelope, second skill tree, copied policy, or symlink appears.

Run:

```bash
set -euo pipefail
scripts/validate-plugin-metadata.sh
scripts/validate-runtime-contracts.sh
scripts/validate-phase-skills.sh
git diff -- .agents/plugins/marketplace.json
find dodi-dev/skills -type l -print -quit | grep -q . && exit 1 || true
rg -n '0\.16\.0' scripts dodi-dev .claude-plugin .agents docs/guides docs/release || true
```

Expected: `plugin metadata ok: 0.17.0`; runtime/phase validators exit `0`; Codex marketplace diff and symlink output are empty; every remaining `0.16.0` hit is an approved historical/migration/non-regression reference from Task 1.

- [ ] **Step 5:** Run the full candidate test battery, review the diff, and commit the final code/docs/metadata state. This commit becomes immutable candidate C only after all non-live review fixes are complete.

```bash
set -euo pipefail
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
dodi-dev/scripts/tests/test-codex-release-validation.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
scripts/validate-codex-compatibility.sh
scripts/validate-runtime-contracts.sh
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
git diff --check
git status --short
git add scripts dodi-dev docs/guides docs/release/0.17.0-release-evidence.md .claude-plugin/marketplace.json
git commit -m "feat: add codex release validation for 0.17.0"
CANDIDATE="$(git rev-parse HEAD)"
git status --short
printf 'CANDIDATE=%s\n' "$CANDIDATE"
```

Expected: every command exits `0`; status is clean after commit; C is a 40-character SHA containing no final C5 evidence bundle.

### Task 7: Validate immutable candidate C from an isolated installed artifact

**Files:**
- No tracked files at C.
- Write staging only: install artifacts under a mode-0700 directory outside every repository/worktree.

- [ ] **Step 1:** Create a detached worktree at C and prove its tree id. Reject a dirty candidate or any candidate that lacks the exact dependency implementation commits inventoried in Task 1.
- [ ] **Step 2:** Run compatibility default and `--require-isolated-install` from the detached C worktree. Also run `validate-codex-install.sh` with the durable external staging directory that will feed E.
- [ ] **Step 3:** Hash and retain compact install artifacts, runtime version/help/schema observations, validator summaries, and cleanup result in staging. Keep raw logs separately mode `0600`; do not place them under the repo.

```bash
set -euo pipefail
CANDIDATE="$(git rev-parse HEAD)"
CANDIDATE_TREE="$(git rev-parse "${CANDIDATE}^{tree}")"
WORKTREE="$(mktemp -d)/dodi-skills-0.17.0-candidate"
: "${C5_STAGING_ROOT:?set by Task 1 and recorded in implementation evidence}"
STAGING="$C5_STAGING_ROOT"
mkdir -p "$STAGING"
chmod 700 "$STAGING"
test -s "$STAGING/task1-dependency-ledger.json"
DEPENDENCY_LEDGER="$STAGING/task1-dependency-ledger.json"
git worktree add --detach "$WORKTREE" "$CANDIDATE"
(
  cd "$WORKTREE"
  scripts/validate-codex-compatibility.sh
  scripts/validate-codex-compatibility.sh --require-isolated-install
  scripts/validate-codex-install.sh --candidate-root "$WORKTREE" --output-dir "$STAGING"
)
test "$(git -C "$WORKTREE" rev-parse HEAD)" = "$CANDIDATE"
test "$(git -C "$WORKTREE" rev-parse HEAD^{tree})" = "$CANDIDATE_TREE"
```

Expected: all three validators exit `0`; staging contains valid install/discovery artifacts bound to C/tree/payload; the installed root was outside source; cleanup is authoritative. Preserve `CANDIDATE`, `CANDIDATE_TREE`, `WORKTREE`, and `STAGING` for Tasks 8-9.

### Task 8: Execute the complete candidate-bound Codex and Claude live gates

**Files:**
- No tracked files at C.
- Write staging only: redacted matrix and cleanup records outside the repository.

- [ ] **Step 1:** Freeze the Task 1 owner-command inventory into shell variables for this run: `CANDIDATE`, `CANDIDATE_ROOT`, `INSTALLED_ROOT`, `PROFILE`, `REPO`, `STAGING`, `DEPENDENCY_LEDGER`, `RUNTIME_EVIDENCE_DIR`, `TIER_MAP`, `TIER_ADAPTER`, `MODEL_PIN_HOOK`, `WORKER_ADAPTER`, `RUNTIME_PREFLIGHT`, `SETUP_SKILL`, `RUNTIME_REGISTER`, `RUNTIME_STATE`, `SCHEDULER_ADAPTER`, `GATE2_GUARD`, and `SLACK_ADAPTER`. `DEPENDENCY_LEDGER` is the Task 1 mode-`0600` JSON ledger containing exact implementation commits, evidence paths/hashes, C3 takeover mode, and C4 freeze/baseline identity. These paths come from the verified installed plugin root; do not hard-code `$INSTALLED_ROOT/dodi-dev/...` because C1 owns the concrete root shape. If any owner surface lacks a callable command or compact output/observation path needed below, block DOD-815 and return to the owning child; do not invent a C5 substitute parser.
- [ ] **Step 2:** Generate C2 records by invoking the installed C2 owner commands. At minimum run `codex-tier-adapter.sh validate-map`, `resolve-tier`, `verify-main-loop`, and `verify-attestation` for every required semantic tier, using fresh `runtime-preflight.sh verify-profile` nonces and current-runtime attestation/request observation files. Run the installed model-pin and Gate 2 hook live-fire surfaces for deny/allow cases, then append one normalized record per scenario to `codex-release-matrix.redacted.jsonl`.
- [ ] **Step 3:** Generate C3 records by invoking `codex-worker-adapter.sh` through its landed phases: `prepare-intent`, `spawn --phase request`, `spawn --phase observe`, `await --phase request`, `await --phase observe`, `persist-result`, `close --phase request`, `close --phase observe`, `reap-recover`, and `digest --phase ready|claim|ack`. The top-level session performs each native spawn/wait/query/enumerate/close action and writes the exact redacted observation file consumed by the next owner command. Cover read-only and mutable lifecycles, equivalent/conflicting evidence, invalid-attestation quarantine, planned refresh/resume, cross-session recovery, selected takeover mode, and crash-before-binding.
- [ ] **Step 4:** Generate C4 records by invoking the landed setup/state owners: `setup-dodi-dev inspect`; `runtime-preflight.sh verify-profile`; `runtime-register.sh discover|replay|create|append-obligation|append-delivered`; `runtime-state.sh` proposal/apply/recover/rollback/classify/complete-attempt surfaces; `codex-scheduler-adapter.sh`; `hook-gate2-guard.sh`; and `slack-escalation-adapter.sh`. Cover separately confirmed disposable runtime id, direct Linear register create-adopt-append-replay, profile/health crash recovery, rollback preserving a post-snapshot obligation, complete C3 quiescence, protected-base Gate 2 denial, scheduler boot/no-overlap/no-op/refresh successor/failure/cleanup, register-backed Slack delivery plus unknown/retry/degraded/repair/stale re-escalation, and stale-marketplace migration/exact rollback.
- [ ] **Step 5:** Run focused Claude Code smoke in an unrelated temporary repository with no Codex profile/marketplace and no Dodi checkout as cwd. Prove one shared entry-point root, both hooks with Claude `Bash` and `Task|Agent` allow/deny shapes, one pinned leaf alias and native wake, transcript-backed `await-worker.sh`, mixed legacy/v1 Claude/v1 Codex manifest classification, reap, and claim/worktree preservation.
- [ ] **Step 6:** Normalize each owner command result into only: `scenario`, `runtime`, `candidate`, `installed_payload_hash`, `owner_command`, `owner_output_hash`, `evidence_kind`, `result`, `timestamp`, and non-secret `observation_hash`, plus allowlisted family-specific ids/fingerprints. Required real install/trust/worker/auth/scheduler/Gate2/Slack/migration/cleanup scenarios must be `live`; only approved conflict/failure injections may be `synthetic-negative`.
- [ ] **Step 7:** Use C4 recovery after each external action and require authoritative cleanup for every disposable Linear/GitHub/task/Slack/marketplace scope. Any unknown result stays recorded and blocks E creation.
- [ ] **Step 8:** Rerun owning validators/tests from C against the captured installed/evidence paths. A C1-C4 failure returns to its owner and invalidates C; do not edit C5 evidence to make it pass.

Run the live capture from the top-level session, with native action observations written back into the owner commands:

```bash
set -euo pipefail
test -n "${CANDIDATE:?}"
test -d "${CANDIDATE_ROOT:?}"
test -d "${INSTALLED_ROOT:?}"
test -d "${STAGING:?}"
test -s "${DEPENDENCY_LEDGER:?}"
: "${TIER_MAP:?}" "${TIER_ADAPTER:?}" "${MODEL_PIN_HOOK:?}" "${WORKER_ADAPTER:?}" "${RUNTIME_PREFLIGHT:?}"
: "${SETUP_SKILL:?}" "${RUNTIME_REGISTER:?}" "${RUNTIME_STATE:?}" "${SCHEDULER_ADAPTER:?}" "${GATE2_GUARD:?}" "${SLACK_ADAPTER:?}"
for cmd in "$TIER_ADAPTER" "$MODEL_PIN_HOOK" "$WORKER_ADAPTER" "$RUNTIME_PREFLIGHT" "$RUNTIME_REGISTER" "$RUNTIME_STATE" "$SCHEDULER_ADAPTER" "$GATE2_GUARD" "$SLACK_ADAPTER"; do
  test -x "$cmd"
done
test -f "$SETUP_SKILL"
mkdir -p "$STAGING/owners/c2" "$STAGING/owners/c3" "$STAGING/owners/c4" "$STAGING/release"

"$TIER_ADAPTER" validate-map \
  --map "$TIER_MAP" \
  > "$STAGING/owners/c2/validate-map.json"
for tier in frontier capable standard fast; do
  nonce="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  "$TIER_ADAPTER" resolve-tier \
    --tier "$tier" --profile "$PROFILE" \
    --invoke-verifier "$RUNTIME_PREFLIGHT" \
    --repo "$REPO" --operation-nonce "$nonce" \
    > "$STAGING/owners/c2/resolve-$tier.json"
done
# For each native main-loop and worker attestation captured by the top-level session:
for tier in frontier capable standard fast; do
  "$TIER_ADAPTER" verify-main-loop \
    --tier "$tier" --profile "$PROFILE" --attestation "$STAGING/native/main-loop-$tier.redacted.json" \
    --invoke-verifier "$RUNTIME_PREFLIGHT" \
    --repo "$REPO" --operation-nonce "$(uuidgen | tr '[:upper:]' '[:lower:]')" \
    > "$STAGING/owners/c2/main-loop-$tier.json"
  "$TIER_ADAPTER" verify-attestation \
    --tier "$tier" --profile "$PROFILE" --request "$STAGING/native/worker-request-$tier.redacted.json" \
    --attestation "$STAGING/native/worker-terminal-$tier.redacted.json" \
    --gate-context "$STAGING/native/worker-gate-context-$tier.redacted.json" \
    --invoke-verifier "$RUNTIME_PREFLIGHT" \
    --repo "$REPO" --operation-nonce "$(uuidgen | tr '[:upper:]' '[:lower:]')" \
    > "$STAGING/owners/c2/worker-$tier.json"
done
set +e
"$TIER_ADAPTER" verify-attestation \
  --tier standard --profile "$PROFILE" --request "$STAGING/native/worker-request-invalid-attestation.redacted.json" \
  --attestation "$STAGING/native/worker-terminal-invalid-attestation.redacted.json" \
  --gate-context "$STAGING/native/worker-gate-context-invalid-attestation.redacted.json" \
  --invoke-verifier "$RUNTIME_PREFLIGHT" \
  --repo "$REPO" --operation-nonce "$(uuidgen | tr '[:upper:]' '[:lower:]')" \
  > "$STAGING/owners/c2/worker-invalid-attestation.json" \
  2> "$STAGING/native/worker-invalid-attestation.stderr.redacted.txt"
invalid_tier_rc=$?
set -e
test "$invalid_tier_rc" -ne 0
python3 - "$STAGING/owners/c2/worker-invalid-attestation.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert data.get('status') in {'TIER_UNVERIFIED', 'attestation-invalid', 'UNVERIFIED'}
PY
rg -n 'TIER_UNVERIFIED|attestation-invalid|UNVERIFIED' "$STAGING/native/worker-invalid-attestation.stderr.redacted.txt" "$STAGING/owners/c2/worker-invalid-attestation.json"
for hook_case in model-pin-allow model-pin-deny gate2-allow gate2-deny; do
  raw_hook="$STAGING/native/$hook_case-hook-output.redacted.txt"
  case "$hook_case" in
    model-pin-*) hook_json="$STAGING/owners/c2/$hook_case.json" ;;
    gate2-*) hook_json="$STAGING/owners/c4/$hook_case.json" ;;
  esac
  set +e
  case "$hook_case" in
    model-pin-*) "$MODEL_PIN_HOOK" < "$STAGING/native/$hook_case-event.redacted.json" > "$raw_hook" 2>&1 ;;
    gate2-*) "$GATE2_GUARD" < "$STAGING/native/$hook_case-event.redacted.json" > "$raw_hook" 2>&1 ;;
  esac
  rc=$?
  set -e
  case "$hook_case" in
    *-allow) test "$rc" -eq 0 ;;
    *-deny) test "$rc" -ne 0; rg -n 'DENIED|BLOCKED|MODEL_PIN_DENIED|GATE2_DENIED' "$raw_hook" ;;
  esac
  python3 - "$hook_case" "$rc" "$raw_hook" "$hook_json" <<'PY'
import hashlib, json, sys
case, rc, raw_path, output_path = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
raw = open(raw_path, 'rb').read()
text = raw.decode('utf-8', 'replace')
record = {
    'scenario': case,
    'owner_command': 'model-pin-hook' if case.startswith('model-pin-') else 'gate2-hook',
    'exit_code': rc,
    'expected': 'deny' if case.endswith('-deny') else 'allow',
    'status': 'DENIED' if rc else 'ALLOWED',
    'output_hash': hashlib.sha256(raw).hexdigest(),
    'status_excerpt': text[:200],
}
open(output_path, 'w').write(json.dumps(record, sort_keys=True, separators=(',', ':')) + '\n')
PY
done

# For each required C3 live scenario, feed native observations into the landed owner phases.
for c3_case in read-only mutable equivalent refresh-resume cross-session takeover; do
  "$WORKER_ADAPTER" prepare-intent --input "$STAGING/c3/$c3_case-intent.json" \
    > "$STAGING/owners/c3/01-prepare-$c3_case.json"
  "$WORKER_ADAPTER" spawn --phase request --intent "$STAGING/owners/c3/01-prepare-$c3_case.json" \
    > "$STAGING/native/spawn-action-$c3_case.redacted.json"
  # Top-level session invokes native spawn/enumerate as required and saves "$STAGING/native/spawn-observation-$c3_case.redacted.json".
  "$WORKER_ADAPTER" spawn --phase observe --observation "$STAGING/native/spawn-observation-$c3_case.redacted.json" \
    > "$STAGING/owners/c3/02-spawn-$c3_case.json"
  "$WORKER_ADAPTER" await --phase request --dispatch "$STAGING/owners/c3/02-spawn-$c3_case.json" \
    > "$STAGING/native/await-action-$c3_case.redacted.json"
  # Top-level session invokes native wait/query and saves "$STAGING/native/await-observation-$c3_case.redacted.json".
  "$WORKER_ADAPTER" await --phase observe --observation "$STAGING/native/await-observation-$c3_case.redacted.json" \
    > "$STAGING/owners/c3/03-await-$c3_case.json"
  "$WORKER_ADAPTER" persist-result \
    --terminal "$STAGING/owners/c3/03-await-$c3_case.json" \
    --result "$STAGING/native/result-$c3_case.redacted.json" \
    --tier-proof "$STAGING/owners/c2/worker-standard.json" \
    > "$STAGING/owners/c3/04-result-$c3_case.json"
  "$WORKER_ADAPTER" close --phase request --terminal "$STAGING/owners/c3/04-result-$c3_case.json" \
    > "$STAGING/native/close-action-$c3_case.redacted.json"
  # Top-level session invokes native close/query and saves "$STAGING/native/close-observation-$c3_case.redacted.json".
  "$WORKER_ADAPTER" close --phase observe --observation "$STAGING/native/close-observation-$c3_case.redacted.json" \
    > "$STAGING/owners/c3/05-close-$c3_case.json"
  "$WORKER_ADAPTER" reap-recover \
    --manifest "$STAGING/c3/$c3_case-dispatch-manifest.jsonl" --worktree "$CANDIDATE_ROOT" --session "$SESSION_ID" \
    > "$STAGING/owners/c3/06-reap-$c3_case.json"
  "$WORKER_ADAPTER" digest --phase ready --terminal "$STAGING/owners/c3/06-reap-$c3_case.json" \
    > "$STAGING/owners/c3/07-digest-ready-$c3_case.json"
  "$WORKER_ADAPTER" digest --phase claim --ready "$STAGING/owners/c3/07-digest-ready-$c3_case.json" --claim-key "$STAGING/c3/claim-key-$c3_case.json" \
    > "$STAGING/owners/c3/08-digest-claim-$c3_case.json"
  "$WORKER_ADAPTER" digest --phase ack --claim "$STAGING/owners/c3/08-digest-claim-$c3_case.json" --seam "$STAGING/c3/seam-$c3_case.json" \
    > "$STAGING/owners/c3/09-digest-ack-$c3_case.json"
done
for c3_case in conflicting invalid-attestation crash-before-binding; do
  "$WORKER_ADAPTER" prepare-intent --input "$STAGING/c3/$c3_case-intent.json" \
    > "$STAGING/owners/c3/01-prepare-$c3_case.json"
  "$WORKER_ADAPTER" spawn --phase request --intent "$STAGING/owners/c3/01-prepare-$c3_case.json" \
    > "$STAGING/native/spawn-action-$c3_case.redacted.json"
  if [ "$c3_case" = "crash-before-binding" ]; then
    # Top-level session invokes native spawn and intentionally crashes/stops before binding the accepted id.
    "$WORKER_ADAPTER" reap-recover \
      --manifest "$STAGING/c3/$c3_case-dispatch-manifest.jsonl" --worktree "$CANDIDATE_ROOT" --session "$SESSION_ID" \
      > "$STAGING/owners/c3/06-reap-$c3_case.json"
    rg -n 'spawn-acceptance-unknown|emergency-close|writer-uncertain|quarantine' "$STAGING/owners/c3/06-reap-$c3_case.json"
    ! rg -n 'digest-ready|claim-accepted|acknowledged' "$STAGING/owners/c3/06-reap-$c3_case.json"
    continue
  fi
  "$WORKER_ADAPTER" spawn --phase observe --observation "$STAGING/native/spawn-observation-$c3_case.redacted.json" \
    > "$STAGING/owners/c3/02-spawn-$c3_case.json"
  "$WORKER_ADAPTER" await --phase request --dispatch "$STAGING/owners/c3/02-spawn-$c3_case.json" \
    > "$STAGING/native/await-action-$c3_case.redacted.json"
  set +e
  "$WORKER_ADAPTER" await --phase observe --observation "$STAGING/native/await-observation-$c3_case.redacted.json" \
    > "$STAGING/owners/c3/03-await-$c3_case.json"
  await_rc=$?
  set -e
  case "$c3_case" in
    conflicting)
      test "$await_rc" -ne 0
      rg -n 'evidence-conflict|writer-uncertain|quarantine' "$STAGING/owners/c3/03-await-$c3_case.json" ;;
    invalid-attestation)
      set +e
      "$WORKER_ADAPTER" persist-result \
        --terminal "$STAGING/owners/c3/03-await-$c3_case.json" \
        --result "$STAGING/native/result-$c3_case.redacted.json" \
        --tier-proof "$STAGING/owners/c2/worker-invalid-attestation.json" \
        > "$STAGING/owners/c3/04-result-$c3_case.json"
      result_rc=$?
      set -e
      test "$result_rc" -ne 0
      rg -n 'attestation-invalid|TIER_UNVERIFIED|quarantine' "$STAGING/owners/c3/04-result-$c3_case.json"
      "$WORKER_ADAPTER" close --phase request --terminal "$STAGING/owners/c3/04-result-$c3_case.json" \
        > "$STAGING/native/close-action-$c3_case.redacted.json"
      # Top-level session invokes native close/query and saves "$STAGING/native/close-observation-$c3_case.redacted.json".
      "$WORKER_ADAPTER" close --phase observe --observation "$STAGING/native/close-observation-$c3_case.redacted.json" \
        > "$STAGING/owners/c3/05-close-$c3_case.json" ;;
  esac
  "$WORKER_ADAPTER" reap-recover \
    --manifest "$STAGING/c3/$c3_case-dispatch-manifest.jsonl" --worktree "$CANDIDATE_ROOT" --session "$SESSION_ID" \
    > "$STAGING/owners/c3/06-reap-$c3_case.json"
  ! rg -n 'digest-ready|claim-accepted|acknowledged' "$STAGING/owners/c3/06-reap-$c3_case.json"
done

"$RUNTIME_PREFLIGHT" verify-profile --repo "$REPO" --operation setup-apply --operation-nonce "$(uuidgen | tr '[:upper:]' '[:lower:]')" \
  > "$STAGING/owners/c4/verify-profile-setup-apply.json"
"$RUNTIME_REGISTER" discover --runtime-id "$RUNTIME_ID" --team-key "$LINEAR_TEAM_KEY" --transaction "$STAGING/c4/transaction" --lock-context "$STAGING/c4/lock-context.json" \
  > "$STAGING/owners/c4/register-discover.json"
"$RUNTIME_REGISTER" replay --runtime-id "$RUNTIME_ID" --issue-id "$LINEAR_REGISTER_ISSUE_ID" --transaction "$STAGING/c4/transaction" --lock-context "$STAGING/c4/lock-context.json" \
  > "$STAGING/owners/c4/register-replay.json"
"$RUNTIME_REGISTER" append-obligation --intent "$STAGING/c4/obligation-intent.json" --transaction "$STAGING/c4/transaction" --lock-context "$STAGING/c4/lock-context.json" \
  > "$STAGING/owners/c4/register-obligation.json"
"$RUNTIME_STATE" classify-health --profile "$PROFILE" --transaction "$STAGING/c4/transaction" \
  > "$STAGING/owners/c4/health-classification.json"
"$SCHEDULER_ADAPTER" discover --profile "$PROFILE" --repo "$REPO" --scope "$STAGING/c4/scheduler-scope.json" \
  > "$STAGING/native/scheduler-discover-action.redacted.json"
# Top-level session invokes native scheduled-task discovery/mutation probes and saves "$STAGING/native/scheduler-observation.redacted.json".
"$SCHEDULER_ADAPTER" observe --observation "$STAGING/native/scheduler-observation.redacted.json" --transaction "$STAGING/c4/transaction" \
  > "$STAGING/owners/c4/scheduler-observe.json"
"$SLACK_ADAPTER" prepare --profile "$PROFILE" --event "$STAGING/c4/slack-event.json" --transaction "$STAGING/c4/transaction" \
  > "$STAGING/native/slack-send-action.redacted.json"
# Top-level session invokes native Slack send and saves "$STAGING/native/slack-observation.redacted.json".
"$SLACK_ADAPTER" observe --observation "$STAGING/native/slack-observation.redacted.json" --transaction "$STAGING/c4/transaction" \
  > "$STAGING/owners/c4/slack-observe.json"

for c4_case in \
  register-create register-adopt register-append-replay profile-health-crash-recover rollback-post-snapshot c3-complete-quiescence \
  scheduler-boot scheduler-no-overlap scheduler-no-op scheduler-refresh-successor scheduler-failure scheduler-cleanup \
  slack-unknown slack-retry slack-degraded slack-repair slack-stale-re-escalation marketplace-migration marketplace-rollback; do
  case "$c4_case" in
    register-create)
      "$RUNTIME_REGISTER" create --intent "$STAGING/c4/register-create-intent.json" --transaction "$STAGING/c4/transaction" --lock-context "$STAGING/c4/lock-context.json" \
        > "$STAGING/owners/c4/$c4_case.json" ;;
    register-adopt|register-append-replay)
      "$RUNTIME_REGISTER" replay --runtime-id "$RUNTIME_ID" --issue-id "$LINEAR_REGISTER_ISSUE_ID" --transaction "$STAGING/c4/transaction" --lock-context "$STAGING/c4/lock-context.json" \
        > "$STAGING/owners/c4/$c4_case.json" ;;
    profile-health-crash-recover)
      "$RUNTIME_STATE" recover --profile "$PROFILE" --transaction "$STAGING/c4/transaction" --observation "$STAGING/native/$c4_case-observation.redacted.json" \
        > "$STAGING/owners/c4/$c4_case.json" ;;
    rollback-post-snapshot|marketplace-rollback)
      "$RUNTIME_STATE" rollback --profile "$PROFILE" --transaction "$STAGING/c4/transaction" --observation "$STAGING/native/$c4_case-observation.redacted.json" \
        > "$STAGING/owners/c4/$c4_case.json" ;;
    marketplace-migration)
      "$RUNTIME_STATE" begin --profile "$PROFILE" --transaction "$STAGING/c4/transaction" --proposal "$STAGING/c4/marketplace-migration-proposal.json" \
        > "$STAGING/owners/c4/$c4_case-begin.json"
      "$RUNTIME_STATE" record-observation --profile "$PROFILE" --transaction "$STAGING/c4/transaction" --observation "$STAGING/native/$c4_case-observation.redacted.json" \
        > "$STAGING/owners/c4/$c4_case-observation.json"
      "$RUNTIME_STATE" apply --profile "$PROFILE" --transaction "$STAGING/c4/transaction" \
        > "$STAGING/owners/c4/$c4_case.json" ;;
    c3-complete-quiescence)
      "$WORKER_ADAPTER" reap-recover --manifest "$STAGING/c4/quiescence-manifest.jsonl" --worktree "$CANDIDATE_ROOT" --session "$SESSION_ID" \
        > "$STAGING/owners/c4/$c4_case.json" ;;
    scheduler-*)
      "$SCHEDULER_ADAPTER" observe --observation "$STAGING/native/$c4_case-observation.redacted.json" --transaction "$STAGING/c4/transaction" \
        > "$STAGING/owners/c4/$c4_case.json" ;;
    slack-*)
      "$SLACK_ADAPTER" observe --observation "$STAGING/native/$c4_case-observation.redacted.json" --transaction "$STAGING/c4/transaction" \
        > "$STAGING/owners/c4/$c4_case.json" ;;
  esac
done

mkdir -p "$STAGING/owners/claude"
for claude_case in shared-root hook-bash-allow hook-bash-deny hook-task-allow hook-task-deny pinned-leaf-native-wake await-worker-transcript mixed-manifest-reap claim-worktree-preservation; do
  test -s "$STAGING/native/claude-$claude_case-observation.redacted.json"
  python3 - "$claude_case" "$CANDIDATE" "$STAGING/native/claude-$claude_case-observation.redacted.json" "$STAGING/owners/claude/$claude_case.json" <<'PY'
import hashlib, json, sys, time
case, candidate, observation_path, output_path = sys.argv[1:]
payload = open(observation_path, 'rb').read()
record = {
    'scenario': 'claude-' + case,
    'runtime': 'claude-code',
    'candidate': candidate,
    'owner_command': 'top-level-claude-smoke',
    'owner_output_hash': hashlib.sha256(payload).hexdigest(),
    'evidence_kind': 'live',
    'result': 'passed',
    'timestamp': int(time.time()),
    'observation_hash': hashlib.sha256(payload).hexdigest(),
}
open(output_path, 'w').write(json.dumps(record, sort_keys=True, separators=(',', ':')) + '\n')
PY
done

python3 scripts/normalize-codex-release-evidence.py \
  --candidate "$CANDIDATE" \
  --dependency-ledger "$DEPENDENCY_LEDGER" \
  --installed-payload-manifest "$STAGING/installed-payload-manifest.json" \
  --owners "$STAGING/owners" \
  --native "$STAGING/native" \
  --manifest-output "$STAGING/release/release-manifest.json" \
  --output "$STAGING/release/codex-release-matrix.redacted.jsonl" \
  --claude-output "$STAGING/release/claude-non-regression.redacted.jsonl" \
  --cleanup-output "$STAGING/release/external-cleanup.redacted.jsonl"

cd "$CANDIDATE_ROOT"
scripts/validate-runtime-contracts.sh
scripts/validate-runtime-contracts.sh --require-codex-worker-live
scripts/validate-runtime-contracts.sh --require-codex-setup-live
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
scripts/validate-codex-compatibility.sh
```

Expected: all required live families are present and successful; every synthetic record is allowlisted; Claude smoke is clean; cleanup has no unknown; C and installed payload hashes are unchanged.

### Task 9: Redact, hash, and commit evidence-only E

**Files:**
- Create: exactly the seven files under `docs/release/0.17.0-evidence/` listed in File Structure.

- [ ] **Step 1:** Build `release-manifest.json` with C/tree, exact DOD-811 through DOD-814 implementation commits/ancestry, C2/C3/C4 evidence hashes, C3 takeover mode, C4 freeze/baseline identity, supported runtime versions, source/install/plugin/payload fingerprints, validator command/outcome summaries, matrix status, and cleanup state. Do not include E, I, index identity/hash, absolute home/cache paths, or secret-derived values.
- [ ] **Step 2:** Copy only validated compact installed payload/discovery records and normalized redacted Codex/Claude/cleanup JSONL from `$STAGING`. Sort JSONL records deterministically by `scenario`, reject duplicate/missing scenario ids, reject missing `owner_command`/`owner_output_hash` on live records, and reject any record that names E, I, the release index, or an absolute home/cache path.
- [ ] **Step 3:** Scan all six non-hash artifacts for credentials, authorization headers, key/webhook prefixes, private-key blocks, canaries, high-entropy unclassified fields, prompts/user content, transcripts, Slack bodies, production issue bodies, opaque payloads, and absolute home paths. The scanner must run before hash generation and again after the files are staged.
- [ ] **Step 4:** Generate `evidence-hashes.json` last with SHA-256 entries for the other six artifacts only. It must not hash itself, the release index, C/E/I identity files, or future commits. Immediately recompute and compare every listed hash.
- [ ] **Step 5:** Commit exactly the evidence directory as E, then prove C is an ancestor and every `C..E` path is allowlisted.

```bash
set -euo pipefail
test -n "${CANDIDATE:?}"
test -d "${STAGING:?}"
mkdir -p docs/release/0.17.0-evidence
install -m 600 "$STAGING/release/release-manifest.json" docs/release/0.17.0-evidence/release-manifest.json
install -m 600 "$STAGING/installed-payload-manifest.json" docs/release/0.17.0-evidence/installed-payload-manifest.json
install -m 600 "$STAGING/skill-hook-discovery.redacted.json" docs/release/0.17.0-evidence/skill-hook-discovery.redacted.json
install -m 600 "$STAGING/release/codex-release-matrix.redacted.jsonl" docs/release/0.17.0-evidence/codex-release-matrix.redacted.jsonl
install -m 600 "$STAGING/release/claude-non-regression.redacted.jsonl" docs/release/0.17.0-evidence/claude-non-regression.redacted.jsonl
install -m 600 "$STAGING/release/external-cleanup.redacted.jsonl" docs/release/0.17.0-evidence/external-cleanup.redacted.jsonl
python3 - <<'PY'
import collections, hashlib, json, math, os, re
from pathlib import Path
root = Path('docs/release/0.17.0-evidence')
json_files = [
    'release-manifest.json',
    'installed-payload-manifest.json',
    'skill-hook-discovery.redacted.json',
]
jsonl_files = [
    'codex-release-matrix.redacted.jsonl',
    'claude-non-regression.redacted.jsonl',
    'external-cleanup.redacted.jsonl',
]
for name in json_files:
    data = json.loads((root / name).read_text())
    text = json.dumps(data, sort_keys=True, separators=(',', ':'))
    forbidden = {'evidence_commit', 'index_commit', 'signoff_commit', 'I', 'release_index_hash'}
    if forbidden.intersection(data):
        raise SystemExit(f'forbidden identity field in {name}')
    (root / name).write_text(text + '\n')
for name in jsonl_files:
    records = []
    seen = set()
    for line in (root / name).read_text().splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        scenario = record.get('scenario')
        if not scenario or scenario in seen:
            raise SystemExit(f'duplicate/missing scenario in {name}: {scenario!r}')
        seen.add(scenario)
        if record.get('evidence_kind') == 'live' and (not record.get('owner_command') or not record.get('owner_output_hash')):
            raise SystemExit(f'live record lacks owner proof: {scenario}')
        for bad in ('evidence_commit', 'index_commit', 'signoff_commit', 'release_index_hash'):
            if bad in record:
                raise SystemExit(f'forbidden identity field in {name}: {bad}')
        records.append(record)
    records.sort(key=lambda r: r['scenario'])
    (root / name).write_text(''.join(json.dumps(r, sort_keys=True, separators=(',', ':')) + '\n' for r in records))
text = ''.join((root / name).read_text() for name in json_files + jsonl_files)
patterns = [
    r'Authorization:\s*Bearer\s+\S+', r'github_pat_', r'gh[pousr]_[A-Za-z0-9_]+',
    r'xox[baprs]-', r'-----BEGIN [A-Z ]*PRIVATE KEY-----', r'LINEAR_(DODI_)?API_KEY\s*=',
    r'https://hooks\.slack\.com/', r'/Users/[^/\s]+/', r'BEGIN PROMPT', r'raw_transcript',
]
canary_path = Path('dodi-dev/scripts/tests/fixtures/codex-release/secret-canaries.txt')
if not canary_path.exists():
    raise SystemExit('missing required secret canary fixture')
patterns.extend(re.escape(line.strip()) for line in canary_path.read_text().splitlines() if line.strip())
for pat in patterns:
    if re.search(pat, text):
        raise SystemExit(f'secret/redaction pattern matched: {pat}')
def entropy(value):
    counts = collections.Counter(value)
    total = len(value)
    return -sum((n / total) * math.log2(n / total) for n in counts.values())
entropy_allow = [
    re.compile(r'^[a-f0-9]{40}$'),
    re.compile(r'^[a-f0-9]{64}$'),
    re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'),
]
for token in re.findall(r'[A-Za-z0-9_+/=-]{32,}', text):
    if any(p.fullmatch(token) for p in entropy_allow):
        continue
    if entropy(token) >= 4.2:
        raise SystemExit(f'unclassified high-entropy value: {token[:8]}...')
hashes = {}
for name in json_files + jsonl_files:
    hashes[name] = hashlib.sha256((root / name).read_bytes()).hexdigest()
(root / 'evidence-hashes.json').write_text(json.dumps({'artifacts': hashes}, sort_keys=True, indent=2) + '\n')
loaded = json.loads((root / 'evidence-hashes.json').read_text())['artifacts']
for name, expected in loaded.items():
    actual = hashlib.sha256((root / name).read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f'hash mismatch for {name}')
print('release evidence normalized, scanned, and hashed')
PY
git diff --check
git add docs/release/0.17.0-evidence
python3 - <<'PY'
import subprocess, sys
allowed = {
  'docs/release/0.17.0-evidence/release-manifest.json',
  'docs/release/0.17.0-evidence/installed-payload-manifest.json',
  'docs/release/0.17.0-evidence/skill-hook-discovery.redacted.json',
  'docs/release/0.17.0-evidence/codex-release-matrix.redacted.jsonl',
  'docs/release/0.17.0-evidence/claude-non-regression.redacted.jsonl',
  'docs/release/0.17.0-evidence/external-cleanup.redacted.jsonl',
  'docs/release/0.17.0-evidence/evidence-hashes.json',
}
staged = set(subprocess.check_output(['git', 'diff', '--cached', '--name-only'], text=True).splitlines())
if staged != allowed:
    raise SystemExit(f'unexpected staged paths: {sorted(staged ^ allowed)}')
PY
git commit -m "docs: add redacted 0.17.0 release evidence"
EVIDENCE_COMMIT="$(git rev-parse HEAD)"
git merge-base --is-ancestor "$CANDIDATE" "$EVIDENCE_COMMIT"
test -z "$(git diff --name-only "$CANDIDATE..$EVIDENCE_COMMIT" | sed -n '/^docs\/release\/0\.17\.0-evidence\//!p')"
```

Expected: all artifacts parse, sort, scan, and hash-verify; duplicate scenarios and forbidden identity fields fail; exactly seven evidence paths are committed; E is a descendant of C and changes nothing else.

### Task 10: Complete index-only I and run the read-only release verdict

**Files:**
- Modify: `docs/release/0.17.0-release-evidence.md` only.

- [ ] **Step 1:** Replace template tokens with C and E identities, C tree, supported runtime versions, installed payload hash, links and hashes for all seven artifacts, matrix summaries, cleanup state, rollback readiness, and remaining blockers. Do not add an I/index/signoff commit identity field to the index; the validator derives I from clean `HEAD`.
- [ ] **Step 2:** Keep `## TL;DR` and `## Key Points` self-sufficient. State that evidence proves release eligibility but does not perform Gate 2. Keep `Human Gate 2 decision: PENDING` in the pre-merge I package; the validator treats that exact value as an intact human fence, not a release blocker. The human records the actual approve/reject action through the existing DOD-810 Gate 2 surface rather than requiring an automated or post-decision rewrite of release evidence.
- [ ] **Step 3:** Commit only the index as I. Prove `E..I` contains one path and no evidence artifact changed.
- [ ] **Step 4:** Run `--require-live-release` and `--release` from a clean checkout at I. Require `--release` to accept only the exact pending human-fence value before merge; missing, blank, pre-approved, or automation-authored decision text fails docs/signoff validation.

```bash
set -euo pipefail
git add docs/release/0.17.0-release-evidence.md
test "$(git diff --cached --name-only)" = "docs/release/0.17.0-release-evidence.md"
git commit -m "docs: index 0.17.0 release evidence"
INDEX_COMMIT="$(git rev-parse HEAD)"
test "$INDEX_COMMIT" = "$(git rev-parse HEAD)"
! rg -n 'index_commit|signoff_commit|release_index_hash|^I:' docs/release/0.17.0-release-evidence.md
test "$(git diff --name-only "$EVIDENCE_COMMIT..$INDEX_COMMIT")" = "docs/release/0.17.0-release-evidence.md"
git status --short
scripts/validate-codex-compatibility.sh --require-live-release
scripts/validate-codex-compatibility.sh --release
```

Expected before human Gate 2: clean status; live mode exits `0`; release mode emits one JSON object with `RELEASE_READY`; the index still says `Human Gate 2 decision: PENDING`; no external state is mutated.

### Task 11: Run final regression, provenance, ownership, and release-fence audit

**Files:**
- Verify only: all C5 files and all landed C1-C4 owned surfaces.

- [ ] **Step 1:** Run the complete deterministic and repository battery from clean I.

```bash
set -euo pipefail
export PATH="/tmp/dodi-runtime-contracts-venv/bin:$PATH"
dodi-dev/scripts/tests/test-codex-release-validation.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
scripts/validate-runtime-contracts.sh
scripts/validate-runtime-contracts.sh --require-codex-worker-live
scripts/validate-runtime-contracts.sh --require-codex-setup-live
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
scripts/validate-codex-compatibility.sh
scripts/validate-codex-compatibility.sh --require-live-release
scripts/validate-codex-compatibility.sh --release
git diff --check
```

Expected: every command exits `0`; focused test prints `codex release validation tests ok`; metadata prints `plugin metadata ok: 0.17.0`; final release summary is `RELEASE_READY` with the human Gate 2 field still `PENDING`.

- [ ] **Step 2:** Prove the C/E/I graph and plugin payload immutability.

```bash
set -euo pipefail
git merge-base --is-ancestor "$CANDIDATE" "$EVIDENCE_COMMIT"
git merge-base --is-ancestor "$EVIDENCE_COMMIT" "$INDEX_COMMIT"
test -z "$(git diff --name-only "$CANDIDATE..$EVIDENCE_COMMIT" | sed -n '/^docs\/release\/0\.17\.0-evidence\//!p')"
test "$(git diff --name-only "$EVIDENCE_COMMIT..$INDEX_COMMIT")" = "docs/release/0.17.0-release-evidence.md"
test -z "$(git diff --name-only "$CANDIDATE..$INDEX_COMMIT" -- dodi-dev scripts .claude-plugin .agents docs/guides)"
```

Expected: ancestry checks pass; C..E is evidence-only; E..I is index-only; runtime/validator/metadata/guide/plugin payload are unchanged after C.

- [ ] **Step 3:** Prove metadata topology and single-tree ownership.

```bash
set -euo pipefail
python3 - <<'PY'
import json
from pathlib import Path
claude = json.loads(Path('dodi-dev/.claude-plugin/plugin.json').read_text())
codex = json.loads(Path('dodi-dev/.codex-plugin/plugin.json').read_text())
market = json.loads(Path('.claude-plugin/marketplace.json').read_text())['plugins'][0]
codex_market = json.loads(Path('.agents/plugins/marketplace.json').read_text())['plugins'][0]
assert claude['version'] == codex['version'] == market['version'] == '0.17.0'
assert market['source'] == './dodi-dev'
assert codex_market['source']['path'] == './dodi-dev'
assert 'version' not in codex_market
print('0.17.0 topology ok')
PY
test "$(find . -type d -path '*/skills' -not -path './dodi-dev/skills' -not -path './.git/*' | wc -l | tr -d ' ')" = "0"
test -z "$(find dodi-dev/skills -type l -print)"
```

Expected: `0.17.0 topology ok`; no mirror/symlink; Codex marketplace remains versionless.

- [ ] **Step 4:** Rerun the release secret/redaction scan over tracked C5 surfaces and inspect `git status --short`. Verify no raw logs, production ids/content, credentials, absolute homes, prompts, transcripts, opaque native payloads, or unclassified high-entropy fields are tracked.
- [ ] **Step 5:** Review the release index header and links as the DOD-810 Gate 2 package. Confirm no validator/script/task contains merge, auto-merge, tag, publish, branch-protection mutation, or production enablement behavior. Present readiness; do not perform Gate 2.

## Handoff Assumptions And Blockers

- Assumption: DOD-811 through DOD-814 implementation commits will land before DOD-815 delivery in the approved waterfall order; their current mature-branch planning commits are not sufficient.
- Assumption: The supported current Codex Desktop/plugin runtime exposes the marketplace/plugin, app-server discovery, hook trust, worker/model, and task surfaces approved by the parent spec. The locally observed `codex-cli 0.38.0` is unsupported.
- Assumption: C4 provides proposal-bound disposable setup, complete C3 quiescence, exact marketplace migration/rollback, and authoritative external cleanup evidence that C5 can invoke and hash without reimplementation.
- Assumption: Exact version-bound fixture paths are finalized from the landed C1-C4 tree in Task 1; the two known profile fixtures named in File Structure are minimum expected inputs, not permission to invent absent files.
- Assumption: I presents an intact `PENDING` human Gate 2 fence; the eventual approve/reject action uses the existing DOD-810 Gate 2 surface and does not require rewriting candidate-bound evidence. Any runtime, validator, guide, metadata, or evidence correction requires a new C and complete rerun.
- Blocker: Any missing/incompatible C1-C4 executable contract or owning evidence returns to that child and stops C5.
- Blocker: Missing supported runtime, disposable external scope, Claude harness, exact trust/authority proof, or authoritative cleanup blocks `0.17.0`; no fixture or reduced support statement substitutes.
- Blocker: Any secret leak, stale candidate, out-of-surface E/I diff, unresolved rollback, missing/altered human Gate 2 fence, or attempted automated Gate 2 action prevents a final `RELEASE_READY` verdict.
