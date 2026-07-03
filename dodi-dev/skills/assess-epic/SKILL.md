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
- Classify each child using the orchestrator-tracked table in `epic-orchestrator/state-transitions.md`.
- Build ready work and maturity work queues.
- Build the dependency map with parallelism in mind: it is what the orchestrator uses to decide which children may run in concurrent delivery lanes, so record file-surface overlap signals (shared modules, config, schema) alongside ticket dependencies.
- Treat `spec-ready` and `ready-to-implement` as hard gates.
- The outputs feed the Gate 1 signoff package: state map, dependency map, and any child that should carry `needs-human-spec`.
- Do not create PRs or dispatch lanes from this skill.

## Evidence

- Record child state map, dependency map, ready work queue, maturity work queue, and blockers.
- Record source links for labels, comments, specs, plans, branches, and worktrees.

## Stop Conditions

- Stop on ticket access failure, inconsistent child hierarchy, or missing repository context.
- Stop when a child ticket needs human spec input.
- Stop when dependencies are unclear enough to affect sequencing — an unclear dependency also disqualifies the pair from parallel lanes.
