# Effort as a First-Class Axis (DOD-1214) Implementation Plan

> **For agentic workers:** Use dodi-dev:implement to execute this plan.

**Goal:** Add reasoning effort to the model-tier contract as a declared expectation — a per-tier/per-runtime effort table, the `<tier>@<effort>` notation, effort in every worker prompt's self-declaration (validator-enforced), and effort components in the `tier-degraded(...)` marker and `gate-ledger: final=` field — per spec `docs/specs/2026-08-28-effort-first-class-axis-design.md` and canon DR-002/DR-003/DR-005.

**Architecture:** Pure doctrine-and-propagation change: prose edits in `AGENTS.md` (§§ Model Tiers, Fable Availability Policy, Dispatch Discipline) and `dodi-dev/skills/review/SKILL.md` (§ Catch Attribution, § Gate Ledger), one-parenthetical edits in all 15 worker prompt templates, one new multi-line-tolerant grep in `scripts/validate-phase-skills.sh`, and the five-file version bump to `0.17.0`. No script logic beyond the validator predicate changes; `dodi-dev/scripts/hook-require-model-pin.sh` stays **byte-identical to main** (acceptance criterion 11), and no SKILL.md gains an `effort:` frontmatter key (criterion 12).

**Tech Stack:** Markdown doctrine files, bash validators, JSON plugin metadata. No CI — every check is local (`bash <path>`).

**Worktree:** `/Users/may/github/dodi/dodi-skills/dodi-dev/worktrees/epic-dod-1213`, branch `epic/dod-1213-fable-scarcity-doctrine`. Run every command from this worktree root.

**Cross-ticket coordination (from spec § 3):** `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` is also DOD-1217's subject (the dual-tier self-declaration fix). Both tickets edit the same parenthetical. This plan edits the template **as it exists today** (single `(Capable tier)` declaration); whichever ticket merges second rebases its change onto the other's — the effort addition must be re-applied onto DOD-1217's dual-tier text, never revert it. DOD-1215 (mature-ticket policy row) consumes this ticket's `Capable@max` vocabulary and must land after it.

## Testing Contract

### Required Test Groups

- Unit: `not-required`
  - Scope: n/a (doctrine prose plus one validator predicate)
  - Reason: no unit-test harness for markdown content exists in this repo and inventing one is out of scope (ticket contract).
  - Minimum assertions: none.

- Integration: `required`
  - Scope: repository validators over the full skill tree and plugin metadata.
  - Reason: `validate-phase-skills.sh` is the real regression surface — it enforces the shape of the tier+effort self-declarations across all 15 templates; `validate-plugin-metadata.sh` enforces five-file version parity.
  - Harness: `existing` — standalone bash scripts, no runner above them.
  - Minimum assertions:
    - `bash scripts/validate-phase-skills.sh` exits 0 and prints `phase skills ok` (all 15 templates pass tier check AND new effort check).
    - **Negative case, run by hand and recorded in the PR evidence:** strip the effort text from one prompt template → validator exits non-zero printing `worker prompt does not name its effort: <file>` → restore → validator exits 0 again (exact commands in Task 7).
    - `bash scripts/validate-plugin-metadata.sh` exits 0 after the five-file bump to `0.17.0`.

- E2E: `not-required` (not-applicable)
  - Scope: n/a.
  - Reason: whether a dispatch actually runs at the declared effort is unobservable from the dispatch site on Claude Code (DR-005 — the Agent tool has no effort parameter). Do not write a test asserting it; the runtime gap is the ticket's subject matter, not a coverage oversight.
  - Harness: `not-applicable`
  - Minimum assertions: none.

### Critical Flows

- `bash scripts/validate-phase-skills.sh` passes on the full edited tree, and fails naming the file when any template's effort declaration is removed (negative case).
- All 15 templates satisfy the ticket's single-line grep: `grep -L -E '(Frontier|Capable|Standard|Fast) tier[^)]*effort' dodi-dev/skills/*/*-prompt.md` returns nothing.
- Marker/ledger grammar is identical in shape in `AGENTS.md` and `dodi-dev/skills/review/SKILL.md`: `tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` and `final=<tier>@<effort>`.

### Regression Surface

- `dodi-dev/scripts/hook-require-model-pin.sh` must stay byte-identical to `main` — proven by `git diff main -- dodi-dev/scripts/hook-require-model-pin.sh` (empty) and by `bash dodi-dev/scripts/tests/test-hooks-payload.sh` (criterion 11: no effort logic leaked into the hook).
- `dodi-dev/scripts/comment-species.sh` does not parse `tier-degraded`/`gate-ledger` text (verified in spec), but the marker grammar change touches comment text that species classification reads — `bash dodi-dev/scripts/tests/test-comment-species.sh` and `bash dodi-dev/scripts/tests/test-driver-claim.sh` must still pass.
- All six scripts in `dodi-dev/scripts/tests/` are cheap; run the whole directory.
- The existing tier self-declaration check in `validate-phase-skills.sh` stays as-is and must still pass on every template.

### Commands

