#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
VM="$HERE/../verify-merge.sh"
bash -n "$VM"

# DOD-1351 regression: origin's configured fetch refspec is restricted to
# master only (as in the dodi_v2 repo). `git fetch origin <target>` with no
# explicit refspec lands the commit in FETCH_HEAD but never creates/updates
# refs/remotes/origin/<target> when the remote's fetch refspec doesn't cover
# it — so `git merge-base --is-ancestor <sha> origin/<target>` blows up on a
# missing ref (or compares against a stale one), and a real merge reads back
# as "NOT verified". A normal full-clone remote never reproduces this: the
# tracking ref pre-exists from the clone itself.

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
)

git clone -q remote.git clone1
cd clone1
git config user.email t@t.test; git config user.name t
# Restrict AFTER cloning, and merge into a branch (epic-target) that is
# created only AFTER the restriction — clone1 has never seen it at all, so
# the "opportunistic tracking-ref update on clone" escape hatch cannot apply.
git config remote.origin.fetch "+refs/heads/master:refs/remotes/origin/master"

(
  cd ../seed
  git checkout -q master -b epic-target
  git merge -q --no-ff feature-branch -m "Merge PR #99"
  git rev-parse HEAD >"$tmp/merge_sha"
  git push -q origin epic-target
)
merge_sha="$(cat "$tmp/merge_sha")"

fakebin="$tmp/fakebin"; mkdir -p "$fakebin"
cat >"$fakebin/gh" <<EOF
#!/usr/bin/env bash
echo '{"state":"MERGED","mergeCommit":{"oid":"$merge_sha"}}'
EOF
chmod +x "$fakebin/gh"

# --- Case 1: real merge on a branch never before tracked locally -> verified.
set +e
out="$(PATH="$fakebin:$PATH" bash "$VM" 99 epic-target . 2>&1)"
rc=$?
set -e
[[ "$rc" -eq 0 ]] || { echo "FAIL verified: expected exit 0, got $rc ($out)" >&2; exit 1; }
[[ "$out" == "$merge_sha" ]] || { echo "FAIL verified: expected sha $merge_sha, got: $out" >&2; exit 1; }

# --- Case 2: gh reports the PR as still open -> not verified, exit 1, no fetch/merge-base crash.
cat >"$fakebin/gh" <<'EOF'
#!/usr/bin/env bash
echo '{"state":"OPEN","mergeCommit":null}'
EOF
set +e
out2="$(PATH="$fakebin:$PATH" bash "$VM" 100 epic-target . 2>&1)"
rc2=$?
set -e
[[ "$rc2" -eq 1 ]] || { echo "FAIL not-merged: expected exit 1, got $rc2 ($out2)" >&2; exit 1; }
grep -q "NOT verified" <<<"$out2" || { echo "FAIL not-merged: expected NOT verified message, got: $out2" >&2; exit 1; }

echo "verify-merge tests ok"
