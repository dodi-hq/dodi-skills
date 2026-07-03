---
name: mature-ticket
description: Use when a child ticket lacks spec-ready or ready-to-implement and needs specification, plan, review, or human signoff
model: fable
---

# Mature Ticket

Move a child ticket through spec and plan maturity gates. This skill may draft and review artifacts, but it must preserve human signoff before planning unless explicit delegation is recorded.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child lacks `spec-ready` or `ready-to-implement` | ticket id, current artifacts, dependency context, human contact | clean spec, clean plan when allowed, readiness label decision | artifact links, reviewer evidence, assumptions, labels | spec drafter, spec reviewer, plan writer, plan reviewer | needs human spec input, unresolved dependency, review findings, spec/plan mismatch |

## Inputs

- ticket id
- current ticket description and comments
- existing spec or plan artifacts
- dependency context
- human contact or delegation record

## Process

- Draft spec questions or a proposed spec for tickets without spec-ready — dispatch a spec-drafter subagent (see spec-drafter-prompt.md); the main loop coordinates and runs review loops.
- Require human signoff or explicit delegation before write-plan.
- Run spec review until the final round is clean.
- Run write-plan only after spec signoff.
- Run plan review until the final round is clean.
- Apply `spec-ready` only after clean spec review and required human signoff or delegation.
- Apply `ready-to-implement` only after clean plan review and dependency check.
- Do not move to implementation without both labels.

## Evidence

- Record spec artifact, plan artifact, reviewer type, review status, assumptions, dependency state, and labels applied or withheld.
- Record human signoff or explicit delegation before planning.
- Record why any ticket remains in maturity work.
- The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.
- Durable PM state is the source of truth.

## Stop Conditions

- Stop for human spec input, unresolved dependency, review findings, or spec/plan mismatch.
- Stop if the plan cannot define required unit, integration, and e2e test groups.
- Stop before implementation unless `spec-ready` and `ready-to-implement` are present.
- Stop at `ready-for-child-pr` only after downstream local development phases have completed.
