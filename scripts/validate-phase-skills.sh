#!/usr/bin/env bash
set -euo pipefail

skills=(
  brainstorm
  file-ticket
  implement
  pickup
  quality-gate
  review
  submit
  verify
  write-plan
  epic-orchestrator
  pickup-epic
  assess-epic
  mature-ticket
  pickup-ticket
  implement-ticket
  review-implementation
  create-tests
  review-child-pr
  submit-ticket-pr
  submit-epic-pr
)

for skill in "${skills[@]}"; do
  test -f "dodi-dev/skills/${skill}/SKILL.md"
  test -f "plugins/dodi-dev/skills/${skill}/SKILL.md"
done

find plugins/dodi-dev/skills -type l -print | while read -r link; do
  echo "unexpected symlink: ${link}" >&2
  exit 1
done
find dodi-dev/skills -type l -print | while read -r link; do
  echo "unexpected symlink: ${link}" >&2
  exit 1
done
find dodi-dev/skills plugins/dodi-dev/skills -maxdepth 2 -type f | sort

echo "phase skills ok"
