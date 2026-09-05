#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"

# Copy-tree-and-mutate: the validator reads only dodi-dev/skills, dodi-dev/scripts,
# dodi-dev/hooks, dodi-dev/.claude-plugin (the function-hook chain), and its own
# repo-relative paths — no templates/, no git state.
# Enumerated subtrees, not `cp -R dodi-dev`: the main checkout hosts worktrees
# under dodi-dev/worktrees/, which a bare recursive copy would drag along.
# AGENTS.md is copied too: the Fable Availability Policy check (validator,
# pre-registry loop) greps AGENTS.md for any `model: fable` frontmatter pin it
# finds under dodi-dev/skills — and mature-ticket/SKILL.md carries one (DOD-1215)
# — so an unmutated copy without AGENTS.md fails case (a) for a reason
# unrelated to the registry this test exercises.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/dodi-dev"
cp -R "$REPO_ROOT/dodi-dev/skills" "$REPO_ROOT/dodi-dev/scripts" "$REPO_ROOT/dodi-dev/hooks" "$REPO_ROOT/dodi-dev/.claude-plugin" "$tmp/dodi-dev/"
cp -R "$REPO_ROOT/scripts" "$tmp/"
cp "$REPO_ROOT/AGENTS.md" "$tmp/"

fail=0
# The validator's error messages name prompts skill-relative (the ${prompt}
# array value), not repo-relative — assert on that form.
prompt_rel="submit-epic-pr/epic-integration-reviewer-prompt.md"
target_rel="dodi-dev/skills/$prompt_rel"
target="$tmp/$target_rel"

run_validator() { # sets rc and err
  rc=0
  err="$( (cd "$tmp" && bash scripts/validate-phase-skills.sh 2>&1 >/dev/null) )" || rc=$?
}

# Case (a): unmutated copy passes.
run_validator
if [[ "$rc" -ne 0 ]]; then
  echo "FAIL case-a: validator failed on unmutated copy: $err" >&2
  fail=1
fi

# Case (b): remove EVERY 'Frontier tier' occurrence from the dual-tier template
# (the registry check is file-scope — a partial removal would pass wrongly).
sed 's/Frontier tier/Redacted tier/g' "$target" > "$target.new" && mv "$target.new" "$target"
if grep -q 'Frontier tier' "$target"; then
  echo "FAIL case-b: mutation did not apply" >&2
  fail=1
fi
run_validator
if [[ "$rc" -eq 0 ]]; then
  echo "FAIL case-b: validator passed with the Frontier seat undeclared" >&2
  fail=1
fi
case "$err" in
  *"$prompt_rel"*) ;;
  *) echo "FAIL case-b: stderr does not name the offending file: $err" >&2; fail=1 ;;
esac
case "$err" in
  *Frontier*) ;;
  *) echo "FAIL case-b: stderr does not name the missing seat (Frontier): $err" >&2; fail=1 ;;
esac

# Restore for case (c).
cp "$REPO_ROOT/$target_rel" "$target"

# Case (c): a prompt_files entry with no registry row fails the completeness
# assert. The fake file carries a valid single-tier declaration so the failure
# is the registry's, not the tier-presence loop's.
vt="$tmp/scripts/validate-phase-skills.sh"
awk '{print} $0 == "  submit-epic-pr/epic-integration-reviewer-prompt.md" {print "  submit-epic-pr/fake-seat-prompt.md"}' "$vt" > "$vt.new" && mv "$vt.new" "$vt"
if ! grep -q 'fake-seat-prompt.md' "$vt"; then
  echo "FAIL case-c: prompt_files mutation did not apply" >&2
  fail=1
fi
printf 'You are a fake seat (Fast tier, no effort axis). Registry completeness-assert fixture.\n' \
  > "$tmp/dodi-dev/skills/submit-epic-pr/fake-seat-prompt.md"
run_validator
if [[ "$rc" -eq 0 ]]; then
  echo "FAIL case-c: validator passed with an unregistered prompt file" >&2
  fail=1
fi
case "$err" in
  *"no seat-registry row"*"fake-seat-prompt.md"*) ;;
  *) echo "FAIL case-c: expected the no-seat-registry-row message naming fake-seat-prompt.md, got: $err" >&2; fail=1 ;;
esac

if (( fail )); then echo "validate-phase-skills tests FAILED" >&2; exit 1; fi
echo "validate-phase-skills tests ok"
