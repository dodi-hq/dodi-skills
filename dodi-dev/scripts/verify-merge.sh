#!/usr/bin/env bash
# Post-merge postcondition check. `gh pr merge` can exit 0 without merging —
# never claim a merge from the merge command alone; claim it from this script.
#
# Usage: verify-merge.sh <pr-number> <target-branch> [repo-dir=.]
# Exit: 0 verified (prints merge commit SHA); 1 not merged / not reachable; 2 error.
set -euo pipefail

pr="${1:?usage: verify-merge.sh <pr-number> <target-branch> [repo-dir]}"
target="${2:?usage: verify-merge.sh <pr-number> <target-branch> [repo-dir]}"
repo_dir="${3:-.}"
cd "$repo_dir"

state_json="$(gh pr view "$pr" --json state,mergeCommit)"
state="$(STATE="$state_json" python3 -c 'import json,os; print(json.loads(os.environ["STATE"])["state"])')"
sha="$(STATE="$state_json" python3 -c 'import json,os; mc=json.loads(os.environ["STATE"])["mergeCommit"]; print(mc["oid"] if mc else "")')"

if [[ "$state" != "MERGED" || -z "$sha" ]]; then
  echo "verify-merge: PR #$pr state=$state mergeCommit=${sha:-none} — NOT verified" >&2
  exit 1
fi

git fetch origin "$target" --quiet
if git merge-base --is-ancestor "$sha" "origin/$target"; then
  echo "$sha"
else
  echo "verify-merge: merge commit $sha not reachable on origin/$target — NOT verified" >&2
  exit 1
fi
