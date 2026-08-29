# Pre-PR vs Child-PR Post-Fix Re-Review Fable-Seat Asymmetry — DOD-1218 Spec

Epic: DOD-1213 (fable scarcity doctrine). Ticket: DOD-1218. Status: **QUESTIONS_FOR_HUMAN** — this ticket carries `needs-human-spec`; the direction choice below is a genuine product/architecture judgment reserved for a human ruling and is deliberately **not** pre-resolved here. Everything mechanical is drafted so implementation can begin the moment the ruling lands.

Binding inputs: epic Decision Register canon DR-001..DR-005 (none pre-decides this call; DR-003 constrains Direction B — see below); `AGENTS.md` §§ Model Tiers / Fable Availability Policy; the gate ledger and catch attribution in `dodi-dev/skills/review/SKILL.md`.

## TL;DR

Two structurally identical post-fix focused re-reviews are tiered differently: the child-PR post-fix re-round runs at the gate's fable seat (`review/SKILL.md:47`) while the pre-PR verify-stage focused re-review is pinned `model: opus` with no fable seat (`review/SKILL.md:55`) — and the governing rule ("Focused post-fix re-rounds inherit their gate's policy", `AGENTS.md:54`) read literally contradicts the shipped `:55` pin, so the mandatory dispatch-time fable-policy lookup (`execution-model.md:15`) has no unambiguous answer. The ledger shows the ambiguity is already live: of the only two focused re-reviews ever run, one closed at `opus` (DOD-1098) and one at `fable` (DOD-990). **The human must pick which principle governs** — parity/inherit (seat `:55`: Direction A or C), downstream-backstop ending at merge-into-epic (ratify the status quo: Direction D), or downstream-backstop extending past the merge (downgrade `:47`: Direction B, which additionally requires superseding epic canon DR-003). The empirical sample (N=2) cannot settle it; this spec names the deciding statistic and the revisit trigger, and drafts the text edits for every direction.

## Key Points

- **The exact question for the human (answerable in one line):** *"Direction A, B, C, or D?"* — A: seat the pre-PR focused re-review's closing round at **deferred** fable via the inherit rule; B: downgrade the child-PR post-fix re-round to `opus` (requires a DR-003 supersede entry); C: give `focused-re-review` its **own deferred policy row** as a first-class gate; D: ratify the status quo — keep `:55` at `opus` and write the downstream-backstop principle into `AGENTS.md` as stated doctrine.
- **The choice is between principles, not just pins.** A/C encode *parity*: "a post-fix re-round that re-establishes gate-clean carries its gate's fable policy." D encodes *downstream backstop bounded at the merge*: "a fable seat is required only where no fable seat lies downstream of the delta before the next irreversible step — and merge-into-epic is that step." B encodes *unbounded backstop*: epic-integration + the make-up round also count, so neither re-round needs a seat. Exactly one becomes written doctrine (`AGENTS.md:54` rewritten); the others are rejected by name.
- **Direction A/C fable bill:** +1 **deferred** fable dispatch per ticket that takes a verify-stage product-code fix (a routine path — `deliver-playbook.md:29`), plus one more `FABLE_MAKEUP` obligation in the already-batched `submit-epic-pr` make-up round when substituted. **No new hard seat ⇒ no new park edge**; no ticket class parks that does not park today. A and C are bill-identical; they differ only in doctrinal mechanism (inherit sentence vs own table row) and in how they answer the own-gate-vs-sub-loop question.
- **Direction B fable bill:** −1 fable dispatch per child-PR fix loop, and `needs-capable-delivery` tickets **lose an inelastic hard seat** — today the seat that makes exactly those tickets park under scarcity (`AGENTS.md:50`). Cheaper and unblocks capable-tier tickets, but on those tickets the fix worker is already `opus`, so an `opus` re-round is opus reviewing opus on invariant-dense work — the failure mode `AGENTS.md:40` names as the reason capable-tier delivery exists. **B also removes a fable seat, which epic canon DR-003 rules out of contract** ("any child spec proposing a seat removal as its solution is out of contract"); choosing B therefore requires the human to also supersede DR-003 for this ticket, recorded in the same register entry.
- **Direction D fable bill: zero.** No seat moves, no park edge changes. Its cost is doctrinal: the backstop principle must be written down (it currently lives in one unargued parenthetical, `docs/specs/2026-07-07-execution-model-flatten-design.md:138`), and open question 3 must be answered in the same breath — merge-into-epic is the irreversible step that ends backstop credit, which is what keeps `:47`'s seat justified while `:55` stays seatless.
- **Field evidence: the ambiguity already bites.** Only two `gate-ledger: focused-re-review` lines exist in the PM system, and they disagree: DOD-1098 closed `final=opus` (the shipped `:55` pin), DOD-990 closed `final=fable` (the literal inherit rule). Two sessions performed the same lookup and got different answers — the defect `AGENTS.md:46` ("pre-declared per gate, never improvised mid-lane") exists regardless of which direction wins.
- **The empirical sample cannot decide today.** The deciding statistic (how often child-PR fable rounds catch defects *located in the verify-stage fix delta* that the `opus` focused re-review passed) needs per-finding location analysis over N≥10 paired occurrences; N=2 exists. The honest outcome is a human ruling on doctrine now plus the named revisit trigger in § Evidence.
- ⚠ **Assumption to confirm at ruling:** the operator's binding constraint is inelastic **hard** seats (park edges), not total fable dispatch count. The epic partially confirms (batched make-up compresses deferred cost to one round per epic) and partially cuts against it (the allowance runs to 100% utilization every cycle, so added dispatches are not free). A and C are cheap under the hard-seat reading, expensive under the utilization reading; D is free under both.
- **Everything below the fork is drafted:** register-entry template, `AGENTS.md` rewrite per direction, `review/SKILL.md` `:47`/`:55` replacement text per direction, prompt-file deltas, validator pins with the negative assertion, five-file version lockstep. Implementation is mechanical once the ruling lands.

