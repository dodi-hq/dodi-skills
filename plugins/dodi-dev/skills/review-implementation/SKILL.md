---
name: review-implementation
description: Use when child ticket implementation is complete and needs fresh-context pre-PR review before tests and local readiness
model: sonnet
---

# Review Implementation

Run the pre-PR implementation review loop from fresh context. Reviewers read the spec, plan, and diff directly; implementation workers fix findings until the final review is clean.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| implementation completes before PR creation | ticket id, clean spec, clean plan, child worktree, diff | clean pre-PR review or findings to fix | ticket comment with reviewer status and fixed findings | fresh-context code reviewers and fix workers | review findings, spec/plan mismatch, production changes requiring focused re-review |

## Inputs

- ticket id
- clean spec
- clean plan
- child worktree
- implementation diff
- prior review findings, if any

## Process

- Read the spec, plan, and diff directly.
- Dispatch a fresh-context reviewer.
- Dispatch fix workers for findings.
- Repeat until the final review round is clean.
- Require focused re-review when production code changes during verification.
- Do not create PRs or merge branches in Phase 2.

## Evidence

- Record reviewer status, findings, fixes, reviewed diff range, and final clean review evidence.
- Record whether findings were implementation issues, test issues, hygiene/security issues, regression risks, or spec/plan mismatches.
- The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.
- Durable PM state is the source of truth.

## Stop Conditions

- Stop on spec/plan mismatch or unresolved review findings.
- Stop if fixes require product, architecture, scope, or plan judgment.
- Stop if a focused re-review is required and not yet clean.
- Stop at `ready-for-child-pr` only after review, tests, verification, and quality gate are clean.
