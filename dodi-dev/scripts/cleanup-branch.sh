#!/usr/bin/env bash
# Delete a branch (remote + worktree + local) only after verifying it is merged
# — never by name. Two accepted proofs:
#   1. The branch tip is reachable from origin/<base> (true merge / fast-forward).
#   2. A verified merge SHA is supplied (the SHA verify-merge.sh printed for the
#      branch's PR) and that SHA is reachable from origin/<base> — the chain of
#      trust for SQUASH merges, which rewrite the SHA so proof 1 can never hold.
# Squash merges are the primary merge mode: callers should always thread the
# SHA from verify-merge.sh through. Without it, a squash-merged branch is
# refused (fail closed).
#
# Usage: cleanup-branch.sh <branch> <base-branch> [worktree-path] [repo-dir=.] [verified-merge-sha]
# Exit: 0 cleaned; 1 refused (not verifiably merged); 2 error.
set -euo pipefail

branch="${1:?usage: cleanup-branch.sh <branch> <base-branch> [worktree-path] [repo-dir] [verified-merge-sha]}"
base="${2:?usage: cleanup-branch.sh <branch> <base-branch> [worktree-path] [repo-dir] [verified-merge-sha]}"
worktree="${3:-}"
repo_dir="${4:-.}"
verified_sha="${5:-}"
cd "$repo_dir"

git fetch origin "$base" --quiet
tip="$(git rev-parse "refs/remotes/origin/$branch" 2>/dev/null || git rev-parse "refs/heads/$branch" 2>/dev/null || true)"
if [[ -z "$tip" ]]; then
  echo "cleanup-branch: $branch has no local or remote ref; nothing to clean" >&2
  exit 1
fi

proof=""
if git merge-base --is-ancestor "$tip" "origin/$base"; then
  proof="tip $tip reachable from origin/$base"
elif [[ -n "$verified_sha" ]]; then
  # Squash proof: the supplied SHA must be reachable from base AND carry this
  # branch's content (patch-id of the squash commit == patch-id of the branch's
  # net diff). Reachability alone would let a wrong-but-reachable SHA delete an
  # unmerged branch.
  if ! git merge-base --is-ancestor "$verified_sha" "origin/$base"; then
    echo "cleanup-branch: REFUSED — supplied merge SHA ($verified_sha) is not reachable from origin/$base" >&2
    exit 1
  fi
  mb="$(git merge-base "$tip" "origin/$base")"
  branch_pid="$(git diff "$mb".."$tip" | git patch-id --stable | awk '{print $1}')"
  squash_pid="$(git diff-tree -p "$verified_sha" | git patch-id --stable | awk '{print $1}')"
  if [[ -n "$branch_pid" && "$branch_pid" == "$squash_pid" ]]; then
    proof="squash merge $verified_sha content-matches $branch net diff (patch-id) and is reachable from origin/$base"
  else
    echo "cleanup-branch: REFUSED — supplied SHA $verified_sha is reachable from origin/$base but its patch-id does not match $branch's net diff ($mb..$tip). Either the SHA is not this branch's merge, or the squash resolved conflicts; verify manually before deleting." >&2
    exit 1
  fi
else
  echo "cleanup-branch: REFUSED — $branch ($tip) is not reachable from origin/$base and no verified merge SHA was supplied. For squash merges, pass the SHA that verify-merge.sh printed as the 5th argument." >&2
  exit 1
fi

git push origin --delete "$branch" 2>/dev/null || echo "cleanup-branch: remote branch already gone"
if [[ -n "$worktree" && -d "$worktree" ]]; then
  git worktree remove "$worktree" --force
fi
git branch -D "$branch" 2>/dev/null || echo "cleanup-branch: local branch already gone"
git worktree prune
echo "cleaned $branch ($proof)"
