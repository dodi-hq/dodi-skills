---
name: pickup-ticket
description: Use when a child ticket is ready to implement and needs a child branch and worktree created from the epic branch
model: haiku
---

# Pickup Ticket

Create the child ticket branch and worktree from the epic branch. This skill is the implementation pickup gate; it must refuse tickets missing readiness labels.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| child has `ready-to-implement` | ticket id, epic branch/worktree, repo path, clean spec, clean plan | child branch and child worktree based on epic branch | ticket comment with child branch/worktree | none by default | stale epic branch, branch conflict, dirty worktree, missing readiness labels |

## Inputs

- ticket id
- repo path
- epic branch and worktree
- clean spec artifact
- clean plan artifact
- `spec-ready` and `ready-to-implement` labels

## Process

- Verify spec-ready and ready-to-implement are present.
- Refresh the epic branch before branching.
- Create the child branch and child worktree from the epic branch.
- Record the created branch and worktree before implementation starts.
- Do not branch from main or master for child ticket work.
- Do not create PRs or merge branches in Phase 2.

## Evidence

- Record ticket id, epic branch, child branch, child worktree, spec artifact, and plan artifact.
- Record readiness labels and latest epic branch sync evidence.

## Stop Conditions

- Stop on missing readiness labels, stale epic branch, branch conflict, or dirty worktree.
- Stop if spec or plan artifacts are missing or not clean.
- Stop if branch creation would overwrite local work.
- Stop at `ready-for-child-pr` only after local implementation, review, tests, verify, and quality-gate complete.
