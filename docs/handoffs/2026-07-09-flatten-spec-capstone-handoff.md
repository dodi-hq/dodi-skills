# Flatten Spec (DOD-796) — Fable Capstone Findings Handoff (2026-07-09)

## TL;DR

The 0.16.0 flatten-redesign spec (`docs/specs/2026-07-07-execution-model-flatten-design.md`, epic DOD-796) completed its opus 3-lens review loop clean at round 9 (commit `5147fd3`). The follow-on fable holistic capstone then found **2 blocking cross-cutting defects** the lens loop was structurally blind to, plus 3 advisories. **Holding here before any fold or implementation** — both blocking findings require a design choice, not a mechanical fix, and Mike/the user asked to pause and review before proceeding.

## Key Points

- **Spec state:** `docs/specs/2026-07-07-execution-model-flatten-design.md` on `epic-DOD-796`, HEAD `5147fd3`, tree clean. Opus 3-lens loop (coverage-loss / canon-coherence / groundedness) ran rounds 1–9 (`e7d1d3e`..`5147fd3`); round 9 returned zero blocking across all three lenses — convergence rule satisfied.
- **Capstone findings NOT yet folded.** The fable holistic capstone (dispatched after round-9 convergence, per the 0.14/0.15 precedent of a whole-artifact pass after the lens loop clears) found 2 blocking + 3 advisory. Full findings below. **No spec edits have been made for these** — this doc exists specifically so nothing is lost while we pause.
- **Blocking #1 — hard-park resume story is deliver-lane-only, but 2 of 3 ratified hard fable gates live in mature.** Needs a design choice: extend RESUMABLE/checkpoint/continuation-brief machinery to the mature lane, or add a narrower intra-gate push-back rule scoped to the park case only.
- **Blocking #2 — waterfall mode's maturation phase has zero merges, so C4's merge-triggered refresh never fires during it**, leaving only emergency bloat-park (which C4's own rationale says should be the exception). Needs a choice: count lane close-outs (not just merges) toward the refresh budget, add a maturation-only refresh point, or explicitly exempt the phase with stated rationale.
- **3 advisories, all mechanical/cheap once a direction is picked:** mode-decision tier/re-evaluation mechanism unspecified (haiku-pinned `assess-epic` deciding a judgment call — contradicts AGENTS.md's own "escalate tier for judgment" doctrine); two stale "tick" references survived the grep-clean sweep (`AGENTS.md:86` is the substantive one); `state-transitions.md`'s `epic-ready-for-pr` row doesn't surface C3's new FABLE_MAKEUP pre-freeze gate.
- **Next steps once unblocked:** fold the two blocking findings (design choice + edit) and the 3 advisories → likely a second **confirmation** capstone (per the 0.14.0/0.15.0 precedent: every substantial capstone fold got a second holistic pass, and both times it earned its keep — 0.14.0's caught 5 more polish items, 0.15.0's caught 2 new blocking in the corner the first fold touched) → Gate 1 signoff request to Mike → children filed (Decomposition Sketch: C1a→C1b→{C2,C3,C4}→C5) → drive-epic takes over per its own guard (verified inert pre-Gate-1 by direct test this session).
- **No children filed, no Gate 1 signoff requested, no implementation started.** DOD-796 is still `Backlog`, zero children, zero labels.

---

## Full capstone findings (verbatim from the review, for the record)

### Blocking 1 — C3's hard-park resume story doesn't hold for the mature lane

C3 §Mechanics 2 says a mid-lane `pending-capacity` park resumes because "the successor resumes the lane from its durable checkpoints (the existing RESUMABLE machinery — the CAPACITY_PARK entry's recorded dispatch is the resume key)." But of the three Mike-ruled hard gates, two (spec authoring, final spec-review) live in the **mature** lane, and the mature lane has no Lane Checkpoint contract (`state-transitions.md`'s checkpoint table is explicitly "inside deliver-ticket"), no `RESUMABLE` exit state (`mature-ticket`'s contract/Stop Conditions: `awaiting-epic-signoff`, `QUESTIONS_FOR_HUMAN`, dependency, findings, mismatch — no resumable exit), no continuation-brief mechanics, and the priority table's resume-RESUMABLE slot (migrating from `pickup-next:33` into C2's table) covers deliver lanes only.

Worse: the mature playbook's **per-gate push-back rule** (C1a preserves it verbatim from `mature-ticket/SKILL.md:37`) pushes artifacts only *at gate transitions*. So at the **final spec-review round** (a hard gate), the entire drafted-and-loop-reviewed spec sits unpushed in an ephemeral worktree. A hard park there loses the maximum possible unpushed work at the single most likely hard-park site; the successor re-enters `mature-ticket` cold, redrafts from scratch, and burns another **hard fable spec-authoring dispatch** — spending the scarcest resource precisely under the scarcity condition the park exists to respect. Also unspecified: what exit state the parked mature lane's *ticket claim* carries (deliver has `RESUMABLE`; mature has nothing).

*Why the lens loop missed it:* groundedness on C3 confirms "the existing RESUMABLE machinery" exists (it does — in deliver-ticket); coverage on C3 confirms every fable seat has a policy row. Only mapping the hard bucket's gates onto **which lane owns each gate's durability machinery** — a C3×C1a cross-child read — exposes that the resume claim is false for two of three ratified hard gates.

