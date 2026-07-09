# Mature Playbook

The single statement of the mature lane's sequence: move a child ticket through spec and plan maturity gates under the two-gate model. Gate 1 epic signoff (`epic-signed-off` + delegation comment on the epic) is the recorded delegation for every child, so routine per-child signoff is not required; the escape hatches below preserve human input where it genuinely matters.

The executing session (the resident driver walking this lane inline, or a manual `mature-ticket` session) runs this sequence per the dispatch mechanics in `execution-model.md` (leaf rule, tier pins, dual-wake await, STALLED handling, the `RESUMABLE`/seam/continuation-brief mechanics, manifest discipline). This file never restates those mechanics — it declares only the phase sequence, the durable seams, the durable surface, the exit edges, and the resume key.

## Phase sequence

| Phase | Worker prompt | Tier pin + fable-policy | Marker posted (state transition) | Exit / demotion edge |
| --- | --- | --- | --- | --- |
| Draft spec | `mature-ticket/spec-drafter-prompt.md` | Frontier (`fable`); **hard** | → `spec-reviewing` (draft done) | `QUESTIONS_FOR_HUMAN` ⇒ stop and ask; product/scope surprise ⇒ demote |
| Spec review loop | `brainstorm/spec-reviewer-prompt.md` | Frontier (`fable`); non-final rounds **soft**, **final round hard** | → `needs-plan` — **this transition applies `spec-ready`** | findings ⇒ another round (loop capped, final must be clean); stale/missing scannable header is a finding |
| Write plan | `write-plan/plan-writer-prompt.md` | Frontier (`fable`); **deferred** | → `plan-reviewing` (plan written) | planning exposes product ambiguity ⇒ demote to spec |
| Plan review loop | `write-plan/plan-reviewer-prompt.md` | Frontier (`fable`); non-final rounds **soft**, **final round deferred** | → `ready-to-implement` — **terminal; applies `ready-to-implement` (+ `needs-capable-delivery` on a `capable` verdict)** | findings ⇒ another round; unresolved dependency ⇒ `blocked-dependency` |

fable-policy values are the per-gate policy the executing session looks up (per § 2 of `execution-model.md`) immediately before writing each dispatch's tier pin; the AGENTS.md gate-policy table is authoritative. Research and read-and-digest sub-dispatches within a phase (codebase exploration, external/integration API docs, test-harness orientation) pin Standard (`sonnet`); see § Model tiers.

## Signoff model

- **Default (Gate 1 delegated):** if the epic carries `epic-signed-off`, proceed spec → plan → readiness labels without waiting on a human. Record delegated assumptions (⚠-flagged) in the spec and a ticket comment.
- **Per-child gate:** if the child carries `needs-human-spec`, require explicit human signoff on the spec before write-plan — the pre-Gate-1 behavior.
- **Genuine ambiguity:** if the spec drafter returns `QUESTIONS_FOR_HUMAN`, stop and ask regardless of delegation. Delegation covers routine choices, not open product questions.
- If the epic carries neither `epic-signed-off` nor a per-child signoff, do not enter planning — report `awaiting-epic-signoff` to the orchestrator.

## Process

- **Draft the spec** — dispatch a spec-drafter worker (`mature-ticket/spec-drafter-prompt.md`); the executing session coordinates and runs the review loops. Specs lead with the scannable header (`## TL;DR` + `## Key Points`).
- The epic's **decision register canon summary** (the `## Decision Register — Canon` section of the epic description) is required drafter and reviewer input: canonical decisions from already-merged siblings bind this spec. A spec that contradicts a canon decision is a review finding.
- **Pre-register epics** (no canon summary exists — the epic predates the register): proceed and note its absence in the artifact; absence is not a blocker and does not trigger a retroactive review from this lane. The epic's first coherence review seeds the register, bootstrapping prior canon at depth proportional to artifact quality (per the coherence-reviewer prompt).
- Run **spec review** until the final round is clean; a missing or stale scannable header is a review finding.
- Run **write-plan** after the spec is clean (and signed off, where the Signoff model requires it).
- Run **plan review** until the final round is clean.
- Apply `spec-ready` after clean spec review; apply `ready-to-implement` only after clean plan review and dependency check.
- **Delivery-tier label:** the plan reviewer's output includes a required delivery-tier classification (standard | capable — see `write-plan/plan-reviewer-prompt.md`). If **any** chunk's final clean round classifies `capable`, apply `needs-capable-delivery` at the same gate transition as `ready-to-implement`, before the gate comment. The label routes every implementer and fix worker in the delivery lane to Capable tier (`opus`); its absence means Standard-tier delivery. Escalation is pre-routed here, never improvised mid-lane.
- Do not move to implementation without both labels.