## Problem (verified in this worktree)

- `dodi-dev/skills/review/SKILL.md:47` — child-PR fix loop: "a **focused re-round at the gate's fable seat** aimed at the fix delta — it inherits the child-PR final's fable-policy (**hard** on `needs-capable-delivery`, **deferred** on standard-tier), since it is the round that re-establishes gate-clean, not a confirmation sweep."
- `dodi-dev/skills/review/SKILL.md:55` — pre-PR/verify-stage: "**Focused re-review** … a fresh reviewer at Capable tier (`model: opus` on Claude Code) … a scoped instance of the review fix loop … under the pre-PR loop's cap." No fable seat. The justification `:47` gives for its seat ("the round that re-establishes gate-clean") is verbatim true of `:55`.
- `AGENTS.md:54` — "Focused post-fix re-rounds inherit their gate's policy" — stated generally, instantiated only for child-PR. The pre-PR gate's own final **is** a fable seat (`review/SKILL.md:35`), assigned **deferred** at `AGENTS.md:51`, so the literal inherit reading gives `:55` a deferred fable seat, contradicting the shipped `opus` pin.
- `AGENTS.md:52` puts "post-clean-pass confirmation sweeps" in **soft**; `:55` is classified neither as an inheriting re-round nor as a sweep.
- The only written justification for the asymmetry is one unargued parenthetical: `docs/specs/2026-07-07-execution-model-flatten-design.md:138` — "(The pre-PR focused re-review is an opus seat and needs no row.)" — inside a paragraph that argues at length for `:47`'s seat.
- **Structural ambiguity underneath:** `:55` says the re-review runs "under the pre-PR loop's cap" (a sub-loop), but the ledger treats `focused-re-review` as a first-class gate — its own `caught-by` gate token (`review/SKILL.md:62`), its own covered ledger gate (`:77`), its own posting surface (`:80`, the `ready-for-child-pr` checkpoint; mirrored at `epic-orchestrator/state-transitions.md:33`). An independent gate has no parent to inherit from — under that reading the inherit rule is inapplicable and the policy table is missing a row, which is itself the `AGENTS.md:54` defect shape ("a fable seat without a row is a defect" — cutting the other way, a *gate* without a declared policy).
- **The ambiguity has produced divergent behavior in the field.** PM-comment aggregation (2026-08-28) finds exactly two `gate-ledger: focused-re-review` lines ever posted:
  - DOD-1098 (`needs-capable-delivery`): `gate-ledger: focused-re-review rounds=1 findings=0/4 outcome=clean final=opus` — the shipped `:55` pin.
  - DOD-990: `gate-ledger: focused-re-review rounds=1 findings=0/0 outcome=clean final=fable` — the literal inherit rule.

  Same lookup, two answers. `execution-model.md:15` mandates this lookup "immediately before the pin is written"; today it cannot be performed deterministically.

