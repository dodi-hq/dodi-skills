# Effort as a First-Class Axis — DOD-1214 Spec

Epic: DOD-1213 (fable scarcity doctrine). Ticket: DOD-1214. Status: draft for spec review.

## TL;DR

The repo enforces model tier as a first-class axis but writes reasoning effort down in exactly one sentence (`AGENTS.md:36`, the Grok Build row), so "Frontier tier" means three different intelligence levels on the three runtimes. This spec adds effort to the tier contract as a **declared expectation**: a per-tier/per-runtime effort table in § Model Tiers, a `<tier>@<effort>` notation, effort in every worker prompt's tier self-declaration (validator-enforced), and an effort component in the `tier-degraded(...)` marker and `gate-ledger: final=` field. Per canon DR-005, Claude Code's Agent tool has no per-dispatch effort parameter, so on Claude Code effort stays prose — self-declared and attributable, never a mechanical pin — and the doctrine says so out loud. Scope is the ticket's own slices A+B (doctrine + propagation); slice C (frontmatter `effort:` keys, `.claude/agents/*.md`, hook enforcement) is excluded, matching the epic's out-of-scope list.

## Key Points

- **Decision — scope is A+B in one ticket, C excluded.** The epic carries child 1 as one ticket "per the operator's request, with the split as a spec question"; the ticket's own fallback says A+B can merge and C must not be included under any splitting; the epic's out-of-scope list independently excludes C's parts (`.claude/agents/*.md`, hook effort logic). No further split recommended.
- **Decision — per-tier declared efforts (Claude Code vocabulary):** Frontier `xhigh`, Capable `high` (the model default) with `Capable@max` the nameable elevated-substitution target, Standard session-default, Fast **no effort axis** (`haiku` is not effort-capable). Grok Build row unchanged; Codex column stays "highest-reasoning configuration" with an explicit no-level-implied note. ⚠ Delegated: the specific level choices are anchored (Grok precedent at `AGENTS.md:36`, DR-003 changes-nothing, operator's `opus (max effort)` ruling recorded in the epic) but not operator-dictated cell by cell.
- **Decision — effort is a declared expectation, not a guarantee.** On Claude Code every dispatch inherits the session effort (DR-005) and even a set level can be silently clamped (enterprise caps) or silently downgraded (unsupported-level fallback). The doctrine therefore says "declared", makes deviation visible via self-declaration and the `tier-degraded` marker, and never writes a pin nothing can enforce — the same posture as tier fit (`AGENTS.md:71-72`).
- **In scope:** `AGENTS.md` §§ Model Tiers / Dispatch Discipline / Fable Availability Policy prose; all 15 worker prompt templates; `scripts/validate-phase-skills.sh` effort check; `review/SKILL.md` § Catch Attribution + § Gate Ledger grammar; five-file version bump.
- **Out of scope:** any `effort:` frontmatter key, `.claude/agents/*.md` files, hook changes (`hook-require-model-pin.sh` stays byte-identical), `${CLAUDE_EFFORT}` branching, any tier-assignment or policy-bucket change, Codex effort research.
- **Boundary with DOD-1215 (sibling):** this ticket only makes `Capable@max` a legal, nameable target; the mature-ticket operator-choice policy row itself is the sibling's work.
- **Risk:** multi-seat templates wrap their tier parenthetical across lines today, so the validator's effort check must be multi-line-tolerant (design below) while the ticket's single-line verification grep still passes on the primary declaration line.
- ⚠ Delegated: `tier-degraded` effort components record each seat's **declared** effort (table values), not a runtime readout — on Claude Code the actual is unobservable from the dispatch site, which is the ticket's own subject matter.
- ⚠ Delegated: version bump target left to implementation per repo convention (recommend next minor, `0.17.0`, for a doctrine-axis addition; recent history has shipped features as patch bumps).

## Problem

Verified in this worktree (branch `epic/dod-1213-fable-scarcity-doctrine`):

- The tier table (`AGENTS.md:26-31`) has no effort dimension. `grep -rn effort` finds the doctrine footprint at `AGENTS.md:36` (Grok row) and `AGENTS.md:70` (Grok clause in the dispatch bullet), plus two unrelated "best-effort" hits (`dodi-dev/scripts/await-worker.sh:57` and a historical plan doc, `docs/plans/2026-07-04-resident-orchestrator-0.14.0.md:1277`) — the doctrine footprint is still exactly one sentence.
- All 15 `dodi-dev/skills/*/*-prompt.md` templates name a tier (validator-enforced at `scripts/validate-phase-skills.sh:60-70`); none names an effort.
- `dodi-dev/scripts/hook-require-model-pin.sh` checks pin presence and tier fit from `tool_input`/`toolInput`; there is no effort field in the Claude Code payload for it to read.
- `dodi-dev/skills/review/SKILL.md:65,73,79`: the substitution marker `tier-degraded(fable→<tier>,<policy>)` and `gate-ledger: ... final=<tier>` are tier-only — an `opus@max` substitution and an `opus@high` one are indistinguishable in every posted finding and ledger line.
- **Re-verified this session against the live harness:** the Claude Code Agent tool schema exposes `description, isolation, model, prompt, run_in_background, subagent_type` — no effort parameter — and the harness documents that a subagent's model and reasoning effort come from its agent-type definition, not the call. This independently corroborates canon DR-005.

Net effect: "Frontier tier" means `fable` at whatever the session effort happens to be on Claude Code, "highest-reasoning configuration" on Codex, and `grok-4.6 @ xhigh` on Grok Build — three intelligence levels behind one name, one of them written down. The sibling ticket's operator ruling ("proceed at opus (max effort)") is unimplementable until "opus at max effort" is nameable in the tier contract.

## Goals

1. Every tier/runtime pair has a written effort value in § Model Tiers, including the explicit not-expressible cells (DR-002, DR-004 posture).
2. A single defined notation, `<tier>@<effort>`, usable by doctrine, markers, and the sibling ticket (`Capable@max`).
3. Every worker prompt self-declares effort alongside tier, validator-enforced, with the same wrong-value-visible rationale as tier self-declaration.
4. Substitutions are effort-attributed: `tier-degraded` and `gate-ledger: final=` carry effort components.
5. The Claude Code limitation (DR-005) is stated in doctrine, not papered over: no per-dispatch effort parameter exists; workers inherit session effort; the self-declaration is the only per-dispatch record.

## Non-Goals

- No `effort:` key in any SKILL.md frontmatter (unverified for plugin-shipped skills; hard-fails the six-field Agent Skills spec packaging; gated on the portability question — see Open Assumptions).
- No `.claude/agents/*.md` agent-type definitions (epic out-of-scope; the only true per-dispatch effort mechanism on Claude Code, and a real architecture change — its own ticket if wanted).
- No effort logic in `hook-require-model-pin.sh` (no payload field to read on Claude Code; Grok `spawn_subagent` key name unverified; an unenforceable check is exactly what § Deterministic Skeleton rejects). The hook stays **byte-identical to main**.
- No `${CLAUDE_EFFORT}` branching in skill bodies (per-runtime divergence inside harness-neutral files).
- No change to tier assignments, Fable Availability Policy gate buckets, `needs-capable-delivery` routing, or the Grok Build mapping (DR-003).
- No Codex effort research beyond keeping "highest-reasoning configuration" honest.
- No mature-ticket policy row (that is the sibling ticket, which consumes this ticket's vocabulary).

## Design

### 1. Effort dimension in § Model Tiers (`AGENTS.md`)

Add a companion table (not a fourth column — the runtime split needs its own axis) immediately after the existing tier table, plus defining prose:

| Tier | Claude Code (declared effort) | Codex | Grok Build |
|------|-------------------------------|-------|------------|
| Frontier | `xhigh` | highest-reasoning configuration (no level implied) | `grok-4.6` @ `xhigh` (unchanged) |
| Capable | `high` (the model default); `max` only at a declared elevated-substitution seat | highest-reasoning configuration (no level implied) | `grok-4.6` @ `xhigh` (unchanged) |
| Standard | session default | default coding model | `grok-4.6` @ session default (unchanged) |
| Fast | **not expressible** — the `haiku` alias does not resolve to an effort-capable model | small fast model | `grok-4.6` @ session default (unchanged) |

Accompanying doctrine sentences (normative content; exact wording at implementation):

- **Vocabulary rule (mirrors `AGENTS.md:34`):** effort levels are Claude Code vocabulary (`low|medium|high|xhigh|max`). A prompt or marker that names a level means that tier's declared effort; each runtime maps it per this table, exactly as model aliases map.
- **Notation, defined once:** `<tier>@<effort>` — tier name or Claude alias, `@`, effort level: `Frontier@xhigh`, `Capable@max`, `fable@xhigh→opus@high` in markers. A bare tier name means that tier at its declared default effort.
- **Harness-neutrality rule for effort:** the tier's model pin is the invariant and is mechanically enforced; the tier's effort is a **declared expectation** — expressed mechanically where the runtime allows it at the dispatch site (Grok `spawn_subagent`) and by self-declaration where it does not (Claude Code Agent dispatches). Effort is never silently assumed: a dispatch that cannot set it says which effort it is declared at.
- **The Claude Code limitation, stated plainly (DR-005):** the Agent tool exposes no per-dispatch effort parameter; a Claude Code worker inherits the session effort, so per-tier effort differentiation within one session is not mechanically expressible — the prompt's self-declaration is the only per-dispatch record. Consistent with § Deterministic Skeleton: an invariant with no code surface stays prose.
- **Declared, never guaranteed:** unsupported levels fall back silently to the highest supported level at or below the request, and enterprise caps clamp silently — a declared effort is an expectation the transcript makes auditable, never a runtime guarantee.
- **Fast tier:** a Fast dispatch declares `no effort axis` instead of a level (see § 3).
- **`Capable@max` is legal and nameable** — the elevated-substitution target the operator ruled for the mature-ticket case (consumed by the sibling ticket's policy row). Automatic `deferred`/`soft` substitutions run Capable at its declared default (`opus@high`) unless a gate's policy row names `Capable@max`. `needs-capable-delivery` implementers stay at Capable's default effort — the label routes tier, not effort (DR-003).
- **Two portability semantics** (one sentence each): the effort scale is calibrated per model, so a level does not survive a tier change without re-evaluation; and changing effort mid-conversation breaks prompt-cache prefixes, so effort varies across workloads, never within one lane's cached conversation.

### 2. § Dispatch Discipline rewrite (`AGENTS.md:70`)

Rewrite the dispatch-pin bullet so effort is stated per runtime rather than as a Grok afterthought: Claude Code pins `model` only (**no effort parameter exists**; the worker runs at the session effort and the prompt self-declares the tier's declared effort); Grok Build pins the slug plus reasoning effort per the effort table; Codex maps per the table. No other content change to the bullet.

### 3. Tier self-declaration extension (`AGENTS.md:71` + all 15 templates)

Extend the self-declaration contract: every worker prompt names its tier **and its declared effort** in the same parenthetical, tier and effort on the same line. Canonical forms:

- Frontier: `(Frontier tier, xhigh effort)`
- Capable: `(Capable tier, high effort)`
- Standard: `(Standard tier, session-default effort)`
- Fast: `(Fast tier, no effort axis)`

Standard and Fast have no legal `<tier>@<effort>` form — "session-default" and "no effort axis" are declared postures, not values in the `low|medium|high|xhigh|max` vocabulary, so `Standard@...`/`Fast@...` never appears in doctrine or a marker.

Multi-seat templates name the effort for each seat, matching the existing tier pattern, e.g. `review/review-prompt.md`: `(Capable tier, high effort per round; Frontier tier, xhigh effort for the final gate round — match this dispatch's pin)`. The four multi-seat templates are `review/review-prompt.md`, `review/child-pr-integration-prompt.md`, `implement/implementer-prompt.md`, `submit-ticket-pr/docs-sync-prompt.md`. Because these parentheticals wrap across lines today, templates are reflowed so each seat's `<tier> tier, <effort> effort` unit sits on one line (this also keeps the ticket's verification grep single-line-satisfiable). `docs-sync-prompt.md`'s second seat is a policy-substitution alternative, not a fixed tier: its canonical form is `(Frontier tier, xhigh effort — hard policy; or the tier and effort this dispatch's fable-policy lookup substitutes, per AGENTS.md § Fable Availability Policy)`.

`submit-epic-pr/epic-integration-reviewer-prompt.md` is also DOD-1217's subject (the dual-tier self-declaration fix for that template). Both tickets edit the same parenthetical; whichever merges second rebases its effort addition onto the other's tier-declaration fix rather than reverting it.

Rationale sentence added beside the existing one at `AGENTS.md:71`: the effort declaration is normative (what this seat is declared to run at per the table), not a runtime readout — it makes a wrong or missing effort visible in the transcript and in review, since nothing mechanical can check it on Claude Code.

All 15 templates: `brainstorm/spec-reviewer-prompt.md`, `mature-ticket/spec-drafter-prompt.md`, `write-plan/plan-writer-prompt.md`, `write-plan/plan-reviewer-prompt.md`, `implement/implementer-prompt.md`, `review/review-prompt.md`, `review/child-pr-integration-prompt.md`, `verify/test-runner-prompt.md`, `submit-ticket-pr/local-ci-runner-prompt.md`, `submit-ticket-pr/docs-sync-prompt.md`, `submit-epic-pr/epic-integration-reviewer-prompt.md`, `epic-orchestrator/state-reader-prompt.md`, `epic-orchestrator/evidence-checker-prompt.md`, `epic-orchestrator/gate1-package-prompt.md`, `epic-orchestrator/coherence-reviewer-prompt.md` (all under `dodi-dev/skills/`).

### 4. Validator check (`scripts/validate-phase-skills.sh`)

Extend the tier self-declaration loop (currently lines 60-70): after the existing tier-presence grep, add an effort-presence check that is tolerant of the wrapped parenthetical, e.g. flatten newlines then match:

```bash
if ! tr '\n' ' ' < "$path" | grep -qE '\((Frontier|Capable|Standard|Fast) tier[^)]{0,200}effort'; then
  echo "worker prompt does not name its effort: ${prompt}" >&2
  exit 1
fi
```

The `{0,200}` bound keeps a stray unclosed parenthesis from matching across the whole file. Failure message names the file, mirroring the tier message. The existing tier check stays as-is.

### 5. Marker and ledger grammar (`review/SKILL.md` § Catch Attribution + § Gate Ledger, `AGENTS.md:62`)

- `tier-degraded` marker gains effort components on both sides: `tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` — e.g. `caught-by: pre-pr/2/opus tier-degraded(fable@xhigh→opus@high,deferred)`. Effort values are the **declared** efforts of each seat (the fable seat's table value; the substitute's table value, or `max` when the substitution seat is a declared `Capable@max` case). The `caught-by: <gate>/<round>/<tier>` core grammar is unchanged.
- `gate-ledger:` `final=` field becomes `final=<tier>@<effort>`, e.g. `gate-ledger: spec-review rounds=3 findings=4/2,1/1,0/1 outcome=clean final=fable@xhigh`; a substitution appends the extended `tier-degraded` marker as today.
- `AGENTS.md:62` (Attribution bullet) is updated to match the review skill's grammar verbatim in shape. Both surfaces change together; grammar is forward-only (historical PM comments keep the old form; `grep tier-degraded(` still matches both).
- `AGENTS.md:63` (Hook interplay) gains one sentence: the hook cannot check effort because Claude Code's dispatch payload carries no effort field — the policy-and-declaration layer is the only effort surface.

### 6. Version bump

Same-change bump in all five metadata files (`.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json`, all `0.16.4` today), tag per `AGENTS.md:16`.

## Integration points

- `AGENTS.md` §§ Model Tiers (`:22-42`), Fable Availability Policy (`:44-63`), Dispatch Discipline (`:70-72`).
- `dodi-dev/skills/review/SKILL.md:60-81` (Catch Attribution, Gate Ledger).
- 15 prompt templates listed in § 3.
- `scripts/validate-phase-skills.sh:60-70`.
- Five version-bearing metadata files.
- **Not touched:** `dodi-dev/scripts/hook-require-model-pin.sh` (byte-identical to main — acceptance-checked), `dodi-dev/scripts/comment-species.sh` (verified: it does not parse `tier-degraded`/`gate-ledger` text, so the grammar change cannot break it; its tests run as regression anyway), all SKILL.md frontmatter.
- **Downstream consumer:** DOD-1215 (mature-ticket policy row) references `Capable@max`; this ticket must land first (registered blocked-by edge).

## Edge cases

1. **Multi-line parentheticals:** the four multi-seat templates wrap; validator uses the flattened check (§ 4) and templates keep each seat's tier+effort on one line so the ticket's single-line verification grep also passes.
2. **Fast tier grep-ability:** `(Fast tier, no effort axis)` contains `effort` after `tier`, satisfying both the validator and criterion 6's grep, while criterion 3's "says what a Fast dispatch declares instead" is met by the doctrine sentence.
3. **Silent degradation:** unsupported-level fallback and enterprise clamps mean the declared effort can differ from actual with no signal; doctrine wording is "declared", never "running at" (§ 1).
4. **Grok reads a Claude level:** a harness-neutral prompt saying `xhigh effort` on Grok is correct by the vocabulary rule — the runtime maps per the effort table, same as model aliases; Capable's declared `high` (Claude form) maps to Grok's `xhigh` per the table, and per-model calibration means the level names were never cross-runtime comparable anyway.
5. **Historical markers:** old `tier-degraded(fable→opus,deferred)` strings persist in PM comments; aggregation greps must not assume the new arity. No script parses the marker today (verified), so this is a doc note, not a migration.
6. **Criterion-4 notation sweep:** `grep -rn '@\(low\|medium\|high\|xhigh\|max\)' AGENTS.md dodi-dev/skills` must show only the defined `<tier>@<effort>` form — implementation keeps all examples in that shape.

## Testing contract

Matches the ticket's contract; repo layout confirmed (no CI; all checks local standalone bash).

- **Unit: not-required.** Doctrine prose plus one validator predicate; no markdown unit harness exists and inventing one is out of scope.
- **Integration: required, existing harness.** `bash scripts/validate-phase-skills.sh` exits 0 printing `phase skills ok`; negative case run by hand and recorded in the PR (strip effort text from one template → non-zero exit naming the file → restore). `bash scripts/validate-plugin-metadata.sh` exits 0 after the version bump.
- **Regression:** `bash dodi-dev/scripts/tests/test-hooks-payload.sh` (proves criterion 11 — no effort leak into the hook); `test-comment-species.sh` and `test-driver-claim.sh` (marker grammar touches comment text); running all six scripts in `dodi-dev/scripts/tests/` is cheap.
- **E2E: not-applicable.** Whether a dispatch actually runs at the declared effort is unobservable from the dispatch site on Claude Code (DR-005); do not write a test asserting it. The honest coverage story: the validator enforces declaration shape, human review enforces content, and the runtime gap is the ticket's subject matter, not an oversight.

## Acceptance criteria

The ticket's 14 criteria are adopted as written, with two refinements:

- **Criterion 6/7 (self-declarations):** satisfied via the canonical forms in § 3; Fast templates use `no effort axis` as their effort text; multi-seat templates reflowed so each seat's tier+effort is single-line.
- **Criterion 8 (validator):** the new check is the multi-line-tolerant form in § 4; the negative case is exercised exactly as the ticket specifies.

All others (effort table completeness; DR-005 stated; Fast-tier rule; notation defined once; harness-neutrality rule; marker + ledger grammar in both files; `Capable@max` nameable; hook byte-identical; no `effort:` frontmatter; five-file version parity; harness-neutral prose per `AGENTS.md:14`) map one-to-one to §§ 1-6.

## Open assumptions and delegated decisions

⚠ **Per-tier effort table (§ 1)** — delegated, anchored: Frontier `xhigh` extends the repo's only written effort contract (Grok row, `AGENTS.md:36`) cross-runtime and avoids `max`'s footguns (not persistable in settings, silent clamping, Opus-5 `thinking: disabled` 400 at `xhigh`/`max`); Capable `high` writes down current behavior (`high` ≡ omitting the parameter — DR-003 closes gaps, changes nothing); `Capable@max` reserved for declared substitution seats per the operator ruling recorded in the epic; `needs-capable-delivery` gets no effort escalation (DR-003 + epic out-of-scope). Grok row unchanged.

⚠ **Split position** — ship as one ticket = slices A+B, C excluded; follows the operator's carried-as-one request, the ticket's own A+B-may-merge fallback, and the epic's child-1 description which scopes exactly A+B.

⚠ **Marker records declared effort, not measured** — the only honest option on Claude Code; stated in § 5.

⚠ **Version bump target** — implementer picks per repo convention; `0.17.0` recommended.

**Recorded for follow-up, none blocking this ticket (all belong to the excluded slice C or its own tickets):** whether SKILL.md `effort:` retargets `context: fork` subagents; whether `effort:` is honored for plugin-shipped subagents (the epic's ⚠ verify-before-implementation item — it travels with the mechanism follow-up, not this doctrine/propagation ticket); minimum Claude Code version for `effort` frontmatter; the Workflow tool's `agent({effort})` options; Codex effort expression; Grok `spawn_subagent`'s effort key name (the one item that could move hook enforcement into scope later); and whether the repo still targets claude.ai/Skills-API packaging at all (it already ships non-spec `model:` frontmatter on 18 of 20 skills — either portability was abandoned, making `effort:` frontmatter free for the mechanism ticket, or `model:` is an existing bug worth its own ticket).
