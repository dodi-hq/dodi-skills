---
name: implement-ticket
description: Use when a ready child ticket has a child worktree and implementation must follow the reviewed plan exactly
---

# Implement Ticket

Dispatch implementation workers against the clean plan. The implementation must follow the plan exactly; surprises that require judgment return the ticket to the spec lane.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child worktree exists | ticket id, clean spec, clean plan, child worktree | implementation commits or explicit escalation | ticket comment with commit ids, worker evidence, surprise notes | implementation workers only | product decision needed, architecture decision needed, scope surprise, plan mismatch, worker blocked |

## Inputs

- ticket id
- clean spec
- clean plan
- child branch and worktree
- repo instructions
- Testing Contract from the plan

## Process

- Read the clean plan and dispatch bounded implementation workers.
- Require exact plan adherence.
- Demote to the spec lane on product, architecture, scope, or plan mismatch surprises.
- Keep implementation workers scoped to the plan and child worktree.
- Record commits and commands as implementation evidence.
- Do not create PRs or merge branches in Phase 2.

## Evidence

- Record worker status, commit ids, files changed, commands run, and surprise notes.
- Record any demotion reason and the artifact that must be revised.
- The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.
- Durable PM state is the source of truth.

## Stop Conditions

- Stop on product decision, architecture decision, scope surprise, plan mismatch, or worker blocker.
- Stop if implementation cannot follow the plan without new judgment.
- Stop if required dependencies are unavailable.
- Stop at `ready-for-child-pr` only after review, tests, verification, and quality gate are clean.
