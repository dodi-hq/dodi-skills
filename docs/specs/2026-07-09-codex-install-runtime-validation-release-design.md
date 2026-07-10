# DOD-815 - Codex Install/Runtime Validation, Documentation, and 0.17.0 Release

**Date:** 2026-07-09
**Parent epic:** DOD-810
**Type:** Compatibility validation / release gate
**Target repo:** dodi-hq/dodi-skills
**Target release:** dodi-dev 0.17.0
**Predicted delivery tier:** standard

## TL;DR

DOD-815 is the final release child for DOD-810. It proves the landed C1-C4 implementation from a clean Codex installation, repeats the complete supported-runtime matrix, records focused Claude Code non-regression evidence, publishes operator install/upgrade guidance, and advances every version-bearing metadata envelope to `0.17.0` as one release candidate.

C5 is an evidence and release fence, not a fifth runtime implementation layer. Missing, stale, ambiguous, unredacted, or candidate-mismatched evidence blocks release; C5 may expose an upstream defect, but it may not redefine C1-C4 contracts or weaken v0.16 workflow and Gate semantics to make the matrix pass.

## Key Points

- **Landed dependencies are mandatory:** release validation starts only after the DOD-811, DOD-812, DOD-813, and DOD-814 implementation commits are ancestors of the release candidate and their deterministic/live evidence validates from the candidate tree.
- **The installed artifact is the subject:** an isolated `HOME`/`CODEX_HOME` installs from the candidate marketplace into a real cache, and every discovery, root, profile, hook, tier, worker, setup, scheduler, and escalation assertion runs against that installed root rather than the source checkout.
- **One final validator owns the verdict:** `scripts/validate-codex-compatibility.sh` composes existing C1-C4 validators and C5 install/live/Claude evidence checks; it links to their mechanics and does not copy their schemas or policy.
- **Live means live and current:** C2-C4 implementation evidence remains required input, but C5 repeats the parent-approved Codex matrix on the supported current Desktop/plugin runtime and binds the result to one immutable release-candidate commit.
- **Claude Code remains a release gate:** an unrelated temporary repository proves shared skill/root resolution, both hooks, pinned leaf dispatch, transcript fallback, mixed manifests, and reap/claim state without a Codex profile.
- **Release metadata is synchronized:** the three version-bearing envelopes become `0.17.0` together; both marketplace envelopes must still resolve the same `./dodi-dev` directory, and no copied/symlinked skill tree or synthetic Codex-marketplace version field is introduced.
- **Documentation and evidence are checked artifacts:** install/upgrade/rollback guidance and the redacted evidence index are hash/provenance checked against the candidate, supported runtime, installed root, and actual validator commands.
- **Gate 2 remains human:** a clean C5 verdict permits DOD-810 release submission; no validator, scheduled task, or release script merges, auto-merges, publishes around, or weakens the epic Gate 2 decision.

---

## Decision Context

The DOD-810 parent design is approved at `docs/specs/2026-07-09-codex-runtime-compatibility-design.md @ baf219a`. The epic uses waterfall delivery:

```text
DOD-811 -> DOD-812 --+
    |                 +-> DOD-814 -> DOD-815
    +-> DOD-813 -----+
```

The following child designs and plans are canonical ownership inputs:

| Child | Canonical epic state | C5 consumes | C5 must not redefine |
| --- | --- | --- | --- |
| DOD-811 / C1 | `978cad7` | installed runtime canon; profile/health/register/manifest schemas; root bootstrap; shared adapter interfaces; deterministic validator | paths, schema fields, generation/hash binding, statuses, runtime authority |
| DOD-812 / C2 | `5d084b5` | Codex model map; main-loop/worker verification; capacity policy routing; model-pin hook fixtures/live evidence | tier pairs, proof allowlist, Fable policy, attestation or substitution semantics |
| DOD-813 / C3 | `a3124f4` | Codex worker adapter; result/manifest/quarantine evidence; selected takeover mode; worker live evidence | spawn/await/close/reap ordering, lifecycle states, uncertainty or quarantine rules |
| DOD-814 / C4 | `a7a63a2` | setup/preflight/auth/register/state/scheduler/Gate 2/Slack/marketplace operations; C4 live evidence; C5 fences | setup state machine, quiescence, writer/lock ownership, external action normalization, rollback mechanics |

Those commits identify approved specs and plans, not proof that implementation exists. The C5 release manifest records the exact landed implementation commit for each child, verifies each is an ancestor of the candidate, and binds its evidence hashes. A missing executable contract, incompatible landed shape, or unreviewed C1-C4 change returns to the owning child or DOD-810 decision lane.

The preserved compatibility baseline is v0.16 behavior: one canonical `dodi-dev/skills/` tree, top-level-only worker dispatch, leaf workers, serial mutable lanes, one driver writer, existing Fable availability policy, claims, review rounds, coherence handling, refresh seams, and human Gate 2. Codex adapters may realize those semantics through their approved runtime contracts; C5 may not alter the semantics themselves.