- Unit: `not-required — none`
- Integration: `bash scripts/validate-phase-skills.sh` ; `bash scripts/validate-plugin-metadata.sh` ; negative case per Task 7
- E2E: `not-applicable — none`
- Broader regression: `for t in dodi-dev/scripts/tests/test-*.sh; do bash "$t" || exit 1; done` ; `bash scripts/validate-ticket-comment-templates.sh`

### Harness Requirements

- `bash`, `python3` (used inside the validators), `git` — all present locally; no services, env vars, seeds, browsers, mocks, or accounts. Run everything from the worktree root (the validators use repo-relative paths).

### Non-Required Rationale

- Unit: doctrine prose plus one grep predicate; no markdown unit harness exists and inventing one is out of scope.
- Integration: (required — n/a)
- E2E: actual dispatch effort is unobservable from the dispatch site on Claude Code (DR-005); the honest coverage story is validator-enforced declaration shape + human-review-enforced content.

### Verification Rules

- Missing harness is not a skip reason; set it up or report a concrete blocker.
- If a test failure exposes an implementation issue, fix the implementation, not the test.
- If testing exposes a spec or plan mismatch, demote the ticket to the spec lane.

---

## File Structure

No files are created except this plan. Modified files (22):

| File | Responsibility of the change |
|------|------------------------------|
| `AGENTS.md` | § Model Tiers: effort table + 8 doctrine bullets; § Fable Availability Policy: Attribution + Hook-interplay bullets; § Dispatch Discipline: dispatch-pin bullet + self-declaration bullet |
| `dodi-dev/skills/review/SKILL.md` | § Catch Attribution tier-degraded grammar; § Gate Ledger `final=` grammar (4 lines) |
| 11 single-seat prompt templates (listed in Task 5) | one-line self-declaration edits |
| 4 multi-seat prompt templates (listed in Task 6) | reflowed self-declarations, each seat's tier+effort on one line |
| `scripts/validate-phase-skills.sh` | effort-presence check in the tier self-declaration loop |
| `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json` | version `0.16.4` → `0.17.0` |

**Never modified:** `dodi-dev/scripts/hook-require-model-pin.sh` (byte-identical to main), any SKILL.md frontmatter, `.agents/plugins/marketplace.json` (carries no version field), tier assignments, policy buckets, `needs-capable-delivery` routing, the Grok Build mapping sentence at `AGENTS.md:36`.

---

### Task 1: AGENTS.md § Model Tiers — effort table + doctrine bullets

**Files:**
- Modify: `AGENTS.md:31-37` (insert after the tier table and after the Grok bullet)

- [ ] **Step 1:** Insert the effort companion table immediately after the tier table. Edit `AGENTS.md` — replace:

```text
| Fast | `haiku` | Git mechanics, state classification, command/test runners, read-only state digests |

- Aliases only — never full model IDs; aliases track model upgrades.
```

with:

```text
| Fast | `haiku` | Git mechanics, state classification, command/test runners, read-only state digests |

Effort is the second capability axis. Every tier carries a **declared effort** per runtime — the same contract shape as the alias column, one row per tier, no cell left silent:

| Tier | Claude Code (declared effort) | Codex | Grok Build |
|------|-------------------------------|-------|------------|
| Frontier | `xhigh` | highest-reasoning configuration (no level implied) | `grok-4.6` @ `xhigh` |
| Capable | `high` (the model default); `max` only at a declared elevated-substitution seat | highest-reasoning configuration (no level implied) | `grok-4.6` @ `xhigh` |
| Standard | session default | default coding model | `grok-4.6` @ session default |
| Fast | not expressible — the `haiku` alias does not resolve to an effort-capable model | small fast model | `grok-4.6` @ session default |

- Aliases only — never full model IDs; aliases track model upgrades.
```

- [ ] **Step 2:** Insert the effort doctrine bullets between the Grok Build bullet and the capability-match bullet. Edit `AGENTS.md` — replace:

```text
substitution.
- Pick tiers by capability match, never by cost
```

(the seam between the bullet ending `...the same attributed exception as a `deferred`/`soft` substitution.` and the bullet starting `- Pick tiers by capability match, never by cost`) with:

