## TL;DR

Astra on Codex and Fable on Claude Code satisfy the same existing Frontier tier, including every hard gate and every outstanding Frontier make-up obligation. Update active workflow doctrine, execution evidence, and the associated guards without changing gate assignments, lower-tier routing, Grok's mapping, or durable protocol tokens. Selection stays inside the executing runtime; this change does not move a task between runtimes.

## Key Points

- Frontier means Fable on Claude Code, Astra at the highest available reasoning configuration on Codex, and the existing Grok mapping. Astra is a full Frontier executor, with no downgrade marker or new make-up debt solely because it is Astra.
- Rename active policy prose to **Frontier Availability Policy**. The existing hard, deferred, soft, and operator-choice rules retain their gate assignments and consequences.
- Preserve `FABLE_MAKEUP`, `FLORIST_FABLE_POLICY`, and `fable-unavailable` exactly as compatibility tokens; document that each refers to Frontier availability or obligations across runtimes.
- Existing make-up obligations can be discharged by a qualified Astra round over the original required scope. The existing keyed consumption, current-head, and clean-review requirements continue to apply.
- Preserve canonical `fable` tier markers and historical evidence; add a small per-round executor record so a new review identifies its runtime, native dispatch model, and requested effort without pretending a requested configuration is an observed runtime guarantee.
- Keep Claude-native `model: fable` frontmatter/examples valid. Codex translates the Frontier seat to its native Astra dispatch; no Claude alias named `astra`, copied skill tree, or versioned model ID in shipped doctrine is introduced.
- Preserve standard-epic routing, delivery-tier routing, fresh reviewers, and existing model-diversity qualifications. Guards and validator tests cover the new mapping and the retained protocol boundaries.
- ⚠ Release version is selected from current metadata and local/remote tags at implementation time. Main is `0.21.1`, while the observed installed cache is `0.21.2`; do not reuse that cache version without resolving its provenance.

## Status and authority

**DRAFT_READY.** The operator approved the design summarized above and authorized continuing through ticket creation, pickup, maturation, implementation, and PR. This artifact makes that approved direction concrete for specification and plan review; it grants no new release or merge authority beyond the existing workflow.

Repository baseline inspected: main commit `e8773cc`, release `0.21.1`. On 2026-09-07, both local tags and `git ls-remote --tags origin 'v0.21.*'` exposed `v0.21.0` and `v0.21.1`, with no remote `v0.21.2`. An installed-cache directory named `0.21.2` was supplied in the session context. These observations are release inputs, not a reservation of any next version.

## Problem

The tier table already treats Claude model aliases as portable vocabulary, but Frontier's operational doctrine repeatedly equates the tier with Fable: hard-gate availability, capacity parks, make-up collection, manual-session checks, and review attribution all use that provider name. Codex has a native Astra executor that the approved design accepts as Frontier. A session following the current wording can incorrectly block a hard gate, add a degradation marker, leave a valid make-up unconsumed, or report its review as if Claude executed it.

The guard has a related mechanical gap: `hook-require-model-pin.sh` recognizes Claude aliases for its tier-fit check and treats unknown slugs as presence-only. A recognized Astra pin must receive the same above-Standard mechanical-work check as a recognized Fable pin when that payload reaches this guard. This does not imply the Claude/Grok hook is installed into Codex automatically.

## Goals and non-goals

The change establishes provider-independent Frontier eligibility, an unambiguous runtime-local selection rule, forward-compatible evidence, and regression protection for the actual script surfaces.

It does not add a tier, alter any gate's hard/deferred/soft/operator-choice bucket, change review counts or aims, loosen clean/current-head evidence, change make-up scopes, reclassify delivery tickets, redesign Florist, add runtime handoff, install another runtime, migrate historical comments, or edit historical specs/plans. It does not blanket-seat lower-tier work on Astra or claim that equivalent tier eligibility makes every pair of native models identical in behavior. It creates no mirrored skills or standalone review-evidence service.

## Design

### 1. Separate tier eligibility from runtime-native selection

`AGENTS.md` remains the repository's tier doctrine. Its Frontier row and Codex mapping must say explicitly that Astra and Fable are interchangeable **within Frontier**, including all policy-gated work. The shipping execution contract, `dodi-dev/skills/epic-orchestrator/execution-model.md` § 2, must carry the runtime interpretation needed by installed skills; installed behavior must not require reading this spec or another repository-only artifact.

