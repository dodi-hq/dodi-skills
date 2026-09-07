#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CB="$HERE/../cleanup-branch.sh"
bash -n "$CB"

# DOD-1351 regression: origin's configured fetch refspec is restricted to
# master only (as in the dodi_v2 repo). `git fetch origin <base>` with no
# explicit refspec then leaves refs/remotes/origin/<base> stale or missing,
# and a bare `git rev-parse <maybe-missing-ref> || git rev-parse <fallback>`
# leaks the missing ref's echoed name onto stdout, corrupting $tip. Both bugs
# are exercised here against a from-scratch bare remote + restricted clone —
# a normal full-clone remote never reproduces either.

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

git init -q --bare remote.git
git clone -q remote.git seed
(
  cd seed
  git config user.email t@t.test; git config user.name t
  echo base >f.txt && git add f.txt && git commit -q -m init
  git branch -m master && git push -q origin master
  git checkout -q -b feature-branch
  echo change >>f.txt && git commit -q -am "feature commit"
  git push -q origin feature-branch
  git checkout -q -b unmerged-branch master
  echo other >>f.txt && git commit -q -am "unmerged commit"
  git push -q origin unmerged-branch
)

git clone -q remote.git clone1
cd clone1
git config user.email t@t.test; git config user.name t
# Restrict AFTER cloning: mirrors a real remote whose fetch refspec never
# covered non-master branches in the first place.
git config remote.origin.fetch "+refs/heads/master:refs/remotes/origin/master"

# Land the squash merge on master only after the restriction is in place, so
# refs/remotes/origin/master (if fetched the buggy way) would also be stale —
# fetch_and_track_ref must force it current regardless.
(
  cd ../seed
  git checkout -q master
  git merge -q --squash feature-branch
  git commit -q -m "squash merge feature-branch"
  git rev-parse HEAD >"$tmp/merge_sha"
  git push -q origin master
)
merge_sha="$(cat "$tmp/merge_sha")"

# --- Case 1: squash-merged branch, proven via verified SHA -> cleaned, exit 0.
set +e
out="$(bash "$CB" feature-branch master "" . "$merge_sha" 2>&1)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || { echo "FAIL squash-clean: expected exit 0, got $rc ($out)" >&2; exit 1; }
grep -q "^cleaned feature-branch" <<<"$out" || { echo "FAIL squash-clean: expected 'cleaned feature-branch', got: $out" >&2; exit 1; }

# --- Case 2: genuinely unmerged branch -> refused, never reaches the deletion
# steps. This also exercises resolve_branch_tip's "ref legitimately absent"
# path (unmerged-branch was never fetched under the restricted refspec) —
# a corrupted two-line $tip would otherwise crash merge-base with a garbage
# ref argument instead of cleanly reporting "nothing to clean".
set +e
out2="$(bash "$CB" unmerged-branch master 2>&1)"
rc2=$?
set -e
[[ "$rc2" -ne 0 ]] || { echo "FAIL unmerged: expected non-zero exit, got 0 ($out2)" >&2; exit 1; }
grep -qE "nothing to clean|REFUSED" <<<"$out2" || { echo "FAIL unmerged: expected a refusal message, got: $out2" >&2; exit 1; }

# --- Case 3: the Bug-1 vector — a branch with a local head but NO
# remote-tracking ref. Cases 1 and 2 cannot reach it: clone1 was cloned before
# the refspec was restricted, so refs/remotes/origin/<branch> exists for both
# and resolve_branch_tip returns on its first lookup. Only a purely local
# branch forces the fallback, where the old
#   `git rev-parse <missing> || git rev-parse <fallback>`
# chain leaked the missing ref's echoed name onto stdout and produced a
# two-line $tip — non-empty, so it passed the -z guard and then crashed the
# merge-base/patch-id calls with a garbage ref (DOD-1351).
git fetch origin master --quiet
git branch local-only refs/remotes/origin/master
[[ -z "$(git rev-parse --verify -q refs/remotes/origin/local-only 2>/dev/null)" ]] \
  || { echo "FAIL local-only: precondition — remote-tracking ref must not exist" >&2; exit 1; }
set +e
out3="$(bash "$CB" local-only master 2>&1)"
rc3=$?
set -e
[[ "$rc3" -eq 0 ]] || { echo "FAIL local-only: expected exit 0, got $rc3 ($out3)" >&2; exit 1; }
grep -q "^cleaned local-only" <<<"$out3" || { echo "FAIL local-only: expected 'cleaned local-only', got: $out3" >&2; exit 1; }

echo "cleanup-branch tests ok"