```text
substitution.
- Effort levels are Claude Code vocabulary (`low|medium|high|xhigh|max`), exactly as model aliases are. A prompt or marker that names a level means that tier's declared effort; each runtime maps it per the effort table above, the same way it maps aliases.
- **Notation (defined once, used everywhere a tier-plus-effort pair appears):** `<tier>@<effort>` — a tier name or Claude alias, `@`, an effort level: `Frontier@xhigh`, `Capable@max`, `fable@xhigh→opus@high` in markers. A bare tier name means that tier at its declared default effort. Standard and Fast have no `<tier>@<effort>` form — "session default" and "no effort axis" are declared postures, not levels in the vocabulary, so `Standard@`/`Fast@` never appears in doctrine or a marker.
- **Harness-neutrality rule for effort:** the tier's model pin is the invariant and is mechanically enforced; the tier's effort is a **declared expectation** — expressed mechanically where the runtime allows it at the dispatch site (Grok `spawn_subagent`) and by self-declaration where it does not (Claude Code Agent dispatches). Effort is never silently assumed: a dispatch that cannot set it says which effort it is declared at.
- **The Claude Code limitation, plainly:** the Agent tool exposes no per-dispatch effort parameter — a Claude Code worker inherits the session effort, so per-tier effort differentiation within one session is not mechanically expressible; the prompt's self-declaration is the only per-dispatch record. Consistent with § Deterministic Skeleton: an invariant with no code surface stays prose.
- **Declared, never guaranteed:** unsupported levels fall back silently to the highest supported level at or below the request, and enterprise caps clamp silently — a declared effort is an expectation the transcript makes auditable, never a runtime guarantee.
- A Fast dispatch declares `no effort axis` instead of a level — the `haiku` alias does not resolve to an effort-capable model, so the Fast tier has no effort dimension on Claude Code.
- **`Capable@max` is legal and nameable** — the elevated-substitution target for a gate whose policy row names it (the operator-ruled mature-ticket case, consumed by DOD-1215). Automatic `deferred`/`soft` substitutions run Capable at its declared default (`opus@high`) unless the gate's policy row names `Capable@max`. `needs-capable-delivery` implementers stay at Capable's declared default effort — the label routes tier, not effort.
- Two portability semantics: the effort scale is calibrated per model, so a level does not survive a tier change without re-evaluation; and changing effort mid-conversation breaks prompt-cache prefixes, so effort varies across workloads, never within one lane's cached conversation.
- Pick tiers by capability match, never by cost
```

(Only the seam text is shown here for anchoring; the surrounding bullets are byte-unchanged. The Grok Build bullet at `AGENTS.md:36` is **not** edited — DR-003.)

- [ ] **Step 3:** Verify

Run: `grep -c '^| ' AGENTS.md`
Expected: `14` — the new effort table adds 5 lines starting `| ` (1 header + 4 rows; separator rows start `|-` and do not count) to the current 9 (tier table 5 + Fable policy table 4).

Run: `grep -n 'declared effort\|no effort axis\|Capable@max' AGENTS.md | head -20`
Expected: hits in § Model Tiers for the table, the Fast bullet, and the `Capable@max` bullet.

Run: `bash scripts/validate-phase-skills.sh`
Expected: exit 0, last line `phase skills ok` (validator does not read AGENTS.md).

### Task 2: AGENTS.md § Fable Availability Policy — Attribution + Hook interplay

**Files:**
- Modify: `AGENTS.md:62-63` (the last two Mechanics bullets)

- [ ] **Step 1:** Replace the Attribution bullet. Edit `AGENTS.md` — replace:

```text
- **Attribution (never silent):** every substitution extends the catch-attribution line with a `tier-degraded(fable→<tier>,<policy>)` marker (`review` § Catch Attribution). No gate is ever clean by silence; the marker feeds evidence-based reclassification of these bucket assignments.
```

with:

```text
- **Attribution (never silent):** every substitution extends the catch-attribution line with a `tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` marker (`review` § Catch Attribution) — e.g. `tier-degraded(fable@xhigh→opus@high,deferred)`. Effort components are each seat's **declared** effort per the effort table (the substitute records `max` only at a declared `Capable@max` seat), never a runtime readout. The grammar is forward-only: historical PM comments keep the old two-component form, and aggregation greps must not assume the new arity. No gate is ever clean by silence; the marker feeds evidence-based reclassification of these bucket assignments.
```

- [ ] **Step 2:** Extend the Hook interplay bullet. Edit `AGENTS.md` — replace:

```text
- **Hook interplay:** `hook-require-model-pin.sh` is unchanged — a substitution still carries an explicit pin (`model: opus`); the policy check happens in skill prose immediately before the pin is written.
```

with:

```text
- **Hook interplay:** `hook-require-model-pin.sh` is unchanged — a substitution still carries an explicit pin (`model: opus`); the policy check happens in skill prose immediately before the pin is written. The hook cannot check effort: Claude Code's dispatch payload carries no effort field to read, so the policy-and-declaration layer is the only effort surface.
```

- [ ] **Step 3:** Verify

Run: `grep -n 'tier-degraded' AGENTS.md`
Expected: line ~40 (bare-name mention, unchanged) and the Attribution bullet now showing `tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)`.

### Task 3: AGENTS.md § Dispatch Discipline — dispatch pin + self-declaration

**Files:**
- Modify: `AGENTS.md:70-71` (the first two Dispatch Discipline bullets after the intro)

- [ ] **Step 1:** Rewrite the dispatch-pin bullet's runtime parenthetical (no other content change). Edit `AGENTS.md` — replace:

```text
- Every worker dispatch pins a model tier explicitly (the Agent tool's `model` parameter on Claude Code; `spawn_subagent`'s `model` parameter on Grok Build, using the Grok slug for that tier, plus reasoning effort `xhigh` when the tier is Frontier or Capable). A dispatch that omits the pin silently inherits the session model
```

