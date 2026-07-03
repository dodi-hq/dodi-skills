# Epic Coherence Gate & Decision Register Design

## TL;DR

Add a Frontier-tier **epic-coherence review** at the post-merge seam: after each child merges into the epic branch and before any new work is dispatched for that epic, a fable reviewer checks the merged result against the epic's design intent — because every existing review is ticket-local, and small judgment calls compound as later children conform to earlier ones. The **epic ticket itself becomes the master decision register**: every notable judgment call and every verdict lands there as structured comments, and downstream spec drafters, plan writers, and lanes consume it as input. Legitimate divergence (child right, design stale) is a first-class outcome: the register updates, affected children lose their readiness labels, and the tick routes them back through `mature-ticket` automatically — no new machinery.

## Key Points

- **The gap: all current reviews are ticket-local.** Pre-PR review, child-PR review, and quality gate ask "does this child match its own spec/plan?" Nothing asks "does the merged result still match the epic's design?" until the epic PR's full regression — which is functional, not architectural, and arrives after drift has compounded.
- **Drift compounds by construction.** Children build on the merged epic branch and every skill says "follow existing patterns," so child 1's slightly-off judgment call becomes child 3's local convention. Correction cost grows with every merge; the gate runs where it is cheapest — immediately after each merge.
- **New seam in the tick:** after `pickup-next`'s merge action completes, the epic enters `coherence-pending`, which blocks new `deliver-ticket` dispatches and `mature-ticket` planning for that epic until the review clears. Running the review is a tick action, priority just below merges. Serial lanes (the 0.12.0 default) get the full benefit — the gate protects dispatches, not work already in flight.
- **Frontier tier, alignment only.** The coherence reviewer (`model: fable`) reviews the merged diff + child spec against the epic design / Gate 1 package, the decision register, and sibling specs. It does not re-review correctness — that already passed opus rounds. Design-intent alignment is judgment whose quality compounds downstream: the definition of Frontier work.
- **The epic ticket is the master decision register.** Every coherence review appends a register entry comment to the epic: the child's notable judgment calls, the verdict, and any newly canonical decisions. Spec drafters, plan writers, and lanes receive the register as required input — the preventive half that stops the *next* child from drifting the same way.
- **Four verdicts, four routes.** ALIGNED → register entry only. MINOR_DRIFT → register entry + downstream notes; no rework. MATERIAL_DRIFT (child wandered, design right) → corrective ticket sequenced before dependent children; epic holds for dependents until corrected. LEGITIMATE_DIVERGENCE (child right, design stale) → the new decision becomes canonical in the register and affected children are realigned.
- **Realignment is label hygiene, not new machinery.** For each affected child the reviewer names: strip `ready-to-implement` (and `spec-ready` only when the spec itself is invalidated); the tick then routes the child back through `mature-ticket`, whose drafter consumes the updated register. Divergence is judged once, at the seam — never re-derived inside lanes, which stay forbidden from redesigning mid-flight.
- **Gate 1 amendment escape hatch.** A divergence that contradicts what the human explicitly approved at Gate 1 is never canonized by automation: escalate with the scannable header, hold dependent dispatches, and wait. Delegation covers routine choices, not silent rewrites of approved intent.
- **Watch the verdict distribution.** On a well-specified epic most verdicts should be ALIGNED. If the gate never fires beyond that across a few epics, the register alone may be doing the work — revisit whether the review can drop to sampling. The bet is the usual one: a bounded Frontier check per merge against unbounded compounted rework.

---

## Gate Placement in the Tick Model

`pickup-next`'s action priorities gain one slot and one precondition:

1. Merge a `ready-to-merge-child` — unchanged, but its close-out now marks the epic `coherence-pending` instead of leaving it free.
2. **Run the epic-coherence review for a `coherence-pending` epic** (new; outranks everything below so the epic is never blocked longer than one tick).
3. Run `submit-epic-pr` when all children are done — requires the last merge's coherence review clean.
4. Resume a RESUMABLE lane — allowed while `coherence-pending` (the lane predates the merge; stopping it mid-flight loses more than it protects).
5. Dispatch `deliver-ticket` — **blocked for a `coherence-pending` epic.**
6. Run `mature-ticket` — **blocked for a `coherence-pending` epic** (specs drafted against a register about to change are waste).

`coherence-pending` is a label on the epic, applied by the merge close-out and removed by the review's close-out. A crashed review run leaves the label; the next tick re-runs the review (it is read-only until its verdict writes, so re-running is safe). Manual `epic-orchestrator` sessions honor the same label.