| Executing runtime | Frontier selection | Effort interpretation |
| --- | --- | --- |
| Claude Code | `fable`, using the existing native alias | Declared `xhigh`; the existing inheritance and non-guarantee caveats remain |
| Codex | The runtime's native Astra model option | Explicitly request the highest reasoning configuration that the selected option supports; resolve its native spelling from the available model/tool metadata |
| Grok Build | Existing `grok-4.6` mapping | Existing `xhigh` mapping; unchanged |

The approved equivalence concerns Astra and Fable eligibility, not a new spelling that every harness resolves. Canonical SKILL frontmatter retains its existing Claude aliases; prose and worker templates describe the tier and Claude-native form. On Codex, the executing session interprets a Frontier declaration or `model: fable` example as an instruction to select Astra and pin the native model and highest supported reasoning effort at dispatch. It must not send `fable` to a Codex tool that only accepts native model names, send `astra` to Claude, or claim that a Claude frontmatter alias mechanically switches a Codex session.

A manual session self-check uses its actual visible runtime/model configuration. An already running qualified Astra session satisfies the Frontier expectation; loading a skill does not itself change that session's model. If the configuration is not Frontier, apply the existing operator-choice rule. No capability is inferred from a model's name alone beyond the explicit runtime mapping.

The current session's tool metadata exposes Astra with `ultra` as its highest reasoning option. This is execution-time evidence, not a permanent doctrine pin: shipped prose uses the stable Astra name plus “highest supported reasoning,” and concrete native IDs/effort strings belong in dispatch arguments, tests where necessary, and recorded evidence. Existing Grok literals remain the already approved mapping rather than being generalized by this ticket.

All non-Frontier seats retain their existing routing. In particular, `FLORIST_EPIC_TIER=standard` still resolves its spec/plan and review gates to the existing Capable seats, with no Frontier scarcity event or substitution record. `needs-capable-delivery`/`FLORIST_DELIVERY_TIER` continues to route implementers and fix workers only. Preserve fresh-context review and the existing diversity objective, Grok mapping qualification, and lower-tier-substitution qualification. Canonical tier names alone are not proof that two dispatches used different native models; executor evidence must make any native identity overlap visible without silently reclassifying either seat.

### 2. Frontier Availability Policy

Rename the active heading and active references from **Fable Availability Policy** to **Frontier Availability Policy**. Use “Frontier seat,” “Frontier availability,” and “Frontier make-up” in provider-independent instructions; retain Fable where it actually denotes the Claude executor, a Claude-native example, or a compatibility token.

Resolve the gate's existing tier and policy first, then its native executor inside the current runtime. Selecting Astra for a Frontier seat is ordinary execution, not a fallback to another tier. Claude Fable capacity being unavailable is irrelevant to an otherwise available Codex Astra dispatch. Likewise, Astra existing in another runtime does not automatically rescue a failed Claude dispatch: the workflow does not hand off sessions or probe remote runtimes.

For a Frontier dispatch, the existing capacity/tier-unavailable detection, two spaced retries, and post-retry policy action apply to the selected runtime-native Frontier executor. Other dispatch failures keep their existing error handling and are not relabeled capacity failures.

| Existing policy | Required behavior after this change |
| --- | --- |
| `hard` | A successful qualified Frontier executor satisfies the gate. If that executor is unavailable after bounded retries, retain the existing driver park, manual stop, or Florist decline for the invocation mode. No lower-tier substitution. |
| `deferred` | When Frontier is unavailable, substitute the existing Capable seat, attribute the degradation, and queue the same durable make-up obligation. |
| `soft` | When Frontier is unavailable, substitute the existing Capable seat and attribute it, with no make-up. |
| `operator-choice` | Manual sessions alone self-check their Frontier configuration. An unavailable/unqualified Frontier session stops for the existing wait-or-`Capable@max` decision; qualified Astra needs no new choice. Autonomous mode retains its existing decline behavior. |

No gate moves buckets. Preserve the capable-delivery child-PR final and post-fix hard seat, the standard-delivery focused re-round's plain Capable seat, and the verify-stage focused re-review's plain Capable seat. Preserve the separate standard-epic routing tables that never create a Frontier seat in the first place.

### 3. Durable compatibility and existing make-up obligations

Keep these spellings and their serialized forms byte-compatible:

