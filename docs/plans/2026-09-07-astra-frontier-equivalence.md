## TL;DR

Implement DOD-1369 as one cohesive change making Astra and Fable equal executors of Frontier. Keep runtime-native pins and durable protocol names, add explicit executor evidence, and verify the guard and documentation contracts before opening a PR to main.

## Key Points

- The approved spec is `docs/specs/2026-09-07-astra-frontier-equivalence-design.md`.
- One implementation task keeps policy, evidence, validators, and release metadata consistent in its commit.
- Astra satisfies hard gates and legacy make-up obligations without degradation; actual Capable substitutions retain current consequences.
- Preserve Claude `fable` pins, canonical tier markers, Grok mapping, and all existing routing exceptions.
- Add `review-executor` records to existing review evidence surfaces; no new tracker species or provider integration.
- Regression tests cover guard behavior, validator mutations, and unchanged Florist/capacity protocols.
- Release metadata uses `0.22.0`: open PR #38 reserves `0.21.2`; remote tags inspected on 2026-09-07 stop at `v0.21.1`.
- User approved the design and authorized ticket → pickup → maturation → implementation → PR; no additional product decision is pending.

# Astra / Fable Frontier Equivalence Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Goal:** Every active Frontier gate accepts the executing runtime's qualified Frontier model, including Astra on Codex, while preserving compatibility.

**Architecture:** Tier eligibility stays distinct from native executor selection. `AGENTS.md` defines doctrine, shipped `epic-orchestrator/execution-model.md` carries runtime resolution, and `review/SKILL.md` owns evidence grammar; existing scripts enforce only the concrete contracts they can inspect.

**Tech Stack:** Markdown skill contracts, Bash validators/hooks, embedded Python, JSON metadata, existing shell test harnesses.

**Workspace:** `/Users/may/github/dodi/dodi-skills-DOD-1369`, branch `codex/DOD-1369-astra-frontier`, based on main `e8773cc`.

## Testing Contract

### Required Test Groups

- Unit: `required`
  - Scope: dispatch-pin hook and validator rejection behavior.
  - Reason: recognized Astra pins must not bypass the existing tier-fit rule; new contract pins need negative coverage.
  - Minimum assertions: Astra mechanical description blocked, judgment allowed, justified escalation allowed; both `tool_input` and `toolInput`; missing model blocked; existing Claude/Grok/unknown/opt-out behavior preserved. Remove each new invariant in a temporary fixture and require validator failure; baseline must pass.
- Integration: `required`
  - Scope: all three repo validators, Florist mode/digest, capacity-park species contracts.
  - Reason: retained protocol strings, shipped doctrine, templates, and metadata must remain mutually consistent.
  - Harness: `existing`
  - Minimum assertions: five metadata versions agree; canonical policy pins and template evidence fields pass; existing `FABLE_MAKEUP` remains a make-up species and not a capacity park; Florist env/output/decline grammar remains unchanged.
- E2E: `not-required`
  - Scope: live provider exhaustion, paid cross-runtime dispatches, and production tracker workflows.
  - Reason: no provider adapter, runtime handoff, or external protocol implementation changes.
  - Harness: `not-applicable`
  - Minimum assertions: not applicable; use the documented contract matrix below rather than claiming live execution.

### Critical Flows

- Qualified Codex Astra executes a hard Frontier gate with canonical tier evidence plus native executor provenance and no degradation/debt.
- Astra discharges an old `FABLE_MAKEUP` obligation over its original scope at the required current head.
- Local Frontier capacity failure preserves hard/deferred/soft/operator-choice behavior without probing another runtime.
- Standard-epic seats remain Capable; capable-delivery hard focused final and other Capable focused rounds retain their distinct routing.

### Regression Surface

- Claude frontmatter and native examples, Grok mapping, lower-tier routing, per-seat effort declarations, catch/ledger/rework/session markers, Florist protocol, capacity classification, metadata source paths.

### Commands

- Unit: `bash dodi-dev/scripts/tests/test-hooks-payload.sh`; `bash dodi-dev/scripts/tests/test-validate-phase-skills.sh`; `bash dodi-dev/scripts/tests/test-ticket-comment-templates.sh` (create the latter as specified below).
- Integration: `bash scripts/validate-plugin-metadata.sh`; `bash scripts/validate-phase-skills.sh`; `bash scripts/validate-ticket-comment-templates.sh`; `bash dodi-dev/scripts/tests/test-florist-mode.sh`; `bash dodi-dev/scripts/tests/test-florist-digest.sh`; `bash dodi-dev/scripts/tests/test-capacity-park-scan.sh`.
- E2E: not applicable.
- Broader regression: local-CI runner discovers and runs every remaining `dodi-dev/scripts/tests/test-*.sh` not covered by a group runner; `git diff --check`. Record a separate log and exit code per command, and the tested HEAD SHA plus whether the tree was dirty.

