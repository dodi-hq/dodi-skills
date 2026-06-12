---
name: assess-epic
description: Use when an epic worktree exists and orchestration needs to classify child tickets, dependencies, readiness, and blockers
model: haiku
---

# Assess Epic

Classify the epic and child tickets from durable PM and repository state. This skill decides queues; it does not write specs, implement code, create PRs, or merge branches.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| epic worktree exists or orchestration resumes | epic id, child ticket list, repo state, artifact links | ticket maturity map, dependency map, ready work queue, maturity work queue | epic assessment comment or run ledger entry | explorer/reviewer workers for dependency checks only | ticket access failure, inconsistent child hierarchy, missing repo |

## Inputs

- epic id
- child ticket list
- repo state
- artifact links
- existing labels and comments
- optional run ledger records

## Process

- Read the epic and child tickets from the PM system.
- Inspect labels, comments, artifact links, branches, and worktrees.
- Classify each child using the state transition table through ready-for-child-pr only.
- Build ready work and maturity work queues.
- Treat `spec-ready` and `ready-to-implement` as hard gates.
- Do not activate Phase 3 states or create PRs.

## Evidence

- Record child state map, dependency map, ready work queue, maturity work queue, and blockers.
- Record source links for labels, comments, specs, plans, branches, and worktrees.
- The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.
- Durable PM state is the source of truth.

## Stop Conditions

- Stop on ticket access failure, inconsistent child hierarchy, or missing repository context.
- Stop when a child ticket needs human spec input.
- Stop when dependencies are unclear enough to affect sequencing.
- Stop at `ready-for-child-pr` for locally completed tickets.
