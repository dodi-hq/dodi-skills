#!/usr/bin/env bash
# Delete a branch (remote + worktree + local) only after verifying it is merged
# by SHA reachability from the base branch — never by name.
#
# Usage: cleanup-branch.sh <branch> <base-branch> [worktree-path] [repo-dir=.]
# Exit: 0 cleaned; 1 refused (not verifiably merged); 2 error.
set -euo pipefail

branch="${1:?usage: cleanup-branch.sh <branch> <base-branch> [worktree-path] [repo-dir]}"
base="${2:?usage: cleanup-branch.sh <branch> <base-branch> [worktree-path] [repo-dir]}"
worktree="${3:-}"
repo_dir="${4:-.}"
cd "$repo_dir"

git fetch origin "$base" --quiet
tip="$(git rev-parse "refs/remotes/origin/$branch" 2>/dev/null || git rev-parse "refs/heads/$branch" 2>/dev/null || true)"
if [[ -z "$tip" ]]; then
  echo "cleanup-branch: $branch has no local or remote ref; nothing to clean" >&2
  exit 1
fi

# Squash merges rewrite the SHA, so also accept an empty diff against base.
if ! git merge-base --is-ancestor "$tip" "origin/$base"; then
  if [[ -n "$(git diff "origin/$base"..."$tip" --name-only)" ]]; then
    echo "cleanup-branch: REFUSED — $branch ($tip) is neither reachable from origin/$base nor content-merged" >&2
    exit 1
  fi
fi

git push origin --delete "$branch" 2>/dev/null || echo "cleanup-branch: remote branch already gone"
if [[ -n "$worktree" && -d "$worktree" ]]; then
  git worktree remove "$worktree" --force
fi
git branch -D "$branch" 2>/dev/null || echo "cleanup-branch: local branch already gone"
git worktree prune
echo "cleaned $branch (verified against origin/$base)"
