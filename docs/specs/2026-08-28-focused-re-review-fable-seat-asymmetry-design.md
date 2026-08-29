# Pre-PR vs Child-PR Post-Fix Re-Review Fable-Seat Asymmetry — DOD-1218 Spec

Epic: DOD-1213 (fable scarcity doctrine). Ticket: DOD-1218. Status: **DRAFT_READY** — the operator ruling landed 2026-08-29 (recorded as **DR-025** in the epic canon table): **Direction B scoped to standard-tier tickets only** (a hybrid of B and the status quo). The four-direction fork this spec previously posed is closed; the fork analysis is retained below as compressed decision history.

Binding inputs: epic Decision Register canon DR-001..DR-005 plus **DR-025** (the ruling; DR-003 interaction handled in § Register hygiene); `AGENTS.md` §§ Model Tiers / Fable Availability Policy; the gate ledger and catch attribution in `dodi-dev/skills/review/SKILL.md`.

**Citation mapping:** siblings DOD-1214..1217 have merged since the ruling's citations were written. The ruling's `AGENTS.md:54` (inherit sentence) is today's `AGENTS.md:72`; its `AGENTS.md:40` (writer-≠-final-gate invariant) is today's `AGENTS.md:57`; its `AGENTS.md:50` (hard bucket) is today's `AGENTS.md:67`. `review/SKILL.md:47`/`:55` are unchanged. This spec cites today's lines.

## TL;DR

Two structurally identical post-fix focused re-reviews were tiered differently — the child-PR post-fix re-round at the gate's fable seat (`review/SKILL.md:47`), the verify-stage focused re-review pinned `model: opus` with no seat (`:55`) — while the governing inherit rule (`AGENTS.md:72`) read literally contradicted the shipped `:55` pin, so the mandatory dispatch-time fable-policy lookup (`execution-model.md:15`) had no deterministic answer; the only two ledger occurrences ever closed at different tiers (DOD-1098 `opus`, DOD-990 `fable`). **The operator has ruled (DR-025): Direction B, scoped to standard-tier tickets.** The child-PR post-fix re-round downgrades to Capable tier (`opus@high`) on standard-tier tickets and keeps its **hard** fable seat on `needs-capable-delivery` tickets; the verify-stage re-review stays Capable on every ticket tier. The operative principle: **a post-fix re-round keeps a hard fable seat only where a Capable re-round would collapse writer and reviewer with no independent Frontier look left before the merge** — true exactly of the capable-tier child-PR re-round (the fix worker is already `opus` and merge-into-epic is next), false everywhere else. No hard seat is removed, so no park edge changes; the fable bill drops by one deferred dispatch per standard-tier child-PR fix loop. OQ5 is answered (the asymmetry is resolved on standard tier and deliberately, now justifiably, persists on capable tier); OQ1–4/6–7 remain open with the N≥10 ledger revisit trigger recorded. This revision drafts the exact replacement text for `AGENTS.md`, `review/SKILL.md:47`, and `child-pr-integration-prompt.md`, the validator pins, and the DR-003 register-hygiene record; implementation is mechanical.

## Key Points