with:

```text
- Every worker dispatch pins a model tier explicitly. On Claude Code that is the Agent tool's `model` parameter, and only that — the Agent tool has no per-dispatch effort parameter, so the worker runs at the session effort and the prompt self-declares the tier's declared effort (§ Model Tiers). On Grok Build, `spawn_subagent` pins the Grok slug for that tier plus the reasoning effort the effort table declares. On Codex, tier and effort map per the same table. A dispatch that omits the pin silently inherits the session model
```

(The rest of the bullet — `— in spec/plan sessions that is Frontier, ... stays in the Frontier main loop.` — is byte-unchanged.)

- [ ] **Step 2:** Extend the tier self-declaration bullet. Edit `AGENTS.md` — replace the entire bullet:

```text
- **Tier self-declaration (every worker prompt names its own tier).** Each worker prompt opens by stating the tier it is dispatched at — `You are a test runner (Fast tier), ...`, `You are the spec drafter (Frontier tier), ...`. Where a template serves seats at more than one tier (the review rounds, implementers under `needs-capable-delivery`, the docs-sync seats), it names the alternatives and instructs the worker to match this dispatch's pin. The pin is what the harness enforces; the self-declaration is what makes a **wrong** tier visible — to the worker, in the transcript, and in review — since `hook-require-model-pin.sh` can only check that a pin exists, never that it fits. A worker prompt that does not name its tier is a review finding. (Field evidence, 2026-08-26: the one delivery lane whose worker prompts carried no tier line ran every leaf at `opus`, test runners included; the lane whose prompts named tiers seated all four tiers correctly.)
```

with:

```text
- **Tier and effort self-declaration (every worker prompt names its own tier and declared effort).** Each worker prompt opens by stating the tier it is dispatched at and that tier's declared effort, in the same parenthetical, tier and effort on the same line — `You are a test runner (Fast tier, no effort axis), ...`, `You are the spec drafter (Frontier tier, xhigh effort), ...`. Canonical forms: `(Frontier tier, xhigh effort)`, `(Capable tier, high effort)`, `(Standard tier, session-default effort)`, `(Fast tier, no effort axis)`. Where a template serves seats at more than one tier (the review rounds, implementers under `needs-capable-delivery`, the docs-sync seats), it names each alternative's tier and effort — each seat's `<tier> tier, <effort> effort` unit on one line — and instructs the worker to match this dispatch's pin. The pin is what the harness enforces; the self-declaration is what makes a **wrong** tier visible — to the worker, in the transcript, and in review — since `hook-require-model-pin.sh` can only check that a pin exists, never that it fits. The effort declaration is normative — what this seat is declared to run at per the effort table — never a runtime readout: it makes a wrong or missing effort visible the same way, since nothing mechanical can check effort on Claude Code. A worker prompt that does not name its tier and effort is a review finding. (Field evidence, 2026-08-26: the one delivery lane whose worker prompts carried no tier line ran every leaf at `opus`, test runners included; the lane whose prompts named tiers seated all four tiers correctly.)
```

- [ ] **Step 3:** Verify acceptance-criterion greps on AGENTS.md

Run: `grep -n "no effort parameter\|session effort" AGENTS.md`
Expected: at least one hit (criterion 2 — the Model Tiers limitation bullet and the Dispatch Discipline bullet both say "session effort").

Run: `grep -rn '@\(low\|medium\|high\|xhigh\|max\)' AGENTS.md`
Expected: hits only in the defined `<tier>@<effort>` / `<alias>@<effort>` form (`Frontier@xhigh`, `Capable@max`, `fable@xhigh→opus@high`, `opus@high`) — no other shape (criterion 4).

- [ ] **Step 4:** Commit

