---
name: mature-ticket
description: Use when a child ticket lacks spec-ready or ready-to-implement and needs specification, plan, review, or human input
model: fable
---

# Mature Ticket

Manual entry point for one mature lane — move a child ticket through spec and plan maturity gates under the two-gate model. Gate 1 epic signoff (`epic-signed-off` + delegation comment on the epic) is the recorded delegation for every child, so routine per-child signoff is not required; the escape hatches preserve human input where it genuinely matters.

The lane's sequence, signoff model, per-gate push-back, durable seams, and stop conditions live in **`epic-orchestrator/lanes/mature-playbook.md`**; the dispatch mechanics (leaf rule, tier pins, dual-wake await, STALLED handling, the `RESUMABLE`/seam/continuation-brief mechanics, manifest discipline) live in **`epic-orchestrator/execution-model.md`**. This skill restates neither — it is the manual wrapper that names the contract and the claim discipline, then executes the playbook. In the autonomous epic, the resident driver (`drive-epic`) executes the same playbook inline; this skill is for a single ticket driven by hand.

The `model: fable` frontmatter pin covers this wrapper's main loop only — it never flows into worker dispatches. Every dispatch inside the playbook carries its own explicit pin and fable-policy (per `execution-model.md` § 2); a dispatch without a pin inherits the frontmatter default, which is a defect the tier-pin hook forbids.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child lacks `spec-ready` or `ready-to-implement` | ticket id, current artifacts, dependency context, Gate 1 delegation record | clean spec, clean plan, readiness label decision | artifact links, reviewer evidence, assumptions, labels | spec drafter, spec reviewer, plan writer, plan reviewer | needs human spec input, unresolved dependency, review findings, spec/plan mismatch |

## Claim discipline

Manual invocation is a lane session under the same per-ticket claim discipline the driver applies: claim the ticket first (`${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh <ticket> mature-ticket <session-run-id>`), skipping any live claim from another session per the liveness hierarchy; fence and release the claim with its exit state (`${CLAUDE_PLUGIN_ROOT}/scripts/release-claim.sh <ticket> <exit-state> --session <session-run-id>`) at close-out. Claims serialize tickets; worktrees serialize files; nothing serializes runs.

## Exit states

- **Advance** — `spec-ready` applied (after clean spec review), then `ready-to-implement` (after clean plan review + dependency check, `needs-capable-delivery` where classified).
- **awaiting-epic-signoff** — neither `epic-signed-off` nor a per-child signoff present.
- **QUESTIONS_FOR_HUMAN** — the spec drafter returned open product questions; stop and ask regardless of delegation.
- **blocked-dependency** — an unresolved dependency.
- **demote-to-spec** — a product, architecture, scope, or spec/plan mismatch surprise: comment per the demotion rules in `epic-orchestrator/state-transitions.md` and exit.
- **RESUMABLE** — a deliberate context exit (an emergency reset — capacity-park and refresh-park are driver-only exits, not reachable by a manual session, which stops and reports to the operator instead): push to the epic branch, write the continuation brief, and exit for re-dispatch.
