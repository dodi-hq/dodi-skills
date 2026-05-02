---
name: epic-orchestrator
description: Top-level local epic workflow orchestrator; dispatches phase skills and workers without implementing, reviewing, or testing directly
---

# Epic Orchestrator

Orchestrate one feature epic from intake through local readiness for child PR creation. Do not implement product code, review code directly, or run tests as the primary actor. Dispatch bounded workers and advance state only from durable evidence.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| Hive starts or resumes work on an epic | epic id, repo path, PM system context | next state decision, dispatched phase work, epic progress summary | epic comments, child ticket comments, labels, artifact links | phase skills, workers, reviewers, test runners | needs human spec input, blocked dependency, tool/auth failure |

## Inputs

- `epicId`
- `repoPath`
- `pmSystem`
- `mode`: `start` or `start-or-resume`
- optional `baseBranch`
- optional `humanContact`
- optional `runLedgerPath`

## Hard Gates

- No ticket enters planning without human spec signoff or explicit delegation.
- No ticket enters implementation without `spec-ready` and `ready-to-implement`.
- Any implementation surprise requiring product, architecture, scope, or plan judgment returns the ticket to the spec lane.
- Phase 2 stops before PR creation. If a ticket reaches local PR readiness, report `ready-for-child-pr` and stop.

## State Reconstruction

1. Read the epic and child tickets from the PM system.
2. Read branch and worktree state.
3. Read the local ledger if present.
4. Prefer PM labels, PM comments, artifact links, and Git state over local ledger entries when they disagree.
5. Choose exactly one allowed next action.

## Process

1. Reconstruct epic and child ticket state from durable evidence.
2. Pick exactly one allowed next action.
3. Dispatch the owning phase skill or worker.
4. Verify evidence before advancing state.
5. Stop at `ready-for-child-pr` in Phase 2.

## Allowed Next Actions

- Run `pickup-epic`.
- Run `assess-epic`.
- Run `mature-ticket`.
- Run `pickup-ticket`.
- Run `implement-ticket`.
- Run `review-implementation`.
- Run `create-tests`.
- Run `verify`.
- Run `quality-gate`.
- Stop for human spec input.
- Stop for a concrete blocker.
- Stop with `ready-for-child-pr`.

## State Transitions

Use only the Phase 2 subset of the child-ticket and epic-level transition tables in `docs/specs/2026-05-02-epic-orchestration-design.md`. Phase 2 ends at `ready-for-child-pr`. Do not execute or encode `child-pr-reviewing`, `ready-to-merge-child`, `done`, `epic-ready-for-pr`, or `epic-pr-open` as active transitions in this release.

## Evidence Rule

Never advance from a worker success claim alone. Verify labels, comments, artifacts, branch/worktree state, commits, or command output first.

The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.

Durable PM state is the source of truth.

## Evidence

- PM labels and comments
- artifact links
- branch and worktree state
- commit ids
- command output
- optional run ledger records

## Stop Conditions

- human spec input required
- tool or auth failure
- blocked dependency
- implementation surprise requiring spec or plan revision
- `ready-for-child-pr`

## Progress Record

Emit progress records with `epicId`, optional `ticketId`, `state`, `action`, `evidence`, `nextAction`, and `needsHuman`.
