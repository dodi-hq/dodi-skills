---
name: submit
description: Use after review passes — creates PR, waits for CI, and merges only after CI is green
---

# Submit

Create a PR and merge only after CI passes.

## Process

1. **Pre-flight:**
   - Verify you're on a feature branch (not main/master)
   - Check for uncommitted changes — commit or warn
   - Ensure branch is pushed to remote

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
   - Check CI status: `gh pr checks <pr-number> --watch`
   - If CI fails: report the failure, do NOT merge
   - If CI passes: proceed to merge

4. **Merge (only after CI green):**
   - Confirm with user before merging
   - `gh pr merge <pr-number> --squash --delete-branch`

5. **Cleanup:**
   - Remove worktree if applicable: `git worktree remove <path>`
   - Delete local branch if not already deleted
   - Update ticket status if tracker tools available

## Key Rules

- **Never merge with failing CI**
- **Never force-merge without user confirmation**
- **Always squash-merge** (clean history)
- **Delete branch after merge** (keep repo clean)