## The question for the human

**Pick one direction — answer "A", "B", "C", or "D".** Each direction is one principle made doctrine; the table is the whole decision.

| | Principle written into `AGENTS.md` | `:55` (pre-PR focused re-review) | `:47` (child-PR re-round) | Fable-bill delta | Park-edge delta | Ticket classes affected | Canon fit |
|---|---|---|---|---|---|---|---|
| **A** | Parity via inherit: re-rounds inherit their gate's policy — and `focused-re-review`'s gate is **pre-PR** (sub-loop reading) | closing round gains a **deferred** fable seat | unchanged | **+1 deferred** per ticket with a verify-stage product fix; +1 batched `FABLE_MAKEUP` when substituted | none (deferred substitutes, never parks) | every ticket (standard + capable) that takes a verify-stage fix | Compatible with DR-001..005 |
| **B** | Downstream backstop, credit extends past merge-into-epic (epic-integration + make-up rounds count) | unchanged (`opus`) | **downgraded to `opus`** | **−1 fable** per child-PR fix loop | **removes a hard seat** on `needs-capable-delivery` — those tickets stop parking at this point | tickets with child-PR fix loops; hard-seat removal hits `needs-capable-delivery` specifically | **Conflicts with DR-003** ("removes no fable seat… out of contract") — requires an explicit supersede entry; also strains `AGENTS.md:40` (opus reviewing opus on invariant-dense work) and `AGENTS.md:38` ("never economize") |
| **C** | `focused-re-review` is a **first-class gate** (as the ledger already treats it) with its **own deferred row** in the policy table; the inherit sentence is narrowed to same-gate re-rounds (i.e. `:47` only) | closing round gains a **deferred** fable seat (via its own row) | unchanged | same as A | same as A (none) | same as A | Compatible; directly satisfies DR-004's "every seat maps to a row" standard and resolves open question 1 in the ledger's favor |
| **D** | Downstream backstop, credit **ends at merge-into-epic** (the irreversible step): a fable seat is required only where no fable seat lies downstream of the delta before the next irreversible step — the verify-stage fix delta is by construction "new or changed since the pre-PR gate", so the child-PR `opus`+`fable` pair (`review/SKILL.md:56`) is its declared backstop | unchanged (`opus`), now justified by stated doctrine, declared **not a fable seat** (needs no row) | unchanged (justified: no fable look between it and the merge) | **zero** | none | none | Compatible; promotes the `2026-07-07:138` parenthetical to argued doctrine and answers open question 3 (merge bounds the credit) |

Secondary confirmations requested with the ruling (one word each, defaults stated):

