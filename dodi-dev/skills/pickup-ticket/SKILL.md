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
- Default the child worktree to a sibling directory of the repo — `../<repo-name>-<ticket-id>` — matching the plain pickup skill's convention, unless a child worktree path was given as input. Never nest the worktree inside the repo tree itself (e.g. not `<repo>/worktrees/...`): a worktree nested inside the repo shows up as untracked repo content and can get walked by the repo's own tooling.
- Create the child branch and child worktree from the epic branch.
- Name the child branch `<user>/<ticket-id>-<slug>` with the ticket id lowercase (the PM system's branch-name format, e.g. `mike/dodi-123-instantly-webhook`) — this is what lets the PM system's GitHub integration attach PR state to the ticket automatically.
- Record the created branch and the child worktree path **as an absolute path** before implementation starts — the lane's dispatch manifest anchors to this absolute path (agent cwd resets between Bash calls, so a relative path is fiction for the lane). The lane's first `.dodi/` manifest write self-creates `<child-worktree-abs>/.dodi/.gitignore` containing `*` (same self-ignoring behavior as the driver's — the first manifest write in _any_ worktree owns the ignore-file creation), so the lane worktree never leaks `.dodi/` into git.
- Do not branch from main or master for child ticket work.
- Do not create PRs or merge branches from this step; the deliver-ticket lane owns the PR stage and the orchestrator owns merges.

## Evidence

- Record ticket id, epic branch, child branch, child worktree (absolute path), spec artifact, and plan artifact.
- Record readiness labels and latest epic branch sync evidence.

## Stop Conditions

- Stop on missing readiness labels, stale epic branch, branch conflict, or dirty worktree.
- Stop if spec or plan artifacts are missing or not clean.
- Stop if branch creation would overwrite local work.
- Stop at `ready-for-child-pr` only after local implementation, review, tests, and verification (incl. repo-local checks) complete.
