#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

make_fixture() {
  local name="$1"
  local root="$TMP_ROOT/$name"
  mkdir -p "$root/templates" "$root/scripts"
  cp -R "$REPO_ROOT/templates/ticket-comments" "$root/templates/"
  cp "$REPO_ROOT/scripts/validate-ticket-comment-templates.sh" "$root/scripts/"
  printf '%s' "$root"
}

run_validator() {
  local root="$1"
  (cd "$root" && bash scripts/validate-ticket-comment-templates.sh >/dev/null 2>&1)
}

baseline="$(make_fixture baseline)"
if ! run_validator "$baseline"; then
  echo "FAIL baseline: ticket-comment validator rejected an unmodified fixture" >&2
  exit 1
fi

templates=(
  spec-ready
  ready-to-implement
  lane-checkpoint
  child-pr-ready
  epic-pr-ready
  decision-register-entry
  continuation-brief
  demotion
)

for template in "${templates[@]}"; do
  fixture="$(make_fixture "missing-executor-${template}")"
  target="$fixture/templates/ticket-comments/${template}.md"
  sed '/review-executor:/d' "$target" > "$target.new"
  mv "$target.new" "$target"
  if run_validator "$fixture"; then
    echo "FAIL missing-executor-${template}: validator accepted a template without review-executor:" >&2
    exit 1
  fi
done

fixture="$(make_fixture missing-fable-makeup)"
target="$fixture/templates/ticket-comments/decision-register-entry.md"
sed '/Kind: FABLE_MAKEUP/d' "$target" > "$target.new"
mv "$target.new" "$target"
if run_validator "$fixture"; then
  echo "FAIL missing-fable-makeup: validator accepted removal of Kind: FABLE_MAKEUP" >&2
  exit 1
fi

echo "ticket comment template tests ok"