| Durable token | Clarified meaning |
| --- | --- |
| `Kind: FABLE_MAKEUP` | A deferred **Frontier** make-up obligation, regardless of the native executor that created or later consumes it |
| `FLORIST_FABLE_POLICY` | The seat's **Frontier** availability bucket, including existing `none` for a seat outside Frontier |
| `declined reason=fable-unavailable` | The required runtime-local **Frontier** executor is unavailable and the seat's policy does not permit proceeding |

Do not introduce replacement tokens, dual-write old/new tokens, rewrite historical entries, change Florist digest grammar, or rename `fable_policy=` in the existing mode-helper output. Comments and help text may explain the retained names. `CAPACITY_PARK`, existing park keys, the capacity-scan species partition, and retry/wake rules stay unchanged; provider-independent park prose records the native blocked dispatch so a successor knows what actually failed.

`submit-epic-pr` consumes old and new `FABLE_MAKEUP` entries together through its existing batched round. A qualified Astra reviewer may consume any outstanding obligation, including one originally created by an Opus substitute for a Fable dispatch. It must review the original obligation's required scope: review gates retain their original review scope, and plan writing/review debt retains the affected merged-diff consequence surface. Keyed references, clean/current-head requirements, fix-induced restarts, and zero-open-obligations before PR remain unchanged. Record which obligations the successful round consumed; Astra's identity creates neither extra debt nor an extra Fable-only confirmation.

### 4. Review evidence: canonical tiers plus native executor

Keep the existing `caught-by`, `gate-ledger`, `rework-origin`, and `session-tier` grammars. Their `fable` component is the canonical **Frontier tier alias**, not a claim that Claude ran the round. Thus an Astra Frontier review uses `caught-by: child-pr/2/fable` and a clean gate may close with `final=fable@xhigh`. The `xhigh` there is the portable declared effort vocabulary, not a copy of Codex's native effort string. An Astra Frontier round has no `tier-degraded(...)` marker merely because its executor differs from Claude Fable.

A real lower-tier substitution retains the existing grammar, for example `tier-degraded(fable@xhigh→opus@high,deferred)`. Preserve acceptance of historical two-component degradation markers; do not rewrite old evidence or require a new companion on historical rounds.

Add one forward-only companion record per new reviewer round, including clean rounds, on that round's existing durable evidence surface:

`review-executor: <gate>/<round> runtime=<claude-code|codex|grok-build> model=<native-dispatch-pin> effort=<native-requested-effort|inherited> source=dispatch`

This minimal record identifies the actual execution path selected by the dispatcher without claiming an unavailable runtime attestation. `model` is copied from the actual dispatched request, never inferred from `caught-by`; `effort` is the actual native effort argument, or `inherited` where the runtime exposes no per-dispatch control. Do not substitute the canonical Claude effort when the native request used another spelling. Runtime-reported overrides or model/effort mismatches must be reported alongside the line in the same evidence, and an unqualified fallback must not count as a Frontier success.

The dispatcher owns this record, just as it owns ledger counters and final catch attribution. Reviewer prompts stay focused on their review, and test runners acquire no review fields. Include the line in the next-boundary checkpoint/comment or Seat Record already carrying the round's evidence; no new PM artifact species. If a gate exits unfinished through `RESUMABLE` or a park, preserve its completed rounds' executor records in the continuation brief alongside the running ledger tally, so resumption loses neither provenance nor round identity. For single-shot coherence and epic-integration rounds, use their existing round identities and output surfaces even though they have no lane gate ledger. Interactive reviews use their existing equivalent close-out surface. Unavailable execution evidence is reported as a concern rather than fabricating an observed model; old evidence remains usable under its original contract.

Update the shipped review contract and dispatch contract, plus comment-template evidence slots where applicable. Exact native model IDs in execution evidence are allowed because they record a completed dispatch; stable shipped doctrine and copyable template examples use placeholders or approved aliases.

### 5. Mechanical enforcement

Update `hook-require-model-pin.sh` so a recognized Astra family/model pin is ranked as Frontier for the existing tier-fit check. Retain the explicit-pin requirement, judgment-description exclusions, description-only shape matching, deliberate `tier-justified:` escape, general opt-out, and unknown-slug/Grok presence-only behavior. Recognizing Astra is not permission to treat every unknown slug as Frontier or to alter how Grok's single-model mapping works. Keep the guard's deployment claims accurate: recognizing a payload is testable locally; native Codex hook integration is outside scope.

