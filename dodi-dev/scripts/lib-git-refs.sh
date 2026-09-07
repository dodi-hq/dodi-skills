#!/usr/bin/env bash
# Shared git-ref helpers for scripts that check whether a branch is merged.
# Sourced, not executed.

# fetch_and_track_ref <remote> <branch>
# Force-updates refs/remotes/<remote>/<branch> regardless of the remote's
# configured fetch refspec. A plain `git fetch origin <branch>` only lands the
# commit in FETCH_HEAD and leaves the local tracking ref stale/missing when
# origin's fetch refspec doesn't cover that branch (e.g. restricted to
# `+refs/heads/master:refs/remotes/origin/master`) — which made a real,
# already-merged PR read back as "NOT verified" (DOD-1351).
fetch_and_track_ref() {
  local remote="$1" branch="$2"
  git fetch "$remote" "+refs/heads/$branch:refs/remotes/$remote/$branch" --quiet
}

# resolve_branch_tip <branch>
# Prints the tip SHA of refs/remotes/origin/<branch>, falling back to
# refs/heads/<branch>. Prints nothing and returns 1 if neither resolves.
# Uses `rev-parse --verify -q` rather than a bare `rev-parse ref1 || rev-parse
# ref2`: a bare `git rev-parse <missing-ref>` echoes the ref name to stdout
# before failing, and command substitution captures that stdout regardless of
# exit code — so when ref1 was missing and ref2 resolved, the bare-rev-parse
# chain produced a two-line value (echoed ref1 name, then ref2's real SHA),
# corrupting every downstream merge-base/diff call (DOD-1351).
resolve_branch_tip() {
  local branch="$1" tip
  tip="$(git rev-parse --verify -q "refs/remotes/origin/$branch" 2>/dev/null)" && { printf '%s\n' "$tip"; return 0; }
  tip="$(git rev-parse --verify -q "refs/heads/$branch" 2>/dev/null)" && { printf '%s\n' "$tip"; return 0; }
  return 1
}