## Problem

C1-C4 can each pass while the release remains unusable. Repository validators may inspect source files rather than the installed cache; implementation live evidence may have been captured against a different commit or runtime; a stale same-name marketplace may install an older package; hook discovery may hide an untrusted or wrong-root command; documentation and metadata can drift after tests; and Codex-oriented shared changes can regress Claude Code behavior.

The release therefore needs one final boundary that answers all of these questions with candidate-bound evidence:

1. Did the candidate install into a clean supported Codex environment from the canonical marketplace source?
2. Did the installed cache contain exactly the canonical release tree, skills, hooks, policy, adapters, and `0.17.0` metadata?
3. Did the complete live Codex contract pass from that installed root with current trust, auth, task, worker, and external-action evidence?
4. Did the shared tree retain Claude Code behavior in an unrelated repository?
5. Are install, upgrade, rollback, metadata, and evidence references mutually consistent and free of secrets?
6. Can a human make the DOD-810 Gate 2 decision without relying on transient logs or an operator assertion?

## Goals

1. Provide deterministic CI validation for candidate packaging, contract/reference integrity, metadata parity, documentation links, evidence structure, and forbidden runtime assumptions.
2. Prove a clean local candidate marketplace install in isolated Codex state without consulting the operator's existing marketplace or cache.
3. Repeat the complete parent-approved live Codex matrix against the installed release candidate.
4. Prove focused Claude Code non-regression from the same candidate.
5. Produce one redacted, hash-bound release evidence bundle and self-sufficient release checklist.
6. Document supported install, upgrade, setup, stale-marketplace migration, verification, and rollback paths.
7. Advance all version-bearing release metadata to `0.17.0` without changing marketplace topology.
8. Make every missing, stale, ambiguous, mismatched, or leaking prerequisite a release blocker.

## Non-Goals

- No new runtime profile, health, register, model-map, manifest, quarantine, scheduler, Slack, hook, or adapter schema.
- No implementation or repair of C1 root/profile contracts, C2 tier/hook mechanics, C3 worker lifecycle, or C4 setup/auth/scheduling/escalation mechanics.
- No copied Codex skill tree, compatibility mirror, symlinked skill tree, or release-only runtime-policy copy.
- No change to v0.16 workflow states, Gate 1, Gate 2, Fable buckets, review topology, claims, coherence decisions, retry ceilings, or context-refresh semantics.
- No support claim for legacy Homebrew Codex `0.38.0`; the supported current Codex Desktop/plugin runtime is the release target.
- No production credential capture, production Slack content, raw transcript, prompt, user data, or opaque native payload in committed evidence.
- No automatic production task enablement, release merge, tag, marketplace publication, or post-merge setup mutation.
- No prose downgrade from a failed live scenario to a narrower support claim. The approved matrix passes or `0.17.0` remains blocked.

## Binding Release Inputs

### Candidate identity

Release validation uses an acyclic three-commit identity chain:

1. **Candidate commit C** contains all landed C1-C4 implementation, C5 validators/tests, install guidance, synchronized `0.17.0` metadata, and the empty or template release-index surface, but not the final generated C5 live evidence bundle. Tests execute from a detached worktree at C.
2. **Evidence commit E** may add only the redacted C5 evidence bundle under `docs/release/0.17.0-evidence/`. The bundle records C, the candidate tree id, installed payload hash, runtime observations, cleanup status, and dependency evidence hashes; it does not name E, does not name the release index, and no artifact hashes itself.
3. **Index/signoff commit I** may update only `docs/release/0.17.0-release-evidence.md`. The index names C and E, records the evidence manifest/hash-manifest hashes, summarizes the matrix, and carries the human Gate 2 decision field. No evidence artifact hashes I; the index is the terminal human signoff surface, not runtime authority.

The release validator rejects any runtime, skill, hook, metadata, validator, guide, or C1-C4 evidence delta after C. `--require-live-release` validates C plus the evidence bundle at E; `--release` validates I and the C->E->I surface restrictions. If review finds a defect outside the allowed evidence or index surfaces, a new C is cut and every required C5 gate is rerun.

### Dependency ledger

The release manifest records:

- candidate commit C and tree id;
- exact landed implementation commits for DOD-811 through DOD-814;
- proof that each implementation commit is an ancestor of the candidate;
- hashes of C2 tier live evidence, C3 worker live evidence, and C4 setup live evidence;
- C3 selected takeover mode and C4 contract-freeze/baseline identity;
- exact validator versions/paths and exit outcomes;
- supported Codex and Claude runtime versions used by C5;
- canonical source root, installed cache root fingerprint, plugin metadata hashes, and installed payload manifest hash;
- cleanup/rollback status for every disposable external scope.

The release index, not the evidence manifest, records C and E identities; `--release` derives I from the clean checkout `HEAD`. That keeps the hash graph one-way: candidate and bundle evidence can be hashed before the final signoff index exists, and the final index can refer back to them without becoming part of the installed payload proof.

