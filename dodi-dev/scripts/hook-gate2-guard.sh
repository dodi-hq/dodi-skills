#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash) — client-side Gate 2 guard.
# Blocks any `gh pr merge` whose PR targets main/master. Fails CLOSED: if the
# command is a merge and the base branch cannot be determined, it is blocked.
# Server-side branch protection remains the authoritative enforcement.
set -uo pipefail

input="$(cat)"
command="$(HOOK_IN="$input" python3 -c 'import json,os; print(json.loads(os.environ["HOOK_IN"]).get("tool_input", {}).get("command", ""))' 2>/dev/null)" || exit 0

# Not a PR merge → allow.
if ! grep -qE 'gh[[:space:]]+pr[[:space:]]+merge' <<<"$command"; then
  exit 0
fi

# Extract the PR identifier (number or URL) following `gh pr merge`.
pr_ref="$(grep -oE 'gh[[:space:]]+pr[[:space:]]+merge[[:space:]]+([^[:space:]]+)' <<<"$command" | awk '{print $4}')"
cwd="$(HOOK_IN="$input" python3 -c 'import json,os; print(json.loads(os.environ["HOOK_IN"]).get("cwd", "."))' 2>/dev/null || echo .)"

base=""
if [[ -n "$pr_ref" ]]; then
  base="$(cd "$cwd" 2>/dev/null && gh pr view "$pr_ref" --json baseRefName -q .baseRefName 2>/dev/null || true)"
fi

if [[ "$base" == "main" || "$base" == "master" ]]; then
  echo "BLOCKED by dodi-dev Gate 2 guard: this PR targets '$base' — the epic PR into main/master is merged only by a human (Gate 2). No automation may merge it." >&2
  exit 2
fi

if [[ -z "$base" ]]; then
  echo "BLOCKED by dodi-dev Gate 2 guard: could not determine the PR's base branch for '$command'. Merges fail closed — verify the PR targets an epic branch (not main/master) with 'gh pr view <pr> --json baseRefName', then retry." >&2
  exit 2
fi

exit 0
