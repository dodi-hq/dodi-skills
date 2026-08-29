#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash) — client-side Gate 2 guard.
#
# Scope: only Gate-2-protected repositories (where a merged epic PR
# auto-deploys to production). The protected set comes from DODI_GATE2_REPOS
# (comma- or space-separated; each entry is a repo `name` or `owner/name`),
# default: dodi_v2. A `gh pr merge` in any other repository is out of scope
# and allowed — this guard must never block merges in unprotected repos.
#
# In scope, blocks any `gh pr merge` whose PR targets main/master. Fails
# CLOSED: the merge is blocked whenever the hook payload cannot be parsed for
# a merge-shaped command, the target repository cannot be determined, or the
# PR's base branch cannot be verified against the target repository. The base
# is resolved with an explicit `--repo` (never gh's own repo inference) and
# the answer is accepted only if the returned PR URL belongs to that
# repository — a ref resolved against a different repo (seen under gh
# account/host ambiguity) is a wrong answer, not a pass.
# Server-side branch protection remains the authoritative enforcement.
set -uo pipefail

block() {
  echo "BLOCKED by dodi-dev Gate 2 guard: $1" >&2
  exit 2
}

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

merge_re='gh[[:space:]]+pr[[:space:]]+merge'

input="$(cat)"

parse_ok=1
command="$(HOOK_IN="$input" python3 -c 'import json,os; d=json.loads(os.environ["HOOK_IN"]); ti=d.get("tool_input") or d.get("toolInput") or {}; print(ti.get("command",""))' 2>/dev/null)" || parse_ok=0

if [[ "$parse_ok" -ne 1 ]]; then
  # Could not parse the payload. If it plausibly carries a merge, fail closed;
  # a broken parser must never wave a merge through.
  if grep -qE "$merge_re" <<<"$input"; then
    block "hook payload could not be parsed, and it appears to carry a 'gh pr merge'. Merges fail closed — retry, or merge only after a human verifies the PR's base branch."
  fi
  exit 0
fi

# Not a PR merge → allow.
if ! grep -qE "$merge_re" <<<"$command"; then
  exit 0
fi

cwd="$(HOOK_IN="$input" python3 -c 'import json,os; print(json.loads(os.environ["HOOK_IN"]).get("cwd", "."))' 2>/dev/null || echo .)"

# Extract the PR identifier (number, URL, or branch) following `gh pr merge`.
# A flag in that position means the ref was omitted (merge the current branch).
pr_ref="$(grep -oE "${merge_re}[[:space:]]+[^[:space:]]+" <<<"$command" | awk '{print $4}')"
case "$pr_ref" in -*) pr_ref="" ;; esac

# Resolve the target repository ourselves: from the PR URL if one was given,
# else from the cwd's origin remote, else GH_REPO. gh's own inference is never
# trusted for scoping — under an ambiguous gh account/host it can resolve the
# ref against the wrong repository.
owner_repo=""
pull_url_re='^https?://[^/]+/([^/]+)/([^/]+)/pull/[0-9]+'
if [[ "$pr_ref" =~ $pull_url_re ]]; then
  owner_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
else
  for candidate in "$(git -C "$cwd" remote get-url origin 2>/dev/null || true)" "${GH_REPO:-}"; do
    [[ -n "$owner_repo" || -z "$candidate" ]] && continue
    u="${candidate%/}"
    u="${u%.git}"
    case "$u" in
      http://*|https://*|ssh://*)
        rest="${u#*://}"   # host[:port]/...path
        rest="${rest#*/}"  # ...path
        ;;
      *@*:*)
        rest="${u#*:}"     # scp-style git@host:owner/name
        ;;
      *)
        rest="$u"          # bare OWNER/NAME (GH_REPO form)
        ;;
    esac
    if [[ "$rest" == */* && "$rest" != */*/* ]]; then
      owner_repo="$rest"
    fi
  done
fi

if [[ -z "$owner_repo" ]]; then
  block "could not determine the target repository for '$command' (no PR URL in the command, no usable 'origin' remote in '$cwd', no GH_REPO). Merges fail closed — run the merge from the repository checkout or pass the full PR URL."
fi

# Out of scope → allow. Only Gate-2-protected repos are guarded.
repo_lc="$(lc "$owner_repo")"
name_lc="${repo_lc##*/}"
in_scope=0
for entry in $(printf '%s' "${DODI_GATE2_REPOS:-dodi_v2}" | tr ',' ' '); do
  entry_lc="$(lc "$entry")"
  if [[ "$entry_lc" == */* ]]; then
    [[ "$repo_lc" == "$entry_lc" ]] && in_scope=1
  else
    [[ "$name_lc" == "$entry_lc" ]] && in_scope=1
  fi
done
if [[ "$in_scope" -ne 1 ]]; then
  exit 0
fi

# Resolve the base branch, pinned to the scoped repository. Accept the answer
# only if the returned PR URL actually lives in that repository (and matches a
# numeric ref) — otherwise treat the base as unknown and fail closed.
view_json="$(cd "$cwd" 2>/dev/null || true; gh pr view ${pr_ref:+"$pr_ref"} --repo "$owner_repo" --json baseRefName,url 2>/dev/null)" || view_json=""

base=""
if [[ -n "$view_json" ]]; then
  base="$(VIEW_JSON="$view_json" EXPECT_REPO="$owner_repo" PR_REF="$pr_ref" python3 - <<'PY' 2>/dev/null
import json, os, re
from urllib.parse import urlparse
try:
    d = json.loads(os.environ["VIEW_JSON"])
except Exception:
    raise SystemExit(0)
url = d.get("url") or ""
m = re.match(r"^/([^/]+/[^/]+)/pull/(\d+)$", urlparse(url).path or "")
if not m or m.group(1).lower() != os.environ["EXPECT_REPO"].lower():
    raise SystemExit(0)  # resolved against a different repository — reject
ref = os.environ.get("PR_REF", "")
if ref.isdigit() and m.group(2) != ref:
    raise SystemExit(0)  # resolved a different PR than the one being merged
print(d.get("baseRefName", ""))
PY
)" || base=""
fi

if [[ "$base" == "main" || "$base" == "master" ]]; then
  echo "BLOCKED by dodi-dev Gate 2 guard: this PR targets '$base' in Gate-2-protected repo '$owner_repo' — the epic PR into main/master is merged only by a human (Gate 2). No automation may merge it." >&2
  exit 2
fi

if [[ -z "$base" ]]; then
  block "could not verify the PR's base branch for '$command' in Gate-2-protected repo '$owner_repo' (gh failed, or resolved a different repo/PR — check the active gh account with 'gh auth status'). Merges fail closed — verify the PR targets an epic branch (not main/master) with 'gh pr view <pr> --repo $owner_repo --json baseRefName', then retry."
fi

exit 0