Specs, plans, ticket status, or a clean implementation-child review do not substitute for this ledger. C5 validates the landed executable contracts and committed evidence present in the candidate.

### Existing validator composition

The final gate invokes, rather than restates, the landed validation surfaces:

```bash
scripts/validate-runtime-contracts.sh
scripts/validate-runtime-contracts.sh --require-codex-worker-live
scripts/validate-runtime-contracts.sh --require-codex-setup-live
scripts/validate-phase-skills.sh
scripts/validate-plugin-metadata.sh
scripts/validate-ticket-comment-templates.sh
for test_file in dodi-dev/scripts/tests/test-*.sh; do "$test_file"; done
```

C2's committed live fixture family is also required and checked by its landed tests/reference rules. C5 must not add a parallel parser for C1-C4 evidence semantics; it verifies required files/hashes/provenance, invokes the owning validators, and records their compact outcomes.

## Design

### 1. Final compatibility validator

Add `scripts/validate-codex-compatibility.sh` as the single release verdict surface. It has four explicit modes:

| Mode | Purpose | External mutation |
| --- | --- | --- |
| default | CI-safe candidate metadata, packaging, reference, docs-template, redaction-rule, dependency-declaration, fixture, and negative-case checks | none |
| `--require-isolated-install` | require and validate a fresh installed-cache evidence set for the candidate | local temporary marketplace/cache only |
| `--require-live-release` | require current C5 Codex and Claude live evidence bundle E plus cleanup proof for C | none; capture occurs through separately confirmed disposable runs |
| `--release` | require every prior mode, evidence-only E diff, index-only I diff, and complete signoff checklist | none during validation |

Unknown flags, missing tools, evidence absent from a mode that requires it, unsupported runtime versions, unresolved external outcomes, or skipped commands are failures. The validator emits one compact machine-readable summary plus concise diagnostics, never raw logs or secret-bearing environment values.

The default mode checks at least:

- every existing repository validator and C1-C4 focused test remains registered and callable;
- all required dependency commit declarations exist and candidate-time dependency evidence paths are present; final C5 live evidence/index checks are skipped unless the selected mode requires them;
- both marketplaces still source `./dodi-dev`, plugin ids/names agree, and version-bearing metadata is exactly `0.17.0`;
- one real canonical `dodi-dev/skills/` directory exists, with no mirror, copied runtime policy, or symlink;
- the source skill set equals the expected released skill manifest derived from canonical `SKILL.md` frontmatter, including C4's setup skill, without relying on the parent's pre-C4 count;
- every installed runtime-policy/script reference resolves under `dodi-dev/`, ordinary skill commands contain no unresolved ambient plugin-root dependency, and hooks remain the narrowly validated exception;
- C1-C4 schema/policy ownership fences hold and C5 files contain no competing mechanics;
- guides, release-index template fields, command names, supported-runtime statement, and marketplace paths resolve and agree with metadata/scripts before live evidence exists;
- JSON/JSONL, shell syntax/executable bits, file permissions, canonical hashes, `git diff --check`, and candidate/evidence/index surface-rule fixtures pass;
- secret canaries and credential patterns are absent from tracked release surfaces.

`scripts/validate-codex-install.sh` is the narrow installed-artifact harness used by `--require-isolated-install`. It owns temporary-home setup, Codex marketplace/plugin operations, installed-root discovery, and compact evidence capture; it does not implement runtime preflight, setup, tier, worker, hook, scheduler, or escalation logic.

### 2. Isolated Codex install gate

The install harness creates fresh `HOME`, `CODEX_HOME`, XDG/config, target repository, and evidence/log directories with no inherited Codex marketplace, plugin cache, Dodi profile, auth file, hooks trust, or task state. It installs through the candidate's local marketplace path so the pre-merge commit, not `main`, is tested.

The gate must prove:

1. pre-install marketplace/plugin/cache listings are empty for `dodi-skills` and `dodi-dev`;
2. the local candidate marketplace canonicalizes to the detached candidate checkout and both envelopes resolve `./dodi-dev`;
3. `dodi-dev@dodi-skills` installs into a cache path outside the source checkout and reports `0.17.0`;
4. the installed payload manifest matches the candidate `dodi-dev/` payload byte-for-byte except for allowlisted installer-owned metadata, which is recorded and explained;
5. app-server `skills/list` discovers exactly the canonical source skill names with no errors, duplicates, or disabled release skill;
6. `hooks/list` discovers exactly the model-pin and Gate 2 hooks from the installed root, with command paths/hashes matching installed metadata rather than source paths;
7. a skill locator under the installed cache resolves the same concrete installed plugin root through C1 bootstrap, while source-root, mixed-root, traversal, missing-metadata, and locator/root mismatch cases fail closed;
8. bootstrap and read-only inspect work before a profile exists; mutating/tiered operations return the approved setup fence rather than searching host state;
9. after separately confirmed disposable setup, the generated profile/health/register bindings name the installed root/version and pass C2-compatible verification;
10. the installed package contains the runtime canon, schemas, model map, Claude and Codex worker adapter contracts/implementation, setup skill, deterministic helpers, and no repository-only dependency;
11. uninstall/cleanup removes the temporary plugin, marketplace, profiles, tasks, disposable worktrees, and local secrets, with unknown cleanup treated as a failed gate.