- **The ruling (DR-025, operator, 2026-08-29):** child-PR post-fix re-round (`review/SKILL.md:47`) → Capable tier (`model: opus`) on **standard-tier tickets**; unchanged **hard** fable seat on `needs-capable-delivery` tickets. Verify-stage focused re-review (`:55`) → unchanged, Capable on **any** ticket tier. Direction A rejected as unnecessary added cost; full Direction B rejected because an all-`opus` re-round on `needs-capable-delivery` tickets would violate writer-≠-final-gate (`AGENTS.md:57`) on exactly the invariant-dense work that tier protects.
- **The operative principle (the doctrine sentence `AGENTS.md:72` will carry):** post-fix focused re-rounds run at Capable by default; a re-round keeps its gate's hard fable seat only where **both** hold — it is the last checkpoint before the fix delta reaches the epic branch, **and** the fix worker is itself Capable, so a Capable re-round would collapse writer and reviewer with no independent look remaining before the merge. The capable-tier child-PR re-round satisfies both; the standard-tier re-rounds fail the collapse test (`sonnet` fix worker), and the verify-stage re-review on any tier fails the last-checkpoint test (its delta still faces the child-PR integration pair downstream).
- **Pin answers under the ruled doctrine (the acceptance-criterion read-through):** standard-tier ticket — verify-stage re-review `opus@high`, child-PR re-round `opus@high`. `needs-capable-delivery` ticket — verify-stage re-review `opus@high`, child-PR re-round `fable@xhigh`, **hard**. Deterministic in all four cells.
- **Fable bill and park edges:** −1 deferred fable dispatch (and one fewer potential `FABLE_MAKEUP` obligation) per standard-tier child-PR fix loop. **No hard seat moves** — the capable-tier re-round seat stays, so no ticket class changes its park behavior. The standard-tier re-round becomes a plain Capable seat: not a substituted fable seat, so its rounds carry **no** `tier-degraded` marker and queue **no** make-up; a standard-tier gate closed by a post-fix re-round posts `gate-ledger: child-pr … final=opus@high` clean.
- **DR-003 hygiene:** DR-003 ("the epic removes no fable seat; any child spec proposing a seat removal as its solution is out of contract") binds agent proposals; DR-025 is the operator's own ruling, so authority is not in question — but DR-003 stands unedited in the canon table. The implementation-time register entry must carry an **explicit scoped DR-003 amendment-by-operator-ruling** (§ Register hygiene) so the register never shows a live contradiction.
- **Open questions:** the ruling answers **OQ5 only** (its own text says so — "the partial resolution named in open question 5"). OQ1–4 and 6–7 remain open and are re-stated post-ruling in § Open questions; the N≥10 paired-ledger location analysis remains the revisit trigger, now aimed at DR-025's standard-tier scope.
- **Surfaces that change:** `AGENTS.md` (hard-row Gates cell + the `:72` doctrine sentence — the tier-conditional clause the ruling's scope note requires), `review/SKILL.md:47`, `child-pr-integration-prompt.md:3,6,10,16` (standard-tier path only), `scripts/validate-phase-skills.sh` (pins). **Unchanged:** `review/SKILL.md:55`, `review-prompt.md`, all orchestrator surfaces, park/make-up machinery, `hook-require-model-pin.sh`.
- **Version:** five-file lockstep bump to **0.17.4** (current 0.17.3 after DOD-1214..1217; patch per DR-015's boundary — row coverage and doctrine wording, no new axis). Vocabulary follows DOD-1214's merged `<tier>@<effort>` notation throughout.

## Problem (verified in this worktree; pre-ruling state)

- `dodi-dev/skills/review/SKILL.md:47` — child-PR fix loop: "a **focused re-round at the gate's fable seat** aimed at the fix delta — it inherits the child-PR final's fable-policy (**hard** on `needs-capable-delivery`, **deferred** on standard-tier), since it is the round that re-establishes gate-clean, not a confirmation sweep."
- `dodi-dev/skills/review/SKILL.md:55` — pre-PR/verify-stage: "**Focused re-review** … a fresh reviewer at Capable tier (`model: opus` on Claude Code) … a scoped instance of the review fix loop … under the pre-PR loop's cap." No fable seat. The justification `:47` gave for its seat ("the round that re-establishes gate-clean") is verbatim true of `:55`.
- `AGENTS.md:72` — "Focused post-fix re-rounds inherit their gate's policy" — stated generally, instantiated only for child-PR. The pre-PR gate's own final **is** a fable seat (`review/SKILL.md:35`), assigned **deferred** at `AGENTS.md:68`, so the literal inherit reading gave `:55` a deferred fable seat, contradicting the shipped `opus` pin.
- The only written justification for the asymmetry was one unargued parenthetical: `docs/specs/2026-07-07-execution-model-flatten-design.md:138`.
- **Structural ambiguity underneath:** `:55` says the re-review runs "under the pre-PR loop's cap" (a sub-loop), but the ledger treats `focused-re-review` as a first-class gate — its own `caught-by` gate token (`review/SKILL.md:62`), its own covered ledger gate (`:77`), its own posting surface (`:80`). (Post-ruling: non-load-bearing for policy — see OQ1.)
- **The ambiguity produced divergent behavior in the field.** Exactly two `gate-ledger: focused-re-review` lines exist: DOD-1098 (`needs-capable-delivery`) closed `final=opus` (the shipped `:55` pin); DOD-990 closed `final=fable` (the literal inherit rule). Same lookup, two answers — the defect `execution-model.md:15` mandates against.

## The ruling — DR-025 (decision history)

Posted by the operator 2026-08-29 on DOD-1218; canon as DR-025 on epic DOD-1213. **Direction: B, scoped to standard-tier tickets only** (hybrid of B and the status quo):

- **Child-PR post-fix re-round (`review/SKILL.md:47`):** downgrades from the fable seat to Capable tier (`opus`) on **standard-tier tickets**. On `needs-capable-delivery` tickets the fable seat stays — **hard**, unchanged.
- **Verify-stage focused re-review (`review/SKILL.md:55`):** unchanged — Capable tier (`opus`), no fable seat, on any ticket tier.
- **Rationale (operator's own words, condensed):** Direction A rejected as unnecessary added cost. Full Direction B rejected because on `needs-capable-delivery` tickets the fix worker is already `opus` — an all-`opus` re-round there would violate the writer-≠-final-gate invariant on exactly the invariant-dense work that tier exists to protect (OQ5). The hybrid keeps the hard fable seat where that risk is real and removes it where the fix worker was never `opus`, so there is no writer/reviewer collapse to guard against. The child-PR re-round is the last checkpoint before the fix reaches the epic branch — it is where the epic can still afford exactly one fable-tier independent check on capable-tier work.
- **Scope notes from the ruling:** the gate-policy table's `focused-re-review` outcome becomes tier-conditional for the first time — `AGENTS.md` § Fable Availability Policy needs a split row or an explicit tier-conditional clause, not a single bucket label. `child-pr-integration-prompt.md`'s focused-re-round pins change only on the standard-tier path. This is explicitly the partial resolution named in OQ5; OQ1–4/6–7 were not asked and are not settled.

### Decision history — the four-direction fork (decided; retained for the record)

| | Principle | `:55` | `:47` | Outcome |
|---|---|---|---|---|
| A | Parity via inherit (sub-loop reading): seat `:55` at deferred fable | +deferred seat | unchanged | **Rejected** — unnecessary added cost |
| B (full) | Unbounded downstream backstop: downgrade `:47` to `opus` on all tiers | unchanged | `opus` everywhere | **Rejected** — writer/reviewer collapse on `needs-capable-delivery` (`AGENTS.md:57`) |
| **B (hybrid — ruled)** | Collapse test: hard seat only where the fix worker is Capable and the merge is next | **unchanged** | **`opus` on standard-tier; hard `fable` on `needs-capable-delivery`** | **Chosen — DR-025** |
| C | `focused-re-review` as first-class gate with its own deferred row | +deferred seat | unchanged | **Rejected** with A (same bill) |
| D | Ratify status quo; backstop bounded at merge, written as doctrine | unchanged | unchanged | **Rejected** — the asymmetry `:47` carried on standard tier was not retained |

## The operative principle (doctrine)

The ruling answers "which direction"; the spec states why the doctrine now reads this way. The principle the replacement `AGENTS.md:72` sentence carries:

> Post-fix focused re-rounds run at Capable tier (`opus@high`) by default. A re-round keeps its gate's **hard** fable seat only where both hold: **(a)** it is the last checkpoint before the fix delta reaches the epic branch, and **(b)** the fix worker is itself Capable — so a Capable re-round would collapse writer and reviewer with no independent look remaining before the merge.

Instantiated: the capable-tier child-PR re-round satisfies (a) and (b) — hard fable seat, unchanged. The standard-tier child-PR re-round fails (b) — the `sonnet` fix worker means an `opus` re-round is already an independent cross-tier check — so it is a plain Capable seat. The verify-stage focused re-review fails (a) on every ticket tier — its delta still faces the child-PR integration pair downstream — so it is a plain Capable seat everywhere, which is why `:55` is correct as shipped and needs no row. This resolves the `AGENTS.md:72`-vs-`:55` contradiction by replacing the inherit rule, not by patching its instantiation list. ⚠ The two-condition articulation is the spec's synthesis of the ruling's rationale (the ruling supplies both halves but does not join them as one test) — delegated, overridable at spec review; the pins it produces are the ruling's own and do not move if the articulation is rephrased.

The former deferred seat on the standard-tier re-round is **removed, not substituted**: no `tier-degraded` marker, no `FABLE_MAKEUP` obligation, `gate-ledger` closes `final=opus@high` bare. The fix delta on a standard-tier ticket reaches the epic branch having seen Capable review only; the epic-integration rounds and the batched make-up round exist downstream as a matter of fact, but this spec deliberately does **not** elevate them to doctrinal backstop — that is OQ3, unresolved (§ Open questions).

## Design — ruled direction (normative text)

Replacement text is normative in substance; final wording at implementation. All tier-plus-effort pairs use DOD-1214's `<tier>@<effort>` notation.

### 1. `AGENTS.md` § Fable Availability Policy

**Hard row (`:67`) Gates cell** — the ruling's tier-conditional requirement, split-row half: the cell entry "the capable-tier child-PR final round (`needs-capable-delivery` tickets)" becomes:

> the capable-tier child-PR final round **and its post-fix focused re-round** (`needs-capable-delivery` tickets)

**Doctrine sentence (`:72`)** — the inherit sentence is replaced (the "A fable seat without a row is a defect." opener and the closing spec-hard/plan-deferred asymmetry sentence are retained verbatim around it):

> Post-fix focused re-rounds run at Capable tier (`opus@high`) by default; a re-round keeps its gate's **hard** fable seat only where both hold: it is the last checkpoint before the fix delta reaches the epic branch, and the fix worker is itself Capable — a Capable re-round there would collapse writer and reviewer with no independent look left before the merge (DR-025). Concretely: on a `needs-capable-delivery` ticket the child-PR post-fix re-round runs at the gate's **hard** fable seat (`fable@xhigh` — the `opus` fix worker makes it the last independent Frontier check before merge-into-epic); on a standard-tier ticket the child-PR post-fix re-round runs at Capable (`opus@high` — not a fable seat: no substitution, no make-up, no row needed); and the verify-stage focused re-review runs at Capable (`opus@high`) on any ticket tier — its delta still faces the child-PR integration pair downstream. Either re-round is the round that re-establishes gate-clean, never a confirmation sweep.

The acceptance read-through works from this sentence alone: all four tier×re-round cells are stated by name. The deferred row (`:68`) is untouched — the standard-tier child-PR **final** stays deferred; only the post-fix re-round leaves the fable-seat universe.

### 2. `review/SKILL.md:47`

> 4. **Fix loop** — findings from either round route to fix workers (`model: sonnet`; `model: opus` when the ticket carries `needs-capable-delivery`), then a **focused re-round** aimed at the fix delta — tier-conditional per AGENTS.md § Fable Availability Policy (DR-025): on a `needs-capable-delivery` ticket it runs at the gate's **hard** fable seat (`model: fable` on Claude Code — the fix worker is `opus`, so this re-round is the last independent Frontier check before the merge); on a standard-tier ticket it runs at Capable tier (`model: opus` on Claude Code — the `sonnet` fix worker leaves no writer/reviewer collapse to guard against; not a fable seat — no substitution, no make-up). Either way it is the round that re-establishes gate-clean, not a confirmation sweep. Total child-PR rounds cap at 5; cap exhaustion escalates with the unresolved findings — it never merges.

`:48` (step 5, gate-clean and the final's deferred/hard policy) is unchanged — the child-PR **final** keeps its seat on both tiers. `:55` is unchanged byte-for-byte.

### 3. `child-pr-integration-prompt.md` (standard-tier path only; lines `3, 6, 10, 16`)

- **`:3`** — "A post-fix **focused re-round** is a fresh `model: fable` dispatch of this template aimed at the fix delta." becomes: "A post-fix **focused re-round** is a fresh dispatch of this template aimed at the fix delta — `model: fable` on `needs-capable-delivery` tickets (the gate's hard seat), `model: opus` on standard-tier tickets (DR-025)."
- **`:6`** — the Agent-tool line becomes: "Agent tool (general-purpose, model: opus for the integration round; model: fable for the integration final; for a focused re-round: model: fable on `needs-capable-delivery` tickets, model: opus on standard-tier tickets)".
- **`:10`** — the tier self-declaration becomes: "You are a child-PR integration reviewer (Capable tier, high effort for the integration round and a standard-tier focused re-round; Frontier tier, xhigh effort for the integration final and a `needs-capable-delivery` focused re-round — match this dispatch's pin)." (Still satisfies the validator's flattened `\((Frontier|Capable|Standard|Fast) tier[^)]{0,200}effort` self-declaration check.)
- **`:16`** — the Round slot gains the tier annotation: "**Round:** [integration round | integration final | focused re-round at [Frontier@xhigh (`needs-capable-delivery`) | Capable@high (standard-tier)] (fix delta: [diff range])]".

`review-prompt.md` is **unaffected**: it serves the pre-PR gate and the verify-stage focused re-review, and `:55` did not move; its existing declaration already covers the Capable focused round.

### 4. Ledger and marker consequences (prose-pinned here; no grammar change)

- A standard-tier child-PR gate closed by a post-fix re-round posts `gate-ledger: child-pr … final=opus@high` with **no** `tier-degraded` marker — the closing round is a Capable seat, not a substituted fable seat. A capable-tier gate closed by its re-round posts `final=fable@xhigh` (hard — or parks; never substitutes).
- Catch attribution is untouched: standard-tier re-round findings tag `caught-by: child-pr/<n>/opus` bare.
- Forward-only, no back-edits: DOD-1098's `final=opus` focused-re-review line is conforming under the ruled doctrine; DOD-990's `final=fable` line is retroactively the non-conforming reading — it stands as posted (append-only rule) and as the evidence that motivated this ticket.

### 5. Register hygiene — DR-003 (requirement of this revision)

DR-003 ("the epic removes no fable seat; any child spec proposing a seat removal as its solution is out of contract") was written to bound **agent-proposed** solutions; DR-025 is the operator's own ruling, so authority is not in question. But the ruled hybrid does remove a (deferred) fable seat, and DR-003 stands unedited — left alone, the canon table would carry a live contradiction. **Implementation must record, in the same decision-register entry that lands this ticket (next free DR number):**

1. The ruled direction, the operative-principle sentence, and the rejected alternatives by name (A, full-B, C, D).
2. An **explicit scoped DR-003 amendment-by-operator-ruling**: "DR-003 is amended by operator ruling DR-025 — the standard-tier child-PR post-fix re-round's deferred seat is removed on the operator's own authority; DR-003 continues to bind every other seat and all agent-proposed removals."
3. The fable-bill consequence (−1 deferred dispatch per standard-tier child-PR fix loop; zero park-edge change) and the N≥10 revisit trigger (§ Evidence).

⚠ Delegated assumption (non-blocking): the amendment's **shape** — a clause inside the new entry plus an "amended by DR-025/DR-0XX" annotation on DR-003's existing canon-table row, rather than editing DR-003's original text or issuing a standalone supersede entry. Rationale: the register is append-only in spirit and DR-003 is not voided, only scoped. Overridable at plan review.

### 6. Validator pins (`scripts/validate-phase-skills.sh`; existing `grep -qF --` style)

- **Positive pins:**
  - (a) `review/SKILL.md` contains the `:47` hard clause fragment (`focused re-round` … `hard` … `model: fable`) and the standard clause fragment ("on a standard-tier ticket it runs at Capable tier (`model: opus` on Claude Code");
  - (b) `review/SKILL.md` contains the unchanged `:55` clause ("a fresh reviewer at Capable tier (`model: opus` on Claude Code) reads the fix delta") — pinning the resolved asymmetry's stationary half so it cannot drift silently;
  - (c) `AGENTS.md` contains the doctrine sentence's core ("Post-fix focused re-rounds run at Capable tier (`opus@high`) by default");
  - (d) `AGENTS.md` hard-row cell contains "and its post-fix focused re-round".
- **Negative assertion (the pre-ruling shape cannot reappear):** fail if `review/SKILL.md` contains the retired phrase `focused re-round at the gate's fable seat` (the unconditional inherit-seat wording). Combined with (c), the asymmetry cannot silently reappear without the doctrine sentence being deleted first — and deleting the doctrine sentence itself breaks the build via (c); verified during implementation by deleting it in a scratch copy and confirming non-zero exit.
- The existing frontmatter fable-seat check and the effort self-declaration check are untouched; § 3's `:10` text keeps the latter satisfied.

### 7. Release mechanics

Five version-bearing files bump in lockstep **0.17.3 → 0.17.4** (patch per DR-015's boundary: row coverage and doctrine wording, not an axis addition): `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json`. Tag `v0.17.4`; bare version string in the commit message. `.agents/plugins/marketplace.json` carries no version key — do not add one. Full battery: `validate-plugin-metadata.sh && validate-phase-skills.sh && validate-ticket-comment-templates.sh`.

### 8. Invariants (unchanged by this ticket)

- No change to the pre-PR final (`review/SKILL.md:35`), the child-PR integration pair and final-round policy (`:44–:46`, `:48`), the ledger/catch grammar (`:62–:81`), `review-prompt.md`, the verify-stage surfaces (`state-transitions.md:33`, `deliver-playbook.md`), the park/make-up machinery, or `hook-require-model-pin.sh`.
- Harness-specific tier mentions use the Claude form plus tier name; tier-plus-effort pairs use `<tier>@<effort>` (DOD-1214, merged).
- No skill file references a repo-only document; `docs/specs/2026-07-07…:138`'s parenthetical is historical record — never edited.

## Open questions — what DR-025 did and did not settle

Per the ruling's own text, **only OQ5 is answered**; OQ1–4 and 6–7 "were not asked and should not be treated as settled."

- **OQ5 — answered.** Does B break writer-≠-final-gate on capable tier? Yes, which is why full B was rejected: the ruled hybrid is "explicitly the partial resolution named in open question 5" — the asymmetry is fully resolved on standard-tier tickets (both post-fix re-rounds at `opus@high`) and deliberately persists, now justified, on `needs-capable-delivery` tickets, where the child-PR re-round is the last checkpoint at which the epic can afford one fable-tier independent check on capable-tier work.
- **OQ2 — partially addressed, not closed.** The ruling picks the direction; the operative principle in this spec (collapse test + last-checkpoint condition) is the spec's articulation of why the doctrine reads this way, drafted from the ruling's rationale — it goes to spec review as this spec's content, not as ruled canon.
- **OQ1 — open** (own gate vs sub-loop for `focused-re-review`). Non-load-bearing for policy after the ruling: the verify-stage re-review is a plain Capable seat under either identity reading. The ledger gate identity (`caught-by: focused-re-review/…`, its own `gate-ledger` line and posting surface) stands for attribution regardless.
- **OQ3 — open** (does backstop credit survive merge-into-epic?). Deliberately not invoked: the standard-tier seat removal is justified by the collapse test, not by counting epic-integration/make-up rounds as backstop. This spec states as fact that a standard-tier fix delta reaches the epic branch with Capable review only; whether downstream rounds constitute doctrinal backstop remains unruled.
- **OQ4 — open** (is a deferred seat on a fires-only-on-fix gate acceptable?). Moot in practice — after this change no fires-only-on-fix deferred seat remains — but doctrinally unsettled.
- **OQ6 — open**; the deciding sample does not exist yet (§ Evidence; revisit trigger recorded in the register entry).
- **OQ7 — open** (does the justified-asymmetry precedent generalize?). DR-025 adds a second instance of justified asymmetry with its justification written into doctrine; whether the pattern generalizes is unruled.

## Evidence — what the ledger showed, and the revisit trigger

**The datum that motivated the ticket stands:** the only two `gate-ledger: focused-re-review` lines ever posted closed at different tiers — DOD-1098 (`needs-capable-delivery`) `final=opus`, DOD-990 `final=fable`. Same mandatory lookup, two answers. The ruled doctrine makes the lookup deterministic in all four tier×re-round cells; that repair is the ticket's core deliverable and is direction-independent.

**Deciding statistic (unchanged, now aimed at DR-025's scope):** over tickets with a `gate-ledger: focused-re-review` line in the `ready-for-child-pr` checkpoint evidence, pair with the same ticket's `caught-by: child-pr/<round>/fable` (and epic-integration fable) tags and classify each blocking finding by location inside vs outside the verify-stage fix delta; symmetrically, on standard-tier tickets classify epic-integration/make-up fable catches against the child-PR fix delta the `opus` re-round passed. If Frontier rounds repeatedly catch fix-delta blockers that Capable re-rounds passed, DR-025's standard-tier scope is costing catches and the bucket assignment re-opens.

**Revisit trigger (record in the register entry):** at N≥10 tickets carrying a `focused-re-review` ledger line paired with a completed child-PR ledger, run the location analysis and re-open as an evidence-based reclassification (the purpose `AGENTS.md` § Model Tiers assigns to marker data). N=2 today (DOD-1098's 7 subsequent child-PR blocking findings are test-quality/doc-drift catches, child-PR-native, not fix-delta escapes; DOD-990 found nothing). Until the trigger, DR-025 is doctrinal.

## Acceptance criteria and testing contract

The ticket's acceptance criteria are adopted with the fork resolved: `grep -n "focused re-round at the gate's fable seat" dodi-dev/skills/review/SKILL.md` comes back **empty**; the tier-conditional `:47` clause, the unchanged `:55` clause, the AGENTS.md doctrine sentence, and the hard-row cell addition are all validator-pinned (§ 6). Testing contract: validator wording pins with the negative assertion, metadata lockstep to 0.17.4, full three-script battery, and the manual read-through — a reader with only `AGENTS.md` § Fable Availability Policy + `execution-model.md` § 2 states the pin for both post-fix re-rounds on a standard-tier and a `needs-capable-delivery` ticket (four answers), recorded in the PR body. No new test harness; no shell-script behavior changes beyond the pins.

## Delegated assumptions (all non-blocking, ⚠)

- **Operative-principle articulation:** the two-condition test (last-checkpoint ∧ Capable fix worker) is the spec's synthesis of the ruling's rationale; the pins do not move if reworded at spec review.
- **DR-003 record shape:** amendment clause in the new register entry + annotation on DR-003's canon row, not an edit of DR-003's text or a standalone supersede entry (§ 5).
- **Version number:** 0.17.4 assumes no further sibling merges before implementation; take current+1 at implementation time.
- **DOD-990/DOD-1098 ledger reading:** one occurrence each; used only as proof the lookup was non-deterministic (and, post-ruling, as the conforming/non-conforming examples), never as evidence for the direction.
- **`:16` Round-slot annotation shape** (§ 3): the inline tier alternative in the template slot; any equivalent per-dispatch tier record satisfies the intent (the dispatch pin must be readable from the round header).

## Status

**DRAFT_READY.** The `needs-human-spec` gate is satisfied: the operator ruling (DR-025) landed 2026-08-29 and is folded in above; no product question remains open for this ticket's scope (OQ1–4/6–7 are explicitly out of its scope per the ruling). Proceed to spec review, then `write-plan` against §§ Design 1–8; the register entry in § 5 lands with implementation.