Update `scripts/validate-phase-skills.sh` comments, diagnostics, and existing wording pins for the renamed policy. Its canonical frontmatter check still recognizes `model: fable`, including quoted/commented forms, because frontmatter retains that alias; do not create a new `model: astra` frontmatter contract. Add focused positive/negative checks for the runtime mapping and no-downgrade/debt-consumption requirements where they provide a concrete regression guard. Preserve the current multi-seat declarations, match-this-dispatch instruction, standard-epic pins, and focused-re-round asymmetry checks. Tests should prove mutations fail, rather than only checking that the current file repeats a string.

`validate-ticket-comment-templates.sh` continues to require the durable old token and validates any added executor placeholder on the relevant evidence templates. Do not make historical comment contents a validation input.

### 6. Integration surface and release

Expected edits, narrowed by the implementation's active-reference inventory:

| Surface | Purpose |
| --- | --- |
| `AGENTS.md` | Frontier mapping, policy heading/semantics, compatibility vocabulary, evidence reference |
| `dodi-dev/skills/epic-orchestrator/execution-model.md` | Shipped runtime-local tier resolution and executor-record dispatch contract |
| `dodi-dev/skills/epic-orchestrator/florist-worker-contract.md` | Frontier-wide semantics of retained env/decline tokens and Seat Record evidence |
| `dodi-dev/skills/mature-ticket/SKILL.md`, `review/SKILL.md`, `submit-epic-pr/SKILL.md` | Manual/self-check, gate attribution, and make-up consumption semantics |
| Active policy consumers under `dodi-dev/skills/` | Rename references and provider-independent wording in drive/reconcile/orchestrator, delivery/mature playbooks, submit/docs-sync, and associated worker prompts where applicable |
| `templates/ticket-comments/decision-register-entry.md`, `spec-ready.md`, `ready-to-implement.md` and relevant existing evidence templates | Compatible obligation descriptions and per-round executor evidence slots |
| `dodi-dev/scripts/hook-require-model-pin.sh`, `scripts/validate-phase-skills.sh`, `scripts/validate-ticket-comment-templates.sh` | Guard recognition, policy/reference pins, template validation |
| `dodi-dev/scripts/tests/test-hooks-payload.sh`, `test-validate-phase-skills.sh` | Behavioral and mutation regressions using existing shell harnesses |
| Five version-bearing metadata files | One consistent release version, selected after collision checks |