A separate negative fixture seeds a same-name stale marketplace/cache provenance before installation. The harness must show C4 collision detection blocks install/upgrade/profile enablement until the explicit migration path yields one canonical source. It may not silently delete, rewrite, or prefer either root.

### 3. Installed-root and hook trust integrity

Discovery is necessary but insufficient. The C5 live gate binds each hook's identity to:

- candidate commit and installed payload hash;
- canonical installed plugin root;
- hook metadata entry and script hash;
- supported runtime version and observed matcher/action schema;
- explicit trust observation for those exact hashes;
- live deny/allow outcomes.

Trust for a source checkout, earlier cache entry, previous script hash, same-name marketplace, or one hook only does not transfer. A root/hash mismatch returns `SETUP_REQUIRED` through C4 behavior and blocks release. C5 records the mismatch; it does not grant broad trust or alter matcher policy.

### 4. Live Codex release matrix

Run the parent design's complete live matrix from the isolated installed root on the supported current Codex Desktop/plugin runtime. Existing C2-C4 live evidence is dependency evidence, not a waiver for this repetition.

The C5 matrix includes:

- exact trust plus complete Gate 2 protected-base/rules deny and child/read allow live-fire, including proof that the restricted scheduled actor cannot merge, auto-merge, update the base, bypass, or administer protection even if client hooks are absent;
- model-pin pre-spawn deny/allow, all four semantic tier model/reasoning probes, effective main-loop/worker attestation, fresh-context/no-inherit evidence, wrong/unverifiable/setup/capacity/error classifications, and required hard/deferred/soft attribution/obligation outcomes;
- one read-only and one mutable worker lifecycle, explicit wait and close, result-before-terminal ordering, tier verification before consumption, duplicate-equivalent and conflicting terminal evidence, digest ready/claim/ack, reap/no-write/slot proof, and invalid-attestation quarantine/baseline behavior;
- planned context refresh/resume and different-top-level-session recovery from durable manifests, including the C3 selected addressability/parent-termination/quarantine mode and crash-before-binding path;
- C4 read-only inspect, selected disposable runtime id, direct Linear read plus register create/adopt/append/replay, profile/health crash recovery, and rollback that preserves a post-snapshot obligation;
- exact scheduler configuration, boot verification, no overlap, one no-op guard, one `refresh-park` successor wake from a distinct context, failure notification, Gate 2 denial, and authoritative probe cleanup;
- one register-backed Slack delivery plus unknown-response, retry, degraded, repair, and stale re-escalation outcomes, with obligation-before-send and delivered-after-durable-result ordering;
- one stale-marketplace migration and exact rollback in a disposable configuration.

Every family is required. Fixture injection is allowed only for the explicitly synthetic conflict/failure cases whose native occurrence would be unsafe or nondeterministic; fixture results must be clearly identified and may not stand in for required real install, trust, worker, auth, scheduler, Gate 2, Slack delivery, migration, or cleanup observations.

### 5. Claude Code non-regression gate

Run from an unrelated temporary target repository with no Codex profile, Codex marketplace, or Dodi repository checkout as cwd. Use the installed/shared candidate tree appropriate to Claude Code and prove:

1. one shared entry-point skill resolves scripts through `${CLAUDE_PLUGIN_ROOT}` with no Codex setup requirement;
2. both hooks live-fire with representative allow and deny payloads, including Claude `Bash` and `Task|Agent` shapes;
3. one explicitly pinned leaf worker uses the requested Claude alias, wakes natively, and writes the existing terminal manifest record;
4. `await-worker.sh` succeeds through the transcript-backed completion fallback;
5. a mixed legacy Claude/v1 Claude/v1 Codex manifest classifies without requiring a Codex result artifact for the Claude record or a Claude transcript for Codex;
6. the completed Claude worker reaps and preserves existing claim/worktree state transitions;
7. existing repository validators and every focused shell test pass under the Claude-compatible environment.

Any shared-canon, script-root, hook, pin, completion, transcript fallback, manifest, reap, claim, or workflow-semantic regression blocks release. C5 does not fix it by adding a Claude-only skill copy or bypassing Codex paths.

### 6. Documentation contract

Create one operator guide at `docs/guides/codex-install-upgrade.md`. It covers:

- supported current Codex Desktop/plugin prerequisites and the explicit non-support of legacy CLI `0.38.0`;
- canonical remote install:

  ```bash
  codex plugin marketplace add dodi-hq/dodi-skills --ref main
  codex plugin add dodi-dev@dodi-skills
  ```