*Fix direction (needs a choice):*
- **(a) Bigger/symmetric:** extend RESUMABLE/checkpoint/continuation-brief mechanics to the mature playbook, matching deliver.
- **(b) Narrower:** add a park-persistence rule to the mature playbook — push the ephemeral worktree's in-progress artifacts back to the epic branch before any hard `pending-capacity` park (an intra-gate variant of the existing push-back rule), and define a mature-lane resume record (the CAPACITY_PARK entry keys to the pushed artifact SHA + loop position).
- C3 then cites whichever mechanism is chosen instead of the deliver-only machinery it currently (incorrectly) cites.

### Blocking 2 — C2's waterfall mode structurally disables C4's planned refresh for exactly the phase that needs it most

C4's trigger is "merges-this-session ≥ budget, evaluated **only at post-merge close-out**." Waterfall is mature-all-then-deliver-all: the entire maturation phase — for a wide epic, the longest stretch of the driver's life, accumulating a dispatch digest, checkpoints, and register traffic per child across spec loop + plan loop — contains **zero merges**, so the refresh trigger cannot fire until the first delivery merge. During that whole phase the only valve is emergency bloat-park, which is precisely what C4's own rationale rules out as a plan: "a degraded context is the worst judge of its own degradation — refresh is the rule, bloat the exception." The rule is unavailable in one of the two shipped modes' first phase; the exception becomes the rule there.

Today's shipped system doesn't have this problem because mature/deliver interleave (sprint-only, today). C2 *creates* the merge-free phase (waterfall) and C4 *assumes* merges pace the session; each is locally sound.

*Why the lens loop missed it:* C2's ordering and C4's trigger are each internally correct and grounded; the defect is only visible by running both riders over one long epic — a seam between two sections no single lens owns.

*Fix direction (needs a choice):*
- **(a)** Count lane close-outs (mature or deliver) toward the refresh budget, not merges only — lane close-out is the same fully-durable seam (fence/release/evidence/reap all complete, nothing in flight by construction), so C4's trigger-point argument carries over unchanged.
- **(b)** Add a maturation-phase-only evaluation point (e.g. every N `ready-to-implement` transitions).
- **(c)** Explicitly exempt the maturation phase from planned refresh, with stated rationale (if judged cheap enough context-wise) — so C4's implementer doesn't build merge-count-only by accident and silently inherit the gap.

### Advisory 3 — mode decision's tier and seam-re-evaluation mechanism are unspecified

C2 homes the sprint/waterfall decision (a judgment call from coupling-graph density, binding epic-wide scheduling, "no third human gate") in `assess-epic`, whose frontmatter is `model: haiku` — the Fast tier AGENTS.md scopes to "state classification," under a doctrine that says "when a task smells like judgment, escalate the tier" (plus the standing intelligence-over-cost decree). Separately, "the driver re-runs the mode evaluation at post-merge close-out and boot audit" never says *how* — inline driver judgment (sonnet), a dispatched worker (which prompt, what pin?), or re-invoking assess-epic (haiku). Same decision: haiku at intake, unspecified at every seam. Ironic beside C3, which pins per-gate model policy exhaustively.

*Fix direction:* one sentence in C2 pinning the mode-evaluation tier (and mechanism at seams) — e.g. the intake decision rides in `assess-epic` at an explicit escalated pin, seam re-evaluation is the driver's own inline judgment over the map it already holds.

### Advisory 4 — two stale "tick" references survive both the grep and C5's six-surface enumeration

`AGENTS.md:86` — "the driver (**or a manual orchestrator session, or the paused tick**) posts a claim comment…" — enumerates a claim-discipline actor that ceases to exist after C5; it carries no `pickup-next` token, so the grep-clean gate passes it, and it is not among the six surfaces C5 names (only `:85` and `:49` are named for AGENTS.md). Milder, same family: `drive-epic/SKILL.md:11` "the principle that retires the tick," `AGENTS.md:48` "a scheduled tick" as a top-level-session class.

*Fix direction:* add `AGENTS.md:86` to C5's sweep (seven surfaces) or to C4's already-open AGENTS.md edits.

### Advisory 5 — `epic-ready-for-pr` state-table row doesn't learn C3's new pre-freeze gate

`state-transitions.md:49` enumerates the evidence gating `epic-pr-open` (regression green, integrated-head review current with head) — precedent is that `submit-epic-pr`'s internal gates *are* surfaced in this row. C3 adds a new one (zero unconsumed `FABLE_MAKEUP` obligations, else `pending-capacity`) but only inside `submit-epic-pr`; the routing canon the driver loads at boot (Boot step 4) never mentions obligations.

*Fix direction:* one clause in the row's Required-evidence cell, added in C3.

---

## Context for whoever picks this up

- This is round 9 + capstone of an established ad-hoc routine (opus 3-lens loop → fable capstone → possible confirmation capstone → Mike's Gate 1 signoff), not yet baked into a checked-in skill/prompt file — see `[[maintainer-thread-state]]` memory for the precedent runs (0.14.0 resident-orchestrator spec, 0.15.0 review-pipeline spec) this session is following.
- Findings 1 and 2 are genuinely cross-cutting (a C3×C1a seam and a C2×C4 seam respectively) — exactly the shape 9 converged lens rounds are structurally positioned to pass individually while missing holistically. Do not re-run the 3-lens checklist on them; they need a design decision + a spec edit, then likely re-verification only in a confirmation capstone.
- `LINEAR_API_KEY` bridge: `~/.linear.env` defines `LINEAR_DODI_API_KEY`; scripts want the literal `LINEAR_API_KEY` name — `export LINEAR_API_KEY="$LINEAR_DODI_API_KEY"` before any `dodi-dev/scripts/*.sh` call.
- DOD-796 Linear comments carry the same status trail (`[PICKUP]`, `[STATUS]` ×2) for anyone reading from the PM side instead of git log.
