---
name: mature-ticket
description: Use when a child ticket lacks spec-ready or ready-to-implement and needs specification, plan, review, or human input
model: fable
---

# Mature Ticket

Move a child ticket through spec and plan maturity gates under the two-gate model: Gate 1 epic signoff (`epic-signed-off` + delegation comment on the epic) is the recorded delegation for every child, so routine per-child signoff is not required. The escape hatches below preserve human input where it genuinely matters.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child lacks `spec-ready` or `ready-to-implement` | ticket id, current artifacts, dependency context, Gate 1 delegation record | clean spec, clean plan, readiness label decision | artifact links, reviewer evidence, assumptions, labels | spec drafter, spec reviewer, plan writer, plan reviewer | needs human spec input, unresolved dependency, review findings, spec/plan mismatch |

## Signoff Model

- **Default (Gate 1 delegated):** if the epic carries `epic-signed-off`, proceed spec → plan → readiness labels without waiting on a human. Record delegated assumptions (⚠-flagged) in the spec and ticket comment.
- **Per-child gate:** if the child carries `needs-human-spec`, require explicit human signoff on the spec before write-plan — the pre-Gate-1 behavior.
- **Genuine ambiguity:** if the spec drafter returns `QUESTIONS_FOR_HUMAN`, stop and ask regardless of delegation. Delegation covers routine choices, not open product questions.
- If the epic carries neither `epic-signed-off` nor a per-child signoff, do not enter planning — report `awaiting-epic-signoff` to the orchestrator.

## Model Tiers

The `model: fable` frontmatter pin covers this skill's main loop only — it never flows into worker dispatches. Every dispatch carries its own explicit pin: spec drafter, spec/plan reviewers, and plan writer carry Frontier pins in their prompt templates; research and read-and-digest workers (external/integration API docs, test-harness orientation, codebase exploration) pin Standard tier (`model: sonnet` on Claude Code). A dispatch without a pin inherits `fable` — that is a defect, not a default.

**Execution model (0.14.1 interim):** never run this skill as a dispatched subagent. Verified harness limitation (2026-07-05): a subagent that dispatches its own worker (drafter, reviewer) and ends its turn is never woken — the completion notification routes to the top-level session instead, and no blocking dispatch mode exists. The top-level session (the resident driver or an interactive session) executes this sequence **inline**; every dispatch it makes is a **leaf** worker whose prompt carries the leaf rule (work directly; never dispatch sub-agents; the final message is the result), awaited via dual-wake (native notification primary, `await-worker.sh` backstop). The 0.15.0 flatten redesign owns the durable architecture.

## Process

- Draft the spec — dispatch a spec-drafter subagent (see spec-drafter-prompt.md); the main loop coordinates and runs review loops. Specs lead with the scannable header (`## TL;DR` + `## Key Points`).
- The epic's **decision register canon summary** (the `## Decision Register — Canon` section of the epic description) is required drafter and reviewer input: canonical decisions from already-merged siblings bind this spec. A spec that contradicts a canon decision is a review finding.
- **Pre-register epics** (no canon summary exists — the epic predates the register): proceed and note its absence in the artifact; absence is not a blocker and does not trigger a retroactive review from this skill. The epic's first coherence review seeds the register, bootstrapping prior canon at depth proportional to artifact quality (per the coherence-reviewer prompt).
- Run spec review until the final round is clean; a missing or stale scannable header is a review finding.
- Run write-plan after the spec is clean (and signed off, where the Signoff Model requires it).
- **Ephemeral worktree, per-gate push-back:** maturity runs in an ephemeral worktree off the epic branch. Push back to the epic branch at **each gate transition before** posting that gate's comment/label — `dispatch-eligible.sh` checks labels, not artifact presence, so a durable label against an artifact in a dangling worktree would arm dispatch against a missing plan. Cite SHAs only post-push (patch-id fallback per the 0.13.5 precedent). Layering rule: claims serialize tickets; worktrees serialize files; nothing serializes runs.
- Run plan review until the final round is clean.
- Apply `spec-ready` after clean spec review; apply `ready-to-implement` only after clean plan review and dependency check.
- Do not move to implementation without both labels.

## Evidence

- Record spec artifact, plan artifact, reviewer type, review status, assumptions, dependency state, and labels applied or withheld.
- Record which signoff path applied: Gate 1 delegation (link the epic delegation comment), per-child signoff, or human answers to drafter questions.
- Record why any ticket remains in maturity work.

## Stop Conditions

- Stop for `awaiting-epic-signoff`, `QUESTIONS_FOR_HUMAN`, unresolved dependency, review findings, or spec/plan mismatch.
- Stop if the plan cannot define required unit, integration, and e2e test groups.
- Stop before implementation unless `spec-ready` and `ready-to-implement` are present.