### Harness Requirements

- Existing Bash/Python/Node/git tools and isolated temporary fixtures used by the shell suites; no live credentials or new dependencies.
- Mutation tests must copy fixture inputs into a temporary directory and leave the worktree untouched.

### Non-Required Rationale

- E2E: this change is doctrine plus local enforcement; no service/provider behavior is implemented.

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.
- Per-group and local-CI runners must return commands, exit codes, log paths, and tested head SHA; avoid duplicating suite runs between runners in one verification stage.

## File responsibilities

| Files | Responsibility |
| --- | --- |
| `AGENTS.md` | Repository tier/policy vocabulary and compatibility rules |
| `dodi-dev/skills/epic-orchestrator/execution-model.md` | Installed runtime mapping, dispatch provenance, local capacity handling |
| `dodi-dev/skills/epic-orchestrator/florist-worker-contract.md` | Retained env/decline tokens and Seat Record routing |
| `dodi-dev/skills/review/SKILL.md` | Canonical markers and companion executor grammar |
| `dodi-dev/skills/mature-ticket/SKILL.md`, `submit-epic-pr/SKILL.md` | Session self-check and legacy make-up eligibility |
| Active policy consumers listed in Step 2 | Consistent seat wording and owner-contract references |
| `templates/ticket-comments/{spec-ready,ready-to-implement,lane-checkpoint,child-pr-ready,epic-pr-ready,decision-register-entry,continuation-brief,demotion}.md` | Existing durable surfaces for executor records and retained obligations |
| `dodi-dev/scripts/hook-require-model-pin.sh` | Frontier rank for recognized Astra pins |
| `scripts/validate-phase-skills.sh`, `scripts/validate-ticket-comment-templates.sh` | Concrete mapping/evidence/compatibility contract checks |
| `dodi-dev/scripts/tests/{test-hooks-payload,test-validate-phase-skills,test-ticket-comment-templates}.sh` | Behavioral and mutation tests |
| Five release JSON files listed in Step 5 | Consistent `0.22.0` release metadata |

## Task 1: Implement the complete Frontier equivalence contract

One implementer owns this task sequentially at Capable tier (high declared effort; native Codex highest-reasoning mapping), as assigned by plan review. Every fix worker uses the same delivery tier. Follow the spec's detailed semantics rather than broadly replacing every Fable occurrence.

- [ ] **Step 1: Establish the runtime mapping and policy canon.**

In `AGENTS.md` rename the policy heading and references to `Frontier Availability Policy`, make Astra the Codex Frontier executor at highest supported reasoning, preserve `fable` as the canonical Claude tier alias, and document that native model/effort spelling is resolved from available runtime metadata. Add the same operative rules to shipped `execution-model.md` § 2. Retain Claude-native frontmatter and `model: fable` examples. Runtime-local capacity uses the existing two retries and mode-specific policy. Qualified Astra does not require operator-choice, cannot cause degradation by identity, and may discharge all old make-up obligations. Preserve the standard-epic/Capable and Grok exceptions, and document that canonical tier names do not prove different native executors.

Use these exact normative anchor sentences in the shipping owner contracts so narrow validation has stable semantic inputs:

```text
# execution-model.md
Codex Frontier uses Astra at the highest supported reasoning configuration.
Astra and Fable are equivalent Frontier executors; choosing Astra creates no tier-degraded marker or make-up debt.
# submit-epic-pr/SKILL.md
Astra may discharge existing FABLE_MAKEUP obligations over their original required scope.
```

- [ ] **Step 2: Update active consumers without changing gate assignments.**

Audit and edit provider-independent wording in `dodi-dev/skills/{drive-epic,reconcile-tickets,epic-orchestrator,mature-ticket,review,submit-ticket-pr,submit-epic-pr}/SKILL.md`; `epic-orchestrator/{execution-model,florist-worker-contract,state-transitions,gate1-package-prompt,coherence-reviewer-prompt}.md`; `epic-orchestrator/lanes/{mature-playbook,deliver-playbook}.md`; `mature-ticket/spec-drafter-prompt.md`; `write-plan/{SKILL,plan-writer-prompt,plan-reviewer-prompt}.md`; `brainstorm/{SKILL,spec-reviewer-prompt}.md`; `review/{review-prompt,child-pr-integration-prompt}.md`; `submit-ticket-pr/docs-sync-prompt.md`; `submit-epic-pr/epic-integration-reviewer-prompt.md`. `implement-ticket/SKILL.md` changes only if its active prose needs the new mapping/reference.

Do not rewrite historical examples or canonical aliases. Keep `FABLE_MAKEUP`, `FLORIST_FABLE_POLICY`, `fable-unavailable`, `fable_policy=`, existing digest envelopes, and historical markers byte-compatible. Clarify their Frontier-wide semantics beside definitions. Retain current scope/current-head/clean-review/keyed-consumption requirements in `submit-epic-pr`. Installed instructions reference shipping owner contracts rather than this plan or repository-only spec. Scan remaining active `fable` occurrences and classify them as actual Claude pins, canonical tier aliases, durable protocol, historical examples, or wording still requiring correction.