With `maxParallelLanes` > 1 a sibling lane may already be in flight when the gate fires; the gate cannot protect it. That lane's own merge gets its own coherence review, which catches conflicts one seam later. This is accepted for now and is one more reason the 0.12.0 serial default should hold until coherence verdicts prove boring.

## Coherence Reviewer

New worker prompt `epic-orchestrator/coherence-reviewer-prompt.md`, dispatched with `model: fable` (Frontier tier) by the tick (or a manual orchestrator session).

Inputs:

- the merged child's diff (merge commit against the pre-merge epic head), spec, and plan
- the epic design artifact and the Gate 1 signoff package (what the human actually approved)
- the current decision register (all register entries on the epic ticket)
- sibling child specs (pending and delivered)

Responsibilities:

- judge **alignment only** — architecture, abstractions, data shapes, responsibility placement, naming conventions, integration-point contracts — against the epic design and register; correctness is already reviewed
- extract the child's notable judgment calls (made silently or explicitly) into register entries, whatever the verdict
- for divergence, decide which side is right: the implementation or the design
- name the affected children explicitly for any verdict that propagates
- flag any divergence that touches Gate-1-approved intent as `GATE1_AMENDMENT` — never canonize it

Output:

- **Verdict:** ALIGNED | MINOR_DRIFT | MATERIAL_DRIFT | LEGITIMATE_DIVERGENCE (+ optional GATE1_AMENDMENT flag)
- **Register entries:** each a one-paragraph decision statement with evidence links
- **Affected children:** ticket ids + which label(s) to strip + one line why, per child
- **Corrective ticket draft** (MATERIAL_DRIFT only): scope, why it must precede dependents

## Verdict Routing

| Verdict | Register write | Child tickets | Epic |
| --- | --- | --- | --- |
| ALIGNED | entries for notable judgment calls | none | clear `coherence-pending` |
| MINOR_DRIFT | entries + drift note naming the convention downstream children must not copy (or must copy — whichever the reviewer rules) | none reworked; affected pending children get a spec-lane note, labels intact | clear `coherence-pending` |
| MATERIAL_DRIFT | entries + the drift ruling | corrective ticket filed (via `file-ticket`) and sequenced before dependent children; dependents' dispatch blocked until it merges | clear `coherence-pending`; dependency map updated |
| LEGITIMATE_DIVERGENCE | the new decision recorded as canonical, superseding the design point (design artifact gets a superseded-by note, never silently edited) | affected children: strip `ready-to-implement`; strip `spec-ready` only if the spec itself is invalidated → tick re-routes through `mature-ticket` with the updated register | clear `coherence-pending` |
| any + GATE1_AMENDMENT | entry marked ⚠ pending human ruling | dependent dispatches held | escalate with scannable header; `coherence-pending` stays until the human rules |

Realignment is deliberately label-driven: no lane ever "checks and repairs" its own instructions. A lane whose plan predates a register change either was named as affected (and lost its labels before dispatch) or was not (and proceeds). Divergence is judged exactly once, at the seam, by the Frontier reviewer with the full picture.

## Decision Register (on the epic ticket)

The epic ticket is the master register. Mechanics:

- Each coherence review appends one **register entry comment** (template: `decision-register-entry`): child id, verdict, decisions recorded (one paragraph each, evidence-linked), affected children, superseded design points.
- Entries are append-only; a later entry may supersede an earlier one by reference, never by editing history.
- The epic description gains a one-line pointer to the register convention so humans and agents know where to look.

Consumers (all gain the register as required input):

- `mature-ticket` spec drafter and `write-plan` plan writer: draft against the register; contradicting a canonical register decision is a review finding.
- `deliver-ticket` lanes: receive the register at pickup as context; still forbidden from redesigning — a perceived register conflict mid-lane is a demote-to-spec surprise, as today.
- The coherence reviewer itself: prior entries are precedent.
- The Gate 1 package and epic readiness summary: link the register so both human gates see the accumulated decisions.

## Out of Scope

- Sampling or skipping coherence reviews on "small" children — run it every merge first; earn the optimization with verdict data.
- Reverting merged children — correction is always forward (corrective ticket), never a revert by automation.
- Coherence checks between concurrent in-flight lanes — covered indirectly at each lane's own merge seam; revisit with `maxParallelLanes` > 1.
- Cross-epic coherence.

## Versioning

Ships as `0.13.0`: new `epic-orchestrator/coherence-reviewer-prompt.md` (fable); `pickup-next` gains the `coherence-pending` action and dispatch blocks; `epic-orchestrator` merge step and state tables gain the seam; `mature-ticket`/spec-drafter, `write-plan`/plan-writer, and `deliver-ticket` gain the register as required input; new `templates/ticket-comments/decision-register-entry.md` wired into validation; AGENTS.md records the register convention.