### Ephemeral worktree, per-gate push-back

Maturity runs in an ephemeral worktree off the epic branch. Push back to the epic branch **at each gate transition, before** posting that gate's comment/label — `dispatch-eligible.sh` checks labels, not artifact presence, so a durable label against an artifact in a dangling worktree would arm dispatch against a missing plan. Cite SHAs only post-push (patch-id fallback per the 0.13.5 precedent). Layering rule: claims serialize tickets; worktrees serialize files; nothing serializes runs.

## Durable seams and resumability

The mature lane's **durable progress markers are the completion-anchored state transitions the lane itself effects** — the four in the phase table above: → `spec-reviewing`, → `needs-plan` (where `spec-ready` is applied), → `plan-reviewing`, and → `ready-to-implement` (terminal, applies `ready-to-implement`). These are **not** a separate `# Lane Checkpoint` token layer: the state transition **is** the marker (inventing checkpoint tokens would collide with the `spec-reviewing`/`plan-reviewing` state names). Each is PM-durable and completion-anchored — a label is applied only on clean phase output — so a park at any of them has nothing in flight by construction. `needs-spec` is entered at **assessment**, before this lane starts, so it is not a lane seam. The `spec-ready`/`ready-to-implement` labels are not separate markers — each rides on the transition that applies it.

The lane carries a **`RESUMABLE` exit state** (its ticket claim's exit state when it parks mid-lane), with the same resume-key semantics deliver has. Its **declared durable surface is the epic branch** — its existing per-boundary push target. Before any `RESUMABLE`, hard capacity-park (`pending-capacity`), or `refresh-park` exit, the per-gate push-back additionally fires *before* the exit: the in-progress artifacts are pushed to the epic branch and the continuation brief records that SHA plus the last state boundary as the resume key, so the successor re-enters at the reviewed-but-unpushed spec/plan rather than cold. The `RESUMABLE`/continuation-brief/push-and-record mechanics themselves are the shared, lane-neutral contract in `execution-model.md` § 5; this file declares only that the mature lane's surface is the epic branch and its seams are the four state transitions.

## Model tiers

The `model: fable` frontmatter pin on the manual wrapper covers its main loop only — it never flows into worker dispatches. Every dispatch carries its own explicit pin: spec drafter, spec/plan reviewers, and plan writer carry Frontier pins; research and read-and-digest workers (external/integration API docs, test-harness orientation, codebase exploration) pin Standard tier (`model: sonnet` on Claude Code). A dispatch without a pin inherits the frontmatter default — that is a defect, not a default, and `hook-require-model-pin.sh` forbids it.

## Evidence

- Record spec artifact, plan artifact, reviewer type, review status, assumptions, dependency state, and labels applied or withheld.
- Record the delivery-tier classification (standard | capable) with the reviewer's one-line reason; on `capable`, record the `needs-capable-delivery` label application.
- Record which signoff path applied: Gate 1 delegation (link the epic delegation comment), per-child signoff, or human answers to drafter questions.
- Record why any ticket remains in maturity work.

## Exit states

- **Advance** — `spec-ready` applied (after clean spec review), then `ready-to-implement` (after clean plan review + dependency check).
- **awaiting-epic-signoff** — neither `epic-signed-off` nor a per-child signoff present.
- **QUESTIONS_FOR_HUMAN** — the spec drafter returned open product questions; stop and ask.
- **blocked-dependency** — an unresolved dependency.
- **demote-to-spec** — a product, architecture, scope, or spec/plan mismatch surprise; comment per the demotion rules in `state-transitions.md` and exit. Never redesign mid-flight.
- **RESUMABLE** — a deliberate context exit (capacity-park, refresh-park, or emergency): push to the epic branch, write the continuation brief keyed to that SHA + last seam, and exit for re-dispatch.

## Stop conditions

- Stop for `awaiting-epic-signoff`, `QUESTIONS_FOR_HUMAN`, unresolved dependency, review findings, or spec/plan mismatch.
- Stop if the plan cannot define required unit, integration, and e2e test groups.
- Stop before implementation unless `spec-ready` and `ready-to-implement` are present.