- local development install from an absolute repository path;
- how to inspect marketplace and installed-cache provenance before install/upgrade;
- same-name stale marketplace collision handling through `setup-dodi-dev`, with explicit confirmation and no manual guessed cache deletion;
- install, upgrade, setup inspect/apply, hook trust, profile verification, disabled-task verification, and separately confirmed lights-out enablement boundaries;
- required external Linear, GitHub, scheduler, and Slack prerequisites without secret values;
- expected fail-closed statuses and the owning repair surface;
- rollback to a verified prior installation/profile/task snapshot while preserving current register, manifest, result, and quarantine evidence;
- removal/cleanup verification.

The guide describes operator sequence and named postconditions. It links to installed commands/scripts for mechanics rather than copying C1-C4 algorithms. The validator checks command names, marketplace ids/paths, metadata version, status names, and evidence links so prose cannot silently drift.

Create `docs/release/0.17.0-release-evidence.md` as the human signoff index. It contains `## TL;DR` and `## Key Points`, candidate C and evidence E identities, exact redacted bundle links/hashes, matrix outcomes, remaining blockers, cleanup status, rollback readiness, and the human Gate 2 decision field. It contains no raw logs and is not runtime authority. Before E exists, the file may contain only the reviewed template/header fields required for candidate-time docs validation.

### 7. Release evidence bundle and redaction

Store final, candidate-bound machine-verifiable C5 evidence under `docs/release/0.17.0-evidence/`, outside the published `dodi-dev/` plugin payload:

| Artifact | Purpose |
| --- | --- |
| `release-manifest.json` | candidate, dependency commits, runtime versions, source/install fingerprints, validator outcomes, matrix status, cleanup state |
| `installed-payload-manifest.json` | relative installed paths, modes, and hashes; no absolute home/cache path |
| `skill-hook-discovery.redacted.json` | expected/observed skill names and hook identities/hashes |
| `codex-release-matrix.redacted.jsonl` | one compact record per required Codex scenario |
| `claude-non-regression.redacted.jsonl` | one compact record per required Claude scenario |
| `external-cleanup.redacted.jsonl` | disposable Linear/GitHub/task/Slack/marketplace cleanup outcomes |
| `evidence-hashes.json` | SHA-256 for every other C5 live artifact, explicitly excluding itself |

Each record names the scenario, runtime, candidate C, installed payload hash, evidence kind (`live` or `synthetic-negative`), result, timestamp, and non-secret observation hash. The hash manifest binds only the evidence bundle artifacts and explicitly excludes itself, the release evidence index, and any future signoff commit identity. Raw execution logs remain outside the repository in a mode-restricted temporary directory and are deleted only after redacted artifacts validate and cleanup is authoritative.

Deterministic negative fixtures and redaction canaries may live under `dodi-dev/scripts/tests/fixtures/codex-release/` because they are part of the released validator test suite. Final live C5 evidence never lives under `dodi-dev/`, is never installed as plugin payload, and never changes the installed-payload hash after C.

Committed evidence must not contain credentials, secret-derived hashes, environment-file contents, prompts, user content, raw transcripts, Slack message bodies, production issue bodies, opaque native payloads, absolute home paths, or unrelated environment values. Synthetic identifiers are preferred; low-risk disposable external ids may be represented by one-way non-secret scope hashes when needed for cleanup correlation.

Secret scanners include known key prefixes, assignment forms, canary values used by C1-C4 tests, private-key blocks, authorization headers, webhook URLs, and high-entropy fields outside an explicit allowlist. A scanner error or suspicious unclassified value blocks the release; C5 never deletes evidence merely to hide a leak without rotating/revoking the exposed credential and regenerating the bundle.

### 8. Metadata and packaging sweep

The release candidate changes all and only the currently version-bearing metadata values to `0.17.0`:

