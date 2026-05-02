---
name: create-tests
description: Use when implementation review is clean and tests must be created or completed according to the ticket Testing Contract
---

# Create Tests

Create or complete required tests from the plan's Testing Contract. Missing harnesses are work to set up where feasible, not a reason to skip required test groups.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| implementation review is clean or plan requires tests | Testing Contract, changed files, child worktree, repo instructions | tests satisfying Testing Contract or concrete escalation | ticket comment with test files, rationale, harness setup evidence | test implementation workers and harness setup workers | invalid Testing Contract, missing harness blocker, spec/plan mismatch |

## Inputs

- Testing Contract
- changed files
- child worktree
- repo instructions
- implementation summary
- review evidence

## Process

- Read the Testing Contract from the plan.
- Dispatch test workers for required unit, integration, and e2e groups.
- Set up missing required harnesses where feasible.
- Escalate when the Testing Contract is invalid.
- Record rationale only for test groups marked not required by the plan.
- Do not create PRs or merge branches in Phase 2.

## Evidence

- Record test files, required groups, harness setup evidence, and rationale for any not-required group.
- Record commands expected to be run by `verify`.
- The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.
- Durable PM state is the source of truth.

## Stop Conditions

- Stop on invalid Testing Contract, missing harness blocker, or spec/plan mismatch.
- Stop if a required harness cannot be set up and report the concrete blocker.
- Stop if test creation reveals an implementation issue that must be fixed first.
- Stop at `ready-for-child-pr` only after verification and quality gate are clean.
