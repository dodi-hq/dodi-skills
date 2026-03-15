---
name: submit
description: Use after review passes — creates PR, waits for CI, and merges only after CI is green
---

# Submit

Create a PR, wait for CI to pass, then merge.

## Process

1. **Pre-flight:**
   - Verify you're on a feature branch (not main/master)
   - Check for uncommitted changes — commit or warn
   - Ensure branch is pushed to remote
   - **Run `/quality-gate`** if available in the current repo (skip silently if not)

2. **Create PR:**
   ```bash
   git push -u origin <branch>
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   <2-3 bullets>

   ## Test Plan
   - [ ] <verification steps>

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   EOF
   )"
   ```

3. **Wait for CI:**
   CI is triggered automatically when a PR is opened. It may take several minutes for checks to appear, and 30-45 minutes to complete.

   - Poll for CI status: `gh pr checks <pr-number> --watch`
   - If no checks appear after 30 seconds, poll with: `gh run list --branch <branch> --limit 1`
   - If CI fails: read the failure logs (`gh run view <run-id> --log-failed`), report the failure, and do NOT merge. Offer to fix the issue.
   - If CI passes: proceed to merge

4. **Merge (only after CI green):**
   - Confirm with user before merging
   - `gh pr merge <pr-number> --squash --delete-branch`
   - If branch protection blocks the merge, CI may not have finished yet — go back to step 3

5. **Cleanup:**
   - Remove worktree if applicable: `git worktree remove <path>`
   - Delete local branch if not already deleted
   - Update ticket status if tracker tools available

## Key Rules

- **Never merge with failing CI** — always wait for green
- **Never force-merge or use --admin** without explicit user approval
- **Always squash-merge** (clean history)
- **Delete branch after merge** (keep repo clean)
- **CI takes time** — don't try to merge immediately after creating the PR