The five release files are `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, and `dodi-dev/.grok-plugin/plugin.json`. `.agents/plugins/marketplace.json` remains versionless. All marketplace sources continue to point to the one `./dodi-dev` tree.

Reserve no version in this spec. At implementation/release, read current branch and remote metadata/tags and account for the observed installed `0.21.2` cache; select a fresh version according to repository release policy. When releasing, put the bare chosen version in the version-bump commit message and tag that commit `vX.Y.Z`, pushing the tag under the existing release workflow. A PR can carry the verified version change without claiming a release tag already exists.

Exclude `dodi-dev/worktrees/**` from edits and inventory. Historical `docs/specs/**` and `docs/plans/**` remain byte-identical except for this new spec and the new implementation plan. Active references are judged by semantics: a legitimate Claude alias, historical example, or durable token must not be removed by a blanket text replacement.

## Acceptance criteria

1. A reader of the shipping execution contract can select a native Frontier executor on each runtime, interpret retained Claude frontmatter, and explain why qualified Astra satisfies every hard gate without consulting repository-only docs.
2. On Codex, a successful Astra dispatch at the required reasoning configuration satisfies spec authoring/final spec review, coherence, capable-delivery child-PR final/focused re-round, epic docs sweep, and make-up collection with no downgrade or new debt. No gate's assigned policy changes.
3. Capacity handling depends on the executing runtime's selected Frontier executor. Failure applies the unchanged retry and mode-specific policy; it does not trigger automatic cross-runtime handoff or treat an available executor in another runtime as local capacity.
4. Both legacy and newly created `FABLE_MAKEUP` entries can be consumed by a qualified Astra round over the original scope. No Fable-only confirmation remains; unresolved obligations still block the epic PR.
5. `FABLE_MAKEUP`, `FLORIST_FABLE_POLICY`, `fable-unavailable`, and existing Florist output grammar remain byte-compatible. Active prose documents their Frontier-wide meanings.
6. New review evidence distinguishes native executor/effort from canonical tier/effort; an Astra round remains canonical `fable`, actual lower-tier degradation stays attributed, and all historical marker forms remain readable without back-edits.
7. Standard-epic routing, implementer/fix-worker routing, Grok mapping, fresh-worker rules, focused re-round asymmetry, and existing diversity qualifications remain intact. No new skill frontmatter alias or lower-tier promotion is introduced.
8. The guard rejects mechanical Astra dispatches absent a declared escalation, permits Astra judgment dispatches, and retains Claude, Grok/unknown, unpinned, and escape-hatch behaviors. Validator mutation cases catch removal of the new core semantics and preserve the existing pins.
9. All required checks pass at the reviewed head, historical trees are untouched, and all five version-bearing metadata files agree on a collision-checked release number.

## Testing Contract

### Required test groups

| Group | Required | Scope and minimum assertions |
| --- | --- | --- |
| Unit/behavioral shell | Yes | Pin guard: Astra mechanical work fails; Astra review succeeds; explicit `tier-justified:` permits mechanical escalation; missing model still fails; existing Claude alias ranks and Grok/unknown presence-only behavior remain. Exercise both supported payload envelopes and stable Astra/native Astra-shaped pins without hardcoding versioned IDs into doctrine. |
| Validator mutation | Yes | Baseline passes; removing the Frontier Codex mapping, no-degradation/equivalence requirement, or legacy make-up eligibility makes the appropriate validation fail. Existing effort/seat-registry, canonical fable frontmatter-policy coverage, standard-epic, and focused-re-round regression cases still pass. Use temporary copies, never mutate the working source to test rejection. |
| Integration/contract | Yes | Run all three repository validators plus the existing Florist mode/digest and capacity-park tests. They prove metadata consistency, compatibility tokens, unchanged mode/digest envelopes, and continued exclusion of make-up entries from park classification. |
| E2E against live providers/PM | No | No native provider adapter, Florist kernel, or service-side protocol changes. Paid dispatches, forced exhaustion, or writes to live review history are not required to validate a prose-and-local-guard change. Record a manual contract matrix instead. |

### Commands

Run from the repository root at the reviewed head:

- `bash scripts/validate-plugin-metadata.sh`
- `bash scripts/validate-phase-skills.sh`
- `bash scripts/validate-ticket-comment-templates.sh`
- `bash dodi-dev/scripts/tests/test-hooks-payload.sh`
- `bash dodi-dev/scripts/tests/test-validate-phase-skills.sh`
- `bash dodi-dev/scripts/tests/test-florist-mode.sh`
- `bash dodi-dev/scripts/tests/test-florist-digest.sh`
- `bash dodi-dev/scripts/tests/test-capacity-park-scan.sh`
- `git diff --check`

Use the existing shell/Python harness and its temporary fixtures; no external credentials, live PM mutation, new package dependency, or service setup. Record command exit codes and the reviewed head in verification evidence. If a touched behavior needs a test not present in these named files, add the smallest case to the owning existing harness and update the plan's commands.

### Manual contract matrix

Record compact outcomes in review/PR evidence for: Claude Frontier success; Codex Astra hard-gate success; old make-up consumed by Astra; Codex Frontier unavailable under hard/deferred/soft; qualified versus unqualified manual sessions; Florist standard-epic gates with no Frontier seat; capable-delivery child-PR focused re-round; and unchanged Grok mapping. For each identify seat, native selection, effort interpretation, marker/debt result, and failure/close-out route. Include one new Astra round's canonical marker plus executor-line example and one historical degradation marker to show forward-only compatibility.

The matrix is a review of executable/documented contracts, not a claim that capacity failures were induced on live providers. Inspect the diff for untouched historical docs/worktrees and scan active references to ensure remaining Fable mentions are Claude-specific or deliberate compatibility vocabulary.

## Delegated implementation choices

- ⚠ The exact next release number is deferred until the current branch/remote and `0.21.2` cache provenance are checked. No product decision depends on that number.
- ⚠ The `review-executor` companion uses dispatch provenance as its minimum trustworthy source; an actual provider-reported mismatch is recorded separately. This avoids a schema or runtime adapter while making executor claims auditable.
- ⚠ Place narrowly scoped doctrine pins in the existing validators and test their rejection behavior; avoid a general parser or framework for policy prose.

There are no unresolved product questions within the approved scope. Plan review must keep the change bounded to equivalence, compatibility, evidence, and existing enforcement surfaces.