- [ ] **Step 3: Add forward-only native executor evidence.**

`review/SKILL.md` owns this exact grammar from the spec:

```text
review-executor: <gate>/<round> runtime=<claude-code|codex|grok-build> model=<native-dispatch-pin> effort=<native-requested-effort|inherited> source=dispatch
```

Require one record per new review round, including clean rounds, emitted by the dispatcher on the existing next-boundary evidence surface. Canonical `caught-by`, ledger, rework and session-tier grammar stays unchanged; native pins and requested effort come from the actual request. `inherited` is used only when the runtime exposes no per-dispatch effort control. Known runtime fallback/mismatch is surfaced alongside the line and cannot silently satisfy Frontier. Historical evidence needs no retroactive companion. Preserve completed rounds' executor records in continuation briefs alongside the running ledger tally when an unfinished gate parks or exits RESUMABLE. Add a reference from `execution-model.md` and the Florist Seat Record guidance; do not push dispatcher accounting into reviewer/test-runner prompts. Add companion placeholders to the eight existing comment templates in the file map, with repeats permitted for multiple rounds. Demotion evidence retains executor records beside its escalated gate ledger. Decision-register evidence covers coherence/make-up review records as applicable; do not create a new Kind. Preserve template headings and existing placeholders.

- [ ] **Step 4: Implement and test concrete guards.**

Extend the existing hook rank tuple without altering the description-only classification, judgment exclusion, opt-outs, or unknown/Grok behavior:

```python
for alias, r in (("haiku", 1), ("sonnet", 2), ("opus", 3), ("fable", 4), ("astra", 4)):
```

Update its explanatory message to name Frontier with Fable/Astra while accurately retaining Claude/Grok deployment scope. Add table-driven hook cases for `astra` and native Astra-shaped pins; mechanical descriptions exit 2, review descriptions exit 0, and `tier-justified:` exits 0 in both payload envelopes. Preserve existing regressions.

Update phase-validator policy diagnostics/reference pins for Frontier wording while retaining canonical `model: fable` frontmatter coverage. Add `grep -qF` checks with useful failure messages for the three normative sentences from Step 1 and for the executor grammar owned by review. Existing focused-round/standard-epic invariants remain; update wording pins only when equivalent semantic wording moved.

Extend `test-validate-phase-skills.sh` temporary-copy mutations to remove each new required anchor independently and assert nonzero validation; preserve baseline and old mutations. In `validate-ticket-comment-templates.sh`, call existing `check_contains` for `review-executor:` in each of the eight templates and keep `Kind: FABLE_MAKEUP`. Create `test-ticket-comment-templates.sh` using the existing shell fixture convention: run baseline validator successfully; for each required template copy baseline to a fresh temp fixture, remove its executor line, run the validator and require nonzero; separately remove `Kind: FABLE_MAKEUP` and require failure. Fail with the fixture/case name if a mutation is incorrectly accepted. Clean fixtures using a trap.

- [ ] **Step 5: Bump metadata and verify before committing.**

Set the version to `0.22.0` in `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, and `dodi-dev/.grok-plugin/plugin.json`. Preserve all other metadata and the versionless Codex marketplace. Recheck remote tags before a release tag; if `v0.22.0` has appeared meanwhile report the collision rather than overwrite it.

Run all Unit and Integration command lines above plus `git diff --check`; expected exit 0 for each suite and all intentional mutation cases rejected. Record logs, commit parent/tree state, and test outcomes. Self-review the spec's acceptance criteria, shipped ownership, preserved protocol tokens, and remaining Fable references. Ensure old `docs/specs/**`, `docs/plans/**`, and every other worktree are untouched. Stage only this ticket's changes and commit them with:

```bash
git commit -m "0.22.0: make Astra and Fable equivalent Frontier choices (DOD-1369)"
```

Return the commit SHA, changed files, test commands/exit codes/log paths, concerns, and a compact manual contract matrix (spec Testing Contract) in an evidence file under `/tmp/dod-1369/` for the dispatcher. Do not push, tag, open a PR, or change tracker state from the worker.

## Review and delivery

After implementation, the dispatcher runs the required fresh Capable review/fix loop and fresh Frontier final; no clean claim until zero issues. Run final per-group/local-CI verification at the resulting HEAD and record the complete contract matrix, accurately labeled as contract inspection rather than live provider tests. Push the requested branch and open the authorized standalone PR to main with the ticket/spec/plan links, review evidence and test summary; do not merge. Apply repository release-tag policy to the verified version-bump commit without claiming the PR is merged. Keep the ticket In Progress/In Review until merge rather than marking it Done on PR creation.