```bash
git add AGENTS.md
git commit -m "DOD-1214: effort as a declared axis in AGENTS.md tier contract

Adds the per-tier/per-runtime declared-effort table, the <tier>@<effort>
notation, the harness-neutrality rule, the DR-005 Claude Code limitation,
Capable@max as a nameable substitution target, and effort components in
the tier-degraded marker doctrine. Grok Build row unchanged (DR-003).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 4: review/SKILL.md — marker and ledger grammar

**Files:**
- Modify: `dodi-dev/skills/review/SKILL.md:65,73,75,79`

- [ ] **Step 1:** Update the Tier-degraded suffix bullet (§ Catch Attribution). Replace:

```text
- **Tier-degraded suffix (fable substitution):** a fable-seated round run at a substituted tier under a `deferred`/`soft` fable-policy (AGENTS.md § Fable Availability Policy) appends ` tier-degraded(fable→<tier>,<policy>)` to its finding tags — e.g. `caught-by: pre-pr/2/opus tier-degraded(fable→opus,deferred)`. The dispatcher appends it exactly where it appends `<round>/<tier>`; append-only, next-boundary rule unchanged. The substitution is recorded and the obligation (deferred) queued — a gate is never clean by silence.
```

with:

```text
- **Tier-degraded suffix (fable substitution):** a fable-seated round run at a substituted tier under a `deferred`/`soft` fable-policy (AGENTS.md § Fable Availability Policy) appends ` tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` to its finding tags — e.g. `caught-by: pre-pr/2/opus tier-degraded(fable@xhigh→opus@high,deferred)`. Effort components are each seat's **declared** effort per the AGENTS.md effort table (the substitute records `max` only when the seat is a declared `Capable@max` case), never a runtime readout. The dispatcher appends it exactly where it appends `<round>/<tier>`; append-only, next-boundary rule unchanged. The substitution is recorded and the obligation (deferred) queued — a gate is never clean by silence. The grammar is forward-only: historical PM comments keep the old two-component form, and aggregation greps must not assume the new arity (a `tier-degraded(` grep matches both).
```

- [ ] **Step 2:** Update the ledger grammar line (§ Gate Ledger). Replace:

```text
`gate-ledger: <gate> rounds=<n> findings=<b/a[,b/a...]> outcome=<clean|escalated> final=<tier>[ tier-degraded(fable→<tier>,<policy>)]`
```

with:

```text
`gate-ledger: <gate> rounds=<n> findings=<b/a[,b/a...]> outcome=<clean|escalated> final=<tier>@<effort>[ tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)]`
```

- [ ] **Step 3:** Update the example line. Replace:

```text
Example: `gate-ledger: spec-review rounds=3 findings=4/2,1/1,0/1 outcome=clean final=fable`
```

with:

```text
Example: `gate-ledger: spec-review rounds=3 findings=4/2,1/1,0/1 outcome=clean final=fable@xhigh`
```

- [ ] **Step 4:** Update the `final=` field bullet. Replace:

```text
- **`final=<tier>`** — the tier alias of the round that closed the gate; a fable-seat substitution appends the same `tier-degraded(fable→<tier>,<policy>)` marker as catch attribution, same semantics, same append point.
```

with:

```text
- **`final=<tier>@<effort>`** — the tier alias of the round that closed the gate, at that seat's declared effort (the effort table's value, or `max` at a declared `Capable@max` seat); a fable-seat substitution appends the same `tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` marker as catch attribution, same semantics, same append point.
```

- [ ] **Step 5:** Verify grammar parity with AGENTS.md (criterion 9)

Run: `grep -o 'tier-degraded([^)]*)' AGENTS.md dodi-dev/skills/review/SKILL.md | sort -u`
Expected: every hit is either the schema form `tier-degraded(fable@<effort>→<tier>@<effort>,<policy>)` or the example form `tier-degraded(fable@xhigh→opus@high,deferred)` — no old two-component `tier-degraded(fable→...` form remains in either file.

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/skills/review/SKILL.md
git commit -m "DOD-1214: effort components in tier-degraded marker and gate-ledger final=

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 5: Single-seat template self-declarations (11 files)

**Files:** modify each listed file — exactly one line each; touch nothing else in the file (dispatch-header lines like `Dispatch with the Agent tool, \`model: fable\` (Frontier tier).` are NOT edited — the self-declaration is the "You are ..." parenthetical).

- [ ] **Step 1:** `dodi-dev/skills/brainstorm/spec-reviewer-prompt.md` — replace:
```text
    You are a spec document reviewer (Frontier tier). Verify this spec is complete and ready for planning.
```
with:
```text
    You are a spec document reviewer (Frontier tier, xhigh effort). Verify this spec is complete and ready for planning.
```

- [ ] **Step 2:** `dodi-dev/skills/mature-ticket/spec-drafter-prompt.md` — replace:
```text
You are the spec drafter (Frontier tier), drafting a specification (or spec questions) for a child ticket so it can reach `spec-ready`.
```
with:
```text
You are the spec drafter (Frontier tier, xhigh effort), drafting a specification (or spec questions) for a child ticket so it can reach `spec-ready`.
```

- [ ] **Step 3:** `dodi-dev/skills/write-plan/plan-writer-prompt.md` — replace:
```text
You are the plan writer (Frontier tier), drafting an implementation plan from an approved spec.
```
with:
```text
You are the plan writer (Frontier tier, xhigh effort), drafting an implementation plan from an approved spec.
```

- [ ] **Step 4:** `dodi-dev/skills/write-plan/plan-reviewer-prompt.md` — replace:
```text
    You are a plan document reviewer (Frontier tier). Verify this plan chunk is complete and ready for implementation.
```
with:
```text
    You are a plan document reviewer (Frontier tier, xhigh effort). Verify this plan chunk is complete and ready for implementation.
```

- [ ] **Step 5:** `dodi-dev/skills/verify/test-runner-prompt.md` — replace:
```text
You are a test runner (Fast tier), executing one test group's verification commands and returning a digest.
```
with:
```text
You are a test runner (Fast tier, no effort axis), executing one test group's verification commands and returning a digest.
```

- [ ] **Step 6:** `dodi-dev/skills/submit-ticket-pr/local-ci-runner-prompt.md` — replace:
```text
You are the local-CI runner (Fast tier). Run the repo's CI-equivalent checks for a child PR targeting an epic branch.
```
with:
```text
You are the local-CI runner (Fast tier, no effort axis). Run the repo's CI-equivalent checks for a child PR targeting an epic branch.
```