- `dodi-dev/.claude-plugin/plugin.json`
- `dodi-dev/.codex-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

`.agents/plugins/marketplace.json` remains versionless by schema and continues to point to local `./dodi-dev`; C5 must not invent a version property. Both marketplace envelopes, both plugin envelopes, and repository validators are still part of the synchronized packaging sweep. No root `.claude-plugin/plugin.json` or alternate plugin envelope is created.

The C1 valid profile fixture and any other approved version-bound fixture move to `0.17.0` in the same candidate. Historical/live evidence that truthfully records an earlier tested plugin version is not rewritten; it is either retained with explicit provenance or regenerated where the owning validator requires candidate equality. Search results for operative `0.16.0` release assumptions must be empty outside allowlisted historical/migration/non-regression text.

The metadata bump never lands as a standalone release claim. It is coupled to validators, guide, candidate install, complete live evidence, Claude evidence, and the release signoff index.

### 9. Release signoff and Gate 2

`0.17.0` is eligible for DOD-810 Gate 2 submission only when:

1. all C1-C4 implementation commits are present and their committed evidence/validators pass;
2. the release candidate C is immutable, E changes only the approved evidence bundle, and I changes only the approved release index;
3. `scripts/validate-codex-compatibility.sh --release` exits `0` from a clean checkout;
4. isolated install, complete Codex live matrix, focused Claude smoke, redaction scan, docs drift check, and cleanup all pass;
5. the evidence index names no blocker or unknown outcome;
6. rollback prerequisites and prior known-good provenance are recorded;
7. the DOD-810 decision register has no unresolved superseding decision;
8. a human reviews the signoff header/evidence links and makes the existing epic Gate 2 decision.

The validator may report `RELEASE_READY`; it cannot merge, auto-merge, enable auto-merge, tag, publish, alter branch protection, or enable production scheduled tasks. After human merge, remote-marketplace installation and real-user setup are separate confirmed rollout actions.

## Fail-Closed Matrix

| Condition | Required C5 behavior |
| --- | --- |
| DOD-811 through DOD-814 implementation commit absent, not an ancestor, or contract/evidence validator fails | `DEPENDENCY_EVIDENCE_INVALID`; no isolated/live release verdict |
| candidate tree changes after live testing, E changes outside evidence paths, or I changes outside the release index | `CANDIDATE_STALE`; cut a new candidate and rerun every C5 gate |
| same-name marketplace, source/config disagreement, stale cache, or installed payload cannot be bound to candidate | `PROVENANCE_MISMATCH`; no install/upgrade/profile enablement |
| skill locator, bootstrap root, hook command root, profile root, or installed root disagree | `INSTALL_ROOT_MISMATCH`; no source-tree fallback or alternate-root search |
| hook missing, untrusted, trusted for another hash/root, matcher ambiguous, or deny/allow result missing | `HOOK_TRUST_MISMATCH`; keep lights-out disabled |
| any required Codex live scenario fails, is skipped, is synthetic where live is required, or has unknown cleanup | `CODEX_LIVE_GATE_FAILED`; release blocked |
| any Claude smoke or existing regression fails | `CLAUDE_REGRESSION`; release blocked; no runtime-specific skill copy |
| three version-bearing values differ, are not `0.17.0`, or marketplace topology/source drifts | `METADATA_DRIFT`; release blocked |
| guide command/status/version/link disagrees with scripts/metadata/evidence, or evidence index/hash is stale | `DOCS_EVIDENCE_DRIFT`; release blocked |
| secret scanner finds a value or cannot classify/redact an artifact safely | `SECRET_LEAK`; stop, revoke/rotate as needed, purge unsafe artifact, regenerate evidence |
| external mutation acceptance or cleanup is unknown | unresolved/failed gate; preserve evidence and use the owning C4 recovery path |
| release rollback cannot prove task quiescence, prior provenance, register continuity, or worker no-write state | `ROLLBACK_INCOMPLETE`; tasks stay disabled and affected work remains fenced |
| any attempt to merge/auto-merge/publish around human Gate 2 | deny and record a release blocker |

No condition may be converted to a warning, skipped check, manual assertion, reduced support statement, or stale evidence waiver.

## File Surfaces

### New files

| File | C5 responsibility |
| --- | --- |
| `scripts/validate-codex-compatibility.sh` | final deterministic/evidence/release verdict and composition of owning validators |
| `scripts/validate-codex-install.sh` | isolated temporary Codex marketplace/install/cache/discovery harness |
| `dodi-dev/scripts/tests/test-codex-release-validation.sh` | negative fixtures for provenance, root/trust, metadata/docs/evidence drift, redaction, and stale candidate behavior |
| `dodi-dev/scripts/tests/fixtures/codex-release/` | deterministic C5 fixtures and redaction canaries |
| `docs/release/0.17.0-evidence/` | final candidate-bound redacted install/Codex/Claude/cleanup evidence, outside installed plugin payload |
| `docs/guides/codex-install-upgrade.md` | supported operator install, upgrade, setup, verification, rollback, and cleanup guide |
| `docs/release/0.17.0-release-evidence.md` | human release evidence index and Gate 2 signoff header |

### Modified files

| Surface | C5 edit |
| --- | --- |
| `scripts/validate-plugin-metadata.sh` | require `0.17.0`, both plugin envelopes, and both canonical marketplace sources without inventing a Codex marketplace version |
| `scripts/validate-phase-skills.sh` | register C5 validators/tests/docs/evidence surfaces while preserving all C1-C4 checks |
| `scripts/validate-runtime-contracts.sh` | remove C5-absence/`0.16.0` fences and expose existing contract evidence to the final composer; no schema/mechanics duplication |
| Landed version-bound valid fixtures under `dodi-dev/scripts/tests/fixtures/runtime-contracts/` | bind candidate-valid fixtures to installed `0.17.0` metadata where owning validators require equality |
| `dodi-dev/.claude-plugin/plugin.json` | version `0.17.0` only |
| `dodi-dev/.codex-plugin/plugin.json` | version `0.17.0` only |
| `.claude-plugin/marketplace.json` | version `0.17.0`, source unchanged |

Exact landed fixture paths may differ from the pre-implementation plan. The C5 plan must reconcile the real C1-C4 tree before naming a narrower modified-file list; it may not manufacture a planned-but-absent dependency.

### Explicitly unchanged

- C1 schema fields, path derivation, generation/hash semantics, root bootstrap behavior, register authority, and adapter interfaces.
- C2 model/reasoning pairs, tier assignments, proof fields, capacity signatures/policy routing, and model-pin enforcement semantics.
- C3 native lifecycle operations, manifest/result/quarantine states, ordering, takeover selection, reaping, and Claude transcript behavior.
- C4 setup confirmations, profile/health writer, auth bridge, Linear register operations, C3 quiescence scope, scheduler/GitHub/Gate 2/Slack/marketplace adapters, and rollback engine.
- Skill workflow semantics, lane playbooks, review prompts, labels, claims, Fable policy, retry ceilings, and human Gate 2.
- Canonical marketplace source `./dodi-dev` and the single physical `dodi-dev/skills/` tree.
- `.agents/plugins/marketplace.json` content unless validation exposes a separately approved metadata defect; C5 verifies it remains versionless and points to `./dodi-dev`, but does not add a version property or edit it by default.

## Validation Strategy

### Deterministic CI

Deterministic fixtures cover clean and stale dependency ledgers; candidate/evidence-only ancestry; marketplace duplicates and symlink/canonical-root collisions; source/cache/root/hook hash mismatches; missing/extra/duplicate/disabled skills; hook trust for wrong hashes; stale metadata; a versionless Codex marketplace; guide command/status/link drift; missing evidence and hash tampering; live-vs-synthetic scenario classification; unknown cleanup; secret canaries; absolute-home-path leakage; and rollback-incomplete outcomes.

Tests use temporary homes and stubbed install/runtime observations where no real runtime is required. They must prove each fail-closed matrix row and never touch the operator's actual marketplace, profile, tasks, repositories, register, or Slack channel.

### Required live harnesses

- Supported current Codex Desktop/plugin runtime with marketplace/plugin, app-server skill/hook discovery, native worker/model attestation, and harness-native task support.
- An isolated local candidate checkout and fresh home/config/cache roots.
- Explicitly confirmed disposable Linear register scope, equivalent protected GitHub repository/branch, dedicated restricted scheduled actor, low-risk Slack channel, marketplace configuration, and task probes.
- A supported Claude Code runtime and unrelated temporary target repository for the non-regression gate.
- C1-C4 test dependencies, including the repository development requirements environment where required.

Missing harness capability is a blocker, not a skip. External mutations use C4's proposal-bound confirmations and recovery/cleanup contracts.

### Release commands

The implementation plan may refine setup commands to the landed interfaces, but the release contract culminates in:

```bash
set -euo pipefail
scripts/validate-codex-compatibility.sh
scripts/validate-codex-compatibility.sh --require-isolated-install
scripts/validate-codex-compatibility.sh --require-live-release
scripts/validate-codex-compatibility.sh --release
```

The first command is CI-safe. The latter modes validate already captured candidate-bound evidence or execute only explicitly selected local/disposable harness actions; `--release` itself is read-only and never performs external mutations.

## Acceptance Criteria

1. Exact landed DOD-811 through DOD-814 implementation commits are ancestors of the immutable candidate, and every required deterministic/live dependency artifact parses, hash-verifies, and passes its owning validator.
2. A fresh isolated Codex environment installs `dodi-dev 0.17.0` from the candidate marketplace into a cache outside the source checkout, with no inherited marketplace/profile/trust/task state.
3. Installed payload, plugin metadata, policy, schemas, scripts, adapters, and setup surfaces match the candidate; only documented installer-owned files may differ.
4. Installed app-server discovery returns exactly the canonical released skill set and both expected hooks, with no errors, duplicates, missing/disabled skill, mirror tree, or repository-only runtime dependency.
5. C1 bootstrap resolves one installed root from an installed skill locator; source/cache/mixed/traversal/missing/mismatched roots fail closed and no ordinary skill command depends on an ambient plugin-root variable.
6. Exact installed hook hashes/roots are trusted and the complete model-pin and Gate 2 matrices live-fire; discovery or trust for another root/hash never passes.
7. The complete current-runtime Codex matrix passes from the installed candidate, including tier/context attestation, lifecycle/recovery/quarantine, profile/register/state, GitHub/Gate 2, scheduler/wake, Slack, marketplace, and cleanup requirements.
8. Existing C2-C4 implementation live evidence remains present and valid, but no prior fixture or implementation run substitutes for C5's candidate-bound live repetition.
9. Focused Claude Code non-regression passes from an unrelated repository with no Codex profile, covering shared root resolution, both hooks, pinned leaf completion, transcript fallback, mixed manifests, reaping, and claim/worktree behavior.
10. `scripts/validate-codex-compatibility.sh` fails every specified dependency, provenance, root, trust, live, Claude, metadata, docs/evidence, secret, candidate-staleness, and rollback negative fixture.
11. The install/upgrade guide is complete, command/status/version checked, and points operators through explicit setup/trust/task confirmations and evidence-preserving rollback without copying C1-C4 mechanics.
12. The C5 evidence bundle is complete, redacted, candidate/runtime/install-root bound, hash-verified, cleanup-complete, and linked by a self-sufficient release evidence header.
13. `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, and `.claude-plugin/marketplace.json` all report `0.17.0`; `.agents/plugins/marketplace.json` remains versionless; both marketplaces resolve the same `./dodi-dev` source.
14. Existing repository validators and every focused shell test pass; no v0.16 workflow, Fable, claim, review, context, or Gate semantic changes are introduced.
15. Final HEAD is the index/signoff commit I, differs from tested candidate C only by approved C5 evidence bundle plus release-index surfaces, and `scripts/validate-codex-compatibility.sh --release` exits `0` from a clean checkout.
16. The release evidence index records rollback readiness and no blocker/unknown; a human retains the sole DOD-810 Gate 2 merge decision.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Source-tree tests mask packaging defects | Fresh homes, real install/cache, installed-locator bootstrap, payload hash comparison, source-root rejection. |
| Prior live evidence is valid but stale for the candidate | Require C1-C4 evidence plus repeat C5 live matrix bound to immutable candidate/runtime/install hashes. |
| C4 adds a skill after the parent's audited count | Derive and freeze expected names from canonical frontmatter; compare exact source and installed sets rather than hard-coding the pre-C4 count. |
| Same-name marketplace installs the wrong cache | Empty-home proof, canonical provenance fingerprints, seeded collision negative test, no silent migration. |
| Trust survives for an older hook hash | Bind trust to installed root and exact hook/script hashes; live-fire both hooks after install. |
| Evidence or index commits change the tested payload | C->E->I identity chain with evidence-only and index-only diff validation; any other change forces a full rerun. |
| Docs or metadata change after testing | Include them in the candidate, hash/link checks, synchronized metadata assertion, release mode from clean checkout. |
| Live evidence leaks credentials or user data | Minimal redacted schemas, temporary raw logs, canary/prefix/high-entropy scans, block-and-rotate response. |
| Claude behavior regresses behind Codex success | Separate required live Claude smoke plus full existing test suite. |
| Rollback discards newer durable obligations or uncertain workers | Invoke C4 rollback and C3 quiescence/quarantine contracts; retain register/manifests/evidence and keep tasks/work fenced on uncertainty. |

