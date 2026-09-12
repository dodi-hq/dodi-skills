# Spec-to-Planner Routing

## TL;DR

The existing successful spec reviewer selects the capability needed to turn that approved spec into a plan. This selects the plan writer and its revisions, not the spec reviewer, plan reviewer, delivery workers, or whole session.

## Key Points

- Classify remaining decomposition work, not spec length, file count, terminology, or epic tier.
- Standard handles familiar sequencing with settled boundaries; Capable handles difficult sequencing and invariants.
- Frontier is an explicitly justified exception, with the existing deferred plan-writing availability policy.
- Unresolved intent, architecture, scope, or shared contracts are spec defects, not reasons to buy a stronger planner.
- Preserve the typed result with the existing spec-ready evidence. No extra assessment call or gate.
- Reuse only while the approved spec remains valid; legacy absence explicitly retains the previous writer policy.

## Successful spec-review output

At the end of the existing clean spec review, return `planner_tier: standard|capable|frontier` and a concise `reason` (at most 2000 characters), plus the reviewed spec path and SHA256 of its raw bytes. An Issues Found result never authorizes planning. The closing clean reviewer owns the classification; the dispatcher preserves it, attaching the durable review locator as `review_ref` without changing its judgment.

| Planner tier | Remaining work after spec approval | Writer pin on Claude Code | Declared effort / policy |
| --- | --- | --- | --- |
| `standard` | Clear, familiar decomposition with settled boundaries | `model: sonnet` | session-default / none |
| `capable` | Tricky dependencies, migration sequencing, recovery, or cross-component invariant preservation | `model: opus` | high / none |
| `frontier` | Explicit exception: unusually difficult decomposition still warrants Frontier; name the difficulty | `model: fable` | xhigh / deferred |

Apply the existing runtime-native mappings in `epic-orchestrator/execution-model.md` § 2; these aliases are not native Codex/Grok model names. Pin **every** delegated writer, including fresh revision workers, from this result before dispatch. Frontier exceptions use the existing bounded local retries, attributed Capable substitution and `FABLE_MAKEUP` consequence-surface obligation; this applies even on a standard Florist epic. Keep the selected tier in the record and report the effective substituted executor separately. A Standard/Capable capacity failure is an operational blocker, not permission to improvise another tier.

The spec drafter/reviewer policy is unchanged. Plan-review rounds retain their existing epic/mode tier and soft/final-deferred policies. The plan reviewer independently classifies **delivery-tier** Standard/Capable after decomposition; never copy planner-tier into that result. Hard Frontier child correctness/coherence is unchanged. Plans still contain no implementation code or pseudocode.

## Record and lifetime

Persist this JSON with the existing successful spec-review/spec-ready evidence (the mature lane's `needs-plan` transition, or the interactive review artifact), outside the spec itself:

```json
{
  "schema": 1,
  "spec_path": "docs/specs/EXAMPLE-contract.md",
  "spec_sha256": "<64 lowercase hex characters: SHA256 of raw spec bytes>",
  "planner_tier": "standard",
  "reason": "Familiar ordered decomposition; interfaces and failure behavior are settled.",
  "source": "spec-review",
  "review_ref": "<durable successful spec-review locator>"
}
```

Run from the repository root before first writing or any revision/restart:

`python3 "${CLAUDE_PLUGIN_ROOT}/scripts/planner-routing.py" check <record.json> <spec-path> --mode <manual|autonomous> [--epic-tier <standard|capable>]`

The helper checks shape, exact repository-relative spec path and current content hash, then returns the selected tier, Claude alias and declared effort/policy. It does not establish review truth or human signoff: also read the existing approval/delegation and any later invalidation. Plan-only commits do not change spec identity. Any spec edit, revoked approval, demotion, or newly conflicting canon invalidates the handoff and returns to the existing spec-review/specification path before planning. Do not edit the spec from the plan lane. Revisions reuse the choice only while the same approved spec remains valid; a difficult plan revision alone does not authorize changing it. Carry the record/locator through continuation evidence; no new checkpoint or state is introduced.

If several unsuperseded records claim the same approved spec, compare them (`check ... --also <other-record.json>`); conflicting classifications or evidence are not resolved by choosing the cheaper, stronger, or latest-looking record. Establish the authoritative successful review or stop for clarification. A later successful existing spec-review round may explicitly supersede the earlier record. A malformed, missing-file, stale, or conflicting record is not legacy absence.

### Legacy absence only

For an already approved legacy spec with **no** classification in its authoritative evidence, retain the former writer policy: manual/resident-driver **Frontier**, Florist `capable` epic **Frontier**, Florist `standard`/unset epic **Capable**. Frontier retains deferred availability. Record `source: legacy-policy`, the approval locator and an explicit absence/fallback reason; never label this a reviewer classification. Generate the record with `planner-routing.py legacy <spec-path> --review-ref <approval-locator> --mode <manual|autonomous> [--epic-tier <standard|capable>]`, preserve it, then check it. This compatibility path adds no classifier call and never silently selects Standard. New successful spec reviews must provide the classification; missing output is an incomplete existing review, not permission to invoke the legacy path. Invalid/stale evidence uses the existing spec-review path or blocks, never fallback.

### Interactive and Florist transport

Interactive `write-plan` still drafts/fixes in the main loop. Read and report the recommended tier, but do not claim prose changed a live model or effort: the operator controls that choice. Preserve the actual session choice separately; delegated writers always obey the classification. The manual mature-session Frontier self-check remains unchanged because it also hosts spec judgment.

Before either Florist contract lane works, run `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/planner-routing.py" require-kernel`. It requires `FLORIST_PLANNER_ROUTING_CONTRACT=spec-review-planner-v1`; failure closes with `blocked reason=worker-blocked`. This is a compatibility signal, not an attestation that the kernel enforces its promise.

Florist `contract-drafting` ends after clean spec review. It emits the normal spec artifact **first**, plus `artifact ref=planner-routing:<safe-relative-locator> sha=<pushed-contract-commit>`; the recommended untracked cache is `.dodi/florist-planner-routing.json`. The kernel validates/ingests the separate record into `UnitDoc.plannerRouting` and materializes its authoritative input at `FLORIST_PLANNER_ROUTING_PATH` for `contract-review`, before any plan-writer dispatch. It must not overwrite the choice with epic-tier/session defaults or store it in the child-review approval schema. No new digest tokens or FSM edge are needed. Preserve it across retries/plan revisions; invalidate on contract demotion/change. Genuine accepted legacy contracts get an explicit kernel-materialized legacy record per the fallback above. Missing transport/env/file is `blocked reason=worker-blocked`, not proof of legacy absence; stale/conflicting classification returns `findings` with thread evidence to the existing spec lane, and malformed/unreadable transport blocks. Deployment must include this companion transport before autonomous planning is enabled; a parser accepting the extra artifact is not proof of preservation.