- [ ] **Step 7:** `dodi-dev/skills/epic-orchestrator/state-reader-prompt.md` — replace:
```text
You are the state reader (Fast tier), reconstructing epic orchestration state so the orchestrator does not have to read raw tickets, diffs, or logs itself.
```
with:
```text
You are the state reader (Fast tier, no effort axis), reconstructing epic orchestration state so the orchestrator does not have to read raw tickets, diffs, or logs itself.
```

- [ ] **Step 8:** `dodi-dev/skills/epic-orchestrator/evidence-checker-prompt.md` — replace:
```text
You are an evidence checker (Fast tier), independently verifying a state-advancement claim. You are not the worker that made the claim; start fresh and trust nothing in the claim itself.
```
with:
```text
You are an evidence checker (Fast tier, no effort axis), independently verifying a state-advancement claim. You are not the worker that made the claim; start fresh and trust nothing in the claim itself.
```

- [ ] **Step 9:** `dodi-dev/skills/epic-orchestrator/gate1-package-prompt.md` — replace:
```text
You are the Gate 1 package drafter (Frontier tier), drafting the epic intent signoff package — the one document the human reads before delegating the entire epic. It must be self-sufficient at the header level: a human who reads nothing below Key Points can approve or redirect.
```
with:
```text
You are the Gate 1 package drafter (Frontier tier, xhigh effort), drafting the epic intent signoff package — the one document the human reads before delegating the entire epic. It must be self-sufficient at the header level: a human who reads nothing below Key Points can approve or redirect.
```

- [ ] **Step 10:** `dodi-dev/skills/epic-orchestrator/coherence-reviewer-prompt.md` — replace:
```text
You are the epic coherence reviewer (Frontier tier), reviewing a just-merged child ticket for **alignment with the epic's design intent** — not correctness.
```
with:
```text
You are the epic coherence reviewer (Frontier tier, xhigh effort), reviewing a just-merged child ticket for **alignment with the epic's design intent** — not correctness.
```
(Anchor on the sentence start; the remainder of the line is byte-unchanged.)

- [ ] **Step 11:** `dodi-dev/skills/submit-epic-pr/epic-integration-reviewer-prompt.md` — replace:
```text
    You are an epic integration reviewer (Capable tier). You are reviewing the
```
with:
```text
    You are an epic integration reviewer (Capable tier, high effort). You are reviewing the
```
**Coordination note:** DOD-1217 rewrites this same parenthetical into a dual-tier declaration. If DOD-1217 has merged into the epic branch by implementation time, apply the effort addition onto its dual-tier text instead — `(Capable tier, high effort for the integrated-head rounds; Frontier tier, xhigh effort for the make-up round — match this dispatch's pin)`-style, matching whatever tier structure DOD-1217 shipped — never revert its fix.

- [ ] **Step 12:** Verify

Run: `grep -L -E '(Frontier|Capable|Standard|Fast) tier[^)]*effort' dodi-dev/skills/*/*-prompt.md`
Expected: exactly the 4 multi-seat files remain (fixed in Task 6): `dodi-dev/skills/implement/implementer-prompt.md`, `dodi-dev/skills/review/child-pr-integration-prompt.md`, `dodi-dev/skills/review/review-prompt.md`, `dodi-dev/skills/submit-ticket-pr/docs-sync-prompt.md`.

### Task 6: Multi-seat template self-declarations (4 files, reflowed)

Each seat's `<tier> tier, <effort> effort` unit must sit on one physical line (spec § 3 / edge case 1) so both the validator's flattened check and the ticket's single-line grep pass.

**Files:**
- Modify: `dodi-dev/skills/review/review-prompt.md:9-12`
- Modify: `dodi-dev/skills/review/child-pr-integration-prompt.md:9-14`
- Modify: `dodi-dev/skills/implement/implementer-prompt.md:9-10`
- Modify: `dodi-dev/skills/submit-ticket-pr/docs-sync-prompt.md:14-15`

- [ ] **Step 1:** `dodi-dev/skills/review/review-prompt.md` — replace:

```text
    You are a fresh-context code reviewer (Capable tier per round; Frontier tier
    for the final gate round — match this dispatch's pin). You are reviewing a
    completed implementation. Start fresh — read the artifacts and the code
    directly; trust nothing you did not verify.
```

with:

```text
    You are a fresh-context code reviewer (Capable tier, high effort per round;
    Frontier tier, xhigh effort for the final gate round — match this
    dispatch's pin). You are reviewing a completed implementation. Start
    fresh — read the artifacts and the code directly; trust nothing you did
    not verify.
```

- [ ] **Step 2:** `dodi-dev/skills/review/child-pr-integration-prompt.md` — replace:

```text
    You are a child-PR integration reviewer (Capable tier for the integration
    round; Frontier tier for the integration final and any focused re-round —
    match this dispatch's pin). You are reviewing a child PR against its epic
    branch. The implementation already passed a full-checklist pre-PR review
    gate; your aim is the delta — exactly what is new or changed since that gate. Start fresh — read the
    artifacts and the diff directly; trust nothing you did not verify.
```

with:

```text
    You are a child-PR integration reviewer (Capable tier, high effort for the
    integration round; Frontier tier, xhigh effort for the integration final
    and any focused re-round — match this dispatch's pin). You are reviewing a
    child PR against its epic branch. The implementation already passed a
    full-checklist pre-PR review gate; your aim is the delta — exactly what is
    new or changed since that gate. Start fresh — read the artifacts and the
    diff directly; trust nothing you did not verify.
```

- [ ] **Step 3:** `dodi-dev/skills/implement/implementer-prompt.md` — replace:

```text
    You are a leaf implementation worker (Standard tier by default; Capable tier
    on a `needs-capable-delivery` ticket — match this dispatch's pin).
```

with:

```text
    You are a leaf implementation worker (Standard tier, session-default effort
    by default; Capable tier, high effort on a `needs-capable-delivery`
    ticket — match this dispatch's pin).
```

- [ ] **Step 4:** `dodi-dev/skills/submit-ticket-pr/docs-sync-prompt.md` — replace:

```text
    You are the docs-sync judge (Frontier tier, or the tier this dispatch pins
    under the gate's fable-policy). For a change about to become a PR:
```

with:

```text
    You are the docs-sync judge (Frontier tier, xhigh effort — hard policy; or
    the tier and effort this dispatch's fable-policy lookup substitutes, per
    AGENTS.md § Fable Availability Policy). For a change about to become a PR:
```

- [ ] **Step 5:** Verify (criteria 6 + 7)

Run: `[ -z "$(grep -L -E '(Frontier|Capable|Standard|Fast) tier[^)]*effort' dodi-dev/skills/*/*-prompt.md)" ] && echo CLEAN || echo REGRESSED`
Expected: `CLEAN` — all 15 templates have a single-line tier+effort declaration. (Do not rely on the bare `grep -L` exit code: this session's shell wraps `grep` with ugrep, whose `-L` exits 1 when no files are listed — i.e. on success — the opposite of stock `/usr/bin/grep -L`'s always-0. Emptiness of the output, not the exit code, is the success signal.)

Run: `grep -rn '^effort:' dodi-dev/skills; echo "exit: $?"`
Expected: no output; `exit: 1` (criterion 12 — no frontmatter key added).

Run: `bash scripts/validate-phase-skills.sh`
Expected: exit 0, `phase skills ok` (the existing tier check still passes on every reflowed template).

- [ ] **Step 6:** Commit

```bash
git add dodi-dev/skills
git commit -m "DOD-1214: effort in every worker prompt tier self-declaration (15 templates)

Single-seat templates gain the canonical tier+effort parenthetical; the
four multi-seat templates are reflowed so each seat's tier+effort unit
sits on one line.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 7: Validator effort check + hand-run negative case

**Files:**
- Modify: `scripts/validate-phase-skills.sh:57-70`

- [ ] **Step 1:** Extend the self-declaration loop. Replace:

```bash
# Tier self-declaration: every worker prompt template names the tier it is
# dispatched at (AGENTS.md Dispatch Discipline). The pin is what the hook
# enforces; this line is what makes a wrong tier visible in the transcript.
for prompt in "${prompt_files[@]}"; do
  case "$prompt" in
    *-prompt.md) ;;
    *) continue ;;
  esac
  path="dodi-dev/skills/${prompt}"
  if ! grep -qE '\((Frontier|Capable|Standard|Fast) tier' "$path"; then
    echo "worker prompt does not name its tier: ${prompt}" >&2
    exit 1
  fi
done
```

with:

```bash
# Tier and effort self-declaration: every worker prompt template names the
# tier and declared effort it is dispatched at (AGENTS.md Dispatch
# Discipline). The pin is what the hook enforces; these lines are what make
# a wrong tier or effort visible in the transcript.
for prompt in "${prompt_files[@]}"; do
  case "$prompt" in
    *-prompt.md) ;;
    *) continue ;;
  esac
  path="dodi-dev/skills/${prompt}"
  if ! grep -qE '\((Frontier|Capable|Standard|Fast) tier' "$path"; then
    echo "worker prompt does not name its tier: ${prompt}" >&2
    exit 1
  fi
  # Effort check is tolerant of parentheticals that wrap across lines
  # (multi-seat templates); the {0,200} bound keeps a stray unclosed
  # parenthesis from matching across the whole file.
  if ! tr '\n' ' ' < "$path" | grep -qE '\((Frontier|Capable|Standard|Fast) tier[^)]{0,200}effort'; then
    echo "worker prompt does not name its effort: ${prompt}" >&2
    exit 1
  fi