1. **Constraint model** — is the binding constraint hard seats (park edges) or total fable dispatches? Default assumed: hard seats (per the epic's "deferred is cheap in seats and expensive only in latency"). Relevant only to A/C vs D.
2. **If B:** confirm the DR-003 supersede explicitly, and confirm whether B applies on `needs-capable-delivery` tickets too (an `opus` re-round after an `opus` fix worker) or only on standard-tier — a standard-only B is a partial resolution and still needs the doctrine sentence for the capable case.

## Evidence — what the ledger can and cannot settle

**Deciding statistic (named operationally):** over tickets where a verify-stage product-code fix occurred — identified by a `gate-ledger: focused-re-review` line in the `ready-for-child-pr` checkpoint evidence (`review/SKILL.md:80`) — pair that line with the same ticket's `caught-by: child-pr/<round>/fable` tags, and classify each child-PR fable-round blocking finding by **location: inside vs outside the verify-stage fix delta** (the delta range is recorded in the focused re-review's dispatch context and the checkpoint evidence). If child-PR fable rounds repeatedly catch fix-delta-located blockers that the `opus` focused round passed, the seat is earning its place ⇒ A/C. If across the sample they never do, the backstop is empirically sufficient ⇒ D (or B, if the same analysis on `:47`'s catches against epic-integration/make-up catches also comes back empty).

**What exists today (queried 2026-08-28):** N=2 focused-re-review occurrences (DOD-1098, DOD-990). DOD-1098's subsequent child-PR gate posted `gate-ledger: child-pr rounds=2 findings=5/0,2/0 outcome=clean final=fable` — 7 blocking findings after the `opus` focused round passed — but the detailed findings are test-quality and doc-drift catches (tests did not exist at the pre-PR gate, so they are child-PR-native, not fix-delta escapes); location classification is not derivable from the ledger line alone and requires reading each finding. DOD-990's focused round found nothing and nothing followed. **N=2 with confounded locations decides nothing.**

**Revisit trigger (record in the register entry):** when N≥10 tickets carry a `focused-re-review` ledger line paired with a completed child-PR ledger, run the location analysis above and re-open the bucket assignment as an evidence-based reclassification (the purpose `AGENTS.md:62` assigns to the `tier-degraded` marker data). Until then the ruling is doctrinal.

**One datum that is already decision-grade:** the two shipped occurrences closed at different tiers. Whatever the ruling, the resolved doctrine must make the `execution-model.md:15` lookup deterministic — that part is common to all four directions.

## Design — common core (all directions)

These items are identical whichever direction is ruled; they can be planned immediately.

### 1. Decision-register entry (epic DOD-1213)

Append an entry comment and a canon-table row (DR-006) recording: the chosen direction, the principle stated in one sentence, the rejected principles by name, the fable-bill consequence, the revisit trigger (N≥10 pairing analysis above), and — iff B — the DR-003 supersede with its rationale. The epic description's `## Decision Register — Canon` table gains the row per `AGENTS.md` § Decision Register.

### 2. `AGENTS.md:54` rewrite — the lookup must be deterministic

Whatever the direction, the sentence following the gate-policy table is rewritten so that a reader who knows only `AGENTS.md` can state the pin for a verify-stage post-fix focused re-review on both a standard-tier and a `needs-capable-delivery` ticket (the acceptance criterion's manual read-through). The current general-rule-plus-one-instantiation shape is the defect; the replacement states the operative principle and instantiates it for **both** re-rounds by name. Direction-specific text in § Forked design.

### 3. Validator pins (`scripts/validate-phase-skills.sh`)

Following the existing `grep -qF --` style:

- **Positive pins:** exact-string assertions on (a) the resolved `:55` bullet's tier clause, (b) the resolved `:47` fix-loop clause, (c) the resolved `AGENTS.md` doctrine sentence.
- **Negative assertion (asymmetry cannot silently reappear):** the script fails if `review/SKILL.md` contains both a fable-seat phrase on one post-fix re-round and a Capable pin on the other **without** the `AGENTS.md` doctrine sentence present — implemented as: assert the doctrine sentence's presence in `AGENTS.md` (deleting the justification breaks the build), verified during implementation by deleting it in a scratch copy and confirming non-zero exit.
- The existing tier self-declaration check (`grep -qE '\((Frontier|Capable|Standard|Fast) tier'`) already covers the prompt files; directions that change a prompt's seat set extend the prompt text, not the check.

### 4. Release mechanics

Five version-bearing files bump in lockstep off the then-current version (0.16.4 at drafting; siblings DOD-1214..1217 may land first — take current+1): `.claude-plugin/marketplace.json`, `dodi-dev/.claude-plugin/plugin.json`, `dodi-dev/.codex-plugin/plugin.json`, `.grok-plugin/marketplace.json`, `dodi-dev/.grok-plugin/plugin.json`. Tag `vX.Y.Z`; bare version string in the commit message. `.agents/plugins/marketplace.json` carries no version key — do not add one. Full battery: `validate-plugin-metadata.sh && validate-phase-skills.sh && validate-ticket-comment-templates.sh`.

### 5. Invariants that hold in every direction

- No change to the pre-PR final (`review/SKILL.md:35`), the child-PR integration pair (`:44–:46`), the ledger/catch grammar (`:62–:81`), the park/make-up machinery, or `hook-require-model-pin.sh`.
- Harness-specific tier mentions use the Claude form plus tier name ("Frontier tier (`model: fable` on Claude Code)").
- No skill file references a repo-only document.
- All tier mentions follow whatever vocabulary DOD-1214 has merged by implementation time (`<tier>@<effort>` if its doctrine slice has landed) — a mechanical rebase concern, not a decision.

## Design — forked by direction

Exactly one subsection applies after the ruling. Replacement text is normative in substance; final wording at implementation.

### Direction A — seat `:55` via the inherit rule (pre-PR sub-loop reading)

**Seat shape (⚠ design decision within A, mirrors the parent gate):** the focused re-review keeps `opus` per-round and gains a **closing round at the gate's fable seat** — the same structure as the pre-PR gate it inherits from (opus rounds + fable final), rather than the child-PR shape (every post-fix re-round at fable). Cost is exactly +1 deferred dispatch per occurrence.

- `review/SKILL.md:55` → "…a fresh reviewer at Capable tier (`model: opus` on Claude Code) reads the fix delta plus its blast surface … a scoped instance of the review fix loop under the pre-PR loop's cap, **closing at its gate's fable seat: the round that re-establishes gate-clean runs at Frontier tier (`model: fable` on Claude Code) under the pre-PR gate's deferred fable-policy** (AGENTS.md § Fable Availability Policy), substitution attributed and the make-up obligation queued as usual."
- `AGENTS.md:54` → "Focused post-fix re-rounds inherit their gate's policy — the round that re-establishes gate-clean is that gate's fable seat: the child-PR post-fix re-round is hard on capable-tier, deferred on standard-tier; the pre-PR verify-stage focused re-review closes at the pre-PR gate's deferred seat. Neither is a confirmation sweep."
- `review-prompt.md:3` — tier self-declaration gains the focused re-review's Frontier closing round ("the final gate round **and the focused re-review's closing round** use `model: fable`… match this dispatch's pin").
- `state-transitions.md:33` / `deliver-playbook.md:17,29,49` — the boundary requirement ("focused re-review clean if fixes occurred") is unchanged in meaning; `deliver-playbook.md:17`'s verify row gains the fable-policy note ("focused re-review closing round Frontier (`fable`), **deferred**") to match the table's convention of naming seats per phase — all four surfaces move together or not at all.
- `docs/specs/2026-07-07…:138`'s parenthetical is historical record — never edited.

### Direction B — downgrade `:47` to `opus` (unbounded backstop; requires DR-003 supersede)

- `review/SKILL.md:47` → the focused re-round becomes "a **focused re-round at Capable tier (`model: opus` on Claude Code)** aimed at the fix delta"; the inherit-justification clause is deleted. `:48`'s gate-clean sentence is unaffected (the child-PR **final** keeps its seat; only post-fix re-rounds move).
- **Gate-clean consequence to state explicitly:** after a fix, the gate re-establishes clean via an `opus` round even though the final that originally cleaned was `fable`. The doctrine sentence must say the epic-integration round + make-up round are the declared fable backstop for post-fix deltas — and, per open question 3, that merge-into-epic does **not** end backstop credit.
- `child-pr-integration-prompt.md:3,6,10,16` — every "focused re-round … `model: fable`" mention becomes `model: opus` / Capable tier; tier self-declaration updated to match.
- `AGENTS.md:54` → the inherit sentence is replaced by the backstop principle: "Post-fix focused re-rounds run at Capable tier; a fable seat is required only where no fable seat lies downstream of the delta before the epic PR opens — the child-PR integration final backs the verify-stage delta, and the epic-integration and make-up rounds back the child-PR fix delta." The hard-bucket Gates cell at `:50` loses nothing (the capable-tier child-PR **final** stays hard) but the parenthetical naming the re-round's inherited hard/deferred split is deleted.
- **Register entry must carry the DR-003 supersede** and the `AGENTS.md:40` exception acknowledgment (opus fix worker re-reviewed by opus re-round on capable-tier tickets — no longer a `tier-degraded`-attributed exception but the designed behavior).

### Direction C — own policy row (first-class gate reading)

- `AGENTS.md` gate-policy table, **deferred** row Gates cell gains: "the `focused-re-review` gate's closing round (verify-stage post-fix; a first-class ledger gate — its own row, not an inheritance)".
- `AGENTS.md:54` inherit sentence is **narrowed**: "Focused post-fix re-rounds *within a gate's own loop* inherit that gate's policy (the child-PR post-fix re-round is hard on capable-tier, deferred on standard-tier); `focused-re-review` is its own gate — it posts its own ledger line to its own surface — and carries its own row above."
- `review/SKILL.md:55` → same closing-seat text as Direction A, except the policy citation is "under its own deferred fable-policy row" and the "under the pre-PR loop's cap" clause is retained purely as a round-budget statement (the cap is shared; the gate identity is not) — one added clarifying clause resolves the sub-loop/own-gate tension in the ledger's favor.
- `review-prompt.md:3`, four orchestrator surfaces: as Direction A.

### Direction D — ratify the status quo (backstop bounded at merge)

- `review/SKILL.md:55` → unchanged pin; gains one justification clause: "…(`model: opus` on Claude Code) — **deliberately not a fable seat: the fix delta is by construction 'new or changed since the pre-PR gate', so the child-PR integration pair is its declared Frontier backstop before the merge** —…".
- `AGENTS.md:54` → the inherit sentence is replaced by the bounded-backstop principle: "A post-fix re-round carries its gate's fable policy when it is the last look before an irreversible step (the child-PR re-round guards the merge into the epic branch: hard on capable-tier, deferred on standard-tier); a re-round whose delta still faces a downstream fable seat before that step runs at Capable — the verify-stage focused re-review's delta faces the child-PR integration final, so it is an `opus` seat and needs no row."
- No prompt files, no orchestrator surfaces, no table rows change. The validator pins (common core §3) are the entire mechanical delta beyond the two doctrine sentences.
- Register entry records the promoted principle and explicitly answers open question 3: merge-into-epic ends backstop credit, which is why `:47` keeps its seat.

## Open-question mapping (ticket's 7 → resolution per direction)

1. **Own gate or sub-loop?** A: sub-loop (inherits from pre-PR). C: own gate (own row; ledger reading wins). B/D: moot for policy (no seat), but D's doctrine sentence should note the ledger gate identity stands for attribution regardless.
2. **Which principle governs?** The ruling itself — parity (A/C), bounded backstop (D), unbounded backstop (B).
3. **Does backstop credit survive the merge?** B: yes (that is B's principle). D: no (merge bounds it — stated in the doctrine sentence). A/C: not load-bearing.
4. **Is a deferred seat on a fires-only-on-fix gate acceptable?** The A/C-vs-D half of the ruling; the batched make-up round's marginal cost is scope size, not extra rounds.
5. **Does B break writer-≠-final-gate on capable-tier?** Substantively yes-adjacent: the final gate (child-PR final) remains fable, but the round that re-establishes clean after an `opus` fix would be `opus` — the register entry must own this if B is chosen, or B is confined to standard-tier (secondary confirmation 2).
6. **Deciding ledger sample?** Named in § Evidence; N=2 today, insufficient; revisit trigger at N≥10 recorded in the register entry.
7. **Does the spec-review-hard/plan-review-deferred precedent generalize?** It licenses *justified* asymmetry, not asymmetry per se — its justification (canon consumption downstream) is argued in `AGENTS.md:54`'s final sentence. D meets that bar by writing an equivalent argument; the current shipped state does not (one parenthetical), which is why the status quo can only survive as D, never as "no change".

## Acceptance criteria and testing contract

The ticket's acceptance criteria are adopted verbatim; direction-conditional criteria resolve per the fork ("`grep -n \"focused re-round at the gate's fable seat\"` hits iff A/C/D, empty iff B", etc.). The testing contract is the ticket's: validator wording pins with the negative assertion (common core §3), metadata lockstep, full three-script battery, and the manual read-through — a reader with only `AGENTS.md` § Fable Availability Policy + `execution-model.md` §2 states the pin for a verify-stage post-fix re-review on a standard-tier and a `needs-capable-delivery` ticket, both answers recorded in the PR body. No new test harness; no shell script changes.

## Delegated assumptions (all non-blocking, ⚠)

- **A/C seat shape:** the fable seat is the *closing* round only (mirroring the pre-PR gate's opus-rounds-plus-fable-final structure), not every post-fix round (the child-PR shape). Bounds cost at exactly +1 deferred dispatch per occurrence; overridable at plan review.
- **Version number:** current+1 off whatever siblings have merged; chosen at implementation.
- **Vocabulary:** if DOD-1214's `<tier>@<effort>` doctrine has merged by implementation, new tier mentions adopt it mechanically.
- **DOD-990/DOD-1098 ledger reading:** treated as one occurrence each; neither ticket's outcome is used as evidence for a direction, only as proof the lookup is non-deterministic.

## Status

**QUESTIONS_FOR_HUMAN.** This ticket carries `needs-human-spec`: explicit human signoff on the direction is required before planning starts, regardless of draft completeness. The one-line answer needed: **"Direction A, B, C, or D?"** (plus the two secondary confirmations in § The question for the human). On receipt, record DR-006 on the epic and proceed to `write-plan` against the matching forked subsection plus the common core.
