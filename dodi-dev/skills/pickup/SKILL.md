---
name: pickup
description: Use when starting work on a ticket — creates a worktree, reads ticket context, and gets you ready to implement
---

# Pickup

Pick up a ticket and set up an isolated workspace for it.

## Input

Either a ticket reference (e.g., `DOD-152`) or a description to search for.

## Process

1. **Ensure we're on the main branch and up to date:**
   ```bash
   # Determine the main branch (master or main)
   git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
   # Switch to it
   git checkout <main-branch>
   # Pull latest
   git pull origin <main-branch>
   ```
   If there are uncommitted changes on the current branch, warn the user and stop.
2. **Look up the ticket** — use available tracker tools to read the full ticket (title, description, acceptance criteria, linked issues)
3. **Create worktree:**
   ```bash
   git worktree add ../<repo-name>-<ticket-id> -b <ticket-id>
   ```
3. **Read context** — if the ticket references a spec, read it. Check for related docs.
4. **Report ready state:**
   ```
   Picked up: <ticket-id> — <title>

   To start working:
     cd ../<repo-name>-<ticket-id> && claude

   When finished:
     git worktree remove ../<repo-name>-<ticket-id>
   ```

## Notes

- Base new worktrees on the main branch (usually `master` or `main`)
- If the branch already exists, offer to use it or suggest a different name
- The ticket ID is the branch name for traceability
- After pickup, the next step is typically `dodi-dev:write-plan`