done
```

- [ ] **Step 2:** Verify positive case

Run: `bash scripts/validate-phase-skills.sh; echo "exit: $?"`
Expected: file listing then `phase skills ok`, `exit: 0`.

- [ ] **Step 3:** Hand-run the negative case (criterion 8) and record the transcript in the lane's PR evidence

```bash
sed -i '' 's/(Fast tier, no effort axis)/(Fast tier)/' dodi-dev/skills/verify/test-runner-prompt.md
bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `worker prompt does not name its effort: verify/test-runner-prompt.md` on stderr, `exit: 1`.

```bash
git checkout -- dodi-dev/skills/verify/test-runner-prompt.md
bash scripts/validate-phase-skills.sh; echo "exit: $?"
```
Expected: `phase skills ok`, `exit: 0`.

- [ ] **Step 4:** Commit

```bash
git add scripts/validate-phase-skills.sh
git commit -m "DOD-1214: validator requires effort in worker prompt self-declarations

Multi-line-tolerant check (flatten newlines, bounded non-paren run) so
wrapped multi-seat parentheticals pass; failure names the file, mirroring
the tier message. Negative case hand-verified.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 8: Version bump 0.16.4 → 0.17.0 (five files)

Minor bump per spec recommendation (doctrine-axis addition). The five version-bearing files (`.agents/plugins/marketplace.json` carries no version field — do not touch it).

**Files:**
- Modify: `.claude-plugin/marketplace.json:12`
- Modify: `dodi-dev/.claude-plugin/plugin.json:4`
- Modify: `dodi-dev/.codex-plugin/plugin.json:3`
- Modify: `.grok-plugin/marketplace.json:12`
- Modify: `dodi-dev/.grok-plugin/plugin.json:4`

- [ ] **Step 1:** In each of the five files, replace:
```text
"version": "0.16.4",
```
with:
```text
"version": "0.17.0",
```

- [ ] **Step 2:** Verify (criterion 13)

Run: `bash scripts/validate-plugin-metadata.sh; echo "exit: $?"`
Expected: prints `plugin metadata ok: 0.17.0`, `exit: 0`.

Run: `grep -h '"version"' .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json | sort -u`
Expected: exactly one line: `  "version": "0.17.0",` (leading whitespace may vary between marketplace and plugin files — if `sort -u` yields two lines differing only in indentation, verify the version substring is identical; the metadata validator is the authoritative parity check).

- [ ] **Step 3:** Commit (bare version string in the message per AGENTS.md:16; the `v0.17.0` tag is applied at release time by the epic PR process, not by this lane)

```bash
git add .claude-plugin/marketplace.json dodi-dev/.claude-plugin/plugin.json dodi-dev/.codex-plugin/plugin.json .grok-plugin/marketplace.json dodi-dev/.grok-plugin/plugin.json
git commit -m "DOD-1214: 0.17.0 — effort as a first-class axis alongside model tier

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 9: Full acceptance + regression sweep (no code changes)

- [ ] **Step 1:** Run the acceptance-criteria greps

```bash
grep -n "no effort parameter\|session effort" AGENTS.md                          # criterion 2: ≥1 hit
grep -rn '@\(low\|medium\|high\|xhigh\|max\)' AGENTS.md dodi-dev/skills          # criterion 4: only defined-form hits
grep -L -E '(Frontier|Capable|Standard|Fast) tier[^)]*effort' dodi-dev/skills/*/*-prompt.md   # criterion 6: no output
grep -rn '^effort:' dodi-dev/skills                                              # criterion 12: no output (exit 1)
git diff main -- dodi-dev/scripts/hook-require-model-pin.sh                      # criterion 11: empty output
```
Expected: as annotated per line. Additionally read `AGENTS.md` §§ Model Tiers / Fable Availability Policy / Dispatch Discipline and `dodi-dev/skills/review/SKILL.md:60-84` to confirm criteria 1, 3, 5, 9, 10, 14 (prose criteria: every effort-table cell filled; Fast-tier rule stated; harness-neutrality rule present; marker grammar identical in shape across both files; `Capable@max` nameable; no runtime-conditional prose — harness mechanics written as the Claude form plus the tier name).

- [ ] **Step 2:** Run the validators and the full regression suite

```bash
bash scripts/validate-phase-skills.sh          # exit 0, "phase skills ok"
bash scripts/validate-plugin-metadata.sh       # exit 0
bash scripts/validate-ticket-comment-templates.sh   # exit 0
for t in dodi-dev/scripts/tests/test-*.sh; do echo "== $t"; bash "$t" || exit 1; done
```
Expected: every validator exits 0; all six test scripts pass (`test-await-worker.sh`, `test-claim-liveness.sh`, `test-comment-species.sh`, `test-driver-claim.sh`, `test-heartbeat.sh`, `test-hooks-payload.sh`). `test-hooks-payload.sh` passing plus the empty `git diff main` proves criterion 11; `test-comment-species.sh` and `test-driver-claim.sh` cover the comment-text regression surface of the marker grammar change.

- [ ] **Step 3:** Confirm the working tree is clean except intended files

Run: `git status --short`
Expected: empty (all changes committed across Tasks 3, 4, 6, 7, 8). If the negative-case scratch edit from Task 7 leaked, restore it before finishing.
