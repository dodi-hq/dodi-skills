---
name: pickup-epic
description: Use when epic orchestration needs to create or resume the epic branch and worktree from the repository base branch
---

# Pickup Epic

Prepare the epic branch and epic worktree. This skill performs branch setup only; it does not assess child tickets, implement code, create PRs, or merge branches.

## Contract

| Trigger | Inputs | Outputs | Durable writes | Allowed delegation | Failure states |
| --- | --- | --- | --- | --- | --- |
| epic accepted for orchestration | epic id, repo path, optional base branch | epic branch and epic worktree | epic comment with branch/worktree paths and base branch | none by default | dirty worktree, missing base branch, branch conflict, pull failure |

## Inputs

- epic id
- repo path
- optional base branch
- optional epic branch name
- optional epic worktree path

## Process

- Verify the current repository worktree is clean before changing branches.
- Discover the base branch from input or origin default branch.
- Pull the latest base branch before creating or refreshing the epic branch.
- Create or switch to the epic branch and epic worktree.
- Do not create PRs or merge branches.
- Report `ready-for-child-pr` only as a Phase 2 boundary state when downstream local checks eventually reach that state.

## Evidence

- Record epic id, repo path, base branch, epic branch, and epic worktree.
- Record branch creation or switch output.
- Record the pull result from the base branch.
- The orchestrator may not advance state from a worker success claim alone. Verify durable PM labels, PM comments, artifact links, branch/worktree state, commits, or command output before advancing.
- Durable PM state is the source of truth.

## Stop Conditions

- Stop on dirty worktree, missing base branch, branch conflict, or pull failure.
- Stop if creating or switching the worktree would overwrite local changes.
- Stop on tool or auth failure.