## Rollout and Rollback

### Pre-merge rollout

1. Reconcile the landed C1-C4 implementation and record exact dependency commits/evidence hashes.
2. Add C5 deterministic validators/tests and install/upgrade guidance without altering C1-C4 mechanics.
3. Apply the synchronized `0.17.0` metadata/fixture sweep and cut the immutable release candidate.
4. Run deterministic validation, isolated install, complete live Codex matrix, Claude non-regression, redaction, docs drift, and cleanup.
5. Commit only the redacted evidence bundle as E, then only the release index as I, and run `--release` from a clean checkout.
6. Complete normal child integration and DOD-810 final review gates. Any non-evidence fix cuts a new candidate and invalidates prior C5 evidence.
7. Present the DOD-810 epic PR for human Gate 2. No automation merges it.

### Post-merge rollout

After human merge, verify that the canonical remote `main` marketplace resolves the merged candidate/evidence lineage and perform one fresh remote-path install smoke before enabling real-user Codex automation. Run `setup-dodi-dev inspect`, resolve any stale marketplace through explicit migration, verify real profile/hook/actor/task/Slack prerequisites, and require separate confirmation before production task enablement.

### Rollback

Before merge, rollback means withdrawing the candidate and restoring metadata to the last known-good release in a reviewed replacement candidate; stale C5 evidence is retained as failed evidence or regenerated, never relabeled.

After merge/install, disable every affected managed task first, await authoritative terminal state, and require C3 quiescence or durable quarantine. Use C4's verified marketplace/profile/task rollback to restore the recorded prior known-good provenance while rebuilding health from the current Linear register; never restore snapshot obligations, delete manifests/results/quarantine, or place a successor beside an uncertain writer.

If exact prior provenance, task cleanup, register continuity, hook trust, or no-write state cannot be proved, return `ROLLBACK_INCOMPLETE`, keep Codex tasks disabled, retain all evidence, and fence affected work. Claude/manual operation may continue only if its independent v0.16 prerequisites and non-regression smoke remain valid. A published `0.17.0` artifact is not silently overwritten; corrections use the repository's next reviewed release version.

## Blocking Questions

None for specification. The exact landed DOD-811 through DOD-814 implementation commits, supported runtime versions, native observation shapes, and disposable scope identifiers are release-time evidence. If they are absent, incompatible, ambiguous, or unsafe, DOD-815 is blocked by design rather than permitted to invent a compatibility path.
